class PermissionValidator {
  constructor() {
    this.rolePermissions = {
      admin: [
        'read_users',
        'write_users',
        'delete_users',
        'read_payments',
        'write_payments',
        'read_listings',
        'write_listings',
        'delete_listings',
        'read_reports',
        'write_reports',
        'manage_roles',
      ],
      moderator: [
        'read_users',
        'read_payments',
        'read_listings',
        'read_reports',
        'write_reports',
      ],
      user: [
        'read_own_profile',
        'write_own_profile',
        'read_listings',
        'write_listings',
        'read_messages',
        'write_messages',
        'read_payments',
        'write_payments',
      ],
    };

    this.resourcePermissions = {
      user: {
        read: ['own', 'admin'],
        write: ['own', 'admin'],
        delete: ['admin'],
      },
      listing: {
        read: ['all'],
        write: ['owner', 'admin'],
        delete: ['owner', 'admin'],
      },
      payment: {
        read: ['parties', 'admin'],
        write: ['admin'],
        delete: ['admin'],
      },
      message: {
        read: ['parties', 'admin'],
        write: ['parties'],
        delete: ['admin'],
      },
    };
  }

  hasPermission(user, permission) {
    const permissions = this.rolePermissions[user.role] || [];
    return permissions.includes(permission);
  }

  canAccessResource(user, resource, action, resourceOwnerId = null) {
    const permissions = this.resourcePermissions[resource]?.[action];

    if (!permissions) {
      return false;
    }

    if (permissions.includes('all')) {
      return true;
    }

    if (permissions.includes('admin') && user.role === 'admin') {
      return true;
    }

    if (permissions.includes('own') && user.userId === resourceOwnerId) {
      return true;
    }

    if (permissions.includes('owner') && user.userId === resourceOwnerId) {
      return true;
    }

    if (permissions.includes('parties')) {
      // For messages and payments, check if user is a party
      return true; // Parent handler should verify actual parties
    }

    return false;
  }

  requirePermission(permission) {
    return (req, res, next) => {
      if (!req.user) {
        return res.status(401).json({
          success: false,
          error: 'Authentication required',
        });
      }

      if (!this.hasPermission(req.user, permission)) {
        return res.status(403).json({
          success: false,
          error: 'Insufficient permissions',
        });
      }

      next();
    };
  }

  requireResourceAccess(resource, action) {
    return (req, res, next) => {
      if (!req.user) {
        return res.status(401).json({
          success: false,
          error: 'Authentication required',
        });
      }

      const resourceOwnerId = req.params.userId || req.params.resourceId;
      const hasAccess = this.canAccessResource(
        req.user,
        resource,
        action,
        resourceOwnerId
      );

      if (!hasAccess) {
        return res.status(403).json({
          success: false,
          error: 'Access denied',
        });
      }

      next();
    };
  }
}

module.exports = new PermissionValidator();
