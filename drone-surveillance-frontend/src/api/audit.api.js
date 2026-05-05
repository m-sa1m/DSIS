import api from './axios';

export const getAuditLogs = (userId) => {
  const params = userId ? { userId } : {};
  return api.get('/audit', { params });
};
