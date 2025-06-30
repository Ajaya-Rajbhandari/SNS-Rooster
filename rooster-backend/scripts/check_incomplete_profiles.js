const mongoose = require('mongoose');
const Employee = require('../models/Employee');
const Notification = require('../models/Notification');

async function notifyAdminsOfIncompleteProfiles() {
  await mongoose.connect('mongodb://localhost:27017/sns_rooster');
  const employees = await Employee.find({});
  for (const emp of employees) {
    if (!emp.phone || !emp.address || !emp.emergencyContact) {
      await Notification.create({
        role: 'admin',
        title: 'Incomplete Employee Profile',
        message: `${emp.firstName} ${emp.lastName} has not completed their profile.`,
        type: 'alert',
        link: `/admin/employee_management`,
        isRead: false,
      });
    }
  }
  mongoose.connection.close();
}

notifyAdminsOfIncompleteProfiles(); 