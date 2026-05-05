-- ============================================================
-- Drone Surveillance & Intelligence System — Seed Data
-- GIK Institute of Engineering Sciences and Technology, Topi
-- ============================================================

-- Roles
INSERT INTO roles (role_name, description) VALUES
('Admin', 'Full system access including user management and audit logs'),
('Operator', 'Manages drones, missions, flight logs, and detections'),
('Analyst', 'Read-only access to alerts, detections, incidents, and reports');

-- Users (6 total: 2 Admin, 2 Operator, 2 Analyst)
-- Passwords are bcrypt hashes of 'password123'
INSERT INTO users (full_name, email, password_hash, role_id, is_active) VALUES
('Maj. Tariq Mehmood',   'tariq.mehmood@giki.edu.pk',   '$2b$10$zrfRlp08KjPo5m5RqoLoPuQUyEqe4/yOVQP9muN81MUE.B2aonFJy', 1, TRUE),
('Dr. Ayesha Siddiqui',  'ayesha.siddiqui@giki.edu.pk', '$2b$10$zrfRlp08KjPo5m5RqoLoPuQUyEqe4/yOVQP9muN81MUE.B2aonFJy', 1, TRUE),
('Hamza Rauf',           'hamza.rauf@giki.edu.pk',      '$2b$10$zrfRlp08KjPo5m5RqoLoPuQUyEqe4/yOVQP9muN81MUE.B2aonFJy', 2, TRUE),
('Nadia Akram',          'nadia.akram@giki.edu.pk',     '$2b$10$zrfRlp08KjPo5m5RqoLoPuQUyEqe4/yOVQP9muN81MUE.B2aonFJy', 2, TRUE),
('Faisal Shahzad',       'faisal.shahzad@giki.edu.pk',  '$2b$10$zrfRlp08KjPo5m5RqoLoPuQUyEqe4/yOVQP9muN81MUE.B2aonFJy', 3, TRUE),
('Sana Malik',           'sana.malik@giki.edu.pk',      '$2b$10$zrfRlp08KjPo5m5RqoLoPuQUyEqe4/yOVQP9muN81MUE.B2aonFJy', 3, TRUE);
