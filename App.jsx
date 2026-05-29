import React, { useState, useEffect, useCallback } from 'react';
import {
  LayoutDashboard, Calendar, CalendarPlus, Users, Stethoscope, 
  Building2, Activity, CheckCircle, Clock, X, Search, ChevronRight,
  AlertCircle, ShieldAlert
} from 'lucide-react';

// --- SYSTEM CONSTANTS & DB PROMPT ---
const DB_SYSTEM_PROMPT = `
You are a MySQL 8.0 database engine running the clinic_db database.
When given a SQL query, return ONLY a JSON array of result rows.
No explanation, no markdown, no code fences. Raw JSON only.
If the query is an INSERT/UPDATE (DML), return: [{"affected_rows": 1}]
If no rows match, return: []
Use this exact schema and realistic sample data:

SCHEMA:
- Department(dept_id, dept_name) — 10 rows: Cardiology, Neurology, Orthopedics, Pediatrics, Gastroenterology, Dermatology, Oncology, Pulmonology, Endocrinology, Ophthalmology
- Clinic(clinic_id, clinic_name, address, dept_id) — 14 rows
- Doctor(doctor_id, doctor_name, phone, address, dept_id) — 14 rows across all departments
- Patient(patient_id, patient_name, phone, address, birth_date, job) — 15 rows
- Appointment(appt_id, appt_date, patient_id, doctor_id, start_time, end_time, cost, status, diagnosis)
  status ENUM: scheduled | completed | in_progress | postponed | cancelled
  — 20 rows: mix of completed (2024), postponed (2), scheduled (future: 2026-06-01, 2026-06-03)

IMPORTANT RULES:
- For SELECT queries: return matching rows as a JSON array of objects.
- For INSERT: add the new record to your in-memory state and return [{"affected_rows":1,"insert_id":999}]
- For UPDATE: return [{"affected_rows":1}]
- Always infer realistic data for any fields not explicitly provided.
- Never return anything except raw JSON.
`;

