# SpaceShare

A full-stack Flutter mobile application paired with a secure Node.js backend for discovering, listing, and renting spaces. SpaceShare enables users to share their spaces with a vibrant community while providing a seamless experience for finding and booking unique locations.

## 📱 Project Overview

SpaceShare is a comprehensive space rental platform that connects space owners with renters. The platform features real-time messaging, secure payments, user authentication, and a robust backend infrastructure built with security best practices.

### Tech Stack

**Frontend:**
- Flutter (Dart)
- Firebase Authentication
- Real-time messaging
- Payment integration (Stripe)

**Backend:**
- Node.js with Express.js
- PostgreSQL & MongoDB
- Firebase (Firestore, Cloud Storage, Cloud Functions)
- JWT authentication
- Advanced security middleware

**Infrastructure:**
- Docker containerization
- Cloud Functions (Python)
- Firebase Rules (Firestore & Storage)
- Multi-database support

## 🚀 Key Features

### User Management
- Secure user authentication with JWT tokens
- Profile management with avatars
- User verification and background checks
- Privacy settings and account security

### Space Listings
- Create and manage space listings
- Image uploads and gallery management
- Real-time availability calendar
- Search and filters by location, price, amenities

### Messaging System
- Real-time chat between users
- Message history and notifications
- Typing indicators and read receipts
- Secure message encryption

### Payments & Bookings
- Stripe integration for secure payments
- Booking management and confirmations
- Commission tracking and analytics
- Refund handling

### Security
- AES-256 encryption for sensitive data
- Rate limiting and DDoS protection
- CORS security headers
- SQL injection prevention
- CSRF protection
- Content Security Policy (CSP)
- Secure cookie handling

## 📋 Prerequisites

### Required
- Flutter SDK (latest stable)
- Node.js 16+
- npm or yarn
- Dart SDK
- PostgreSQL 12+
- Firebase project setup

### Optional
- MongoDB Atlas (for document storage)
- Docker & Docker Compose
- Android Studio / Xcode
- Firebase CLI

## 🔧 Installation & Setup

### 1. Clone the Repository
```bash
git clone https://github.com/alekoh99/Spaceshare.git
cd Spaceshare
```

### 2. Backend Setup

```bash
cd backend
npm install
```

#### Configure Environment Variables
```bash
cp .env.example .env
```

Edit `.env` with your configuration:
```env
PORT=8080
NODE_ENV=development
JWT_SECRET=<your-jwt-secret>
DATABASE_URL=postgresql://user:password@localhost:5432/spaceshare_db
FIREBASE_SERVICE_ACCOUNT_PATH=../serviceAccountKey.json
CORS_ORIGIN=http://localhost:3000
ENCRYPTION_KEY=<your-32-byte-encryption-key>
```

#### Initialize Security
```bash
bash setup-security.sh
bash security-audit.sh
```

#### Start Backend
```bash
npm start
```

### 3. Frontend Setup

```bash
flutter pub get
flutter run
```

#### iOS Setup (macOS)
```bash
cd ios
pod install
cd ..
```

### 4. Firebase Configuration

1. Download `GoogleService-Info.plist` (iOS) from Firebase Console
2. Download `google-services.json` (Android) from Firebase Console
3. Place in respective platform directories
4. Update Firebase rules:
```bash
firebase deploy --only firestore:rules,storage
```

### 5. Database Setup

#### PostgreSQL
```bash
psql -U postgres -d spaceshare < backend/migrations/001_enable_rls.sql
```

#### MongoDB (Optional)
```bash
mongo < backend/migrations/mongodb-indexes.js
```

## 📁 Project Structure

```
SpaceShare/
├── lib/                          # Flutter frontend
│   ├── screens/                  # UI screens
│   ├── models/                   # Data models
│   ├── providers/                # State management
│   ├── services/                 # API & Firebase services
│   ├── widgets/                  # Reusable UI components
│   └── config/                   # App configuration
├── backend/                      # Node.js backend
│   ├── routes/                   # API endpoints
│   ├── middleware/               # Express middleware
│   ├── services/                 # Business logic
│   ├── security/                 # Security utilities
│   ├── migrations/               # Database migrations
│   └── server.js                 # Entry point
├── functions/                    # Firebase Cloud Functions
├── android/                      # Android native code
├── ios/                          # iOS native code
├── web/                          # Web configuration
└── docs/                         # Documentation
```

## 🔐 Security Features

### Authentication & Authorization
- JWT-based authentication with refresh tokens
- Multi-factor authentication (MFA) support
- Secure password hashing with bcrypt
- Session management with token rotation

### Data Protection
- AES-256-GCM encryption for sensitive data
- Input validation and sanitization
- SQL parameterization to prevent injection
- XSS protection with content sanitization

### API Security
- Rate limiting (100 requests/15 min default)
- CORS with origin whitelist
- Helmet.js security headers
- CSRF protection tokens
- Request signing with HMAC

### Database Security
- Row-level security (RLS) policies
- SSL/TLS for database connections
- Encrypted password storage
- Audit logging for sensitive operations

### Application Security
- Secure headers (CSP, X-Frame-Options, etc.)
- HTTP-only cookies
- Secure cookie flag in production
- SameSite cookie policy
- Automatic secret rotation

## 🧪 Testing

