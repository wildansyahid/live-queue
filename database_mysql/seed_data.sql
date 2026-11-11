USE live_queue;

-- Insert data Petugas
INSERT INTO users (username, password, role) VALUES 
('admin_puskesmas', 'admin123', 'admin'),
('loket_1', 'loket123', 'staff');

-- Insert data Layanan/Loket
-- current_number kita set 2, seolah-olah sudah ada 2 orang yang dilayani
INSERT INTO queues (service_name, service_code, current_number) VALUES 
('Pendaftaran Poli Umum', 'A', 2),
('Pengambilan Obat', 'B', 0),
('Layanan Ibu dan Anak', 'C', 0);

-- Insert data Tiket simulasi untuk Loket A (Poli Umum)
INSERT INTO tickets (queue_id, ticket_number, status) VALUES 
(1, 'A-001', 'completed'), -- Sudah selesai dilayani
(1, 'A-002', 'called'),    -- Sedang dipanggil ke loket
(1, 'A-003', 'waiting'),   -- Sedang menunggu giliran
(1, 'A-004', 'waiting');   -- Sedang menunggu giliran