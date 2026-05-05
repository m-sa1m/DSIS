import api from './axios';

export const getDroneUtilization = () => api.get('/reports/drone-utilization');
export const getAlertTrends = () => api.get('/reports/alert-trends');
export const getHighRiskZones = () => api.get('/reports/high-risk-zones');
export const getOperatorPerformance = () => api.get('/reports/operator-performance');
