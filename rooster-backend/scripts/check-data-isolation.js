const mongoose = require('mongoose');
const User = require('../models/User');
const Company = require('../models/Company');
const Attendance = require('../models/Attendance');
require('dotenv').config();

async function checkDataIsolation() {
  try {
    // Connect to MongoDB
    const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/sns-rooster';
    await mongoose.connect(MONGODB_URI);
    console.log('Connected to MongoDB');

    // Find the Cit Express company
    const citExpressCompany = await Company.findOne({ 
      name: { $regex: /cit express/i },
      domain: { $regex: /cityexpress/i }
    });

    if (!citExpressCompany) {
      console.log('❌ Cit Express company not found');
      return;
    }

    console.log('✅ Found Cit Express company:', {
      id: citExpressCompany._id,
      name: citExpressCompany.name,
      domain: citExpressCompany.domain
    });

    // Check users in Cit Express company
    const citExpressUsers = await User.find({ companyId: citExpressCompany._id });
    console.log(`\n👥 Users in Cit Express (${citExpressUsers.length}):`);
    citExpressUsers.forEach(user => {
      console.log(`- ${user.email} (${user.role})`);
    });

    // Check attendance records for Cit Express
    const citExpressAttendance = await Attendance.find({ 
      companyId: citExpressCompany._id 
    });
    console.log(`\n📊 Attendance records in Cit Express (${citExpressAttendance.length}):`);
    citExpressAttendance.forEach(attendance => {
      console.log(`- ${attendance.userId} - ${attendance.date}`);
    });

    // Check if there are any users without companyId
    const usersWithoutCompany = await User.find({ companyId: { $exists: false } });
    console.log(`\n⚠️  Users without companyId (${usersWithoutCompany.length}):`);
    usersWithoutCompany.forEach(user => {
      console.log(`- ${user.email} (${user.role})`);
    });

    // Check if there are any attendance records without companyId
    const attendanceWithoutCompany = await Attendance.find({ companyId: { $exists: false } });
    console.log(`\n⚠️  Attendance records without companyId (${attendanceWithoutCompany.length}):`);
    attendanceWithoutCompany.forEach(attendance => {
      console.log(`- ${attendance.userId} - ${attendance.date}`);
    });

    // Check analytics controller to see if it's filtering by company
    console.log('\n🔍 Checking analytics controller...');
    const analyticsController = require('../controllers/analytics-controller');
    console.log('Analytics controller methods:', Object.keys(analyticsController));

  } catch (error) {
    console.error('Error:', error);
  } finally {
    await mongoose.disconnect();
    console.log('Disconnected from MongoDB');
  }
}

checkDataIsolation(); 