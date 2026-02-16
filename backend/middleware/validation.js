const Joi = require('joi');

/**
 * Validation Schemas
 */
const schemas = {
  // User/Profile validation
  profileSchema: Joi.object({
    userId: Joi.string().required().min(20).max(128),
    email: Joi.string().email().required(),
    name: Joi.string().required().min(2).max(100),
    city: Joi.string().required().min(2).max(100),
    bio: Joi.string().max(1000),
    avatar: Joi.string().uri().max(2048),
    phone: Joi.string()
      .pattern(/^[+]?[\d\s-()]{10,}$/)
      .max(20),
    preferences: Joi.object({
      notifications: Joi.boolean(),
      matureContent: Joi.boolean(),
      petFriendly: Joi.boolean(),
    }),
    verified: Joi.boolean(),
    createdAt: Joi.date(),
    updatedAt: Joi.date(),
  }).unknown(false),

  // Login/Auth validation
  loginSchema: Joi.object({
    email: Joi.string().email().required(),
    password: Joi.string().required().min(12).max(256),
    mfaCode: Joi.string().length(6).pattern(/^\d+$/),
  }).unknown(false),

  // Registration validation
  registerSchema: Joi.object({
    email: Joi.string().email().required(),
    password: Joi.string()
      .required()
      .min(12)
      .max(256)
      .pattern(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]+$/, 'password must contain uppercase, lowercase, number, and special character'),
    confirmPassword: Joi.string().valid(Joi.ref('password')).required(),
    name: Joi.string().required().min(2).max(100),
  }).unknown(false),

  // Password change validation
  passwordChangeSchema: Joi.object({
    currentPassword: Joi.string().required(),
    newPassword: Joi.string()
      .required()
      .min(12)
      .pattern(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]+$/),
    confirmPassword: Joi.string().valid(Joi.ref('newPassword')).required(),
  }).unknown(false),

  // Update profile validation
  updateProfileSchema: Joi.object({
    name: Joi.string().min(2).max(100),
    bio: Joi.string().max(1000),
    avatar: Joi.string().uri().max(2048),
    city: Joi.string().min(2).max(100),
    phone: Joi.string()
      .pattern(/^[+]?[\d\s-()]{10,}$/)
      .max(20),
    preferences: Joi.object({
      notifications: Joi.boolean(),
      matureContent: Joi.boolean(),
      petFriendly: Joi.boolean(),
    }),
  }).unknown(false),

  // Listing validation
  listingSchema: Joi.object({
    title: Joi.string().required().min(5).max(200),
    description: Joi.string().required().min(20).max(5000),
    price: Joi.number().required().min(0).max(999999),
    location: Joi.string().required().min(5).max(200),
    roomType: Joi.string().required().valid('entire', 'shared', 'private'),
    bedrooms: Joi.number().required().min(0).max(10),
    bathrooms: Joi.number().required().min(0).max(10),
    amenities: Joi.array().items(Joi.string()),
    images: Joi.array().items(Joi.string().uri().max(2048)).max(10),
    status: Joi.string().valid('active', 'inactive', 'archived'),
  }).unknown(false),

  // Review validation
  reviewSchema: Joi.object({
    rating: Joi.number().required().integer().min(1).max(5),
    title: Joi.string().required().min(3).max(200),
    comment: Joi.string().required().min(10).max(5000),
    categories: Joi.object({
      cleanliness: Joi.number().integer().min(1).max(5),
      communication: Joi.number().integer().min(1).max(5),
      reliability: Joi.number().integer().min(1).max(5),
      value: Joi.number().integer().min(1).max(5),
    }),
  }).unknown(false),

  // Message validation
  messageSchema: Joi.object({
    conversationId: Joi.string().required().min(10).max(128),
    content: Joi.string().required().min(1).max(10000),
    attachments: Joi.array().items(Joi.string().uri().max(2048)).max(5),
  }).unknown(false),

  // Pagination validation
  paginationSchema: Joi.object({
    page: Joi.number().integer().min(1).default(1),
    limit: Joi.number().integer().min(1).max(100).default(20),
    sort: Joi.string().max(50),
    filter: Joi.object().unknown(true),
  }).unknown(false),
};

/**
 * Validate Request Body
 */
const validateBody = (schemaName) => {
  return (req, res, next) => {
    const schema = schemas[schemaName];

    if (!schema) {
      return res.status(500).json({
        success: false,
        error: `Validation schema '${schemaName}' not found.`,
      });
    }

    const { error, value } = schema.validate(req.body, {
      abortEarly: false,
      stripUnknown: true,
      convert: true,
    });

    if (error) {
      const details = error.details.map((detail) => ({
        field: detail.path.join('.'),
        message: detail.message,
        type: detail.type,
      }));

      return res.status(400).json({
        success: false,
        error: 'Validation failed.',
        details,
      });
    }

    req.validatedBody = value;
    next();
  };
};

/**
 * Validate Request Query Parameters
 */
const validateQuery = (schemaName) => {
  return (req, res, next) => {
    const schema = schemas[schemaName];

    if (!schema) {
      return res.status(500).json({
        success: false,
        error: `Validation schema '${schemaName}' not found.`,
      });
    }

    const { error, value } = schema.validate(req.query, {
      abortEarly: false,
      stripUnknown: true,
      convert: true,
    });

    if (error) {
      const details = error.details.map((detail) => ({
        field: detail.path.join('.'),
        message: detail.message,
      }));

      return res.status(400).json({
        success: false,
        error: 'Invalid query parameters.',
        details,
      });
    }

    req.validatedQuery = value;
    next();
  };
};

/**
 * Validate Request Parameters
 */
const validateParams = (schemaName) => {
  return (req, res, next) => {
    const schema = schemas[schemaName];

    if (!schema) {
      return res.status(500).json({
        success: false,
        error: `Validation schema '${schemaName}' not found.`,
      });
    }

    const { error, value } = schema.validate(req.params, {
      abortEarly: false,
      stripUnknown: true,
      convert: true,
    });

    if (error) {
      const details = error.details.map((detail) => ({
        field: detail.path.join('.'),
        message: detail.message,
      }));

      return res.status(400).json({
        success: false,
        error: 'Invalid URL parameters.',
        details,
      });
    }

    req.validatedParams = value;
    next();
  };
};

/**
 * Sanitize User Input (Remove dangerous characters)
 */
const sanitizeInput = (input) => {
  if (typeof input !== 'string') {
    return input;
  }

  return input
    .replace(/[<>]/g, '') // Remove angle brackets
    .replace(/[\n\r]/g, ' ') // Remove line breaks
    .trim();
};

/**
 * Sanitize Object (Recursively clean object properties)
 */
const sanitizeObject = (obj) => {
  if (typeof obj !== 'object' || obj === null) {
    return obj;
  }

  const sanitized = Array.isArray(obj) ? [] : {};

  for (const [key, value] of Object.entries(obj)) {
    if (typeof value === 'string') {
      sanitized[key] = sanitizeInput(value);
    } else if (typeof value === 'object') {
      sanitized[key] = sanitizeObject(value);
    } else {
      sanitized[key] = value;
    }
  }

  return sanitized;
};

module.exports = {
  validateBody,
  validateQuery,
  validateParams,
  sanitizeInput,
  sanitizeObject,
  schemas,
};
