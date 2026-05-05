# Drone Surveillance Frontend

React.js + Tailwind CSS dashboard for the Drone Surveillance & Intelligence System.

## Prerequisites

- Node.js (v18+)
- npm
- Backend server running on port 5000

## Setup

```bash
npm install
npm run dev
```

The app starts on `http://localhost:5173` and proxies API requests to `http://localhost:5000`.

## Test Login Credentials

All seed users have the password: `password123`

| Email | Role | Pages |
|---|---|---|
| tariq.mehmood@giki.edu.pk | Admin | Dashboard, Users, Drones, Zones, Reports, Audit |
| hamza.rauf@giki.edu.pk | Operator | Dashboard, Missions, Drones, Detections |
| faisal.shahzad@giki.edu.pk | Analyst | Dashboard, Alerts, Incidents, Reports |
