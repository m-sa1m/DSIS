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

-- Flight Missions (15 missions)
INSERT INTO flight_missions (drone_id, zone_id, operator_id, scheduled_time, mission_status, notes) VALUES
(1, 1, 3, '2026-04-15 06:00:00', 'Completed', 'Early morning Main Gate patrol'),
(2, 2, 3, '2026-04-15 08:30:00', 'Completed', 'Faculty Block routine sweep'),
(3, 3, 4, '2026-04-16 22:00:00', 'Completed', 'Night hostel area surveillance'),
(1, 5, 3, '2026-04-17 10:00:00', 'Completed', 'Research Labs perimeter check'),
(5, 1, 4, '2026-04-18 05:30:00', 'Completed', 'Dawn patrol at Main Gate'),
(6, 3, 3, '2026-04-19 23:00:00', 'Completed', 'Late night hostel security sweep'),
(2, 6, 4, '2026-04-20 09:00:00', 'Completed', 'Admin Block morning scan'),
(8, 7, 3, '2026-04-21 12:00:00', 'Completed', 'Tuc Area midday monitoring'),
(3, 4, 4, '2026-04-22 16:00:00', 'Completed', 'Sports Complex event coverage'),
(5, 5, 3, '2026-04-23 14:00:00', 'Completed', 'Afternoon Research Labs patrol'),
(1, 1, 4, '2026-04-25 06:00:00', 'In Progress', 'Morning gate surveillance ongoing'),
(6, 3, 3, '2026-04-26 22:00:00', 'Scheduled', 'Planned night hostel sweep'),
(2, 2, 4, '2026-04-27 08:00:00', 'Scheduled', 'Routine Faculty Block check'),
(8, 7, 3, '2026-04-28 13:00:00', 'Scheduled', 'Tuc Area lunch hour patrol'),
(3, 1, 4, '2026-04-29 05:00:00', 'Aborted', 'Cancelled due to heavy rain');

-- Flight Logs (20 logs)
INSERT INTO flight_logs (mission_id, start_time, end_time, duration_minutes, start_lat, start_lng, end_lat, end_lng) VALUES
(1,  '2026-04-15 06:05:00', '2026-04-15 06:47:00', 42, 34.356950, 72.184530, 34.357050, 72.184630),
(1,  '2026-04-15 06:50:00', '2026-04-15 07:15:00', 25, 34.357050, 72.184630, 34.356850, 72.184430),
(2,  '2026-04-15 08:35:00', '2026-04-15 09:20:00', 45, 34.357820, 72.186210, 34.357920, 72.186410),
(3,  '2026-04-16 22:05:00', '2026-04-16 23:10:00', 65, 34.355680, 72.187450, 34.355780, 72.187650),
(4,  '2026-04-17 10:05:00', '2026-04-17 10:50:00', 45, 34.358130, 72.187830, 34.358230, 72.188030),
(5,  '2026-04-18 05:35:00', '2026-04-18 06:30:00', 55, 34.356950, 72.184530, 34.357150, 72.184730),
(6,  '2026-04-19 23:05:00', '2026-04-20 00:05:00', 60, 34.355680, 72.187450, 34.355480, 72.187250),
(7,  '2026-04-20 09:05:00', '2026-04-20 09:45:00', 40, 34.357450, 72.184980, 34.357550, 72.185180),
(8,  '2026-04-21 12:05:00', '2026-04-21 12:40:00', 35, 34.356120, 72.186750, 34.356220, 72.186950),
(9,  '2026-04-22 16:05:00', '2026-04-22 16:55:00', 50, 34.354720, 72.185890, 34.354820, 72.186090),
(10, '2026-04-23 14:05:00', '2026-04-23 14:50:00', 45, 34.358130, 72.187830, 34.358330, 72.188130),
(11, '2026-04-25 06:05:00', NULL,                   NULL, 34.356950, 72.184530, NULL,      NULL),
(1,  '2026-04-15 07:20:00', '2026-04-15 07:45:00', 25, 34.356850, 72.184430, 34.356950, 72.184530),
(3,  '2026-04-16 23:15:00', '2026-04-16 23:50:00', 35, 34.355780, 72.187650, 34.355680, 72.187450),
(5,  '2026-04-18 06:35:00', '2026-04-18 07:10:00', 35, 34.357150, 72.184730, 34.356950, 72.184530),
(6,  '2026-04-20 00:10:00', '2026-04-20 00:45:00', 35, 34.355480, 72.187250, 34.355680, 72.187450),
(9,  '2026-04-22 17:00:00', '2026-04-22 17:30:00', 30, 34.354820, 72.186090, 34.354720, 72.185890),
(10, '2026-04-23 14:55:00', '2026-04-23 15:25:00', 30, 34.358330, 72.188130, 34.358130, 72.187830),
(7,  '2026-04-20 09:50:00', '2026-04-20 10:20:00', 30, 34.357550, 72.185180, 34.357450, 72.184980),
(4,  '2026-04-17 10:55:00', '2026-04-17 11:30:00', 35, 34.358230, 72.188030, 34.358130, 72.187830);

