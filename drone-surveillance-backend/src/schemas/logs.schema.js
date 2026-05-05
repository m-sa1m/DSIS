const { z } = require('zod');

const createLogSchema = z.object({
  mission_id: z.number().int().positive(),
  start_time: z.string().min(1, 'Start time is required'),
  end_time: z.string().nullable().optional(),
  duration_minutes: z.number().int().nonnegative().nullable().optional(),
  start_lat: z.number().min(-90).max(90).optional(),
  start_lng: z.number().min(-180).max(180).optional(),
  end_lat: z.number().min(-90).max(90).nullable().optional(),
  end_lng: z.number().min(-180).max(180).nullable().optional(),
});

const updateLogSchema = z.object({
  mission_id: z.number().int().positive().optional(),
  start_time: z.string().optional(),
  end_time: z.string().nullable().optional(),
  duration_minutes: z.number().int().nonnegative().nullable().optional(),
  start_lat: z.number().min(-90).max(90).optional(),
  start_lng: z.number().min(-180).max(180).optional(),
  end_lat: z.number().min(-90).max(90).nullable().optional(),
  end_lng: z.number().min(-180).max(180).nullable().optional(),
});

module.exports = { createLogSchema, updateLogSchema };