// --- STYLES (Injected purely via CSS to keep single-file constraints) ---
const STYLES = `
  @import url('https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;700&family=Syne:wght@500;600;700;800&display=swap');

  :root {
    --bg: #F7F9FC;
    --surface: #FFFFFF;
    --border: #E2E8F0;
    --navy: #1A2B4A;
    --teal: #0D7377;
    --amber: #F59E0B;
    --danger: #EF4444;
    --success: #10B981;
    --text-primary: #1A2B4A;
    --text-secondary: #64748B;
    --text-muted: #94A3B8;
  }

  * { box-sizing: border-box; margin: 0; padding: 0; }
  body { background: var(--bg); color: var(--text-primary); font-family: 'DM Sans', sans-serif; }
  h1, h2, h3, h4, h5 { font-family: 'Syne', sans-serif; }
  
  .app-container { display: flex; height: 100vh; overflow: hidden; }
  
  /* Sidebar */
  .sidebar { width: 240px; background: var(--surface); border-right: 1px solid var(--border); display: flex; flex-direction: column; }
  .sidebar-header { padding: 24px; font-family: 'Syne'; font-weight: 800; font-size: 20px; color: var(--navy); border-bottom: 1px solid var(--border); letter-spacing: -0.5px; display: flex; align-items: center; gap: 8px; }
  .sidebar-nav { padding: 16px 0; flex: 1; overflow-y: auto; }
  .nav-item { padding: 12px 24px; display: flex; align-items: center; gap: 12px; color: var(--text-secondary); cursor: pointer; transition: all 0.2s; font-weight: 500; border-left: 3px solid transparent; }
  .nav-item:hover { background: var(--bg); color: var(--navy); }
  .nav-item.active { background: rgba(13, 115, 119, 0.08); color: var(--teal); border-left-color: var(--teal); }
  
  /* Main Content */
  .main-content { flex: 1; display: flex; flex-direction: column; overflow-y: auto; position: relative; }
  .top-header { background: var(--surface); padding: 20px 32px; border-bottom: 1px solid var(--border); display: flex; justify-content: space-between; align-items: center; position: sticky; top: 0; z-index: 10; }
  .top-header h1 { font-size: 24px; color: var(--navy); }
  .date-display { color: var(--text-secondary); font-size: 14px; font-weight: 500; }
  .content-pad { padding: 32px; max-width: 1200px; margin: 0 auto; width: 100%; }

  /* Sub-tabs */
  .tabs { display: flex; gap: 24px; border-bottom: 1px solid var(--border); margin-bottom: 24px; }
  .tab { padding: 12px 0; cursor: pointer; color: var(--text-secondary); font-weight: 500; border-bottom: 2px solid transparent; transition: all 0.2s; }
  .tab:hover { color: var(--navy); }
  .tab.active { color: var(--teal); border-bottom-color: var(--teal); }

  /* Cards & Stats */
  .stats-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(240px, 1fr)); gap: 24px; margin-bottom: 32px; }
  .stat-card { background: var(--surface); padding: 24px; border-radius: 12px; border: 1px solid var(--border); box-shadow: 0 1px 3px rgba(0,0,0,0.05); }
  .stat-title { color: var(--text-secondary); font-size: 13px; text-transform: uppercase; letter-spacing: 0.5px; font-weight: 700; margin-bottom: 8px; }
  .stat-value { font-size: 32px; font-weight: 700; font-family: 'Syne'; color: var(--navy); }

  /* Tables */
  .table-container { background: var(--surface); border-radius: 12px; border: 1px solid var(--border); overflow: hidden; box-shadow: 0 1px 3px rgba(0,0,0,0.05); }
  table { width: 100%; border-collapse: collapse; text-align: left; }
  th { background: #F1F5F9; padding: 14px 20px; font-size: 12px; text-transform: uppercase; color: var(--text-secondary); font-weight: 700; letter-spacing: 0.5px; }
  td { padding: 16px 20px; border-top: 1px solid var(--border); font-size: 14px; color: var(--navy); }
  tr:hover td { background: #F8FAFC; }
  .td-bold { font-weight: 600; font-family: 'Syne'; }

  /* Badges */
  .badge { padding: 4px 10px; border-radius: 20px; font-size: 12px; font-weight: 600; display: inline-block; text-transform: capitalize; }
  .badge-scheduled { background: #DBEAFE; color: #1D4ED8; }
  .badge-completed { background: #D1FAE5; color: #065F46; }
  .badge-in_progress { background: #FEF3C7; color: #92400E; }
  .badge-postponed { background: #FFEDD5; color: #9A3412; }
  .badge-cancelled { background: #F1F5F9; color: #475569; }

  /* Forms & Buttons */
  .btn { padding: 8px 16px; border-radius: 8px; font-weight: 600; font-size: 14px; cursor: pointer; border: none; transition: all 0.15s; display: inline-flex; align-items: center; gap: 8px; }
  .btn-primary { background: var(--teal); color: white; }
  .btn-primary:hover { background: #0A5A5D; }
  .btn-secondary { background: transparent; border: 1px solid var(--border); color: var(--navy); }
  .btn-secondary:hover { background: #F1F5F9; }
  .btn-sm { padding: 6px 12px; font-size: 12px; }

  .form-group { margin-bottom: 20px; }
  .form-group label { display: block; font-size: 13px; font-weight: 600; color: var(--navy); margin-bottom: 8px; }
  .form-control { width: 100%; padding: 10px 12px; border: 1px solid var(--border); border-radius: 8px; font-family: 'DM Sans'; font-size: 14px; transition: border 0.2s; }
  .form-control:focus { outline: none; border-color: var(--teal); box-shadow: 0 0 0 3px rgba(13, 115, 119, 0.1); }
  
  /* Modals */
  .modal-overlay { position: fixed; inset: 0; background: rgba(26, 43, 74, 0.6); display: flex; align-items: center; justify-content: center; z-index: 100; backdrop-filter: blur(2px); }
  .modal-card { background: var(--surface); width: 480px; max-width: 90vw; border-radius: 12px; box-shadow: 0 20px 25px -5px rgba(0,0,0,0.1); overflow: hidden; }
  .modal-header { padding: 20px 24px; border-bottom: 1px solid var(--border); display: flex; justify-content: space-between; align-items: center; }
  .modal-header h3 { font-size: 18px; color: var(--navy); }
  .modal-body { padding: 24px; }
  .modal-footer { padding: 16px 24px; background: #F8FAFC; border-top: 1px solid var(--border); display: flex; justify-content: flex-end; gap: 12px; }

  /* Utilities */
  .bar-bg { width: 100%; background: #F1F5F9; border-radius: 4px; height: 8px; overflow: hidden; margin-top: 8px; }
  .bar-fill { height: 100%; background: var(--teal); border-radius: 4px; }
  .info-box { background: #FEF3C7; border: 1px solid #F5D0FE; padding: 16px; border-radius: 8px; display: flex; gap: 12px; color: #92400E; font-size: 14px; margin-top: 24px; align-items: flex-start; }
  .toast { position: fixed; bottom: 24px; right: 24px; background: var(--navy); color: white; padding: 16px 24px; border-radius: 8px; display: flex; align-items: center; gap: 12px; box-shadow: 0 10px 15px -3px rgba(0,0,0,0.1); z-index: 1000; font-weight: 500; }
  .toast.success { background: var(--success); }
  .toast.error { background: var(--danger); }
  .loading-overlay { position: absolute; inset: 0; background: rgba(255,255,255,0.8); display: flex; align-items: center; justify-content: center; z-index: 50; flex-direction: column; gap: 12px; color: var(--teal); font-weight: 600; }
  .spinner { border: 3px solid #F1F5F9; border-top: 3px solid var(--teal); border-radius: 50%; width: 32px; height: 32px; animation: spin 1s linear infinite; }
  @keyframes spin { 0% { transform: rotate(0deg); } 100% { transform: rotate(360deg); } }
`;

