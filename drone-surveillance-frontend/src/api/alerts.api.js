import api from './axios';

export const getAlerts = () => api.get('/alerts');
export const getAlert = (id) => api.get(`/alerts/${id}`);
export const updateAlert = (id, data) => api.put(`/alerts/${id}`, data);
