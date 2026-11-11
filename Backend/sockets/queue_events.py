from flask_socketio import emit
from extensions import db
from models import Queue, Ticket, OperationalDay
from datetime import datetime

def register_socket_events(socketio):
    
    @socketio.on('connect')
    def handle_connect():
        print("Klien terhubung ke WebSocket.")

    # 1. AKSI: Selesaikan Antrean
    @socketio.on('selesaikan_antrean')
    def handle_selesaikan(data):
        service_id = data.get('service_id', 1)
        today = datetime.utcnow().date()
        
        active_queues = Queue.query.join(OperationalDay).filter(
            OperationalDay.service_id == service_id,
            OperationalDay.business_date == today,
            Queue.status.in_(['called', 'serving'])
        ).all()
        
        for q in active_queues:
            q.status = 'completed'
            ticket = Ticket.query.filter_by(queue_id=q.id).first()
            if ticket: 
                ticket.completed_at = datetime.utcnow()
        
        db.session.commit()
        
        waiting_count = Queue.query.join(OperationalDay).filter(
            OperationalDay.service_id == service_id,
            OperationalDay.business_date == today,
            Queue.status == 'waiting'
        ).count()

        socketio.emit('antrean_selesai', {'display_text': '-', 'jumlah_menunggu': waiting_count})

    # 2. AKSI: Lewati Antrean (Skip)
    @socketio.on('lewati_antrean')
    def handle_lewati(data):
        service_id = data.get('service_id', 1)
        today = datetime.utcnow().date()
        
        active_queues = Queue.query.join(OperationalDay).filter(
            OperationalDay.service_id == service_id,
            OperationalDay.business_date == today,
            Queue.status.in_(['called', 'serving'])
        ).all()
        
        for q in active_queues:
            q.status = 'skipped' # Status diubah ke skipped agar tercatat di analitik
            
        db.session.commit()
        
        waiting_count = Queue.query.join(OperationalDay).filter(
            OperationalDay.service_id == service_id,
            OperationalDay.business_date == today,
            Queue.status == 'waiting'
        ).count()

        socketio.emit('antrean_selesai', {'display_text': '-', 'jumlah_menunggu': waiting_count})

    # 3. AKSI: Panggil Ulang (Recall)
    @socketio.on('panggil_ulang')
    def handle_panggil_ulang(data):
        service_id = data.get('service_id', 1)
        today = datetime.utcnow().date()
        
        active_queue = Queue.query.join(OperationalDay).filter(
            OperationalDay.service_id == service_id,
            OperationalDay.business_date == today,
            Queue.status.in_(['called', 'serving'])
        ).first()
        
        if active_queue:
            # Mengirim instruksi ke semua layar (terutama layar pengguna) untuk membunyikan/memunculkan pop-up ulang
            socketio.emit('queue.recalled', {
                'ticket_number': active_queue.ticket_number,
                'service_id': service_id
            })

    # 4. AKSI: Reset Harian
    @socketio.on('reset_antrean')
    def handle_reset(data):
        service_id = data.get('service_id', 1)
        today = datetime.utcnow().date()
        op_day = OperationalDay.query.filter_by(service_id=service_id, business_date=today).first()
        
        if op_day:
            waiting_queues = Queue.query.filter_by(operational_day_id=op_day.id, status='waiting').all()
            for q in waiting_queues:
                q.status = 'cancelled'
            
            op_day.current_sequence = 0
            db.session.commit()
            socketio.emit('antrean_direset', {'display_text': '-', 'jumlah_menunggu': 0})