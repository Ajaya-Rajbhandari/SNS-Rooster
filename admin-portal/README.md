# SNS Rooster Admin Portal

A modern, professional admin portal built with React, TypeScript, and Material-UI for managing the SNS Rooster platform.

## 🚀 Features

### Modern UI/UX
- **Responsive Design**: Works seamlessly on desktop, tablet, and mobile
- **Material Design**: Following Google's Material Design principles
- **Dark/Light Theme**: Customizable theme system
- **Smooth Animations**: Professional micro-interactions and transitions
- **Accessibility**: WCAG compliant with keyboard navigation support

### Dashboard & Analytics
- **Real-time Statistics**: Live metrics and KPIs
- **Interactive Charts**: Data visualization with trend analysis
- **Quick Actions**: One-click access to common tasks
- **System Status**: Real-time monitoring of backend services
- **Recent Activities**: Timeline of system events

### Management Features
- **Company Management**: Create, edit, and manage companies
- **Subscription Plans**: Configure and manage pricing plans
- **User Management**: Administer users across all companies
- **Analytics Dashboard**: Comprehensive reporting and insights
- **System Settings**: Platform configuration and preferences

### Security & Authentication
- **JWT Authentication**: Secure token-based authentication
- **Role-based Access**: Super admin privileges only
- **Session Management**: Automatic token refresh
- **Secure API Calls**: HTTPS with proper error handling

## 🛠️ Technology Stack

- **Frontend**: React 19 with TypeScript
- **UI Framework**: Material-UI (MUI) v7
- **State Management**: React Context API
- **HTTP Client**: Axios with interceptors
- **Routing**: React Router v7
- **Build Tool**: Create React App
- **Package Manager**: npm

## 📦 Installation

### Prerequisites
- Node.js (v18 or higher)
- npm (v9 or higher)
- Backend server running on port 5000

### Setup
```bash
# Clone the repository
git clone <repository-url>
cd admin-portal

# Install dependencies
npm install

# Start development server
npm start
```

The admin portal will start on `http://localhost:3001`

## 🏗️ Project Structure

```
src/
├── components/           # Reusable UI components
│   ├── Layout.tsx       # Main layout with sidebar
│   ├── ProtectedRoute.tsx
│   └── dashboard/       # Dashboard-specific components
│       └── StatCard.tsx
├── contexts/            # React contexts
│   └── AuthContext.tsx  # Authentication state
├── pages/               # Page components
│   ├── DashboardPage.tsx
│   ├── LoginPage.tsx
│   ├── CompanyManagementPage.tsx
│   └── SubscriptionPlanManagementPage.tsx
├── services/            # API services
│   └── apiService.ts    # Centralized API client
├── config/              # Configuration files
│   └── api.ts          # API endpoints and settings
├── types/               # TypeScript type definitions
└── utils/               # Utility functions
```

## 🎨 Design System

### Color Palette
- **Primary**: Blue (#1976d2) - Main brand color
- **Secondary**: Pink (#dc004e) - Accent color
- **Success**: Green (#2e7d32) - Positive actions
- **Warning**: Orange (#ed6c02) - Caution states
- **Error**: Red (#d32f2f) - Error states
- **Info**: Light Blue (#0288d1) - Information

### Typography
- **Font Family**: Inter (with Roboto fallback)
- **Headings**: Bold weights (600-700)
- **Body**: Regular weight (400)
- **Captions**: Light weight (300)

### Components
- **Cards**: Elevated with subtle shadows
- **Buttons**: Rounded corners with hover effects
- **Forms**: Clean, accessible input fields
- **Tables**: Sortable, filterable data grids
- **Navigation**: Collapsible sidebar with active states

## 🔧 Configuration

### Environment Variables
Create a `.env` file in the root directory:

```env
# API Configuration
REACT_APP_API_BASE_URL=http://localhost:5000

# Environment
REACT_APP_ENV=development

# App Configuration
REACT_APP_APP_NAME=SNS Rooster Admin Portal
```

### API Configuration
The admin portal connects to these backend endpoints:

- **Authentication**: `/api/auth/*`
- **Super Admin**: `/api/super-admin/*`
- **Companies**: `/api/companies`
- **Users**: `/api/users`
- **Analytics**: `/api/analytics`

## 🚀 Development

### Available Scripts
```bash
# Start development server
npm start

# Build for production
npm run build

# Run tests
npm test

# Eject from CRA (not recommended)
npm run eject
```

### Code Style
- **TypeScript**: Strict mode enabled
- **ESLint**: Airbnb configuration
- **Prettier**: Automatic code formatting
- **Husky**: Pre-commit hooks

### Best Practices
- Use TypeScript for all new code
- Follow Material-UI design patterns
- Implement proper error handling
- Write meaningful component names
- Use semantic HTML elements
- Ensure accessibility compliance

## 📱 Responsive Design

The admin portal is fully responsive with breakpoints:

- **Mobile**: < 600px
- **Tablet**: 600px - 960px
- **Desktop**: > 960px

### Mobile Features
- Collapsible sidebar navigation
- Touch-friendly interface
- Optimized data tables
- Swipe gestures support

## 🔒 Security

### Authentication Flow
1. User enters credentials
2. Backend validates and returns JWT
3. Token stored in localStorage
4. Automatic token refresh
5. Logout clears all data

### Security Features
- HTTPS enforcement in production
- JWT token validation
- CORS protection
- XSS prevention
- CSRF protection

## 📊 Performance

### Optimization Techniques
- **Code Splitting**: Lazy loading of routes
- **Bundle Analysis**: Webpack bundle analyzer
- **Image Optimization**: Compressed assets
- **Caching**: Browser and API caching
- **Minification**: Production builds

### Performance Metrics
- **First Contentful Paint**: < 1.5s
- **Largest Contentful Paint**: < 2.5s
- **Cumulative Layout Shift**: < 0.1
- **First Input Delay**: < 100ms

## 🧪 Testing

### Test Structure
```
src/
├── __tests__/           # Test files
├── components/          # Component tests
├── pages/              # Page tests
└── services/           # Service tests
```

### Testing Tools
- **Jest**: Test runner
- **React Testing Library**: Component testing
- **MSW**: API mocking
- **Cypress**: E2E testing (optional)

## 🚀 Deployment

### Production Build
```bash
# Create optimized build
npm run build

# Serve static files
npx serve -s build
```

### Deployment Options
- **Vercel**: Zero-config deployment
- **Netlify**: Static site hosting
- **AWS S3**: Cloud storage
- **Firebase Hosting**: Google's hosting service

### Environment Setup
1. Set production API URL
2. Configure CORS on backend
3. Set up SSL certificates
4. Configure CDN (optional)
5. Set up monitoring

## 🤝 Contributing

### Development Workflow
1. Create feature branch
2. Make changes following style guide
3. Write/update tests
4. Submit pull request
5. Code review process
6. Merge to main branch

### Code Review Checklist
- [ ] TypeScript types are correct
- [ ] No console.log statements
- [ ] Proper error handling
- [ ] Accessibility compliance
- [ ] Responsive design
- [ ] Performance considerations

## 📚 Documentation

### Additional Resources
- [Material-UI Documentation](https://mui.com/)
- [React Documentation](https://react.dev/)
- [TypeScript Handbook](https://www.typescriptlang.org/docs/)
- [API Documentation](./docs/API.md)

### Support
For questions and support:
- Check existing documentation
- Review closed issues
- Create new issue with details
- Contact development team

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

**Built with ❤️ by the SNS Rooster Team**
