const { z } = require('zod');

const createDetectionSchema = z.object({
  log_id: z.number().int().positive(),
  object_type: z.string().min(1, 'Object type is required').max(100),
  threat_level: z.enum(['Low', 'Medium', 'High']),
  coordinates_lat: z.number().min(-90).max(90).optional(),
  coordinates_lng: z.number().min(-180).max(180).optional(),
  description: z.string().optional(),
});

const updateDetectionSchema = z.object({
  log_id: z.number().int().positive().optional(),
  object_type: z.string().min(1).max(100).optional(),
  threat_level: z.enum(['Low', 'Medium', 'High']).optional(),
  coordinates_lat: z.number().min(-90).max(90).optional(),
  coordinates_lng: z.number().min(-180).max(180).optional(),
  description: z.string().optional(),
});

module.exports = { createDetectionSchema, updateDetectionSchema };
