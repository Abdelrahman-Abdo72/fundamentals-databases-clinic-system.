# Clinic Management System Database Project

## Overview
This project is a Clinic Management System database project developed using MySQL 8.0.  
It manages the main clinic workflow, including departments, clinics, doctors, patients, appointments, diagnoses, appointment costs, and appointment status.

The project also includes SQL views, triggers, sample queries, reports, and a simple web application built with React/Vite for the frontend and Node.js/Express for the backend.

## Main Features
- Manage medical departments and clinics
- Store doctor and patient information
- Schedule appointments between patients and doctors
- Track appointment status, cost, timing, and diagnosis
- Generate reports using SQL views
- Prevent invalid appointment data using triggers
- Display database results through a web application

## Database Tables
The database includes the following main tables:

- Department
- Clinic
- Doctor
- Patient
- Appointment
- Appointment_Audit

The Appointment table is the central table because it connects patients with doctors and stores scheduling, clinical, and financial information.

## SQL Files
The SQL implementation is organized inside the `sql` folder:


```text
sql/
├─ create_tables.sql
├─ load_data.sql
├─ queries.sql
└─ triggers.sql

How to set up and run the website:
1) run all the database sql files
2) go to backend
3) open server.js --> change password to your local instance password
4) open terminal in backend folder
5) type node server.js
6) go to frontend
7) open terminal in frontend folder
8) type npm run dev
9) in your browser go to http://localhost:5173/