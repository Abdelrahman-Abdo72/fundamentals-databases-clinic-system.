-- ============================================================
--  CLINIC MANAGEMENT SYSTEM — DML Load Script
--  Author  : Abdelrahman Hafez  |  ID: 241001974
--  Course  : Database Systems  |  Nile University
--  Engine  : MySQL 8.0
--
--  IMPORTANT: Run create_tables.sql FIRST before this script.
--  Records: 10 Departments | 14 Clinics | 14 Doctors
--           15 Patients    | 20 Appointments
-- ============================================================

USE clinic_db;

-- ============================================================
-- 1. DEPARTMENT  (10 records)
--    Root table — must be populated first.
-- ============================================================
INSERT INTO Department (dept_name) VALUES
    ('Cardiology'),          -- dept_id = 1
    ('Neurology'),           -- dept_id = 2
    ('Orthopedics'),         -- dept_id = 3
    ('Pediatrics'),          -- dept_id = 4
    ('Gastroenterology'),    -- dept_id = 5
    ('Dermatology'),         -- dept_id = 6
    ('Oncology'),            -- dept_id = 7
    ('Pulmonology'),         -- dept_id = 8
    ('Endocrinology'),       -- dept_id = 9
    ('Ophthalmology');       -- dept_id = 10

-- ============================================================
-- 2. CLINIC  (14 records — at least 10 required)
--    Every clinic must reference an existing Department.
-- ============================================================
INSERT INTO Clinic (clinic_name, address, dept_id) VALUES
    -- Cardiology clinics (dept_id = 1)
    ('Ain Shams Heart Clinic',
     '14 Abbas El-Akkad St, Nasr City, Cairo',         1),
    ('Nile Cardiac Center',
     '7 Corniche El-Nile, Maadi, Cairo',                1),

    -- Neurology (dept_id = 2)
    ('Cairo Neuro Clinic',
     '22 El-Nozha St, Heliopolis, Cairo',               2),
    ('Giza Spine & Brain Unit',
     '5 Sphinx Square, Mohandiseen, Giza',              2),

    -- Orthopedics (dept_id = 3)
    ('Pyramids Orthopedic Clinic',
     '88 Pyramids Rd, Haram, Giza',                     3),
    ('Capital Bone & Joint Clinic',
     '3 Tahrir Square, Downtown, Cairo',                3),

    -- Pediatrics (dept_id = 4)
    ('Misr Children Clinic',
     '9 Cleopatra St, Heliopolis, Cairo',               4),

    -- Gastroenterology (dept_id = 5)
    ('Delta GI & Liver Clinic',
     '31 El-Tahrir St, Dokki, Giza',                    5),

    -- Dermatology (dept_id = 6)
    ('Skin Care Derma Clinic',
     '17 Mohamed Farid St, Downtown, Cairo',            6),

    -- Oncology (dept_id = 7)
    ('Magdi Yacoub Cancer Center',
     '20 26th July Corridor, Sheikh Zayed, Giza',       7),

    -- Pulmonology (dept_id = 8)
    ('Chest & Lung Clinic',
     '11 Abbasia Square, Cairo',                        8),

    -- Endocrinology (dept_id = 9)
    ('Cairo Diabetes & Endocrine Center',
     '44 Gesr El-Suez St, Heliopolis, Cairo',           9),

    -- Ophthalmology (dept_id = 10)
    ('Zamalek Eye Clinic',
     '4 Hassan Sabry St, Zamalek, Cairo',               10),
    ('Nour Vision Center',
     '12 El-Batal Ahmed Abd El-Aziz St, Mohandiseen',  10);

