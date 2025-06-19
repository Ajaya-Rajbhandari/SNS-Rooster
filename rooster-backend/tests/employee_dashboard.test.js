const request = require('supertest');
const jwt = require('jsonwebtoken');
const server = require('../server'); // Assuming `app` is exported from `server.js`
const mongoose = require('mongoose');

describe('Employee Dashboard API Tests', () => {
  test('should fetch employee dashboard data successfully', async () => {
    const validToken = jwt.sign({ userId: 'testUser', role: 'employee' }, process.env.JWT_SECRET || 'defaultSecret', { expiresIn: '1h' });

    const response = await request(server)
      .get('/api/employees/dashboard')
      .set('Authorization', `Bearer ${validToken}`);

    expect(response.status).toBe(200);
    expect(response.body).toHaveProperty('dashboardData');
  });

  test('should return 401 for unauthorized access', async () => {
    const response = await request(server).get('/api/employees/dashboard');

    expect(response.status).toBe(401);
    expect(response.body).toHaveProperty('error', 'Unauthorized');
  });
});

// Close server and MongoDB connection after tests
afterAll(async () => {
  await mongoose.connection.close();
  server.close();
  console.log('MongoDB connection closed and server stopped after tests');
});
