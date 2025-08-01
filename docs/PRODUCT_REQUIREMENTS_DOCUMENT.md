
# Product Requirements Document (PRD)

## Architecture Overview
SNS Rooster is a multi-component platform for workforce and business management, consisting of:
- **Admin Portal**: Web-based admin dashboard for super admins and company admins.
- **Backend API**: Node.js/Express.js RESTful API for all business logic, authentication, and data storage.
- **Mobile App**: Flutter-based cross-platform app for employees and admins.

## Project Overview
SNS Rooster is designed for small and medium businesses to manage employees, users, and business operations efficiently. It supports multiple user roles (super admin, company admin, employee) and streamlines attendance, analytics, and user management across web and mobile platforms.

## Target Audience
Small businesses with:
- 5 to 500 employees.
- A need for efficient user and attendance management.
- Limited technical expertise.
- Industries such as retail, healthcare, and education.

## User Roles
1. **Super Admin (Admin Portal)**:
   - Manages all companies, users, and subscription plans.
   - Access to analytics, system settings, and platform-wide configuration.
2. **Company Admin (Admin Portal & Mobile App)**:
   - Manages employees and users within their company.
   - Oversees attendance, business operations, and company-specific settings.
3. **Employee (Mobile App)**:
   - Views and manages attendance, personal profile, and receives notifications.
   - Limited access to company features.

## Features
### Admin Portal (Web)
- Authentication (JWT, role-based)
- Dashboard with real-time analytics and system status
- Company management (CRUD)
- User management across companies (CRUD, role assignment)
- Subscription plan management
- System settings and configuration
- Security: role-based access, protected routes
- Responsive, accessible UI (Material-UI, React)

### Backend API
- RESTful endpoints for all business logic
- User and company management
- Attendance tracking (check-in/out, breaks, reports)
- Analytics aggregation and reporting
- Secure authentication and authorization (JWT)
- Error handling and logging

### Mobile App (Flutter)
- Employee and admin dashboards
- Attendance check-in/out, break management
- User profile management (phone, address, emergency contact, passport upload, education, certificates)
- Push notifications (planned)
- Multi-language support (planned)
- Cloud sync and backup (planned)

### Feature Status
- All core features (user management, attendance, analytics, settings) are implemented in both admin portal and mobile app.
- Analytics and settings are fully functional (not placeholders).
- Future features: push notifications, multi-language, cloud integration.
## Technology Stack
1. **Admin Portal (Web)**:
   - React 19 (TypeScript)
   - Material-UI (MUI) v7
   - React Context API
   - Axios, React Router
2. **Backend**:
   - Node.js, Express.js
   - MongoDB (Mongoose ODM)
   - JWT authentication, CORS
   - RESTful APIs
3. **Mobile App**:
   - Flutter (Dart)
   - Provider for state management
   - HTTP (RESTful API)
4. **Scripts & Tooling**:
   - PowerShell, JavaScript, npm scripts
5. **Testing**:
   - Automated tests (JavaScript, Jest, etc.)

## Folder Structure
```
SNS-Rooster/
├── admin-portal/         # Web admin portal (React)
├── rooster-backend/      # Node.js/Express backend API
├── sns_rooster/          # Flutter mobile app
├── docs/                 # Documentation
└── ...                   # Other scripts, configs, assets
```

## Development Plan
### Phase 1: Core Features
- Complete user, company, and attendance management (web & mobile)
- Secure authentication and role-based access
- Analytics dashboard and system settings
- Estimated timeline: 3 months

### Phase 2: Enhancements
- Push notifications, multi-language support
- UI/UX improvements
- Estimated timeline: 2 months

### Phase 3: Scaling
- Cloud integration, performance optimization
- Support for larger businesses
- Estimated timeline: 2 months

## Challenges
1. Ensuring scalability for larger businesses
   - Strategy: Cloud-based solutions, load testing, modular architecture
2. Maintaining security and data privacy
   - Strategy: Encryption, regular security audits, secure authentication
3. Providing a seamless user experience
   - Strategy: User testing, feedback loops, accessibility standards

## Success Metrics
1. Adoption by small and medium businesses
   - Target: 100+ businesses within the first year
2. Positive user and admin feedback
   - Target: 4.5+ rating on app stores and positive admin reviews
3. Efficient management of employees, users, and companies
   - Target: Reduce admin workload by 30% or more

---
---
This document will evolve as the project progresses and new requirements emerge.
