const mongoose = require('mongoose');
require('dotenv').config();

// Import models
const Location = require('../models/Location');

async function fixLocationCoordinates() {
  try {
    // Connect to database
    const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/sns-rooster';
    await mongoose.connect(MONGODB_URI);
    console.log('Connected to MongoDB');

    // Find the mid baneshwor location
    const location = await Location.findOne({ name: 'mid baneshwor' });
    if (!location) {
      console.log('Location "mid baneshwor" not found');
      return;
    }

    console.log('Found location:', location.name);
    console.log('Current coordinates:', location.coordinates);

    // Add coordinates for mid baneshwor (Kathmandu area)
    const updatedLocation = await Location.findByIdAndUpdate(
      location._id,
      {
        coordinates: {
          latitude: 27.7172,
          longitude: 85.3240
        }
      },
      { new: true }
    );

    console.log('Updated location coordinates:', updatedLocation.coordinates);
    console.log('✅ Location coordinates fixed successfully!');

  } catch (error) {
    console.error('Error fixing location coordinates:', error);
  } finally {
    await mongoose.disconnect();
    console.log('Disconnected from MongoDB');
  }
}

// Run the fix script
fixLocationCoordinates(); 