import csv
from io import StringIO
from flask import Blueprint, Response
from extensions import db
from models import Queue, Ticket, OperationalDay, Service
from datetime import datetime

admin_bp = Blueprint('admin', __name__)

@admin_bp.route('/export/csv', methods=['GET'])
def export_csv():
    # Mengambil data antrean hari ini
    today = datetime.utcnow().date()
    
    queues = db.session.query(Queue, Ticket, Service).join(
        OperationalDay, Queue.operational_day_id == OperationalDay.id
    ).join(
        Service, OperationalDay.service_id == Service.id
    ).outerjoin(
        Ticket, Ticket.queue_id == Queue.id
    ).filter(OperationalDay.business_date == today).all()

    # Membuat file CSV di memori
    si = StringIO()
    writer = csv.writer(si)
    
    # Header CSV
    writer.writerow(['Nomor Tiket', 'Layanan', 'Status', 'Waktu Ambil', 'Waktu Panggil', 'Waktu Selesai'])

    for q, t, s in queues:
        issued = t.issued_at.strftime('%Y-%m-%d %H:%M:%S') if t and t.issued_at else '-'
        called = t.called_at.strftime('%Y-%m-%d %H:%M:%S') if t and t.called_at else '-'
        completed = t.completed_at.strftime('%Y-%m-%d %H:%M:%S') if t and t.completed_at else '-'
        
        writer.writerow([q.ticket_number, s.name, q.status, issued, called, completed])

    output = si.getvalue()
    
    # Mengembalikan response berupa file unduhan
    return Response(
        output,
        mimetype="text/csv",
        headers={"Content-Disposition": f"attachment;filename=laporan_antrean_{today}.csv"}
    )