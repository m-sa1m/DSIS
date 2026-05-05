# Drone Surveillance Backend

Node.js + Express.js REST API for the Drone Surveillance & Intelligence System.

## Prerequisites

- Node.js (v18+)
- PostgreSQL 18
- npm

## Setup

### 1. Create the PostgreSQL database

Open a terminal (PowerShell or Command Prompt) and run:

```bash
psql -U postgres
CREATE DATABASE drone_surveillance;
\q
```

### 2. Run the schema and seed files

```bash
psql -U postgres -d drone_surveillance -f database/schema.sql
psql -U postgres -d drone_surveillance -f database/seed.sql
```

### 3. Configure environment variables

Edit the `.env` file in the project root:

```
DB_USER=postgres
DB_PASSWORD=your_actual_password
JWT_SECRET=some_long_random_string_here
```

### 4. Install dependencies and start

```bash
npm install
npm run dev
```

The server starts on `http://localhost:5000`.

## Test Login Credentials

All seed users have the password: `password123`

| Email | Role |
|---|---|
| tariq.mehmood@giki.edu.pk | Admin |
| ayesha.siddiqui@giki.edu.pk | Admin |
| hamza.rauf@giki.edu.pk | Operator |
| nadia.akram@giki.edu.pk | Operator |
| faisal.shahzad@giki.edu.pk | Analyst |
| sana.malik@giki.edu.pk | Analyst |

## API Base URL

All endpoints are prefixed with `/api/v1/`.