-- Detected Objects (25 detections — mix of threat levels)
INSERT INTO detected_objects (log_id, object_type, threat_level, detected_at, coordinates_lat, coordinates_lng, description) VALUES
(1,  'Unauthorized Vehicle',  'High',   '2026-04-15 06:20:00', 34.357000, 72.184580, 'Unregistered white Suzuki Bolan near Main Gate barrier'),
(1,  'Stray Animal',          'Low',    '2026-04-15 06:25:00', 34.357030, 72.184550, 'Stray dog near guard post'),
(2,  'Suspicious Person',     'Medium', '2026-04-15 07:00:00', 34.356900, 72.184480, 'Individual loitering near boundary wall after hours'),
(3,  'Unknown Package',       'High',   '2026-04-15 09:00:00', 34.357870, 72.186260, 'Unattended bag outside Faculty Block Room 203'),
(4,  'Perimeter Breach',      'High',   '2026-04-16 22:30:00', 34.355730, 72.187500, 'Movement detected near hostel boundary fence'),
(4,  'Suspicious Person',     'Medium', '2026-04-16 22:45:00', 34.355700, 72.187550, 'Two individuals near restricted hostel service area'),
(5,  'Stray Animal',          'Low',    '2026-04-17 10:20:00', 34.358180, 72.187880, 'Stray cat in Research Labs corridor'),
(6,  'Unauthorized Vehicle',  'High',   '2026-04-18 05:50:00', 34.357050, 72.184630, 'Motorcycle without campus sticker at Main Gate'),
(7,  'Suspicious Person',     'High',   '2026-04-19 23:30:00', 34.355580, 72.187350, 'Unidentified individual climbing hostel wall'),
(8,  'Stray Animal',          'Low',    '2026-04-20 09:20:00', 34.357500, 72.185080, 'Stray dog near Admin Block parking'),
(9,  'Unknown Package',       'Medium', '2026-04-21 12:20:00', 34.356170, 72.186800, 'Plastic bag left near Tuc Area bench'),
(10, 'Unauthorized Vehicle',  'Medium', '2026-04-22 16:20:00', 34.354770, 72.185940, 'Vehicle parked in restricted Sports Complex zone'),
(11, 'Perimeter Breach',      'High',   '2026-04-23 14:20:00', 34.358180, 72.187980, 'Fence damage detected near Research Labs boundary'),
(13, 'Stray Animal',          'Low',    '2026-04-15 07:30:00', 34.356950, 72.184530, 'Monkey on campus wall near Main Gate'),
(14, 'Suspicious Person',     'Medium', '2026-04-16 23:25:00', 34.355730, 72.187500, 'Person moving between hostels after curfew'),
(15, 'Unauthorized Vehicle',  'High',   '2026-04-18 06:45:00', 34.357100, 72.184680, 'Van without clearance attempting entry'),
(16, 'Unknown Package',       'High',   '2026-04-20 00:20:00', 34.355530, 72.187300, 'Box left near hostel emergency exit'),
(17, 'Stray Animal',          'Low',    '2026-04-22 17:10:00', 34.354770, 72.185940, 'Stray dog chasing ball on cricket ground'),
(18, 'Suspicious Person',     'Medium', '2026-04-23 15:05:00', 34.358180, 72.187980, 'Individual photographing Research Labs from outside'),
(19, 'Perimeter Breach',      'High',   '2026-04-20 10:00:00', 34.357500, 72.185130, 'Break in Admin Block compound wall detected'),
(20, 'Unauthorized Vehicle',  'Medium', '2026-04-17 11:10:00', 34.358180, 72.187880, 'Rickshaw inside campus restricted road'),
(6,  'Unknown Package',       'Medium', '2026-04-18 06:00:00', 34.357100, 72.184630, 'Bag left at gate checkpoint unattended'),
(3,  'Stray Animal',          'Low',    '2026-04-15 09:10:00', 34.357820, 72.186210, 'Cat inside Faculty Block corridor'),
(7,  'Perimeter Breach',      'High',   '2026-04-19 23:50:00', 34.355630, 72.187400, 'Broken fence panel near hostel H7'),
(11, 'Suspicious Person',     'Medium', '2026-04-23 14:35:00', 34.358230, 72.187930, 'Unknown person near lab equipment storage');

-- Alerts are auto-generated by trigger for High threat detections.
-- Manually insert some Medium/Low alerts for variety.
INSERT INTO alerts (detection_id, alert_status, severity, generated_at) VALUES
(3,  'Acknowledged', 'Medium', '2026-04-15 07:01:00'),
(6,  'Resolved',     'Medium', '2026-04-16 22:46:00'),
(11, 'New',          'Medium', '2026-04-21 12:21:00'),
(12, 'Acknowledged', 'Medium', '2026-04-22 16:21:00'),
(15, 'Resolved',     'Medium', '2026-04-16 23:26:00');
