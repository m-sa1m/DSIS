# DSIS
# Drone Surveillance & Intelligence System

A web application for managing drone-based campus surveillance operations at GIK Institute of Engineering Sciences and Technology.

Built as the semester project for **CS-232 DBMS**.

---

## Table of Contents

- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Database Schema](#database-schema)
- [Role-Based Access Control](#role-based-access-control)
- [Prerequisites](#prerequisites)
- [Setup Instructions (Windows 11)](#setup-instructions-windows-11)
- [Login Credentials](#login-credentials)
- [Author](#author)

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Database | PostgreSQL 18 |
| Backend | Node.js, Express.js |
| Frontend | React.js, Tailwind CSS, Vite |
| Auth | JWT (JSON Web Tokens), bcrypt |
| Validation | Zod |
| Charts | Recharts |
| Icons | Lucide React |

---

## Project Structure

```
├── drone-surveillance-backend/
│   ├── database/
│   │   ├── schema.sql          # Tables, indexes, trigger, views, stored procedures
│   │   ├── seed.sql            # Sample data for GIKI campus
│   │   └── queries.sql         # 14 named SQL queries for course submission
│   ├── src/
│   │   ├── config/db.js        # PostgreSQL connection pool
│   │   ├── middleware/         # auth, rbac, validation, error handler
│   │   ├── schemas/            # Zod validation schemas
│   │   ├── controllers/        # Business logic for each resource
│   │   ├── routes/             # Express route definitions
│   │   ├── app.js              # Express app configuration
│   │   └── server.js           # Entry point
│   ├── .env                    # Environment variables (not committed)
│   └── package.json
│
├── drone-surveillance-frontend/
│   ├── src/
│   │   ├── api/                # Axios API modules
│   │   ├── components/
│   │   │   ├── layout/         # Topbar, Sidebar, Layout, ProtectedRoute
│   │   │   └── ui/             # Button, Badge, Card, Table, Modal, Input, Select, Spinner
│   │   ├── pages/
│   │   │   ├── admin/          # Dashboard, Users, Drones, Zones, Reports, Audit
│   │   │   ├── operator/       # Dashboard, Missions, Drones, Detections
│   │   │   └── analyst/        # Dashboard, Alerts, Incidents, Reports
│   │   ├── context/            # AuthContext with JWT persistence
│   │   ├── hooks/              # useAuth hook
│   │   ├── utils/              # formatDate, roleGuard
│   │   ├── App.jsx             # React Router with role-based routing
│   │   └── main.jsx            # Entry point
│   ├── vite.config.js
│   └── package.json
│
└── README.md
```

---

## Database Schema

10 tables with full referential integrity:

| Table | Purpose |
|-------|---------|
| `roles` | Admin, Operator, Analyst |
| `users` | System users with hashed passwords |
| `surveillance_zones` | GIKI campus areas with GPS coordinates |
| `drones` | Drone fleet with status and zone assignment |
| `flight_missions` | Scheduled/completed patrol missions |
| `flight_logs` | Telemetry data for each flight |
| `detected_objects` | Threat detections with coordinates |
| `alerts` | Notifications generated from detections |
| `incident_reports` | Escalated incidents from alerts |
| `audit_log` | User activity tracking |

Additional database objects:
- 7 performance indexes
- 1 trigger (`auto_generate_alert` — auto-creates Critical alert for High threats)
- 2 views (`analyst_alert_view`, `operator_mission_view`)
- 2 stored procedures (`update_incident_status`, `get_drone_utilization_report`)

---

## Role-Based Access Control

| Role | Access |
|------|--------|
| Admin | Full access — users, drones, zones, missions, reports, audit |
| Operator | Drones, zones, missions, flight logs, detections |
| Analyst | Read-only — alerts, incidents, reports |

---

## Prerequisites

- [Node.js](https://nodejs.org/) v18 or higher
- [PostgreSQL](https://www.postgresql.org/download/) 18 (with pgAdmin 4)
- npm (comes with Node.js)
- Git

---

## Setup Instructions (Windows 11)

### 1. Clone the Repository

```bash
git clone https://github.com/m-sa1m/drone-surveillance.git
cd drone-surveillance
```

### 2. Create the Database

1. Open **pgAdmin 4**
2. Right-click **Databases** → **Create** → **Database**
3. Name: `drone_surveillance` → click **Save**

### 3. Run Schema and Seed

1. Click on `drone_surveillance` database
2. Go to **Tools** → **Query Tool**
3. Click the **Open File** icon (folder), navigate to `drone-surveillance-backend/database/schema.sql`, open it
4. Press **F5** to execute — you should see `CREATE TABLE`, `CREATE INDEX`, `CREATE FUNCTION`, etc.
5. Open a new Query Tool tab, open `drone-surveillance-backend/database/seed.sql`, press **F5**

### 4. Configure Backend Environment

Create or edit `drone-surveillance-backend/.env`:

```env
# Server
PORT=5000
NODE_ENV=development

# PostgreSQL
DB_HOST=localhost
DB_PORT=5432
DB_NAME=drone_surveillance
DB_USER=postgres
DB_PASSWORD=your_postgres_password_here

# JWT
JWT_SECRET=any_long_random_string_here
JWT_EXPIRES_IN=7d
```

Replace `your_postgres_password_here` with your actual PostgreSQL password.

### 5. Start the Backend

```bash
cd drone-surveillance-backend
npm install
npm start
```

Server runs on **http://localhost:5000**

### 6. Start the Frontend

Open a **second terminal**:

```bash
cd drone-surveillance-frontend
npm install
npm run dev
```

App runs on **http://localhost:5173**

### 7. Open in Browser

Go to **http://localhost:5173** and login.

---

## Login Credentials

All accounts use password: **`password123`**

| Email | Role |
|-------|------|
| `tariq.mehmood@giki.edu.pk` | Admin |
| `ayesha.siddiqui@giki.edu.pk` | Admin |
| `hamza.rauf@giki.edu.pk` | Operator |
| `nadia.akram@giki.edu.pk` | Operator |
| `faisal.shahzad@giki.edu.pk` | Analyst |
| `sana.malik@giki.edu.pk` | Analyst |

---


---


## Author

**Muhammad Saim** (2024453)  
u2024453@giki.edu.pk  
GIK Institute of Engineering Sciences and Technology  

CS-232 DBMS — Spring 2026

---

## Acknowledgement

Special thanks to **Sir Nabi** for his excellent contributions in teaching this course and for providing the guidance that made this project possible.
