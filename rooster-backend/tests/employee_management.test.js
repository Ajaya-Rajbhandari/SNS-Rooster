const request = require('supertest');
const server = require('../server');
const mongoose = require('mongoose');
const jwt = require('jsonwebtoken');

const adminToken = jwt.sign({ userId: 'adminUser', role: 'admin' }, process.env.JWT_SECRET || 'defaultSecret', { expiresIn: '1h' });

beforeAll(async () => {
  await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/sns-rooster');
});

afterAll(async () => {
  await mongoose.connection.close();
  server.close();
});

describe('Employee Management API Tests', () => {
  test('should fetch all employees', async () => {
    const response = await request(server)
      .get('/api/employees')
      .set('Authorization', `Bearer ${adminToken}`);

    expect(response.status).toBe(200);
    expect(Array.isArray(response.body)).toBe(true);
  });

  test('should create a new employee', async () => {
    const newEmployee = {
      firstName: 'John',
      lastName: 'Doe',
      email: 'john.doe@example.com',
      employeeId: 'EMP001',
      hireDate: '2025-06-15',
      position: 'Developer',
      department: 'IT',
    };

    const response = await request(server)
      .post('/api/employees')
      .set('Authorization', `Bearer ${adminToken}`)
      .send(newEmployee);

    expect(response.status).toBe(201);
    expect(response.body).toHaveProperty('_id');
  });

  test('should update an employee', async () => {
    const updatedData = {
      position: 'Senior Developer',
    };

    const response = await request(server)
      .put('/api/employees/EMP001')
      .set('Authorization', `Bearer ${adminToken}`)
      .send(updatedData);

    expect(response.status).toBe(200);
    expect(response.body.position).toBe('Senior Developer');
  });

  test('should delete an employee', async () => {
    const response = await request(server)
      .delete('/api/employees/EMP001')
      .set('Authorization', `Bearer ${adminToken}`);

    expect(response.status).toBe(200);
    expect(response.body.message).toBe('Employee deleted successfully');
  });

  test('should return 401 for unauthorized access', async () => {
    const response = await request(server).get('/api/employees');

    expect(response.status).toBe(401);
    expect(response.body).toHaveProperty('message', 'No token, authorization denied');
  });
});
