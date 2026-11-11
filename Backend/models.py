from datetime import datetime
from extensions import db

class User(db.Model):
    __tablename__ = 'users'
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(50), unique=True, nullable=False)
    password_hash = db.Column(db.String(255), nullable=False)
    role = db.Column(db.String(20), default='staff')
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

class Service(db.Model):
    __tablename__ = 'services'
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    description = db.Column(db.Text, nullable=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    # Relasi ke OperationalDay
    operational_days = db.relationship('OperationalDay', backref='service', lazy=True)

class OperationalDay(db.Model):
    __tablename__ = 'operational_days'
    id = db.Column(db.Integer, primary_key=True)
    service_id = db.Column(db.Integer, db.ForeignKey('services.id'), nullable=False)
    business_date = db.Column(db.Date, nullable=False)
    current_sequence = db.Column(db.Integer, default=0)
    
    # Relasi ke Queue
    queues = db.relationship('Queue', backref='operational_day', lazy=True)

class Queue(db.Model):
    __tablename__ = 'queues'
    id = db.Column(db.Integer, primary_key=True)
    operational_day_id = db.Column(db.Integer, db.ForeignKey('operational_days.id'), nullable=False)
    ticket_number = db.Column(db.String(20), nullable=False)
    status = db.Column(db.Enum('waiting', 'called', 'serving', 'completed', 'skipped', 'cancelled'), default='waiting')
    
    # --- DUA KOLOM BARU UNTUK DATA WARGA ---
    customer_name = db.Column(db.String(100), nullable=True)
    customer_phone = db.Column(db.String(20), nullable=True)
    
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    # Relasi ke Ticket
    ticket = db.relationship('Ticket', backref='queue', uselist=False, lazy=True)

class Ticket(db.Model):
    __tablename__ = 'tickets'
    id = db.Column(db.Integer, primary_key=True)
    queue_id = db.Column(db.Integer, db.ForeignKey('queues.id'), nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    completed_at = db.Column(db.DateTime, nullable=True)

class AuditLog(db.Model):
    __tablename__ = 'audit_logs'
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=True)
    action = db.Column(db.String(255), nullable=False)
    details = db.Column(db.Text, nullable=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)