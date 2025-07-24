import apiService from '../services/apiService';

interface LoginResponse {
  token: string;
  user: {
    _id: string;
    email: string;
    firstName: string;
    lastName: string;
    role: string;
  };
}

interface UsersResponse {
  users: any[];
  totalPages: number;
  currentPage: number;
  total: number;
}

export const testBackendConnection = async () => {
  try {
    console.log('🧪 Testing backend connection...');
    
    // Test 1: Basic connectivity
    console.log('1. Testing basic connectivity...');
    const response = await fetch('http://localhost:5000/');
    console.log('✅ Backend is reachable');
    
    // Test 2: Super admin login
    console.log('2. Testing super admin login...');
    const loginResponse = await apiService.post<LoginResponse>('/api/auth/login', {
      email: 'superadmin@snstechservices.com.au',
      password: 'SuperAdmin@123'
    });
    console.log('✅ Super admin login successful');
    console.log('Token:', loginResponse.token ? 'Present' : 'Missing');
    console.log('User role:', loginResponse.user?.role);
    
    // Test 3: Get users with token
    console.log('3. Testing get users endpoint...');
    const usersResponse = await apiService.get<UsersResponse>('/api/super-admin/users');
    console.log('✅ Get users successful');
    console.log('Users count:', usersResponse.users?.length || 0);
    console.log('Total users:', usersResponse.total);
    
    return {
      success: true,
      message: 'All tests passed',
      data: {
        usersCount: usersResponse.users?.length || 0,
        totalUsers: usersResponse.total,
        userRole: loginResponse.user?.role
      }
    };
    
  } catch (error: any) {
    console.error('❌ Test failed:', error);
    return {
      success: false,
      message: error.message,
      error: error.response?.data || error
    };
  }
}; 