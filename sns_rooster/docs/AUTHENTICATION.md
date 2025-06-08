# SNS Rooster Authentication System Documentation

## Overview
The SNS Rooster authentication system implements a token-based authentication flow using JWT (JSON Web Tokens) with a MERN stack backend. The system is designed to handle user authentication, session management, and role-based access control.

## Architecture Components

### 1. Authentication Provider (`AuthProvider`)
Located in `lib/providers/auth_provider.dart`, this is the central state management class for authentication.

#### Key Properties
```dart
String? _token;        // JWT token
Map<String, dynamic>? _user;  // User data
bool _isLoading;       // Loading state
String? _error;        // Error messages
```

#### Core Methods

##### `initAuth()`
```dart
Future<void> initAuth() async {
    // 1. Force clear any existing auth state
    await forceClearAuth();
    // 2. Load stored auth data
    await _loadStoredAuth();
    // 3. Verify auth status with server
    await checkAuthStatus();
}
```
This method is called during app initialization to establish the initial authentication state.

##### `forceClearAuth()`
```dart
Future<void> forceClearAuth() async {
    // 1. Clear in-memory state
    _token = null;
    _user = null;
    _error = null;
    notifyListeners();
    
    // 2. Clear persistent storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
    await prefs.clear();
}
```
Ensures complete clearing of authentication state from both memory and persistent storage.

##### `checkAuthStatus()`
```dart
Future<void> checkAuthStatus() async {
    // 1. Check token existence
    if (_token == null) {
        _user = null;
        notifyListeners();
        return;
    }

    // 2. Check token expiration
    if (isTokenExpired()) {
        await logout();
        return;
    }

    // 3. Verify token with server
    // Makes GET request to /api/auth/me
    // Updates user data if valid
    // Logs out if invalid
}
```
Verifies the current authentication state with the server.

##### `login()`
```dart
Future<void> login(String email, String password) async {
    // 1. Send login request to /api/auth/login
    // 2. Store token and user data if successful
    // 3. Update SharedPreferences
    // 4. Notify listeners of state change
}
```

##### `logout()`
```dart
Future<void> logout() async {
    // 1. Clear in-memory state
    _token = null;
    _user = null;
    _error = null;
    notifyListeners();

    // 2. Clear persistent storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
    await prefs.clear();
    notifyListeners();
}
```

### 2. Splash Screen (`SplashScreen`)
Located in `lib/screens/splash/splash_screen.dart`, handles initial app routing based on authentication state.

#### Authentication Flow
```dart
Future<void> _checkAuthStatus() async {
    // 1. Get AuthProvider instance
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // 2. Initialize auth state
    await authProvider.initAuth();
    
    // 3. Route based on auth state
    if (authProvider.isAuthenticated) {
        // Route to appropriate dashboard based on role
        final route = authProvider.user?['role'] == 'admin' 
            ? '/admin_dashboard' 
            : '/employee_dashboard';
        Navigator.pushReplacementNamed(context, route);
    } else {
        // Route to login screen
        Navigator.pushReplacementNamed(context, '/login');
    }
}
```

### 3. Main App (`MyApp`)
Located in `lib/main.dart`, sets up the authentication context and routing.

#### Key Components
```dart
void main() async {
    WidgetsFlutterBinding.ensureInitialized();
    runApp(
        MultiProvider(
            providers: [
                ChangeNotifierProvider(create: (_) => AuthProvider()),
                // Other providers...
            ],
            child: const MyApp(),
        ),
    );
}

class MyApp extends StatelessWidget {
    @override
    Widget build(BuildContext context) {
        return Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
                return MaterialApp(
                    // Always start with splash screen
                    initialRoute: '/',
                    routes: {
                        '/': (context) => const SplashScreen(),
                        '/login': (context) => const LoginScreen(),
                        // Other routes...
                    },
                );
            },
        );
    }
}
```

## Authentication Flow

### 1. App Startup
1. `main()` initializes the `AuthProvider`
2. `MyApp` sets initial route to splash screen
3. `SplashScreen` calls `_checkAuthStatus()`
4. `_checkAuthStatus()` calls `authProvider.initAuth()`
5. `initAuth()` performs force clear and loads stored auth
6. Based on auth state, routes to appropriate screen

### 2. Login Process
1. User enters credentials
2. `AuthProvider.login()` sends request to backend
3. On success:
   - Token and user data stored in memory
   - Data persisted to SharedPreferences
   - Listeners notified of state change
4. UI routes to appropriate dashboard

### 3. Logout Process
1. User triggers logout
2. `AuthProvider.logout()`:
   - Clears in-memory state
   - Clears persistent storage
   - Notifies listeners
3. UI routes to login screen

### 4. Session Management
- Token expiration checked via `isTokenExpired()`
- Regular auth status verification via `checkAuthStatus()`
- Automatic logout on token expiration or invalid token

## Security Considerations

1. **Token Storage**
   - JWT tokens stored in memory and SharedPreferences
   - Tokens verified with server on app start and periodically
   - Automatic logout on token expiration

2. **State Management**
   - Centralized auth state in `AuthProvider`
   - Clear separation of concerns between components
   - Proper cleanup on logout

3. **Error Handling**
   - Network errors handled gracefully
   - Invalid tokens trigger automatic logout
   - User feedback for authentication failures

## Debugging

The system includes comprehensive logging for debugging:
- `LOGOUT_FLOW`: Logs during logout process
- `AUTH_CHECK`: Logs during authentication verification
- `FORCE_CLEAR`: Logs during auth state clearing
- `SPLASH`: Logs during initial routing

Example log sequence:
```
SPLASH: ===== STARTING AUTH CHECK =====
FORCE_CLEAR: ===== FORCE CLEARING AUTH STATE =====
AUTH_CHECK: ===== STARTING AUTH CHECK =====
SPLASH: After initAuth - isAuthenticated: false
```

## Common Issues and Solutions

1. **Persistent Authentication**
   - Use `forceClearAuth()` to ensure complete state clearing
   - Verify SharedPreferences clearing with storage verification
   - Check token expiration status

2. **Navigation Issues**
   - Ensure proper route replacement using `pushReplacementNamed`
   - Verify auth state before navigation
   - Handle widget mounting state

3. **Token Management**
   - Regular token verification with server
   - Proper error handling for invalid tokens
   - Clear separation of token and user data

## Integration with Other Components

1. **Attendance Provider**
   - Uses `AuthProvider` for authenticated requests
   - Automatically updates when auth state changes

2. **Dashboard Screens**
   - Consume `AuthProvider` for user data
   - Handle role-based access control
   - Implement proper logout flow

3. **API Requests**
   - Include token in Authorization header
   - Handle 401 responses appropriately
   - Maintain session state 