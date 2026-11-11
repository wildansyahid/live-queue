from flask import Blueprint, request, jsonify
from extensions import db, socketio
from models import Queue, OperationalDay
from datetime import datetime

staff_bp = Blueprint('staff', __name__)

@staff_bp.route('/queues/call-next', methods=['POST'])
def call_next():
    data = request.json
    service_id = data.get('service_id', 1)
    today = datetime.utcnow().date()
    
    op_day = OperationalDay.query.filter_by(service_id=service_id, business_date=today).first()
    if not op_day:
        return jsonify({"error": "Belum ada antrean hari ini"}), 400
        
    # Ubah status antrean yang sedang dipanggil saat ini menjadi 'skipped' (jika admin lupa klik selesai)
    current_q = Queue.query.filter_by(operational_day_id=op_day.id, status='called').first()
    if current_q:
        current_q.status = 'skipped'
        
    # Cari antrean berikutnya yang berstatus 'waiting'
    next_q = Queue.query.filter_by(operational_day_id=op_day.id, status='waiting').order_by(Queue.id.asc()).first()
    if not next_q:
        db.session.commit()
        return jsonify({"error": "Tidak ada lagi antrean yang menunggu"}), 400
        
    next_q.status = 'called'
    db.session.commit()
    
    waiting_count = Queue.query.filter_by(operational_day_id=op_day.id, status='waiting').count()
    
    # Pancarkan data antrean baru beserta Nama dan No Telepon ke Frontend Admin
    socketio.emit('queue.called', {
        'ticket_number': next_q.ticket_number,
        'customer_name': next_q.customer_name or '-',
        'customer_phone': next_q.customer_phone or '-',
        'waiting_count': waiting_count
    })
    
    return jsonify({"message": "Berhasil memanggil antrean", "ticket_number": next_q.ticket_number}), 200