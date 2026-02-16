const Joi = require('joi');
const validator = require('email-validator');

// Sanitization functions
const sanitizeString = (str) => {
  if (typeof str !== 'string') return str;
  return str
    .trim()
    .replace(/[<>\"'`]/g, '')
    .slice(0, 1000); // Max 1000 chars
};

const sanitizeEmail = (email) => {
  if (!email) return '';
  return email.toLowerCase().trim().slice(0, 254);
};

const sanitizeObject = (obj) => {
  if (Array.isArray(obj)) {
    return obj.map(sanitizeObject);
  }
  if (obj && typeof obj === 'object') {
    return Object.keys(obj).reduce((acc, key) => {
      acc[key] = sanitizeObject(obj[key]);
      return acc;
    }, {});
  }
  if (typeof obj === 'string') {
    return sanitizeString(obj);
  }
  return obj;
};

// Validation schemas
const schemas = {
  user: Joi.object({
    userId: Joi.string().alphanum().max(128).required(),
    email: Joi.string().email().max(254).required(),
    displayName: Joi.string().max(100),
    bio: Joi.string().max(500),
  }),

  profile: Joi.object({
    firstName: Joi.string().max(50),
    lastName: Joi.string().max(50),
    phone: Joi.string().regex(/^\+?[1-9]\d{1,14}$/).optional(),
    address: Joi.string().max(200),
    city: Joi.string().max(100),
    state: Joi.string().max(50),
    zipCode: Joi.string().regex(/^\d{5}(-\d{4})?$/),
  }),

  authentication: Joi.object({
    email: Joi.string().email().max(254).required(),
    password: Joi.string()
      .min(12)
      .max(128)
      .pattern(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])/)
      .required(),
  }),

  message: Joi.object({
    conversationId: Joi.string().alphanum().required(),
    text: Joi.string().max(5000).required(),
    attachments: Joi.array().items(
      Joi.object({
        type: Joi.string().valid('image', 'file'),
        url: Joi.string().uri(),
      })
    ),
  }),

  listing: Joi.object({
    title: Joi.string().max(200).required(),
    description: Joi.string().max(5000).required(),
    price: Joi.number().positive().required(),
    location: Joi.string().max(250).required(),
    amenities: Joi.array().items(Joi.string().max(50)),
    images: Joi.array().items(Joi.string().uri()).max(10),
  }),
};

const validateInput = (schema) => {
  return async (req, res, next) => {
    try {
      const { error, value } = schema.validate(req.body, {
        abortEarly: false,
        stripUnknown: true,
      });

      if (error) {
        return res.status(400).json({
          success: false,
          error: 'Validation failed',
          details: error.details.map((err) => ({
            field: err.path.join('.'),
            message: err.message,
          })),
        });
      }

      // Sanitize validated data
      req.validatedBody = sanitizeObject(value);
      next();
    } catch (err) {
      res.status(400).json({
        success: false,
        error: 'Input validation error',
      });
    }
  };
};

const validateEmail = (email) => {
  return validator.validate(sanitizeEmail(email));
};

const validatePassword = (password) => {
  if (!password || password.length < 12) return false;
  if (!/[a-z]/.test(password)) return false;
  if (!/[A-Z]/.test(password)) return false;
  if (!/\d/.test(password)) return false;
  if (!/[@$!%*?&]/.test(password)) return false;
  return true;
};

module.exports = {
  sanitizeString,
  sanitizeEmail,
  sanitizeObject,
  validateInput,
  validateEmail,
  validatePassword,
  schemas,
};
