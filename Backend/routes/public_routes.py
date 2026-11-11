from flask import Blueprint, request, jsonify
from datetime import datetime
from models import Queue, Ticket, OperationalDay, User
from extensions import db, socketio
from werkzeug.security import check_password_hash

public_bp = Blueprint('public', __name__)

@public_bp.route('/login', methods=['POST'])
def login():
    data = request.json
    username = data.get('username')
    password = data.get('password')
    
    user = User.query.filter_by(username=username).first()
    if user and check_password_hash(user.password_hash, password):
        return jsonify({"message": "Login berhasil", "user": {"username": username}}), 200
    
    return jsonify({"error": "Username atau password salah"}), 401

@public_bp.route('/tickets', methods=['POST'])
def ambil_tiket():
    data = request.json
    service_id = data.get('service_id', 1)
    
    # Tangkap data nama dan nomor telepon dari Flutter
    nama = data.get('nama', '-')
    no_telp = data.get('no_telp', '-')
    
    today = datetime.utcnow().date()
    
    # Cari atau buat hari operasional baru
    op_day = OperationalDay.query.filter_by(service_id=service_id, business_date=today).with_for_update().first()
    if not op_day:
        op_day = OperationalDay(service_id=service_id, business_date=today, current_sequence=0)
        db.session.add(op_day)
        db.session.flush()
        
    op_day.current_sequence += 1
    new_ticket_number = f"A-{op_day.current_sequence:03d}"
    
    # Simpan nomor antrean beserta data pengunjung
    new_queue = Queue(
        operational_day_id=op_day.id, 
        ticket_number=new_ticket_number, 
        status='waiting',
        customer_name=nama,
        customer_phone=no_telp
    )
    db.session.add(new_queue)
    db.session.flush()
    db.session.add(Ticket(queue_id=new_queue.id))
    db.session.commit()
    
    # Hitung metrik real-time
    waiting_count = Queue.query.filter_by(operational_day_id=op_day.id, status='waiting').count()
    total_count = Queue.query.filter_by(operational_day_id=op_day.id).count()
    
    # Siarkan ke semua dashboard (Admin & TV) via Socket
    socketio.emit('queue.created', {
        'ticket_number': new_ticket_number,
        'waiting_count': waiting_count,
        'total_count': total_count
    })
    
    return jsonify({"message": "Berhasil", "data": {"ticket_number": new_ticket_number}}), 200

@public_bp.route('/queues/status', methods=['GET'])
def queue_status():
    service_id = request.args.get('service_id', 1, type=int)
    today = datetime.utcnow().date()
    
    op_day = OperationalDay.query.filter_by(service_id=service_id, business_date=today).first()
    if not op_day:
        return jsonify({"waiting_count": 0, "current_ticket": "-", "current_name": "-", "current_phone": "-", "total_count": 0}), 200
        
    waiting_count = Queue.query.filter_by(operational_day_id=op_day.id, status='waiting').count()
    total_count = Queue.query.filter_by(operational_day_id=op_day.id).count()
    
    current_q = Queue.query.filter_by(operational_day_id=op_day.id, status='called').first()
    
    # Ambil data nama dan telepon dari database jika ada yang sedang dipanggil
    current_ticket = current_q.ticket_number if current_q else "-"
    current_name = current_q.customer_name if current_q and current_q.customer_name else "-"
    current_phone = current_q.customer_phone if current_q and current_q.customer_phone else "-"
    
    return jsonify({
        "waiting_count": waiting_count,
        "current_ticket": current_ticket,
        "current_name": current_name,
        "current_phone": current_phone,
        "total_count": total_count
    }), 200

@public_bp.route('/tickets/action', methods=['POST'])
def ticket_action():
    data = request.json
    ticket_number = data.get('ticket_number')
    action = data.get('action') 
    target_date_str = data.get('target_date') # Tanggal tujuan untuk Reschedule
    service_id = data.get('service_id', 1)
    
    # Konversi format tanggal dari Flutter (YYYY-MM-DD)
    if target_date_str:
        target_date = datetime.strptime(target_date_str, '%Y-%m-%d').date()
    else:
        target_date = datetime.utcnow().date()

    # Cari tiket yang mau dibatalkan/di-reschedule
    q = Queue.query.filter_by(ticket_number=ticket_number, status='waiting').first()
    if not q:
        return jsonify({"error": "Tiket tidak ditemukan atau sudah dipanggil"}), 400

    # Batalkan tiket lama
    q.status = 'cancelled'
    db.session.commit()

    new_ticket_number = None

    # Jika aksi adalah Reschedule, buatkan tiket baru di tanggal target
    if action == 'reschedule':
        op_day = OperationalDay.query.filter_by(service_id=service_id, business_date=target_date).with_for_update().first()
        if not op_day:
            op_day = OperationalDay(service_id=service_id, business_date=target_date, current_sequence=0)
            db.session.add(op_day)
            db.session.flush()

        op_day.current_sequence += 1
        new_ticket_number = f"A-{op_day.current_sequence:03d}"
        
        # Pindahkan data nama & no telp dari tiket lama ke tiket baru
        new_queue = Queue(
            operational_day_id=op_day.id, 
            ticket_number=new_ticket_number, 
            status='waiting',
            customer_name=q.customer_name, # Salin nama
            customer_phone=q.customer_phone # Salin telepon
        )
        db.session.add(new_queue)
        db.session.flush()
        db.session.add(Ticket(queue_id=new_queue.id))
        db.session.commit()

    # Hitung ulang metrik antrean HARI INI untuk memperbarui Dashboard Admin
    today = datetime.utcnow().date()
    today_op_day = OperationalDay.query.filter_by(service_id=service_id, business_date=today).first()
    
    waiting_count = 0
    total_count = 0
    if today_op_day:
        waiting_count = Queue.query.filter_by(operational_day_id=today_op_day.id, status='waiting').count()
        total_count = Queue.query.filter_by(operational_day_id=today_op_day.id).count()

    # Pancarkan data ke Socket. Jika reschedule di hari lain, tiket baru tidak tampil di dashboard hari ini
    socketio.emit('queue.created', {
        'ticket_number': new_ticket_number if action == 'reschedule' and target_date == today else '-',
        'status': 'waiting',
        'waiting_count': waiting_count,
        'total_count': total_count
    })

    return jsonify({"message": "Berhasil", "new_ticket": new_ticket_number}), 200