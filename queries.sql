-- ============================================================
--  CLINIC MANAGEMENT SYSTEM — Sample Queries
--  Author  : Abdelrahman Hafez  |  ID: 241001974
--  Course  : Database Systems  |  Nile University
--  Engine  : MySQL 8.0
--
--  IMPORTANT: Run create_tables.sql and load_data.sql FIRST.
--
--  Structure:
--    Section A — Simple Retrieval Queries   (Q01 – Q05)
--    Section B — Aggregation & Grouping     (Q06 – Q08)
--    Section C — Advanced / Analytical      (Q09 – Q14)
--    Section D — DML Update Queries         (Q15 – Q17)
--    Section E — View Demonstrations        (Q18 – Q20)
-- ============================================================

USE clinic_db;

-- ============================================================
-- SECTION A — SIMPLE RETRIEVAL QUERIES
-- ============================================================

-- ------------------------------------------------------------
-- Q01: List all patients diagnosed with fatty liver
--      in the last 12 months.
--      Purpose: Disease tracking and follow-up care.
-- ------------------------------------------------------------
SELECT
    p.patient_id,
    p.patient_name,
    p.phone,
    a.appt_date,
    a.diagnosis
FROM Appointment a
JOIN Patient p ON a.patient_id = p.patient_id
WHERE  a.diagnosis LIKE '%fatty liver%'
  AND  a.appt_date >= DATE_SUB(CURDATE(), INTERVAL 1 YEAR)
ORDER  BY a.appt_date DESC;

-- ------------------------------------------------------------
-- Q02: List all clinics belonging to the Cardiology department.
--      Purpose: Patient directories and referral systems.
-- ------------------------------------------------------------
SELECT
    c.clinic_id,
    c.clinic_name,
    c.address,
    d.dept_name
FROM Clinic c
JOIN Department d ON c.dept_id = d.dept_id
WHERE  d.dept_name = 'Cardiology'
ORDER  BY c.clinic_name;

-- ------------------------------------------------------------
-- Q03: Full appointment history for a specific patient,
--      including doctor name, department, and diagnosis.
--      Purpose: Medical record review before a new consultation.
--      → Change patient_id = 1 to target a different patient.
-- ------------------------------------------------------------
SELECT
    a.appt_id,
    a.appt_date,
    a.start_time,
    a.end_time,
    TIMESTAMPDIFF(MINUTE, a.start_time, a.end_time) AS duration_min,
    d.doctor_name,
    dep.dept_name,
    a.cost,
    a.status,
    COALESCE(a.diagnosis, 'Pending')                AS diagnosis
FROM Appointment a
JOIN Doctor      d   ON a.doctor_id = d.doctor_id
JOIN Department  dep ON d.dept_id   = dep.dept_id
WHERE  a.patient_id = 1
ORDER  BY a.appt_date DESC;

-- ------------------------------------------------------------
-- Q04: Find all doctors who belong to the Neurology department.
--      Purpose: Department-level staff directory.
-- ------------------------------------------------------------
SELECT
    doc.doctor_id,
    doc.doctor_name,
    doc.phone,
    doc.address
FROM Doctor     doc
JOIN Department dep ON doc.dept_id = dep.dept_id
WHERE  dep.dept_name = 'Neurology'
ORDER  BY doc.doctor_name;

-- ------------------------------------------------------------
-- Q05: List all upcoming scheduled appointments (today onwards).
--      Purpose: Daily/weekly schedule for clinic reception.
-- ------------------------------------------------------------
SELECT
    a.appt_id,
    a.appt_date,
    a.start_time,
    a.end_time,
    p.patient_name,
    d.doctor_name,
    dep.dept_name,
    a.cost
FROM Appointment a
JOIN Patient    p   ON a.patient_id = p.patient_id
JOIN Doctor     d   ON a.doctor_id  = d.doctor_id
JOIN Department dep ON d.dept_id    = dep.dept_id
WHERE  a.status IN ('scheduled', 'in_progress')
  AND  a.appt_date >= CURDATE()
ORDER  BY a.appt_date, a.start_time;

-- ============================================================
-- SECTION B — AGGREGATION & GROUPING
-- ============================================================

-- ------------------------------------------------------------
-- Q06: Total money paid by each patient across all visits,
--      with visit count and date range.
--      Purpose: Billing history and insurance documentation.
-- ------------------------------------------------------------
SELECT
    p.patient_id,
    p.patient_name,
    p.phone,
    COUNT(a.appt_id)          AS total_appointments,
    COALESCE(SUM(a.cost), 0)  AS total_paid_egp,
    MIN(a.appt_date)          AS first_visit,
    MAX(a.appt_date)          AS last_visit
FROM Patient p
LEFT JOIN Appointment a ON a.patient_id = p.patient_id
GROUP  BY p.patient_id, p.patient_name, p.phone
ORDER  BY total_paid_egp DESC;

