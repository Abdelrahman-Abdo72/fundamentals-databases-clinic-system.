-- ============================================================
--  CLINIC MANAGEMENT SYSTEM — DDL Script
--  Author  : Abdelrahman Hafez  |  ID: 241001974
--  Course  : Database Systems  |  Nile University
--  Engine  : MySQL 8.0
--  Charset : utf8mb4
-- ============================================================

-- ------------------------------------------------------------
-- 0. DATABASE SETUP
-- ------------------------------------------------------------
DROP DATABASE IF EXISTS clinic_db;

CREATE DATABASE clinic_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE clinic_db;

-- ============================================================
-- 1. TABLE: Department
--    Root entity — no foreign keys.
--    Every clinic and doctor references this table.
-- ============================================================
CREATE TABLE Department (
    dept_id    INT          NOT NULL AUTO_INCREMENT,
    dept_name  VARCHAR(100) NOT NULL,

    CONSTRAINT pk_department  PRIMARY KEY (dept_id),
    CONSTRAINT uq_dept_name   UNIQUE      (dept_name)
);

-- ============================================================
-- 2. TABLE: Clinic
--    Each clinic belongs to exactly one Department (N:1).
--    ON DELETE RESTRICT  — a department with clinics cannot be deleted.
--    ON UPDATE CASCADE   — if dept_id changes, the FK updates automatically.
-- ============================================================
CREATE TABLE Clinic (
    clinic_id    INT          NOT NULL AUTO_INCREMENT,
    clinic_name  VARCHAR(150) NOT NULL,
    address      VARCHAR(255) NOT NULL,
    dept_id      INT          NOT NULL,

    CONSTRAINT pk_clinic       PRIMARY KEY (clinic_id),
    CONSTRAINT fk_clinic_dept  FOREIGN KEY (dept_id)
        REFERENCES Department(dept_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);

-- ============================================================
-- 3. TABLE: Doctor
--    Each doctor belongs to exactly one Department (N:1).
--    Phone must be unique — used as an alternate identifier.
-- ============================================================
CREATE TABLE Doctor (
    doctor_id    INT          NOT NULL AUTO_INCREMENT,
    doctor_name  VARCHAR(150) NOT NULL,
    phone        VARCHAR(20)  NOT NULL,
    address      VARCHAR(255),
    dept_id      INT          NOT NULL,

    CONSTRAINT pk_doctor       PRIMARY KEY (doctor_id),
    CONSTRAINT uq_doctor_phone UNIQUE      (phone),
    CONSTRAINT fk_doctor_dept  FOREIGN KEY (dept_id)
        REFERENCES Department(dept_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);

-- ============================================================
-- 4. TABLE: Patient
--    Standalone entity — no FK to Doctor or Clinic.
--    A patient can be registered before any appointment is made.
--    birth_date CHECK prevents future dates.
-- ============================================================
CREATE TABLE Patient (
    patient_id    INT          NOT NULL AUTO_INCREMENT,
    patient_name  VARCHAR(150) NOT NULL,
    phone         VARCHAR(20)  NOT NULL,
    address       VARCHAR(255),
    birth_date    DATE         NOT NULL,
    job           VARCHAR(100),

    CONSTRAINT pk_patient       PRIMARY KEY (patient_id),
    CONSTRAINT uq_patient_phone UNIQUE      (phone),
    CONSTRAINT chk_birth_date   CHECK (birth_date <= CURRENT_DATE)
);

-- ============================================================
-- 5. TABLE: Appointment
--    Central fact table — links Patient + Doctor.
--    Total participation on both Patient and Doctor sides.
--    ON DELETE RESTRICT on both FKs preserves medical history.
--    diagnosis is nullable — filled after consultation completes.
-- ============================================================
CREATE TABLE Appointment (
    appt_id     INT            NOT NULL AUTO_INCREMENT,
    appt_date   DATE           NOT NULL,
    patient_id  INT            NOT NULL,
    doctor_id   INT            NOT NULL,
    start_time  TIME           NOT NULL,
    end_time    TIME           NOT NULL,
    cost        DECIMAL(10,2)  NOT NULL DEFAULT 0.00,
    status      ENUM(
                    'scheduled',
                    'completed',
                    'in_progress',
                    'postponed',
                    'cancelled'
                )              NOT NULL DEFAULT 'scheduled',
    diagnosis   TEXT,

    CONSTRAINT pk_appointment   PRIMARY KEY (appt_id),
    CONSTRAINT fk_appt_patient  FOREIGN KEY (patient_id)
        REFERENCES Patient(patient_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT fk_appt_doctor   FOREIGN KEY (doctor_id)
        REFERENCES Doctor(doctor_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,
    CONSTRAINT chk_appt_times   CHECK (end_time > start_time),
    CONSTRAINT chk_appt_cost    CHECK (cost >= 0)
);

-- ============================================================
-- 6. INDEXES
--    Created on every FK column and commonly filtered columns.
--    MySQL auto-indexes PKs; these cover the remaining hot paths.
-- ============================================================
CREATE INDEX idx_clinic_dept   ON Clinic(dept_id);
CREATE INDEX idx_doctor_dept   ON Doctor(dept_id);
CREATE INDEX idx_appt_patient  ON Appointment(patient_id);
CREATE INDEX idx_appt_doctor   ON Appointment(doctor_id);
CREATE INDEX idx_appt_date     ON Appointment(appt_date);
CREATE INDEX idx_appt_status   ON Appointment(status);

-- ============================================================
-- 7. VIEWS
-- ============================================================

-- ------------------------------------------------------------
-- VIEW 1: vw_appointment_summary
-- Full appointment detail with human-readable names.
-- Intended for receptionists & scheduling staff.
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW vw_appointment_summary AS
SELECT
    a.appt_id,
    a.appt_date,
    a.start_time,
    a.end_time,
    TIMESTAMPDIFF(MINUTE, a.start_time, a.end_time) AS duration_min,
    p.patient_id,
    p.patient_name,
    p.phone                                         AS patient_phone,
    d.doctor_id,
    d.doctor_name,
    dep.dept_name,
    a.cost,
    a.status,
    COALESCE(a.diagnosis, 'Pending')               AS diagnosis
FROM Appointment a
JOIN Patient    p   ON a.patient_id = p.patient_id
JOIN Doctor     d   ON a.doctor_id  = d.doctor_id
JOIN Department dep ON d.dept_id    = dep.dept_id;

-- ------------------------------------------------------------
-- VIEW 2: vw_patient_medical_history
-- Full medical history per patient with aggregated stats.
-- Intended for doctors reviewing a patient before a new visit.
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW vw_patient_medical_history AS
SELECT
    p.patient_id,
    p.patient_name,
    p.phone,
    TIMESTAMPDIFF(YEAR, p.birth_date, CURDATE())   AS age,
    p.job,
    COUNT(a.appt_id)                               AS total_visits,
    COALESCE(SUM(a.cost), 0)                       AS total_paid_egp,
    MAX(a.appt_date)                               AS last_visit_date,
    (SELECT a2.diagnosis
     FROM   Appointment a2
     WHERE  a2.patient_id = p.patient_id
       AND  a2.diagnosis  IS NOT NULL
     ORDER  BY a2.appt_date DESC
     LIMIT  1)                                     AS latest_diagnosis
FROM Patient p
LEFT JOIN Appointment a ON a.patient_id = p.patient_id
GROUP BY
    p.patient_id, p.patient_name, p.phone,
    p.birth_date, p.job;

-- ------------------------------------------------------------
-- VIEW 3: vw_doctor_schedule
-- Upcoming & in-progress appointments per doctor.
-- Intended for doctors and clinic coordinators.
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW vw_doctor_schedule AS
SELECT
    d.doctor_id,
    d.doctor_name,
    dep.dept_name,
    a.appt_date,
    a.start_time,
    a.end_time,
    p.patient_name,
    p.phone  AS patient_phone,
    a.status,
    a.cost
FROM Doctor d
JOIN Department dep ON d.dept_id    = dep.dept_id
JOIN Appointment a  ON a.doctor_id  = d.doctor_id
JOIN Patient p      ON a.patient_id = p.patient_id
WHERE a.status IN ('scheduled', 'in_progress')
  AND a.appt_date >= CURDATE()
ORDER BY d.doctor_id, a.appt_date, a.start_time;

-- ------------------------------------------------------------
-- VIEW 4: vw_revenue_summary
-- Appointment revenue aggregated by department and doctor.
-- Intended for management and finance reporting.
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW vw_revenue_summary AS
SELECT
    dep.dept_id,
    dep.dept_name,
    d.doctor_id,
    d.doctor_name,
    COUNT(a.appt_id)       AS total_appointments,
    COALESCE(SUM(a.cost), 0)          AS total_revenue_egp,
    ROUND(AVG(a.cost), 2)  AS avg_cost,
    MIN(a.appt_date)       AS first_appointment,
    MAX(a.appt_date)       AS latest_appointment
FROM Department dep
JOIN Doctor d          ON d.dept_id    = dep.dept_id
LEFT JOIN Appointment a ON a.doctor_id = d.doctor_id
GROUP BY
    dep.dept_id, dep.dept_name,
    d.doctor_id, d.doctor_name
ORDER BY dep.dept_name, total_revenue_egp DESC;

-- ------------------------------------------------------------
-- VIEW 5: vw_postponed_followup
-- Postponed appointments needing rescheduling.
-- Intended for admin team outreach.
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW vw_postponed_followup AS
SELECT
    a.appt_id,
    a.appt_date        AS original_date,
    p.patient_name,
    p.phone            AS patient_phone,
    p.address          AS patient_address,
    d.doctor_name,
    d.phone            AS doctor_phone,
    dep.dept_name
FROM Appointment a
JOIN Patient    p   ON a.patient_id = p.patient_id
JOIN Doctor     d   ON a.doctor_id  = d.doctor_id
JOIN Department dep ON d.dept_id    = dep.dept_id
WHERE a.status = 'postponed'
ORDER BY a.appt_date;

-- ============================================================
-- END OF DDL SCRIPT
-- ============================================================
