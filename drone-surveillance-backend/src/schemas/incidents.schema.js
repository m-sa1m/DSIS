const { z } = require('zod');

const createIncidentSchema = z.object({
  alert_id: z.number().int().positive(),
  reported_by: z.number().int().positive(),
  title: z.string().min(1, 'Title is required').max(200),
  description: z.string().optional(),
  incident_status: z.enum(['Open', 'Under Review', 'Resolved', 'Archived']).optional(),
});

const updateIncidentSchema = z.object({
  alert_id: z.number().int().positive().optional(),
  reported_by: z.number().int().positive().optional(),
  title: z.string().min(1).max(200).optional(),
  description: z.string().optional(),
  incident_status: z.enum(['Open', 'Under Review', 'Resolved', 'Archived']).optional(),
});

const updateIncidentStatusSchema = z.object({
  incident_status: z.enum(['Open', 'Under Review', 'Resolved', 'Archived']),
});

module.exports = { createIncidentSchema, updateIncidentSchema, updateIncidentStatusSchema };
