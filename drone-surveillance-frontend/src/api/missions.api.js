import api from './axios';

export const getMissions = () => api.get('/missions');
export const getMission = (id) => api.get(`/missions/${id}`);
export const getMissionsByDrone = (droneId) => api.get(`/missions/drone/${droneId}`);
export const createMission = (data) => api.post('/missions', data);
export const updateMission = (id, data) => api.put(`/missions/${id}`, data);
export const deleteMission = (id) => api.delete(`/missions/${id}`);
