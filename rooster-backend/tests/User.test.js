const User = require('../models/User');
const mongoose = require('mongoose');

// Mock Mongoose connection
beforeAll(async () => {
  await mongoose.connect('mongodb://localhost:27017/testdb', {
    useNewUrlParser: true,
    useUnifiedTopology: true,
  });
});

afterAll(async () => {
  await mongoose.connection.close();
});

describe('User Model Tests', () => {
  it('should create a new user', async () => {
    const uniqueEmail = `test${Date.now()}@example.com`;
    const user = new User({
      firstName: 'Test',
      lastName: 'User',
      email: uniqueEmail,
      password: 'password123',
    });

    const savedUser = await user.save();
    expect(savedUser._id).toBeDefined();
    expect(savedUser.firstName).toBe('Test');
    expect(savedUser.lastName).toBe('User');
    expect(savedUser.email).toBe(uniqueEmail);
  });

  it('should fail without required fields', async () => {
    const user = new User({});
    let err;
    try {
      await user.save();
    } catch (error) {
      err = error;
    }
    expect(err).toBeInstanceOf(mongoose.Error.ValidationError);
  });
});
