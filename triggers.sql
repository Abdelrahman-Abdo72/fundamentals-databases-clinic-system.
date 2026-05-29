-- ============================================================
--  CLINIC MANAGEMENT SYSTEM — Triggers Script
--  Engine  : MySQL 8.0
--
--  IMPORTANT: Run create_tables.sql and load_data.sql FIRST.
--
--  Triggers Included:
--    1. trg_no_doctor_overlap       — Prevent double-booking a doctor
--    2. trg_auto_complete_status    — Auto-set status to 'completed'
--                                     when diagnosis is added
--    3. trg_log_postponed           — Log every postponement to an
--                                     audit table
--    4. trg_block_past_appointments — Prevent scheduling appointments
--                                     in the past
-- ============================================================

USE clinic_db;

-- ============================================================
-- SUPPORTING AUDIT TABLE
--   Used by Trigger 3 to record postponement events.
--   Created before the trigger that writes to it.
-- ============================================================
CREATE TABLE IF NOT EXISTS Appointment_Audit (
    audit_id      INT          NOT NULL AUTO_INCREMENT,
    appt_id       INT          NOT NULL,
    changed_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    old_status    VARCHAR(20),
    new_status    VARCHAR(20),
    changed_field VARCHAR(50),
    note          VARCHAR(255),

    CONSTRAINT pk_audit PRIMARY KEY (audit_id)
);

-- ============================================================
-- TRIGGER 1: trg_no_doctor_overlap
-- ============================================================
--  WHAT  : Fires BEFORE INSERT on Appointment.
--  WHY   : Prevents a doctor from being double-booked — i.e.,
--          having two appointments at the same date whose time
--          ranges overlap.
--  HOW   : Checks whether any existing 'scheduled' or
--          'in_progress' appointment for the same doctor on the
--          same date has a time window that overlaps with the
--          new appointment being inserted.
--          Overlap condition (A and B overlap when):
--            NEW.start_time < existing.end_time
--            AND NEW.end_time > existing.start_time
--  RESULT: If overlap found, a SQLSTATE 45000 error is raised
--          and the INSERT is aborted.
-- ============================================================
DROP TRIGGER IF EXISTS trg_no_doctor_overlap;

DELIMITER $$

CREATE TRIGGER trg_no_doctor_overlap
BEFORE INSERT ON Appointment
FOR EACH ROW
BEGIN
    DECLARE conflict_count INT DEFAULT 0;

    SELECT COUNT(*)
    INTO   conflict_count
    FROM   Appointment
    WHERE  doctor_id   = NEW.doctor_id
      AND  appt_date   = NEW.appt_date
      AND  status      NOT IN ('cancelled', 'postponed')
      AND  NEW.start_time < end_time
      AND  NEW.end_time   > start_time;

    IF conflict_count > 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT =
                'Scheduling conflict: this doctor already has an appointment during this time slot.';
    END IF;
END$$

DELIMITER ;

-- Test Trigger 1 (should SUCCEED — no overlap):
-- INSERT INTO Appointment
--     (appt_date, patient_id, doctor_id, start_time, end_time, cost, status)
-- VALUES ('2026-07-01', 1, 1, '09:00', '09:30', 400.00, 'scheduled');

-- Test Trigger 1 (should FAIL — same doctor, overlapping time):
-- INSERT INTO Appointment
--     (appt_date, patient_id, doctor_id, start_time, end_time, cost, status)
-- VALUES ('2026-07-01', 2, 1, '09:15', '09:45', 400.00, 'scheduled');


-- ============================================================
-- TRIGGER 2: trg_auto_complete_status
-- ============================================================
--  WHAT  : Fires BEFORE UPDATE on Appointment.
--  WHY   : Ensures consistency between the diagnosis field and
--          the status field. When a doctor fills in a diagnosis
--          for the first time (diagnosis changes from NULL to a
--          non-null value), the status should automatically
--          become 'completed'. This removes the need for the
--          application layer to manage this transition manually.
--  HOW   : Checks if diagnosis is being set for the first time
--          (OLD value was NULL, NEW value is NOT NULL).
--          If so, forces status = 'completed'.
-- ============================================================
DROP TRIGGER IF EXISTS trg_auto_complete_status;

