/**
 * Response Formatter Middleware
 * Standardizes all API responses to consistent format
 */

const formatSuccess = (data, message = 'Success', statusCode = 200) => {
  return {
    success: true,
    code: statusCode,
    message,
    data,
    timestamp: new Date().toISOString(),
  };
};

const formatError = (error, statusCode = 500, code = 'ERROR') => {
  return {
    success: false,
    code: statusCode,
    error: typeof error === 'string' ? error : error.message,
    details: error.details || null,
    timestamp: new Date().toISOString(),
  };
};

const responseFormatter = (req, res, next) => {
  // Override res.json to use formatter
  const originalJson = res.json.bind(res);

  res.json = function(data) {
    if (data && typeof data === 'object') {
      // If already formatted, send as-is
      if (data.success !== undefined && data.timestamp) {
        return originalJson(data);
      }

      // Format success response
      if (!data.error && !data.success) {
        data = formatSuccess(data, 'Success', res.statusCode || 200);
      }
    }

    return originalJson(data);
  };

  // Helper method for formatted responses
  res.success = function(data, message = 'Success', statusCode = 200) {
    this.status(statusCode);
    return this.json(formatSuccess(data, message, statusCode));
  };

  res.failure = function(error, statusCode = 500, code = 'ERROR') {
    this.status(statusCode);
    return this.json(formatError(error, statusCode, code));
  };

  next();
};

module.exports = {
  responseFormatter,
  formatSuccess,
  formatError,
};