### Backend Tests
```bash
cd backend
npm test
node test-auth-flow.js
node test-security.js
```

### Flutter Tests
```bash
flutter test
flutter test integration_tests/
```

### Security Audit
```bash
cd backend
bash security-audit.sh
```

## 📊 API Documentation

### Authentication Endpoints
- `POST /api/auth/register` - User registration
- `POST /api/auth/login` - User login
- `POST /api/auth/refresh` - Refresh JWT token
- `POST /api/auth/logout` - User logout

### User Endpoints
- `GET /api/users/:id` - Get user profile
- `PUT /api/users/:id` - Update profile
- `POST /api/users/:id/avatar` - Upload avatar
- `GET /api/users/search` - Search users

### Space Endpoints
- `GET /api/spaces` - List all spaces
- `POST /api/spaces` - Create new space
- `GET /api/spaces/:id` - Get space details
- `PUT /api/spaces/:id` - Update space
- `DELETE /api/spaces/:id` - Delete space
- `POST /api/spaces/:id/images` - Upload images

### Messaging Endpoints
- `GET /api/messages/:conversationId` - Get messages
- `POST /api/messages` - Send message
- `GET /api/conversations` - List conversations
- `PUT /api/messages/:id/read` - Mark as read

### Payment Endpoints
- `POST /api/payments/intent` - Create payment intent
- `POST /api/payments/confirm` - Confirm payment
- `GET /api/bookings` - List bookings
- `POST /api/bookings` - Create booking

## 🚢 Deployment

### Docker Deployment
```bash
docker-compose up -d
```

### Firebase Deployment
```bash
firebase deploy
```

### Production Checklist
- [ ] Set `NODE_ENV=production`
- [ ] Update `CORS_ORIGIN` with production domain
- [ ] Generate strong `JWT_SECRET`
- [ ] Enable HTTPS/SSL
- [ ] Configure database backups
- [ ] Set up monitoring and alerts
- [ ] Enable Firebase security rules
- [ ] Update API keys and secrets
- [ ] Configure CDN for static assets
- [ ] Enable database replication

## 📈 Monitoring & Logging

### Logging
- Structured logging with redaction of sensitive data
- Separate log levels for development/production
- Log rotation and retention policies
- Sentry integration for error tracking

### Monitoring
- Real-time error tracking
- Performance monitoring with APM
- Database query logging (development only)
- API response time monitoring

## 🤝 Contributing

1. Create a feature branch: `git checkout -b feature/your-feature`
2. Commit changes: `git commit -am 'Add new feature'`
3. Push to branch: `git push origin feature/your-feature`
4. Submit a pull request

### Code Standards
- Follow Dart/Node.js style guides
- Write tests for new features
- Maintain security best practices
- Document public APIs

## 📝 Environment Variables Reference

### Backend (.env)
```
# Application
PORT=8080
NODE_ENV=production

# Security
JWT_SECRET=<32-char-minimum>
ENCRYPTION_KEY=<32-byte-hex>
ENCRYPTION_IV=<16-byte-hex>
SESSION_SECRET=<your-secret>

# Database
DATABASE_URL=postgresql://user:pass@host:5432/db
DB_USER=username
DB_PASSWORD=password

# Firebase
FIREBASE_SERVICE_ACCOUNT_PATH=./serviceAccountKey.json
FIREBASE_DATABASE_URL=https://project.firebaseio.com

# API Configuration
CORS_ORIGIN=https://yourdomain.com
STRIPE_SECRET_KEY=sk_...
STRIPE_PUBLISHABLE_KEY=pk_...

# Monitoring
SENTRY_DSN=https://...@sentry.io/...
LOG_LEVEL=info
```

## 🐛 Troubleshooting

### Backend Issues
- **Port Already in Use**: Change `PORT` in `.env`
- **Database Connection Failed**: Verify `DATABASE_URL` and PostgreSQL service
- **JWT Authentication Errors**: Check `JWT_SECRET` length (min 32 chars)
- **CORS Errors**: Update `CORS_ORIGIN` for your domain

### Flutter Issues
- **Firebase Plugin Errors**: Run `flutter pub get` and rebuild
- **iOS Build Fails**: Run `cd ios && pod install && cd ..`
- **Android Build Fails**: Check Android Studio SDK paths

### Firebase Issues
- **Firestore Rules Rejected**: Review and update security rules
- **Storage Upload Failed**: Check bucket permissions and quotas
- **Cloud Functions Deployment**: Ensure Node.js 16+ and dependencies installed

## 📚 Additional Resources

- [Flutter Documentation](https://flutter.dev)
- [Node.js Express Guide](https://expressjs.com)
- [Firebase Documentation](https://firebase.google.com/docs)
- [PostgreSQL Docs](https://www.postgresql.org/docs/)
- [Stripe Integration](https://stripe.com/docs)

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 👥 Authors

- **Alex Koh** - Initial development and architecture

## 🙏 Acknowledgments

- Flutter and Dart teams for excellent framework
- Express.js community for robust backend framework
- Firebase for scalable cloud infrastructure
- All contributors and testers

## 📞 Support

For issues, questions, or suggestions:
1. Check [Issues](https://github.com/alekoh99/Spaceshare/issues)
2. Create a new issue with detailed information
3. Contact: [Your Email/Contact]

---

**Last Updated**: February 2026
**Version**: 1.0.0
