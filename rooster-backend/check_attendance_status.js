const mongoose = require('mongoose');
require('dotenv').config();

// Connect to MongoDB
mongoose.connect(process.env.MONGODB_URI)
  .then(() => console.log('Connected to MongoDB'))
  .catch(err => console.error('MongoDB connection error:', err));

// Import models
const Attendance = require('./models/Attendance');
const User = require('./models/User');

async function checkAttendanceRecords() {
  try {
    console.log('=== CHECKING ATTENDANCE RECORDS ===');
    
    // Get all attendance records
    const allRecords = await Attendance.find({}).populate('user', 'firstName lastName email role');
    
    console.log(`Total attendance records: ${allRecords.length}`);
    
    // Group by status
    const statusCounts = {};
    allRecords.forEach(record => {
      const status = record.status || 'no_status';
      statusCounts[status] = (statusCounts[status] || 0) + 1;
    });
    
    console.log('Status distribution:', statusCounts);
    
    // Show recent records
    const recentRecords = allRecords
      .sort((a, b) => new Date(b.date) - new Date(a.date))
      .slice(0, 5);
    
    console.log('\nRecent 5 attendance records:');
    recentRecords.forEach((record, index) => {
      console.log(`${index + 1}. Date: ${record.date}, Status: ${record.status || 'no_status'}, User: ${record.user?.firstName} ${record.user?.lastName} (${record.user?.role}), CheckIn: ${record.checkInTime}, CheckOut: ${record.checkOutTime}`);
    });
    
    // Check for records with checkInTime but no status
    const recordsWithCheckIn = allRecords.filter(r => r.checkInTime);
    console.log(`\nRecords with checkInTime: ${recordsWithCheckIn.length}`);
    
    const recordsWithCheckInNoStatus = recordsWithCheckIn.filter(r => !r.status);
    console.log(`Records with checkInTime but no status: ${recordsWithCheckInNoStatus.length}`);
    
    if (recordsWithCheckInNoStatus.length > 0) {
      console.log('Sample record without status:');
      const sample = recordsWithCheckInNoStatus[0];
      console.log({
        id: sample._id,
        date: sample.date,
        checkInTime: sample.checkInTime,
        checkOutTime: sample.checkOutTime,
        user: sample.user?.firstName + ' ' + sample.user?.lastName
      });
    }
    
  } catch (error) {
    console.error('Error checking attendance records:', error);
  } finally {
    mongoose.connection.close();
  }
}

checkAttendanceRecords(); 