-- ------------------------------------------------------------
-- Q07: Number of appointments per doctor with total revenue.
--      Purpose: Workload analysis and performance tracking.
-- ------------------------------------------------------------
SELECT
    d.doctor_id,
    d.doctor_name,
    dep.dept_name,
    COUNT(a.appt_id)          AS appointment_count,
    COALESCE(SUM(a.cost), 0)  AS total_revenue_egp,
    ROUND(AVG(a.cost), 2)     AS avg_cost_per_appt
FROM Doctor d
JOIN Department dep ON d.dept_id    = dep.dept_id
LEFT JOIN Appointment a ON a.doctor_id = d.doctor_id
GROUP  BY d.doctor_id, d.doctor_name, dep.dept_name
ORDER  BY appointment_count DESC;

-- ------------------------------------------------------------
-- Q08: Revenue per department in the last 6 months.
--      Purpose: Financial reporting and budget allocation.
-- ------------------------------------------------------------
SELECT
    dep.dept_name,
    COUNT(a.appt_id)          AS total_appointments,
    SUM(a.cost)               AS total_revenue_egp,
    ROUND(AVG(a.cost), 2)     AS avg_appointment_cost,
    MIN(a.cost)               AS min_cost,
    MAX(a.cost)               AS max_cost
FROM Department dep
JOIN Doctor d       ON d.dept_id    = dep.dept_id
JOIN Appointment a  ON a.doctor_id  = d.doctor_id
WHERE  a.appt_date >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH)
GROUP  BY dep.dept_id, dep.dept_name
ORDER  BY total_revenue_egp DESC;

-- ============================================================
-- SECTION C — ADVANCED / ANALYTICAL QUERIES
-- ============================================================

-- ------------------------------------------------------------
-- Q09: Patients who have NEVER had an appointment.
--      Purpose: Outreach to registered-but-unseen patients.
--      Uses NOT EXISTS (more efficient than LEFT JOIN / NULL check
--      on large datasets).
-- ------------------------------------------------------------
SELECT
    p.patient_id,
    p.patient_name,
    p.phone,
    p.birth_date,
    TIMESTAMPDIFF(YEAR, p.birth_date, CURDATE()) AS age
FROM Patient p
WHERE NOT EXISTS (
    SELECT 1
    FROM   Appointment a
    WHERE  a.patient_id = p.patient_id
)
ORDER  BY p.patient_name;

-- ------------------------------------------------------------
-- Q10: Top doctors ranked by appointment count,
--      with overall rank using a Window Function.
--      Purpose: Staffing decisions and bonus calculations.
-- ------------------------------------------------------------
SELECT
    d.doctor_id,
    d.doctor_name,
    dep.dept_name,
    COUNT(a.appt_id)          AS total_appointments,
    COALESCE(SUM(a.cost), 0)  AS total_revenue_egp,
    ROUND(AVG(a.cost), 2)     AS avg_cost_per_appt,
    RANK() OVER (ORDER BY COUNT(a.appt_id) DESC) AS overall_rank
FROM Doctor d
JOIN Department dep ON d.dept_id    = dep.dept_id
LEFT JOIN Appointment a ON a.doctor_id = d.doctor_id
GROUP  BY d.doctor_id, d.doctor_name, dep.dept_name
ORDER  BY total_appointments DESC;

-- ------------------------------------------------------------
-- Q11: Most visited department (by appointment volume),
--      with contribution percentage of total appointments.
--      Purpose: Strategic resource allocation.
-- ------------------------------------------------------------
SELECT
    dep.dept_name,
    COUNT(a.appt_id)  AS dept_appointments,
    ROUND(
        COUNT(a.appt_id) * 100.0 /
        SUM(COUNT(a.appt_id)) OVER (), 2
    )                 AS pct_of_total
FROM Department dep
JOIN Doctor d       ON d.dept_id   = dep.dept_id
JOIN Appointment a  ON a.doctor_id = d.doctor_id
GROUP  BY dep.dept_id, dep.dept_name
ORDER  BY dept_appointments DESC;

-- ------------------------------------------------------------
-- Q12: Appointment duration and cost-per-minute efficiency.
--      Purpose: Evaluate pricing appropriateness per slot.
--      NULLIF prevents division-by-zero on zero-duration rows.
-- ------------------------------------------------------------
SELECT
    a.appt_id,
    a.appt_date,
    p.patient_name,
    d.doctor_name,
    dep.dept_name,
    TIMESTAMPDIFF(MINUTE, a.start_time, a.end_time) AS duration_min,
    a.cost,
    ROUND(
        a.cost / NULLIF(
            TIMESTAMPDIFF(MINUTE, a.start_time, a.end_time), 0
        ), 2
    )                                               AS cost_per_minute
FROM Appointment a
JOIN Patient    p   ON a.patient_id = p.patient_id
JOIN Doctor     d   ON a.doctor_id  = d.doctor_id
JOIN Department dep ON d.dept_id    = dep.dept_id
ORDER  BY cost_per_minute DESC;

