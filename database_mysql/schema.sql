-- 1. Buat database baru (jika belum ada) dan gunakan database tersebut
CREATE DATABASE IF NOT EXISTS live_queue;
USE live_queue;

-- 2. Buat Tabel Users (Digunakan untuk login petugas loket/admin)
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL, -- Di produksi riil, ini harus di-hash (misal pakai bcrypt)
    role ENUM('admin', 'staff') DEFAULT 'staff',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. Buat Tabel Queues (Mewakili Layanan atau Loket)
CREATE TABLE queues (
    id INT AUTO_INCREMENT PRIMARY KEY,
    service_name VARCHAR(100) NOT NULL,    -- Contoh: 'Poli Umum', 'Pendaftaran'
    service_code VARCHAR(5) NOT NULL,      -- Kode huruf antrean, misal: 'A', 'B'
    current_number INT DEFAULT 0,          -- Nomor urut yang *sedang* dilayani
    is_active BOOLEAN DEFAULT TRUE         -- Status loket buka/tutup
);

-- 4. Buat Tabel Tickets (Menyimpan riwayat pengambilan tiket oleh warga)
CREATE TABLE tickets (
    id INT AUTO_INCREMENT PRIMARY KEY,
    queue_id INT NOT NULL,                 -- Relasi ke loket mana tiket ini diambil
    ticket_number VARCHAR(15) NOT NULL,    -- Format gabungan, misal: 'A-001'
    status ENUM('waiting', 'called', 'completed', 'cancelled') DEFAULT 'waiting',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (queue_id) REFERENCES queues(id) ON DELETE CASCADE
);