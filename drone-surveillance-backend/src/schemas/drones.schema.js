const { z } = require('zod');

const createDroneSchema = z.object({
  drone_name: z.string().min(1, 'Drone name is required').max(100),
  model: z.string().min(1, 'Model is required').max(100),
  status: z.enum(['Active', 'Inactive', 'Under Maintenance']).optional(),
  zone_id: z.number().int().positive().nullable().optional(),
});

const updateDroneSchema = z.object({
  drone_name: z.string().min(1).max(100).optional(),
  model: z.string().min(1).max(100).optional(),
  status: z.enum(['Active', 'Inactive', 'Under Maintenance']).optional(),
  zone_id: z.number().int().positive().nullable().optional(),
});

module.exports = { createDroneSchema, updateDroneSchema };
