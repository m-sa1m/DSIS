import api from './axios';

export const getIncidents = () => api.get('/incidents');
export const getIncident = (id) => api.get(`/incidents/${id}`);
export const createIncident = (data) => api.post('/incidents', data);
export const updateIncident = (id, data) => api.put(`/incidents/${id}`, data);
export const updateIncidentStatus = (id, data) => api.put(`/incidents/${id}/status`, data);
export const deleteIncident = (id) => api.delete(`/incidents/${id}`);
