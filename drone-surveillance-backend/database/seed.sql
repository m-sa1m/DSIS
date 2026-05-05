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

-- Surveillance Zones (GIKI campus areas)
INSERT INTO surveillance_zones (zone_name, location_description, risk_level, coordinates_lat, coordinates_lng) VALUES
('Main Gate',       'Primary entry and exit point of GIKI campus, Topi, Swabi',         'High',   34.356950, 72.184530),
('Faculty Block',   'Academic faculty offices and lecture halls complex',                'Low',    34.357820, 72.186210),
('Hostel Area',     'Student residential hostels including H1 through H10',             'Medium', 34.355680, 72.187450),
('Sports Complex',  'Cricket ground, football field, basketball courts, and gymnasium',  'Low',    34.354720, 72.185890),
('Research Labs',   'Engineering research laboratories and workshop facilities',         'Medium', 34.358130, 72.187830),
('Admin Block',     'Administrative offices and registrar building',                     'Medium', 34.357450, 72.184980),
('Tuc Area',        'Tuck shops and student cafeteria zone near hostels',                'Low',    34.356120, 72.186750);

-- Drones (8 units)
INSERT INTO drones (drone_name, model, status, zone_id) VALUES
('GIKI-Hawk-01', 'DJI Matrice 300 RTK',    'Active',            1),
('GIKI-Hawk-02', 'DJI Mavic 3 Enterprise',  'Active',            2),
('GIKI-Hawk-03', 'Autel EVO II Pro',        'Active',            3),
('GIKI-Hawk-04', 'DJI Phantom 4 RTK',       'Under Maintenance', 4),
('GIKI-Hawk-05', 'Skydio X2',               'Active',            5),
('GIKI-Hawk-06', 'DJI Matrice 30T',         'Active',            1),
('GIKI-Hawk-07', 'Autel EVO Max 4T',        'Inactive',          6),
('GIKI-Hawk-08', 'DJI Mavic 3 Thermal',     'Active',            7);

