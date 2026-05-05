const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const errorHandler = require('./middleware/errorHandler');

const authRoutes = require('./routes/auth.routes');
const usersRoutes = require('./routes/users.routes');
const dronesRoutes = require('./routes/drones.routes');
const zonesRoutes = require('./routes/zones.routes');
const missionsRoutes = require('./routes/missions.routes');
const logsRoutes = require('./routes/logs.routes');
const detectionsRoutes = require('./routes/detections.routes');
const alertsRoutes = require('./routes/alerts.routes');
const incidentsRoutes = require('./routes/incidents.routes');
const reportsRoutes = require('./routes/reports.routes');
const auditRoutes = require('./routes/audit.routes');

const app = express();

app.use(helmet());
app.use(cors());
app.use(morgan('dev'));
app.use(express.json());

app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/users', usersRoutes);
app.use('/api/v1/drones', dronesRoutes);
app.use('/api/v1/zones', zonesRoutes);
app.use('/api/v1/missions', missionsRoutes);
app.use('/api/v1/logs', logsRoutes);
app.use('/api/v1/detections', detectionsRoutes);
app.use('/api/v1/alerts', alertsRoutes);
app.use('/api/v1/incidents', incidentsRoutes);
app.use('/api/v1/reports', reportsRoutes);
app.use('/api/v1/audit', auditRoutes);

app.use(errorHandler);

module.exports = app;
