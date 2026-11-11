from flask import Blueprint, jsonify, request, current_app
from models.db_handler import fetch_query, execute_query

api_bp = Blueprint('api', __name__)

@api_bp.route('/ambil-antrean', methods=['POST'])
def ambil_antrean():
    data = request.json
    queue_id = data.get('queue_id')

    loket = fetch_query("SELECT service_code FROM queues WHERE id = %s", (queue_id,))
    if not loket:
        return jsonify({"error": "Loket tidak ditemukan"}), 404

    kode = loket[0]['service_code']
    total_tiket = fetch_query("SELECT COUNT(*) as total FROM tickets WHERE queue_id = %s", (queue_id,))
    nomor_baru = total_tiket[0]['total'] + 1
    ticket_number = f"{kode}-{nomor_baru:03d}" 

    # Simpan tiket dengan status 'waiting'
    query = "INSERT INTO tickets (queue_id, ticket_number, status) VALUES (%s, %s, 'waiting')"
    execute_query(query, (queue_id, ticket_number))

    # Hitung sisa orang yang statusnya masih 'waiting'
    sisa = fetch_query("SELECT COUNT(*) as total FROM tickets WHERE queue_id = %s AND status = 'waiting'", (queue_id,))
    jumlah_menunggu = sisa[0]['total'] if sisa else 0

    # Broadcast ke layar Admin lengkap dengan jumlah yang menunggu
    current_app.socketio.emit('antrean_baru', {
        'ticket_number': ticket_number,
        'jumlah_menunggu': jumlah_menunggu
    })

    return jsonify({"message": "Berhasil mengambil antrean", "ticket_number": ticket_number}), 201

# Endpoint login tetap sama
@api_bp.route('/login', methods=['POST'])
def login():
    data = request.json
    username = data.get('username')
    password = data.get('password')

    user = fetch_query("SELECT id, username, role FROM users WHERE username = %s AND password = %s", (username, password))
    if user:
        return jsonify({"message": "Login berhasil", "user": user[0]}), 200
    else:
        return jsonify({"error": "Username atau password salah"}), 401