-- ------------------------------------------------------------
-- Q13: Patients with more than 1 appointment — repeat visitors.
--      Purpose: Identify patients with chronic or ongoing care.
--      Uses HAVING to filter aggregated groups.
-- ------------------------------------------------------------
SELECT
    p.patient_id,
    p.patient_name,
    p.phone,
    COUNT(a.appt_id)    AS visit_count,
    SUM(a.cost)         AS total_spent_egp,
    MIN(a.appt_date)    AS first_visit,
    MAX(a.appt_date)    AS latest_visit
FROM Patient p
JOIN Appointment a ON a.patient_id = p.patient_id
GROUP  BY p.patient_id, p.patient_name, p.phone
HAVING visit_count > 1
ORDER  BY visit_count DESC;

-- ------------------------------------------------------------
-- Q14: Departments with NO appointments yet.
--      Purpose: Identify under-used or newly opened departments.
--      Uses LEFT JOIN + NULL check pattern.
-- ------------------------------------------------------------
SELECT
    dep.dept_id,
    dep.dept_name
FROM Department dep
LEFT JOIN Doctor d   ON d.dept_id    = dep.dept_id
LEFT JOIN Appointment a ON a.doctor_id = d.doctor_id
WHERE  a.appt_id IS NULL
GROUP  BY dep.dept_id, dep.dept_name
ORDER  BY dep.dept_name;

-- ============================================================
-- SECTION D — DML UPDATE QUERIES
-- ============================================================

-- ------------------------------------------------------------
-- Q15: Record a diagnosis and mark appointment as completed.
--      Purpose: Used after a consultation ends.
--      → Replace appt_id = 1 with the target appointment.
-- ------------------------------------------------------------
UPDATE Appointment
SET    diagnosis = 'Hypertension stage 2; Amlodipine 10 mg prescribed',
       status    = 'completed'
WHERE  appt_id   = 1;

-- Verify
SELECT appt_id, status, diagnosis
FROM   Appointment
WHERE  appt_id = 1;

-- ------------------------------------------------------------
-- Q16: Reschedule a postponed appointment to a new date/time.
--      Purpose: Administrative rescheduling workflow.
--      → Replace appt_id = 4 with the target appointment.
-- ------------------------------------------------------------
UPDATE Appointment
SET    appt_date   = '2026-06-15',
       start_time  = '10:00',
       end_time    = '10:30',
       status      = 'scheduled'
WHERE  appt_id = 4
  AND  status  = 'postponed';

-- Verify
SELECT appt_id, appt_date, start_time, end_time, status
FROM   Appointment
WHERE  appt_id = 4;

-- ------------------------------------------------------------
-- Q17: Apply a 10% cost reduction to all scheduled appointments
--      in the Pediatrics department (patient assistance policy).
--      Purpose: Bulk pricing update for a specific department.
-- ------------------------------------------------------------
UPDATE Appointment a
JOIN   Doctor d   ON a.doctor_id = d.doctor_id
JOIN   Department dep ON d.dept_id = dep.dept_id
SET    a.cost = ROUND(a.cost * 0.90, 2)
WHERE  dep.dept_name = 'Pediatrics'
  AND  a.status      = 'scheduled';

-- Verify
SELECT a.appt_id, a.appt_date, a.cost, a.status, dep.dept_name
FROM   Appointment a
JOIN   Doctor d   ON a.doctor_id = d.doctor_id
JOIN   Department dep ON d.dept_id = dep.dept_id
WHERE  dep.dept_name = 'Pediatrics';

-- ============================================================
-- SECTION E — VIEW DEMONSTRATIONS
-- ============================================================

-- ------------------------------------------------------------
-- Q18: Use vw_appointment_summary — today's full appointment list.
-- ------------------------------------------------------------
SELECT *
FROM   vw_appointment_summary
WHERE  appt_date = CURDATE()
ORDER  BY start_time;

-- ------------------------------------------------------------
-- Q19: Use vw_patient_medical_history — show patients who have
--      visited more than once and spent over 500 EGP total.
-- ------------------------------------------------------------
SELECT
    patient_name,
    age,
    total_visits,
    total_paid_egp,
    last_visit_date,
    latest_diagnosis
FROM   vw_patient_medical_history
WHERE  total_visits   > 1
  AND  total_paid_egp > 500
ORDER  BY total_paid_egp DESC;

-- ------------------------------------------------------------
-- Q20: Use vw_revenue_summary — top 5 earning doctors overall.
-- ------------------------------------------------------------
SELECT
    dept_name,
    doctor_name,
    total_appointments,
    total_revenue_egp,
    avg_cost
FROM   vw_revenue_summary
WHERE  total_appointments > 0
ORDER  BY total_revenue_egp DESC
LIMIT  5;

-- ============================================================
-- END OF QUERIES SCRIPT
-- ============================================================
