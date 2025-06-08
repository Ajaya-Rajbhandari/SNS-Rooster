const mongoose = require('mongoose');
const bcrypt = require('bcryptjs'); // For password hashing

const UserSchema = new mongoose.Schema({
  name: {
    type: String,
    required: false, // Optional name, but good to have
  },
  email: {
    type: String,
    required: true,
    unique: true, // Ensures email addresses are unique
    lowercase: true, // Stores email in lowercase
    trim: true, // Removes whitespace
    match: [/^[\w-\.]+@([\\w-]+\.)+[\\w-]{2,4}$/, 'Please enter a valid email address'] // Basic email regex validation
  },
  password: {
    type: String,
    required: true,
    minlength: 6, // Minimum password length
  },
  role: {
    type: String,
    enum: ['employee', 'admin'], // Only allows 'employee' or 'admin'
    default: 'employee', // Default role for new users
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
});

// Middleware to hash the password before saving the user
UserSchema.pre('save', async function(next) {
  // Only hash if the password has been modified (or is new)
  if (!this.isModified('password')) {
    return next();
  }
  const salt = await bcrypt.genSalt(10); // Generate a salt
  this.password = await bcrypt.hash(this.password, salt); // Hash the password
  next();
});

// Method to compare entered password with hashed password
UserSchema.methods.matchPassword = async function(enteredPassword) {
  return await bcrypt.compare(enteredPassword, this.password);
};

module.exports = mongoose.model('User', UserSchema); 