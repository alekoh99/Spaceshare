const bodyParser = require('body-parser');

/**
 * Custom JSON parser that handles Firestore Timestamp objects
 * Converts Firestore Timestamps to ISO strings before parsing
 */
const createTimestampParser = () => {
  return bodyParser.json({
    limit: process.env.MAX_REQUEST_SIZE || '10mb',
    strict: true,
    reviver: (key, value) => {
      // Handle Firestore Timestamp objects
      // Firestore Timestamps are usually sent as { _nanoseconds: number, _seconds: number }
      if (
        value &&
        typeof value === 'object' &&
        ('_seconds' in value || '_nanoseconds' in value || '_seconds' in value)
      ) {
        try {
          // Convert Firestore Timestamp to ISO string
          const seconds = value._seconds || 0;
          const nanoseconds = value._nanoseconds || 0;
          const date = new Date(seconds * 1000 + Math.floor(nanoseconds / 1000000));
          return date.toISOString();
        } catch (error) {
          console.warn('Failed to parse Timestamp:', error.message);
          // Return the original value if parsing fails
          return value;
        }
      }

      // Handle Date objects (if they come through as ISO strings)
      if (key && typeof value === 'string' && /^\d{4}-\d{2}-\d{2}T/.test(value)) {
        // This is likely an ISO date string, keep it as is
        return value;
      }

      return value;
    },
  });
};

module.exports = {
  createTimestampParser,
};
