import api from './axios';

export const getDetections = () => api.get('/detections');
export const getDetection = (id) => api.get(`/detections/${id}`);
export const getDetectionsByLog = (logId) => api.get(`/detections/log/${logId}`);
export const createDetection = (data) => api.post('/detections', data);
export const updateDetection = (id, data) => api.put(`/detections/${id}`, data);
export const deleteDetection = (id) => api.delete(`/detections/${id}`);
