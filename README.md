# SNS Rooster - Employee Management System

A comprehensive employee management system with Flutter mobile app, React admin portal, and Node.js backend.

## 🚀 Quick Start

### Development Setup
1. **Backend**: `cd rooster-backend && npm install && npm start`
2. **Admin Portal**: `cd admin-portal && npm install && npm start`
3. **Flutter App**: `cd sns_rooster && flutter pub get && flutter run`

### Production Deployment
```bash
docker compose up --build
```

## 📱 App Update System (CRITICAL)

**IMPORTANT**: Every time you add new features to the Flutter app, you MUST follow the app update workflow to ensure the update system works correctly.

### Quick Deployment
```powershell
# From sns_rooster directory
.\scripts\deploy-app-update.ps1 -NewVersion "1.0.4" -NewBuildNumber "5" -FeatureDescription "Notification system improvements and Events UI enhancements"
```

### Critical Rules
1. **Always increment both version AND build number**
2. **Backend expects NEXT version, not current version**
3. **Deploy APK first, then backend config**
4. **Test the complete flow before releasing**

### Documentation
- **Complete Workflow**: `docs/APP_UPDATE_WORKFLOW.md`
- **Quick Reference**: `docs/QUICK_UPDATE_GUIDE.md`
- **System Summary**: `docs/UPDATE_SYSTEM_SUMMARY.md`

## 🐳 Dockerized Deployment

SNS Rooster supports a fully containerized setup for both the backend and the admin portal using Docker and Docker Compose. This makes it easy to run the entire stack with minimal local dependencies.

### Requirements
- **Docker** (latest recommended)
- **Docker Compose** (v2+)

### Service Overview
- **Admin Portal** (`ts-admin-portal`)
  - React app served on **port 3000**
  - Built with Node.js **v22.13.1**
- **Backend API** (`js-rooster-backend`)
  - Node.js API on **port 5000**
  - Built with Node.js **v22.13.1**
- **MongoDB** (`mongo`)
  - Database on **port 27017**

### Environment Variables
- **Backend**: Requires a `.env` file in `./rooster-backend/` (see `rooster-backend/.env` for required variables)
- **Admin Portal**: Optionally, provide a `.env` file in `./admin-portal/` if you need to override defaults
- **MongoDB**: Uses default credentials (`root`/`example`), configurable in `docker-compose.yml`

### Build & Run
From the project root, run:

```bash
docker compose up --build
```

This will:
- Build the admin portal and backend images using the provided Dockerfiles
- Start all services and required networks
- Expose the following ports:
  - **3000**: Admin Portal (http://localhost:3000)
  - **5000**: Backend API (http://localhost:5000)
  - **27017**: MongoDB

### Special Configuration
- The admin portal expects the backend to be available at `http://js-rooster-backend:5000` (Docker network alias)
- The backend expects MongoDB at `mongo:27017` with the credentials set in the compose file
- Persistent MongoDB data is stored in the `mongo-data` Docker volume
- All services run as non-root users for improved security

### Notes
- If you need to customize environment variables, edit the respective `.env` files before running Compose
- The `serve` package is used to serve the admin portal's static build
- For production, ensure you update default credentials and review security settings

## 📚 Documentation

- **Development Setup**: `docs/DEVELOPMENT_SETUP.md`
- **App Update Workflow**: `docs/APP_UPDATE_WORKFLOW.md`
- **API Documentation**: `docs/api/API_CONTRACT.md`
- **System Architecture**: `docs/SYSTEM_ARCHITECTURE.md`

---