-- ============================================================
-- 3. DOCTOR  (14 records — at least 10 required)
--    phone is UNIQUE — each doctor has one number.
-- ============================================================
INSERT INTO Doctor (doctor_name, phone, address, dept_id) VALUES
    -- Cardiology (dept_id = 1)
    ('Dr. Ahmed Mostafa El-Sayed',   '01001234567',
     '14 Zamalek St, Cairo',                            1),
    ('Dr. Sara Hassan Khalil',       '01012345678',
     '7 Maadi Road, Cairo',                             1),

    -- Neurology (dept_id = 2)
    ('Dr. Mohamed Farid Nour',       '01023456789',
     '3 Heliopolis Ave, Cairo',                         2),
    ('Dr. Nadia Ibrahim El-Wakil',   '01034567890',
     '9 Dokki Square, Giza',                            2),

    -- Orthopedics (dept_id = 3)
    ('Dr. Tarek Mansour Gaber',      '01045678901',
     '22 6th October Blvd, Giza',                       3),
    ('Dr. Layla Omar Abdel-Fattah',  '01056789012',
     '5 New Cairo, Cairo',                              3),

    -- Pediatrics (dept_id = 4)
    ('Dr. Youssef Samir Hamed',      '01067890123',
     '18 Nasr City, Cairo',                             4),

    -- Gastroenterology (dept_id = 5)
    ('Dr. Hana Ramadan Sherif',      '01078901234',
     '2 Shubra St, Cairo',                              5),

    -- Dermatology (dept_id = 6)
    ('Dr. Khaled Aziz Barakat',      '01089012345',
     '6 Agouza, Giza',                                  6),

    -- Oncology (dept_id = 7)
    ('Dr. Rania Fouad El-Naggar',    '01090123456',
     '11 Abbassia, Cairo',                              7),

    -- Pulmonology (dept_id = 8)
    ('Dr. Omar Gamal El-Din',        '01001122334',
     '33 Mohandiseen, Giza',                            8),

    -- Endocrinology (dept_id = 9)
    ('Dr. Dina Nabil Soliman',       '01002233445',
     '8 Sheikh Zayed, Giza',                            9),

    -- Ophthalmology (dept_id = 10)
    ('Dr. Amir Saad El-Masry',       '01003344556',
     '17 Heliopolis, Cairo',                            10),
    ('Dr. Maha Fathy Abdallah',      '01004455667',
     '29 Mohandiseen, Giza',                            10);

-- ============================================================
-- 4. PATIENT  (15 records — at least 10 required)
--    phone is UNIQUE. birth_date must be <= today.
-- ============================================================
INSERT INTO Patient (patient_name, phone, address, birth_date, job) VALUES
    ('Ali Hassan Abd El-Aziz',
     '01111111111', '5 Talaat Harb St, Cairo',         '1980-03-12', 'Civil Engineer'),

    ('Mona Saeed El-Masry',
     '01122222222', '8 Ramses Ave, Cairo',              '1990-07-25', 'School Teacher'),

    ('Karim Lotfy Mansour',
     '01133333333', '20 Pyramids Rd, Giza',             '1975-11-05', 'Accountant'),

    ('Yasmin Adel El-Shabrawy',
     '01144444444', '3 Mohandiseen, Giza',              '2000-01-30', 'University Student'),

    ('Walid Fathy Barakat',
     '01155555555', '11 Manial Island, Cairo',          '1962-09-18', 'Retired Officer'),

    ('Salma Gamal Khalifa',
     '01166666666', '14 Dokki St, Giza',                '1995-04-22', 'Pharmacist'),

    ('Hassan Nabil El-Rashidy',
     '01177777777', '1 Heliopolis, Cairo',              '1983-12-03', 'Lawyer'),

    ('Nour El-Din Ahmed Farouk',
     '01188888888', '9 Nasr City, Cairo',               '2010-06-15', 'School Student'),

    ('Rana Mahmoud Ezzat',
     '01199999999', '6 Maadi Rd, Cairo',                '1970-08-27', 'Physician'),

    ('Sameh Khalil Ibrahim',
     '01200000001', '19 New Cairo, Cairo',              '1988-02-14', 'Businessman'),

    ('Farah Ali El-Gohary',
     '01200000002', '7 Zamalek, Cairo',                 '1998-10-09', 'Graphic Designer'),

    ('Tamer Saber Abou-Zeid',
     '01200000003', '25 Shubra St, Cairo',              '1968-05-31', 'Bus Driver'),

    ('Laila Mostafa Khalil',
     '01200000004', '3 Nasr Rd, Alexandria',            '1993-03-17', 'Nurse'),

    ('Mahmoud Sherif El-Hakim',
     '01200000005', '88 Port Said St, Cairo',           '1958-11-22', 'Retired Teacher'),

    ('Dalia Osama Fouad',
     '01200000006', '12 Smouha, Alexandria',            '2002-08-05', 'University Student');

