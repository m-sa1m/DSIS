const { z } = require('zod');

const createUserSchema = z.object({
  full_name: z.string().min(1, 'Full name is required').max(100),
  email: z.string().email('Invalid email address').max(150),
  password: z.string().min(6, 'Password must be at least 6 characters'),
  role_id: z.number().int().positive(),
  is_active: z.boolean().optional(),
});

const updateUserSchema = z.object({
  full_name: z.string().min(1).max(100).optional(),
  email: z.string().email().max(150).optional(),
  password: z.string().min(6).optional(),
  role_id: z.number().int().positive().optional(),
  is_active: z.boolean().optional(),
});

module.exports = { createUserSchema, updateUserSchema };
