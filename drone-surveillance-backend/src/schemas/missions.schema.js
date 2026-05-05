const { z } = require('zod');

const createMissionSchema = z.object({
  drone_id: z.number().int().positive(),
  zone_id: z.number().int().positive(),
  operator_id: z.number().int().positive(),
  scheduled_time: z.string().min(1, 'Scheduled time is required'),
  mission_status: z.enum(['Scheduled', 'In Progress', 'Completed', 'Aborted']).optional(),
  notes: z.string().optional(),
});

const updateMissionSchema = z.object({
  drone_id: z.number().int().positive().optional(),
  zone_id: z.number().int().positive().optional(),
  operator_id: z.number().int().positive().optional(),
  scheduled_time: z.string().optional(),
  mission_status: z.enum(['Scheduled', 'In Progress', 'Completed', 'Aborted']).optional(),
  notes: z.string().optional(),
});

module.exports = { createMissionSchema, updateMissionSchema };