DELIMITER $$

CREATE TRIGGER trg_auto_complete_status
BEFORE UPDATE ON Appointment
FOR EACH ROW
BEGIN
    -- Diagnosis being set for the first time → mark as completed
    IF OLD.diagnosis IS NULL AND NEW.diagnosis IS NOT NULL THEN
        SET NEW.status = 'completed';
    END IF;
END$$

DELIMITER ;

-- Test Trigger 2:
-- UPDATE Appointment
-- SET    diagnosis = 'Hypertension stage 2; medication adjusted'
-- WHERE  appt_id = 19;      -- was NULL before → status auto-set to 'completed'
-- SELECT appt_id, status, diagnosis FROM Appointment WHERE appt_id = 19;


-- ============================================================
-- TRIGGER 3: trg_log_postponed
-- ============================================================
--  WHAT  : Fires AFTER UPDATE on Appointment.
--  WHY   : Maintains a full audit trail of every status change
--          to 'postponed'. This supports administrative
--          follow-up (which appointments were postponed and when)
--          and satisfies regulatory record-keeping requirements.
--  HOW   : Checks if the status has changed TO 'postponed'
--          (NEW.status = 'postponed' AND OLD.status != 'postponed').
--          If true, inserts a record into Appointment_Audit.
-- ============================================================
DROP TRIGGER IF EXISTS trg_log_postponed;

DELIMITER $$

CREATE TRIGGER trg_log_postponed
AFTER UPDATE ON Appointment
FOR EACH ROW
BEGIN
    IF NEW.status = 'postponed' AND OLD.status <> 'postponed' THEN
        INSERT INTO Appointment_Audit
            (appt_id, old_status, new_status, changed_field, note)
        VALUES
            (OLD.appt_id,
             OLD.status,
             'postponed',
             'status',
             CONCAT('Appointment postponed. Original date: ', OLD.appt_date));
    END IF;
END$$

DELIMITER ;

-- Test Trigger 3:
-- UPDATE Appointment SET status = 'postponed' WHERE appt_id = 5;
-- SELECT * FROM Appointment_Audit;


-- ============================================================
-- TRIGGER 4: trg_block_past_appointments
-- ============================================================
--  WHAT  : Fires BEFORE INSERT on Appointment.
--  WHY   : Prevents scheduling new appointments in the past.
--          A receptionist should not be able to accidentally (or
--          intentionally) create a backdated appointment marked
--          as 'scheduled'.
--  HOW   : If the new appointment date is strictly before
--          today AND the status is 'scheduled', the INSERT is
--          blocked with a clear error message.
--          Completed or postponed records (e.g., data migration)
--          are allowed to have past dates.
-- ============================================================
DROP TRIGGER IF EXISTS trg_block_past_appointments;

DELIMITER $$

CREATE TRIGGER trg_block_past_appointments
BEFORE INSERT ON Appointment
FOR EACH ROW
BEGIN
    IF NEW.appt_date < CURDATE() AND NEW.status = 'scheduled' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT =
                'Invalid date: cannot schedule a new appointment in the past.';
    END IF;
END$$

DELIMITER ;

-- Test Trigger 4 (should FAIL — past date with scheduled status):
-- INSERT INTO Appointment
--     (appt_date, patient_id, doctor_id, start_time, end_time, cost, status)
-- VALUES ('2020-01-01', 1, 1, '09:00', '09:30', 300.00, 'scheduled');

-- Test Trigger 4 (should SUCCEED — past date but completed, e.g., migration):
-- INSERT INTO Appointment
--     (appt_date, patient_id, doctor_id, start_time, end_time, cost, status, diagnosis)
-- VALUES ('2020-01-01', 1, 1, '09:00', '09:30', 300.00, 'completed', 'Historical record');


-- ============================================================
-- TRIGGER SUMMARY
-- ============================================================
-- Run this to confirm all 4 triggers are installed:

SHOW TRIGGERS FROM clinic_db;

-- ============================================================
-- END OF TRIGGERS SCRIPT
-- ============================================================