-- ============================================================
-- 5. APPOINTMENT  (20 records — at least 10 required)
--    patient_id and doctor_id must reference existing rows.
--    end_time must be > start_time.
--    cost must be >= 0.
-- ============================================================
INSERT INTO Appointment
    (appt_date, patient_id, doctor_id, start_time, end_time,
     cost, status, diagnosis)
VALUES
    -- Jan 2024 — Mix of statuses
    ('2024-01-10',  1,  1, '09:00', '09:30',  400.00,
     'completed',   'Hypertension stage 1; prescribed Amlodipine 5 mg'),

    ('2024-01-11',  2,  3, '10:00', '10:45',  450.00,
     'completed',   'Tension-type headache; advised rest and Paracetamol'),

    ('2024-01-12',  3,  5, '11:00', '11:30',  350.00,
     'completed',   'Lumbar disc herniation L4-L5; physiotherapy recommended'),

    ('2024-01-13',  4,  7, '08:30', '09:00',  280.00,
     'postponed',   NULL),

    ('2024-01-14',  5,  1, '14:00', '14:45',  550.00,
     'completed',   'Coronary artery disease; stress ECG advised'),

    ('2024-01-15',  6,  9, '09:30', '10:00',  220.00,
     'completed',   'Atopic dermatitis, moderate; prescribed topical corticosteroid'),

    ('2024-01-16',  7,  2, '13:00', '13:30',  480.00,
     'completed',   'Mitral valve prolapse; echo follow-up in 6 months'),

    ('2024-01-17',  8,  7, '10:00', '10:30',  180.00,
     'completed',   'Viral upper respiratory tract infection; supportive care'),

    ('2024-01-18',  9, 10, '15:00', '15:45',  650.00,
     'completed',   'Non-alcoholic fatty liver disease (NAFLD); dietary plan issued'),

    ('2024-01-19', 10,  4, '11:30', '12:00',  420.00,
     'completed',   'Migraine with aura; Sumatriptan prescribed'),

    -- Feb 2024
    ('2024-02-05',  3,  8, '09:00', '09:45',  300.00,
     'completed',   'Fatty liver grade II; dietary counseling and follow-up in 3 months'),

    ('2024-02-20', 11,  6, '08:00', '08:45',  340.00,
     'postponed',   NULL),

    ('2024-02-25', 12,  8, '12:00', '12:30',  290.00,
     'completed',   'IBS — Irritable Bowel Syndrome; fibre-rich diet recommended'),

    -- Mar 2024
    ('2024-03-14',  1,  3, '16:00', '16:30',  430.00,
     'completed',   'Cluster headache; Verapamil prophylaxis initiated'),

    ('2024-03-22', 13, 11, '09:00', '09:45',  310.00,
     'completed',   'Mild asthma; Salbutamol inhaler prescribed'),

    -- Apr 2024
    ('2024-04-22',  5, 12, '10:00', '11:00',  500.00,
     'completed',   'Type 2 Diabetes Mellitus; HbA1c elevated at 8.2%; Metformin adjusted'),

    ('2024-04-30', 14, 13, '14:30', '15:00',  370.00,
     'completed',   'Cataract early-stage right eye; annual monitoring advised'),

    -- May 2024
    ('2024-05-10', 15,  9, '10:00', '10:30',  200.00,
     'completed',   'Acne vulgaris grade II; Benzoyl Peroxide gel prescribed'),

    -- Future / upcoming appointments
    ('2026-06-01',  2,  3, '11:00', '11:30',  450.00,
     'scheduled',   NULL),

    ('2026-06-03',  4,  7, '08:30', '09:00',  280.00,
     'scheduled',   NULL);

-- ============================================================
-- VERIFICATION QUERIES
-- Run after loading to confirm record counts.
-- ============================================================
-- SELECT 'Department' AS tbl, COUNT(*) AS n FROM Department
-- UNION ALL
-- SELECT 'Clinic',    COUNT(*) FROM Clinic
-- UNION ALL
-- SELECT 'Doctor',    COUNT(*) FROM Doctor
-- UNION ALL
-- SELECT 'Patient',   COUNT(*) FROM Patient
-- UNION ALL
-- SELECT 'Appointment', COUNT(*) FROM Appointment;

-- ============================================================
-- END OF DML LOAD SCRIPT
-- ============================================================
