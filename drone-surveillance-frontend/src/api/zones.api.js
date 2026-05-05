import api from './axios';

export const getZones = () => api.get('/zones');
export const getZone = (id) => api.get(`/zones/${id}`);
export const createZone = (data) => api.post('/zones', data);
export const updateZone = (id, data) => api.put(`/zones/${id}`, data);
export const deleteZone = (id) => api.delete(`/zones/${id}`);
