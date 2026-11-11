from flask_socketio import emit
from extensions import db
from models import Queue, Ticket, OperationalDay
from datetime import datetime

def register_socket_events(socketio):
    
    @socketio.on('connect')
    def handle_connect():
        print("Klien terhubung ke WebSocket.")

    @socketio.on('reset_antrean')
    def handle_reset(data):
        service_id = data.get('service_id', 1)
        today = datetime.utcnow().date()
        
        # Cari data operasional hari ini
        op_day = OperationalDay.query.filter_by(service_id=service_id, business_date=today).first()
        
        if op_day:
            # 1. Batalkan semua antrean yang masih menunggu
            waiting_queues = Queue.query.filter_by(operational_day_id=op_day.id, status='waiting').all()
            for q in waiting_queues:
                q.status = 'cancelled'
                ticket = Ticket.query.filter_by(queue_id=q.id).first()
                if ticket: 
                    ticket.cancelled_at = datetime.utcnow()
            
            # 2. Reset counter kembali ke 0 (BUKAN MENGHAPUS DATA)
            op_day.current_sequence = 0
            db.session.commit()
            
            # 3. Broadcast ke semua layar
            socketio.emit('antrean_direset', {
                'display_text': '-',
                'jumlah_menunggu': 0
            })