import os
from flask import Flask
from dotenv import load_dotenv
from extensions import db, migrate, socketio, cors

# Import semua model agar terdeteksi saat inisialisasi dan migrasi database
from models import User, Service, OperationalDay, Queue, Ticket, AuditLog

load_dotenv()

def create_app():
    app = Flask(__name__)
    
    # Memuat konfigurasi dari file .env (dengan fallback nilai default)
    app.config['SECRET_KEY'] = os.getenv('SECRET_KEY', 'super_secret_live_queue_key_2026')
    app.config['SQLALCHEMY_DATABASE_URI'] = os.getenv('DATABASE_URL', 'mysql+pymysql://root:@127.0.0.1:3306/live_queue_db')
    app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

    # Inisialisasi Ekstensi ke dalam Flask App
    db.init_app(app)
    migrate.init_app(app, db)
    cors.init_app(app)
    socketio.init_app(app, cors_allowed_origins="*")

    # =========================================================
    # FIX: Tambahkan 2 baris ini agar tabel dibuat ulang otomatis
    # beserta kolom customer_name dan customer_phone
    # =========================================================
    with app.app_context():
        db.create_all()

    # Endpoint untuk mengecek status server berjalan
    @app.route('/')
    def index():
        return {"status": "Live Queue API Running", "version": "1.0"}

    # ---------------------------------------------------------
    # REGISTRASI BLUEPRINT (Rute REST API)
    # ---------------------------------------------------------
    from routes.public_routes import public_bp
    from routes.staff_routes import staff_bp
    from routes.admin_routes import admin_bp

    app.register_blueprint(public_bp, url_prefix='/api/public')
    app.register_blueprint(staff_bp, url_prefix='/api/staff')
    app.register_blueprint(admin_bp, url_prefix='/api/admin')

    # ---------------------------------------------------------
    # REGISTRASI EVENT WEBSOCKET
    # ---------------------------------------------------------
    # Pastikan file queue_events.py berada di dalam folder 'sockets'
    from sockets.queue_events import register_socket_events
    register_socket_events(socketio)

    return app

# Membuat instance aplikasi
app = create_app()

if __name__ == '__main__':
    print("Menjalankan Live Queue Server (Flask + SocketIO) di Port 5000...")
    socketio.run(app, host='0.0.0.0', port=5000, debug=True)