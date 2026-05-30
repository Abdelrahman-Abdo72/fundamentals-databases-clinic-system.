// server.js
const express = require('express');
const cors = require('cors');
const mysql = require('mysql2/promise');

const app = express();

// Allow requests from your React frontend
app.use(cors());
app.use(express.json());

// Set up your MySQL Database Connection
const pool = mysql.createPool({
  host: 'localhost',
  user: 'root',         // <-- CHANGE THIS to your MySQL username
  password: '119721134', // <-- CHANGE THIS to your MySQL password
  database: 'clinic_db' // <-- CHANGE THIS to your database name
});

// Create the exact API endpoint your React code is looking for
app.post('/api/query', async (req, res) => {
  const { query } = req.body;
  console.log("Executing Query:", query);

  try {
    const [results] = await pool.query(query);

    // If it's a SELECT query, MySQL2 returns an array of rows
    if (Array.isArray(results)) {
      res.json(results);
    } 
    // If it's an INSERT/UPDATE, format it exactly as your frontend expects
    else {
      res.json([{ 
        affected_rows: results.affectedRows,
        insert_id: results.insertId 
      }]);
    }
  } catch (error) {
    console.error("Database Error:", error.message);
    // Send the error back to the frontend so it can show the red error toast
    res.status(500).json({ error: error.message });
  }
});

const PORT = 3000;
app.listen(PORT, () => {
  console.log(`✅ Backend Database Server running on http://localhost:${PORT}`);
});