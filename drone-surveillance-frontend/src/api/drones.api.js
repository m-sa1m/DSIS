import api from './axios';

export const getDrones = () => api.get('/drones');
export const getDrone = (id) => api.get(`/drones/${id}`);
export const createDrone = (data) => api.post('/drones', data);
export const updateDrone = (id, data) => api.put(`/drones/${id}`, data);
export const deleteDrone = (id) => api.delete(`/drones/${id}`);