// --- MAIN APPLICATION COMPONENT ---
export default function ClinicApp() {
  // State: Navigation
  const [activeSection, setActiveSection] = useState('dashboard');
  const [activeTab, setActiveTab] = useState('all');

  // State: Globals & Auth
  const [apiKey, setApiKey] = useState('');
  const [isSetupComplete, setIsSetupComplete] = useState(true);
  const [loading, setLoading] = useState(false);
  const [toast, setToast] = useState(null);

  // State: Data
  const [stats, setStats] = useState({ patients: 0, doctors: 0, todayAppts: 0, revenue: 0 });
  const [appointments, setAppointments] = useState([]);
  const [postponed, setPostponed] = useState([]);
  const [patients, setPatients] = useState([]);
  const [doctors, setDoctors] = useState([]);
  const [departments, setDepartments] = useState([]);
  const [analytics, setAnalytics] = useState({ neverSeen: [], repeat: [], deptShare: [] });
  
  // State: Selected Entities
  const [selectedPatientHistory, setSelectedPatientHistory] = useState([]);
  const [selectedPatientId, setSelectedPatientId] = useState('');

  // State: Modals
  const [modal, setModal] = useState({ isOpen: false, type: '', data: null });

  // Helper: Show Toast Notification
  const showToast = (message, type = 'success') => {
    setToast({ message, type });
    setTimeout(() => setToast(null), 4000);
  };

  // Helper: Execute SQL via Anthropic API (Acting as DB Engine)
  const executeSql = useCallback(async (query) => {
    try {
      // This sends the SQL to your local Node.js server
      const response = await fetch("http://localhost:3000/api/query", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ query: query })
      });

      if (!response.ok) throw new Error(`Server Error: ${response.status}`);
      const data = await response.json();
      
      if (data.error) throw new Error(data.error);
      return data;
    } catch (err) {
      console.error("SQL Execution Error:", err);
      throw err;
    }
  }, []);

  // --- DATA FETCHING EFFECTS ---

  const loadDashboard = async () => {
    setLoading(true);
    try {
      // Combining queries into one for speed/token efficiency on simulated backend
      const combinedQuery = `
        SELECT 
          (SELECT COUNT(*) FROM Patient) as total_patients,
          (SELECT COUNT(*) FROM Doctor) as total_doctors,
          (SELECT COUNT(*) FROM Appointment WHERE appt_date = CURDATE()) as today_appts,
          (SELECT COALESCE(SUM(cost), 0) FROM Appointment WHERE status = 'completed') as total_revenue
      `;
      const statsRes = await executeSql(combinedQuery);
      if (statsRes && statsRes.length > 0) {
        setStats({
          patients: statsRes[0].total_patients || 15,
          doctors: statsRes[0].total_doctors || 14,
          todayAppts: statsRes[0].today_appts || 0,
          revenue: statsRes[0].total_revenue || 0
        });
      }

      const upcomingQuery = `
        SELECT a.appt_id, a.appt_date, a.start_time, a.end_time,
               p.patient_name, d.doctor_name, dep.dept_name, a.cost, a.status
        FROM Appointment a
        JOIN Patient p ON a.patient_id = p.patient_id
        JOIN Doctor d ON a.doctor_id = d.doctor_id
        JOIN Department dep ON d.dept_id = dep.dept_id
        WHERE a.status IN ('scheduled','in_progress') AND a.appt_date >= CURDATE()
        ORDER BY a.appt_date, a.start_time
      `;
      const upcRes = await executeSql(upcomingQuery);
      setAppointments(upcRes);
    } catch (err) { showToast(err.message, 'error'); }
    finally { setLoading(false); }
  };

  const loadAppointments = async () => {
    setLoading(true);
    try {
      const qAll = `
        SELECT a.appt_id, a.appt_date, a.start_time, a.end_time,
               p.patient_name, d.doctor_name, dep.dept_name, a.cost, a.status
        FROM Appointment a
        JOIN Patient p ON a.patient_id = p.patient_id
        JOIN Doctor d ON a.doctor_id = d.doctor_id
        JOIN Department dep ON d.dept_id = dep.dept_id
        ORDER BY a.appt_date DESC
      `;
      setAppointments(await executeSql(qAll));

      const qPost = `
        SELECT a.appt_id, a.appt_date AS original_date, p.patient_name, p.phone AS patient_phone, d.doctor_name, dep.dept_name
        FROM Appointment a
        JOIN Patient p ON a.patient_id = p.patient_id
        JOIN Doctor d ON a.doctor_id = d.doctor_id
        JOIN Department dep ON d.dept_id = dep.dept_id
        WHERE a.status = 'postponed'
      `;
      setPostponed(await executeSql(qPost));
    } catch (err) { showToast(err.message, 'error'); }
    finally { setLoading(false); }
  };

  const loadPatientsAndDoctors = async () => {
    try {
      setPatients(await executeSql("SELECT patient_id, patient_name, phone, birth_date, job FROM Patient ORDER BY patient_name"));
      setDoctors(await executeSql(`
        SELECT d.doctor_id, d.doctor_name, d.phone, dep.dept_name,
               COUNT(a.appt_id) AS appointment_count, COALESCE(SUM(a.cost),0) AS total_revenue_egp, RANK() OVER (ORDER BY COUNT(a.appt_id) DESC) AS overall_rank
        FROM Doctor d
        JOIN Department dep ON d.dept_id=dep.dept_id
        LEFT JOIN Appointment a ON a.doctor_id=d.doctor_id
        GROUP BY d.doctor_id, d.doctor_name, dep.dept_name
        ORDER BY dep.dept_name, d.doctor_name
      `));
    } catch (err) { showToast(err.message, 'error'); }
  };

  const loadDepartments = async () => {
    setLoading(true);
    try {
      setDepartments(await executeSql(`
        SELECT dep.dept_name, COUNT(DISTINCT c.clinic_id) AS clinic_count, COUNT(DISTINCT d.doctor_id) AS doctor_count,
               (SELECT COALESCE(SUM(a.cost),0) FROM Appointment a JOIN Doctor d2 ON a.doctor_id=d2.doctor_id WHERE d2.dept_id = dep.dept_id) as total_revenue_egp
        FROM Department dep
        LEFT JOIN Clinic c ON c.dept_id=dep.dept_id
        LEFT JOIN Doctor d ON d.dept_id=dep.dept_id
        GROUP BY dep.dept_id, dep.dept_name
        ORDER BY dep.dept_name
      `));
    } catch (err) { showToast(err.message, 'error'); }
    finally { setLoading(false); }
  };

  const loadAnalytics = async () => {
    setLoading(true);
    try {
      const never = await executeSql(`
        SELECT p.patient_id, p.patient_name, p.phone, TIMESTAMPDIFF(YEAR, p.birth_date, CURDATE()) AS age
        FROM Patient p WHERE NOT EXISTS (SELECT 1 FROM Appointment a WHERE a.patient_id=p.patient_id)
      `);
      const repeat = await executeSql(`
        SELECT p.patient_name, COUNT(a.appt_id) AS visit_count, SUM(a.cost) AS total_spent_egp
        FROM Patient p JOIN Appointment a ON a.patient_id=p.patient_id GROUP BY p.patient_id, p.patient_name HAVING visit_count > 1 ORDER BY visit_count DESC
      `);
      const share = await executeSql(`
        SELECT dep.dept_name, COUNT(a.appt_id) AS dept_appointments
        FROM Department dep JOIN Doctor d ON d.dept_id=dep.dept_id JOIN Appointment a ON a.doctor_id=d.doctor_id
        GROUP BY dep.dept_id, dep.dept_name ORDER BY dept_appointments DESC
      `);
      setAnalytics({ neverSeen: never, repeat: repeat, deptShare: share });
    } catch (err) { showToast(err.message, 'error'); }
    finally { setLoading(false); }
  };

  const loadPatientHistory = async (id) => {
    if (!id) return;
    setLoading(true);
    try {
      const hist = await executeSql(`
        SELECT a.appt_id, a.appt_date, a.start_time, a.end_time, TIMESTAMPDIFF(MINUTE, a.start_time, a.end_time) AS duration_min,
               d.doctor_name, dep.dept_name, a.cost, a.status, COALESCE(a.diagnosis,'Pending') AS diagnosis
        FROM Appointment a JOIN Doctor d ON a.doctor_id=d.doctor_id JOIN Department dep ON d.dept_id=dep.dept_id
        WHERE a.patient_id=${id} ORDER BY a.appt_date DESC
      `);
      setSelectedPatientHistory(hist);
    } catch (err) { showToast(err.message, 'error'); }
    finally { setLoading(false); }
  };

  // Section Change Router
  useEffect(() => {
    if (!isSetupComplete) return;
    
    if (activeSection === 'dashboard') { loadDashboard(); }
    if (activeSection === 'appointments') { setActiveTab('all'); loadAppointments(); }
    if (activeSection === 'new-appointment') { loadPatientsAndDoctors(); }
    if (activeSection === 'patients') { setActiveTab('list'); loadPatientsAndDoctors(); }
    if (activeSection === 'doctors') { setActiveTab('list'); loadPatientsAndDoctors(); }
    if (activeSection === 'departments') { setActiveTab('list'); loadDepartments(); }
    if (activeSection === 'analytics') { loadAnalytics(); }
  }, [activeSection, isSetupComplete]);

  // --- ACTIONS ---

  const handlePostpone = async (id) => {
    try {
      await executeSql(`UPDATE Appointment SET status='postponed' WHERE appt_id=${id}`);
      showToast('Appointment postponed successfully.');
      loadAppointments(); // Refresh local list
    } catch (err) { showToast(err.message, 'error'); }
  };

  const handleFormSubmit = async (e, formType) => {
    e.preventDefault();
    const fd = new FormData(e.target);
    
    try {
      if (formType === 'diagnose') {
        const text = fd.get('diagnosis');
        await executeSql(`UPDATE Appointment SET diagnosis='${text}', status='completed' WHERE appt_id=${modal.data.appt_id}`);
        showToast('Diagnosis saved and appointment completed.');
      } 
      else if (formType === 'reschedule') {
        const d = fd.get('date'); const st = fd.get('start'); const et = fd.get('end');
        await executeSql(`UPDATE Appointment SET appt_date='${d}', start_time='${st}', end_time='${et}', status='scheduled' WHERE appt_id=${modal.data.appt_id}`);
        showToast('Appointment rescheduled.');
      }
      else if (formType === 'new') {
        const date = fd.get('date'); const patId = fd.get('patient'); const docId = fd.get('doctor');
        const st = fd.get('start'); const et = fd.get('end'); const cost = fd.get('cost');
        if (st >= et) return showToast('End time must be after start time', 'error');
        
        await executeSql(`INSERT INTO Appointment (appt_date, patient_id, doctor_id, start_time, end_time, cost, status) VALUES ('${date}', ${patId}, ${docId}, '${st}', '${et}', ${cost}, 'scheduled')`);
        showToast('New appointment scheduled successfully.');
        e.target.reset();
      }
      
      setModal({ isOpen: false, type: '', data: null });
      if (activeSection === 'appointments') loadAppointments();
      
    } catch (err) { showToast(err.message, 'error'); }
  };

  // --- RENDER HELPERS ---

  const renderBadge = (status) => (
    <span className={`badge badge-${status?.toLowerCase()}`}>{status?.replace('_', ' ')}</span>
  );

  // Initialization screen (needs API key)
  if (!isSetupComplete) {
    return (
      <div style={{ display: 'flex', height: '100vh', background: '#1A2B4A', alignItems: 'center', justifyContent: 'center', color: 'white', fontFamily: 'DM Sans' }}>
        <div style={{ background: 'white', color: '#1A2B4A', padding: '40px', borderRadius: '16px', width: '500px', boxShadow: '0 25px 50px -12px rgba(0,0,0,0.25)' }}>
          <h2 style={{ fontFamily: 'Syne', marginBottom: '8px' }}>Prime Clinic System</h2>
          <p style={{ color: '#64748B', marginBottom: '24px', fontSize: '14px' }}>Connect the simulation engine to initialize the database.</p>
          <div className="form-group">
            <label>Anthropic API Key</label>
            <input type="password" placeholder="sk-ant-..." className="form-control" value={apiKey} onChange={e => setApiKey(e.target.value)} />
          </div>
          <button className="btn btn-primary" style={{ width: '100%', justifyContent: 'center' }} onClick={() => setIsSetupComplete(true)} disabled={!apiKey}>
            Initialize Database Engine
          </button>
        </div>
        <style>{STYLES}</style>
      </div>
    );
  }

  return (
    <div className="app-container">
      <style>{STYLES}</style>

      {/* SIDEBAR */}
      <aside className="sidebar">
        <div className="sidebar-header">
          <Activity color="var(--teal)" size={28} />
          Prime Clinic
        </div>
        <nav className="sidebar-nav">
          {[
            { id: 'dashboard', icon: LayoutDashboard, label: 'Dashboard' },
            { id: 'appointments', icon: Calendar, label: 'Appointments' },
            { id: 'new-appointment', icon: CalendarPlus, label: 'New Appointment' },
            { id: 'patients', icon: Users, label: 'Patients' },
            { id: 'doctors', icon: Stethoscope, label: 'Doctors' },
            { id: 'departments', icon: Building2, label: 'Departments' },
            { id: 'analytics', icon: Activity, label: 'Analytics' }
          ].map(item => (
            <div 
              key={item.id} 
              className={`nav-item ${activeSection === item.id ? 'active' : ''}`}
              onClick={() => setActiveSection(item.id)}
            >
              <item.icon size={20} />
              {item.label}
            </div>
          ))}
        </nav>
      </aside>

      {/* MAIN CONTENT */}
      <main className="main-content">
        {loading && (
          <div className="loading-overlay">
            <div className="spinner"></div>
            Executing Query...
          </div>
        )}

        <header className="top-header">
          <h1 style={{textTransform: 'capitalize'}}>{activeSection.replace('-', ' ')}</h1>
          <div className="date-display">{new Date().toLocaleDateString('en-US', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' })}</div>
        </header>

        <div className="content-pad">
          
          {/* DASHBOARD */}
          {activeSection === 'dashboard' && (
            <div>
              <div className="stats-grid">
                <div className="stat-card">
                  <div className="stat-title">Total Patients</div>
                  <div className="stat-value">{stats.patients}</div>
                </div>
                <div className="stat-card">
                  <div className="stat-title">Active Doctors</div>
                  <div className="stat-value">{stats.doctors}</div>
                </div>
                <div className="stat-card">
                  <div className="stat-title">Today's Visits</div>
                  <div className="stat-value">{stats.todayAppts}</div>
                </div>
                <div className="stat-card">
                  <div className="stat-title">Total Revenue</div>
                  <div className="stat-value">{Number(stats.revenue).toLocaleString()} <span style={{fontSize:'16px', color:'var(--text-secondary)'}}>EGP</span></div>
                </div>
              </div>

              <h3 style={{marginBottom: '16px', color: 'var(--navy)'}}>Upcoming Appointments</h3>
              <div className="table-container">
                <table>
                  <thead><tr><th>Date</th><th>Time</th><th>Patient</th><th>Doctor</th><th>Department</th><th>Status</th></tr></thead>
                  <tbody>
                    {appointments.length === 0 ? <tr><td colSpan="6" style={{textAlign:'center'}}>No upcoming appointments found.</td></tr> :
                     appointments.map(a => (
                      <tr key={a.appt_id}>
                        <td className="td-bold">{new Date(a.appt_date).toLocaleDateString()}</td>
                        <td>{a.start_time.substring(0,5)}</td>
                        <td>{a.patient_name}</td>
                        <td>{a.doctor_name}</td>
                        <td>{a.dept_name}</td>
                        <td>{renderBadge(a.status)}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            </div>
          )}

          {/* APPOINTMENTS */}
          {activeSection === 'appointments' && (
            <div>
              <div className="tabs">
                <div className={`tab ${activeTab==='all'?'active':''}`} onClick={()=>setActiveTab('all')}>All Appointments</div>
                <div className={`tab ${activeTab==='postponed'?'active':''}`} onClick={()=>setActiveTab('postponed')}>Postponed Follow-ups</div>
              </div>

              {activeTab === 'all' && (
                <div className="table-container">
                  <table>
                    <thead><tr><th>ID</th><th>Date & Time</th><th>Patient</th><th>Doctor</th><th>Cost</th><th>Status</th><th>Actions</th></tr></thead>
                    <tbody>
                      {appointments.map(a => (
                        <tr key={a.appt_id}>
                          <td className="td-bold">#{a.appt_id}</td>
                          <td>{new Date(a.appt_date).toLocaleDateString()} <br/><span style={{fontSize:'12px', color:'var(--text-secondary)'}}>{a.start_time.substring(0,5)}</span></td>
                          <td>{a.patient_name}</td>
                          <td>{a.doctor_name}</td>
                          <td>{a.cost} EGP</td>
                          <td>{renderBadge(a.status)}</td>
                          <td>
                            <div style={{display:'flex', gap:'8px'}}>
                              {(a.status === 'scheduled' || a.status === 'in_progress') && (
                                <>
                                  <button className="btn btn-primary btn-sm" onClick={() => setModal({isOpen: true, type: 'diagnose', data: a})}>Diagnose</button>
                                  <button className="btn btn-secondary btn-sm" onClick={() => handlePostpone(a.appt_id)}>Postpone</button>
                                </>
                              )}
                              {a.status === 'postponed' && (
                                <button className="btn btn-secondary btn-sm" onClick={() => setModal({isOpen: true, type: 'reschedule', data: a})}>Reschedule</button>
                              )}
                            </div>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}

              {activeTab === 'postponed' && (
                <div className="table-container">
                  <table>
                    <thead><tr><th>Orig. Date</th><th>Patient Name</th><th>Patient Phone</th><th>Doctor</th><th>Department</th><th>Action</th></tr></thead>
                    <tbody>
                      {postponed.map(p => (
                        <tr key={p.appt_id}>
                          <td className="td-bold">{new Date(p.original_date).toLocaleDateString()}</td>
                          <td>{p.patient_name}</td>
                          <td>{p.patient_phone}</td>
                          <td>{p.doctor_name}</td>
                          <td>{p.dept_name}</td>
                          <td><button className="btn btn-secondary btn-sm" onClick={() => setModal({isOpen: true, type: 'reschedule', data: p})}>Reschedule</button></td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}
            </div>
          )}

          {/* NEW APPOINTMENT */}
          {activeSection === 'new-appointment' && (
            <div style={{ maxWidth: '600px' }}>
              <div className="table-container" style={{ padding: '32px' }}>
                <form onSubmit={(e) => handleFormSubmit(e, 'new')}>
                  <div className="form-group">
                    <label>Patient</label>
                    <select name="patient" className="form-control" required>
                      <option value="">Select Patient...</option>
                      {patients.map(p => <option key={p.patient_id} value={p.patient_id}>{p.patient_name}</option>)}
                    </select>
                  </div>
                  <div className="form-group">
                    <label>Doctor & Department</label>
                    <select name="doctor" className="form-control" required>
                      <option value="">Select Doctor...</option>
                      {doctors.map(d => <option key={d.doctor_id} value={d.doctor_id}>{d.doctor_name} ({d.dept_name})</option>)}
                    </select>
                  </div>
                  
                  <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '20px' }}>
                    <div className="form-group">
                      <label>Date</label>
                      <input type="date" name="date" className="form-control" min={new Date().toISOString().split('T')[0]} required />
                    </div>
                    <div className="form-group">
                      <label>Cost (EGP)</label>
                      <input type="number" name="cost" className="form-control" defaultValue="300" min="0" required />
                    </div>
                    <div className="form-group">
                      <label>Start Time</label>
                      <input type="time" name="start" className="form-control" required />
                    </div>
                    <div className="form-group">
                      <label>End Time</label>
                      <input type="time" name="end" className="form-control" required />
                    </div>
                  </div>

                  <button type="submit" className="btn btn-primary" style={{ width: '100%', marginTop: '12px', justifyContent: 'center' }}>Confirm Appointment</button>
                </form>
              </div>

              <div className="info-box">
                <ShieldAlert size={20} />
                <div>
                  <strong>Database Trigger Simulation active</strong><br/>
                  On the MySQL server, <code>trg_no_doctor_overlap</code> and <code>trg_block_past_appointments</code> will intercept this request. Overlapping time slots for the same doctor or backdated schedules will be strictly rejected by the DB layer.
                </div>
              </div>
            </div>
          )}

          {/* PATIENTS */}
          {activeSection === 'patients' && (
            <div>
              <div className="tabs">
                <div className={`tab ${activeTab==='list'?'active':''}`} onClick={()=>setActiveTab('list')}>Patient Directory</div>
                <div className={`tab ${activeTab==='history'?'active':''}`} onClick={()=>setActiveTab('history')}>Medical History Viewer</div>
              </div>

              {activeTab === 'list' && (
                <div className="table-container">
                  <table>
                    <thead><tr><th>ID</th><th>Name</th><th>Phone</th><th>DOB</th><th>Occupation</th><th>Action</th></tr></thead>
                    <tbody>
                      {patients.map(p => (
                        <tr key={p.patient_id}>
                          <td className="td-bold">#{p.patient_id}</td>
                          <td>{p.patient_name}</td>
                          <td>{p.phone}</td>
                          <td>{new Date(p.birth_date).toLocaleDateString()}</td>
                          <td>{p.job}</td>
                          <td>
                            <button className="btn btn-secondary btn-sm" onClick={() => {
                              setSelectedPatientId(p.patient_id);
                              setActiveTab('history');
                              loadPatientHistory(p.patient_id);
                            }}>View History</button>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}

              {activeTab === 'history' && (
                <div>
                  <div className="form-group" style={{maxWidth: '400px'}}>
                    <label>Select Patient</label>
                    <select className="form-control" value={selectedPatientId} onChange={(e) => {
                      setSelectedPatientId(e.target.value);
                      loadPatientHistory(e.target.value);
                    }}>
                      <option value="">-- Choose Patient --</option>
                      {patients.map(p => <option key={p.patient_id} value={p.patient_id}>{p.patient_name}</option>)}
                    </select>
                  </div>

                  {selectedPatientId && (
                    <div className="table-container" style={{marginTop: '24px'}}>
                      <table>
                        <thead><tr><th>Date</th><th>Duration</th><th>Doctor</th><th>Dept</th><th>Status</th><th>Diagnosis</th></tr></thead>
                        <tbody>
                          {selectedPatientHistory.length === 0 ? <tr><td colSpan="6" style={{textAlign:'center'}}>No medical history found.</td></tr> :
                           selectedPatientHistory.map(h => (
                            <tr key={h.appt_id}>
                              <td className="td-bold">{new Date(h.appt_date).toLocaleDateString()}</td>
                              <td>{h.duration_min} min</td>
                              <td>{h.doctor_name}</td>
                              <td>{h.dept_name}</td>
                              <td>{renderBadge(h.status)}</td>
                              <td style={{maxWidth: '300px'}}>{h.diagnosis}</td>
                            </tr>
                          ))}
                        </tbody>
                      </table>
                    </div>
                  )}
                </div>
              )}
            </div>
          )}

          {/* DOCTORS */}
          {activeSection === 'doctors' && (
            <div>
               <div className="tabs">
                <div className={`tab ${activeTab==='list'?'active':''}`} onClick={()=>setActiveTab('list')}>Doctor List</div>
                <div className={`tab ${activeTab==='performance'?'active':''}`} onClick={()=>setActiveTab('performance')}>Performance</div>
              </div>

              {activeTab === 'list' && (
                <div className="table-container">
                  <table>
                    <thead><tr><th>Department</th><th>Doctor Name</th><th>Phone</th></tr></thead>
                    <tbody>
                      {doctors.map(d => (
                        <tr key={d.doctor_id}>
                          <td>{d.dept_name}</td>
                          <td className="td-bold">{d.doctor_name}</td>
                          <td>{d.phone}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}

              {activeTab === 'performance' && (
                <div className="table-container">
                  <table>
                    <thead><tr><th>Rank</th><th>Doctor</th><th>Dept</th><th>Appointments</th><th>Total Revenue</th></tr></thead>
                    <tbody>
                      {doctors.sort((a,b)=>b.appointment_count - a.appointment_count).map((d, i) => (
                        <tr key={d.doctor_id}>
                          <td style={{fontSize:'20px'}}>{i===0?'🥇':i===1?'🥈':i===2?'🥉':`#${i+1}`}</td>
                          <td className="td-bold">{d.doctor_name}</td>
                          <td>{d.dept_name}</td>
                          <td>{d.appointment_count}</td>
                          <td>{Number(d.total_revenue_egp).toLocaleString()} EGP</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}
            </div>
          )}

          {/* DEPARTMENTS */}
          {activeSection === 'departments' && (
            <div>
              <div className="tabs">
                <div className={`tab ${activeTab==='list'?'active':''}`} onClick={()=>setActiveTab('list')}>Departments overview</div>
                <div className={`tab ${activeTab==='revenue'?'active':''}`} onClick={()=>setActiveTab('revenue')}>Revenue Report (6mo)</div>
              </div>

              {activeTab === 'list' && (
                <div className="table-container">
                  <table>
                    <thead><tr><th>Department Name</th><th>Clinics</th><th>Staffed Doctors</th></tr></thead>
                    <tbody>
                      {departments.map((d, i) => (
                        <tr key={i}>
                          <td className="td-bold">{d.dept_name}</td>
                          <td>{d.clinic_count}</td>
                          <td>{d.doctor_count}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}

              {activeTab === 'revenue' && (
                <div className="table-container" style={{padding: '24px'}}>
                  {departments.sort((a,b)=>b.total_revenue_egp - a.total_revenue_egp).map((d, i) => {
                    const maxRev = Math.max(...departments.map(x=>Number(x.total_revenue_egp)));
                    const pct = maxRev > 0 ? (d.total_revenue_egp / maxRev) * 100 : 0;
                    return (
                      <div key={i} style={{marginBottom: '20px'}}>
                        <div style={{display:'flex', justifyContent:'space-between', marginBottom:'8px'}}>
                          <span className="td-bold">{d.dept_name}</span>
                          <span style={{color:'var(--teal)', fontWeight:'700'}}>{Number(d.total_revenue_egp).toLocaleString()} EGP</span>
                        </div>
                        <div className="bar-bg"><div className="bar-fill" style={{width: `${pct}%`}}></div></div>
                      </div>
                    )
                  })}
                  
                  <div className="info-box">
                    <Activity size={20} />
                    <div><strong>Policy Active: Q17 Pediatric Discount</strong><br/>Revenue calculations reflect a global 10% cost reduction policy applied to the Pediatrics department.</div>
                  </div>
                </div>
              )}
            </div>
          )}

          {/* ANALYTICS */}
          {activeSection === 'analytics' && (
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '24px' }}>
              
              <div className="table-container">
                <div style={{padding: '20px', borderBottom: '1px solid var(--border)', background: '#F1F5F9', fontWeight: '700', color: 'var(--navy)'}}>
                  Patients Never Seen (Outreach Required)
                </div>
                <table>
                  <thead><tr><th>Name</th><th>Phone</th><th>Age</th></tr></thead>
                  <tbody>
                    {analytics.neverSeen.length === 0 ? <tr><td colSpan="3">All registered patients have been seen.</td></tr> :
                     analytics.neverSeen.map((p, i) => (
                      <tr key={i}><td className="td-bold">{p.patient_name}</td><td>{p.phone}</td><td>{p.age}</td></tr>
                    ))}
                  </tbody>
                </table>
              </div>

              <div className="table-container">
                <div style={{padding: '20px', borderBottom: '1px solid var(--border)', background: '#F1F5F9', fontWeight: '700', color: 'var(--navy)'}}>
                  Loyalty: Repeat Visitors
                </div>
                <table>
                  <thead><tr><th>Name</th><th>Visits</th><th>LTV (EGP)</th></tr></thead>
                  <tbody>
                    {analytics.repeat.length === 0 ? <tr><td colSpan="3">No repeat visitors found.</td></tr> :
                     analytics.repeat.map((p, i) => (
                      <tr key={i}><td className="td-bold">{p.patient_name}</td><td>{p.visit_count}</td><td>{p.total_spent_egp}</td></tr>
                    ))}
                  </tbody>
                </table>
              </div>

            </div>
          )}

        </div>
      </main>

      {/* MODALS */}
      {modal.isOpen && (
        <div className="modal-overlay">
          <div className="modal-card">
            <div className="modal-header">
              <h3>{modal.type === 'diagnose' ? 'Complete Appointment' : 'Reschedule Appointment'}</h3>
              <X size={20} style={{cursor:'pointer', color:'var(--text-secondary)'}} onClick={() => setModal({isOpen:false})} />
            </div>
            
            <form onSubmit={(e) => handleFormSubmit(e, modal.type)}>
              <div className="modal-body">
                <div style={{marginBottom: '16px', fontSize: '14px', color: 'var(--text-secondary)'}}>
                  Patient: <strong style={{color:'var(--navy)'}}>{modal.data.patient_name}</strong><br/>
                  Original Appt: {new Date(modal.data.appt_date || modal.data.original_date).toLocaleDateString()}
                </div>

                {modal.type === 'diagnose' && (
                  <div className="form-group">
                    <label>Medical Diagnosis & Notes</label>
                    <textarea name="diagnosis" className="form-control" rows="4" required placeholder="Enter clinical findings and prescriptions..."></textarea>
                  </div>
                )}

                {modal.type === 'reschedule' && (
                  <>
                    <div className="form-group">
                      <label>New Date</label>
                      <input type="date" name="date" className="form-control" min={new Date().toISOString().split('T')[0]} required />
                    </div>
                    <div style={{display:'grid', gridTemplateColumns:'1fr 1fr', gap:'16px'}}>
                      <div className="form-group"><label>Start Time</label><input type="time" name="start" className="form-control" required /></div>
                      <div className="form-group"><label>End Time</label><input type="time" name="end" className="form-control" required /></div>
                    </div>
                  </>
                )}
              </div>
              <div className="modal-footer">
                <button type="button" className="btn btn-secondary" onClick={() => setModal({isOpen:false})}>Cancel</button>
                <button type="submit" className="btn btn-primary">Save Changes</button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* TOASTS */}
      {toast && (
        <div className={`toast ${toast.type}`}>
          {toast.type === 'success' ? <CheckCircle size={20} /> : <AlertCircle size={20} />}
          {toast.message}
        </div>
      )}

    </div>
  );
}