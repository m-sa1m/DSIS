const { z } = require('zod');

const createZoneSchema = z.object({
  zone_name: z.string().min(1, 'Zone name is required').max(100),
  location_description: z.string().optional(),
  risk_level: z.enum(['Low', 'Medium', 'High']).optional(),
  coordinates_lat: z.number().min(-90).max(90).optional(),
  coordinates_lng: z.number().min(-180).max(180).optional(),
});

const updateZoneSchema = z.object({
  zone_name: z.string().min(1).max(100).optional(),
  location_description: z.string().optional(),
  risk_level: z.enum(['Low', 'Medium', 'High']).optional(),
  coordinates_lat: z.number().min(-90).max(90).optional(),
  coordinates_lng: z.number().min(-180).max(180).optional(),
});

module.exports = { createZoneSchema, updateZoneSchema };
