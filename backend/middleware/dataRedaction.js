const sensitivePatterns = {
  phone: /(\d{3})\d{3}(\d{4})/g,
  ssn: /(\d{3})-\d{2}-(\d{4})/g,
  creditCard: /(\d{4})\d{8}(\d{4})/g,
  email: /([a-zA-Z0-9._%+-]+)@([a-zA-Z0-9.-]+\.[a-zA-Z]{2,})/g,
  apiKey: /['\"]?[a-zA-Z0-9_-]{32,}['\"]?/g,
  jwt: /eyJ[A-Za-z0-9_-]+\.eyJ[A-Za-z0-9_-]+\.?[A-Za-z0-9_-]*/g,
};

const redactValue = (value, type = 'default') => {
  if (typeof value !== 'string') return value;

  switch (type) {
    case 'phone':
      return value.replace(sensitivePatterns.phone, '$1***$2');
    case 'ssn':
      return value.replace(sensitivePatterns.ssn, '$1-**-$2');
    case 'creditCard':
      return value.replace(sensitivePatterns.creditCard, '$1****$2');
    case 'email':
      return value.replace(sensitivePatterns.email, '$1@***');
    case 'apiKey':
      return value.replace(sensitivePatterns.apiKey, '[REDACTED_KEY]');
    case 'jwt':
      return value.replace(sensitivePatterns.jwt, '[REDACTED_TOKEN]');
    default:
      return '[REDACTED]';
  }
};

const sensitiveFields = [
  'password',
  'token',
  'accessToken',
  'refreshToken',
  'apiKey',
  'secret',
  'creditCard',
  'ssn',
  'socialSecurityNumber',
  'jwt',
  'sessionToken',
];

const redactObject = (obj, depth = 0, maxDepth = 10) => {
  if (depth > maxDepth) return obj;

  if (Array.isArray(obj)) {
    return obj.map((item) => redactObject(item, depth + 1, maxDepth));
  }

  if (obj && typeof obj === 'object') {
    const redacted = {};
    for (const key in obj) {
      if (sensitiveFields.some((field) => key.toLowerCase().includes(field.toLowerCase()))) {
        redacted[key] = '[REDACTED]';
      } else {
        redacted[key] = redactObject(obj[key], depth + 1, maxDepth);
      }
    }
    return redacted;
  }

  return obj;
};

const redactString = (str) => {
  if (typeof str !== 'string') return str;

  let result = str;

  // Redact common patterns
  result = result.replace(sensitivePatterns.phone, '$1***$2');
  result = result.replace(sensitivePatterns.email, '$1@***');
  result = result.replace(sensitivePatterns.apiKey, '[REDACTED_KEY]');
  result = result.replace(sensitivePatterns.jwt, '[REDACTED_TOKEN]');

  return result;
};

const dataRedactionMiddleware = (req, res, next) => {
  // Redact response
  const originalJson = res.json;
  res.json = function (data) {
    const redacted = redactObject(data);
    return originalJson.call(this, redacted);
  };

  next();
};

module.exports = {
  redactValue,
  redactObject,
  redactString,
  dataRedactionMiddleware,
  sensitiveFields,
};
