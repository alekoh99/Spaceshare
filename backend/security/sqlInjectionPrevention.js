const crypto = require('crypto');

class SQLInjectionPrevention {
  constructor() {
    this.whitelist = {
      orderBy: ['created_at', 'updated_at', 'name', 'email', 'status'],
      sortOrder: ['ASC', 'DESC'],
    };
  }

  validateOrderBy(field) {
    return this.whitelist.orderBy.includes(field);
  }

  validateSortOrder(order) {
    return this.whitelist.sortOrder.includes(order.toUpperCase());
  }

  sanitizeQuery(query) {
    // Remove dangerous characters
    return query
      .replace(/['";\\]/g, '')
      .replace(/--/g, '')
      .replace(/\/\*/g, '')
      .replace(/\*\//g, '');
  }

  validateInput(input, type = 'string') {
    const maxLengths = {
      email: 254,
      name: 100,
      phone: 20,
      zipCode: 10,
      string: 1000,
    };

    if (input.length > (maxLengths[type] || maxLengths.string)) {
      return false;
    }

    switch (type) {
      case 'email':
        return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(input);
      case 'phone':
        return /^\+?[1-9]\d{1,14}$/.test(input);
      case 'zipCode':
        return /^\d{5}(-\d{4})?$/.test(input);
      case 'uuid':
        return /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(
          input
        );
      case 'number':
        return !isNaN(input);
      default:
        return true;
    }
  }

  escapeString(str) {
    if (typeof str !== 'string') return str;
    return str.replace(/'/g, "''");
  }

  validatePaginationParams(page, limit) {
    const p = parseInt(page);
    const l = parseInt(limit);

    const isValidPage = !isNaN(p) && p > 0 && p <= 1000000;
    const isValidLimit = !isNaN(l) && l > 0 && l <= 1000;

    return isValidPage && isValidLimit ? { page: p, limit: l } : null;
  }
}

module.exports = new SQLInjectionPrevention();
