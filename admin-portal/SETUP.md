# Admin Portal Setup Guide

## Prerequisites

- Node.js (v16 or higher)
- npm or yarn
- MongoDB running locally or accessible via connection string
- Backend server running on port 5000

## Quick Start

### 1. Install Dependencies

```bash
cd admin-portal
npm install
```

### 2. Start the Backend Server

In a separate terminal:

```bash
cd rooster-backend
npm install
npm run dev
```

The backend will start on `http://localhost:5000`

### 3. Start the Admin Portal

```bash
cd admin-portal
npm start
```

The admin portal will start on `http://localhost:3001`

## Configuration

### Environment Variables

Create a `.env` file in the `admin-portal` directory:

```env
# API Configuration
REACT_APP_API_BASE_URL=http://localhost:5000

# Environment
REACT_APP_ENV=development

# Other configurations
REACT_APP_APP_NAME=SNS Rooster Admin Portal
```

### API Configuration

The admin portal uses a centralized API service located at `src/services/apiService.ts` that:

- Automatically handles authentication tokens
- Includes company context headers
- Provides automatic token refresh
- Handles common error scenarios

## API Endpoints

The admin portal connects to these backend endpoints:

- **Authentication**: `/api/auth/*`
- **Super Admin**: `/api/super-admin/*`
- **Companies**: `/api/companies`
- **Admin Features**: `/api/admin/*`
- **Employees**: `/api/employees`
- **Attendance**: `/api/attendance`
- **Payroll**: `/api/payroll`
- **Leave**: `/api/leave`
- **Notifications**: `/api/notifications`
- **Events**: `/api/events`

## Troubleshooting

### CORS Issues

If you encounter CORS errors, ensure the backend CORS configuration includes both ports:

```javascript
// In rooster-backend/app.js
app.use(cors({
  origin: [
    'http://localhost:3000',  // Flutter web app
    'http://localhost:3001',  // Admin portal
    // ... other origins
  ],
  credentials: true,
}));
```

### Connection Issues

1. **Backend not running**: Ensure the backend server is started with `npm run dev`
2. **Wrong port**: Verify backend is running on port 5000
3. **MongoDB connection**: Check MongoDB is running and accessible
4. **Network issues**: Ensure both services can communicate on localhost

### Authentication Issues

1. **Token expired**: The API service automatically handles token refresh
2. **Invalid credentials**: Check login credentials
3. **Missing company context**: Ensure company ID is set in localStorage

## Development

### Adding New API Calls

Use the centralized API service:

```typescript
import apiService from '../services/apiService';

// GET request
const data = await apiService.get('/api/endpoint');

// POST request
const result = await apiService.post('/api/endpoint', { data });

// PUT request
const updated = await apiService.put('/api/endpoint/id', { data });

// DELETE request
await apiService.delete('/api/endpoint/id');
```

### Adding New Endpoints

1. Add the endpoint to `src/config/api.ts`
2. Use the endpoint in your component via `apiService`
3. Update this documentation if needed

## Production Deployment

For production deployment:

1. Set `REACT_APP_API_BASE_URL` to your production backend URL
2. Ensure CORS is configured for your production domain
3. Set up proper environment variables
4. Build the application with `npm run build` 