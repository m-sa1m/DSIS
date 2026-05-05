const { z } = require('zod');

const updateAlertSchema = z.object({
  alert_status: z.enum(['New', 'Acknowledged', 'Resolved']),
  resolved_by: z.number().int().positive().nullable().optional(),
});

module.exports = { updateAlertSchema };
