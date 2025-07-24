const mongoose = require('mongoose');
require('dotenv').config();

// Import models
const SubscriptionPlan = require('../models/SubscriptionPlan');

async function checkBasicPlan() {
  try {
    // Connect to database
    const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/sns-rooster';
    await mongoose.connect(MONGODB_URI);
    console.log('Connected to MongoDB');

    // Find the Basic plan
    const basicPlan = await SubscriptionPlan.findOne({ name: 'Basic' });
    if (!basicPlan) {
      console.log('Basic plan not found');
      return;
    }

    console.log('\n=== Basic Subscription Plan Details ===');
    console.log(`Name: ${basicPlan.name}`);
    console.log(`Description: ${basicPlan.description}`);
    console.log(`Price Monthly: $${basicPlan.price.monthly}`);
    console.log(`Price Yearly: $${basicPlan.price.yearly}`);
    console.log(`Employee Limit: ${basicPlan.employeeLimit}`);
    console.log(`Storage Limit: ${basicPlan.storageLimit}GB`);
    console.log(`API Call Limit: ${basicPlan.apiCallLimit}`);
    
    console.log('\n=== Features ===');
    console.log(`Max Employees: ${basicPlan.features.maxEmployees}`);
    console.log(`Max Departments: ${basicPlan.features.maxDepartments}`);
    console.log(`Analytics: ${basicPlan.features.analytics}`);
    console.log(`Advanced Reporting: ${basicPlan.features.advancedReporting}`);
    console.log(`Custom Branding: ${basicPlan.features.customBranding}`);
    console.log(`API Access: ${basicPlan.features.apiAccess}`);
    console.log(`Priority Support: ${basicPlan.features.prioritySupport}`);
    console.log(`Data Retention: ${basicPlan.features.dataRetention} days`);
    console.log(`Backup Frequency: ${basicPlan.features.backupFrequency}`);
    
    console.log('\n=== Enterprise Features ===');
    console.log(`Location Based Attendance: ${basicPlan.features.locationBasedAttendance}`);
    console.log(`Multi Location Support: ${basicPlan.features.multiLocationSupport}`);
    console.log(`Expense Management: ${basicPlan.features.expenseManagement}`);
    console.log(`Performance Reviews: ${basicPlan.features.performanceReviews}`);
    console.log(`Training Management: ${basicPlan.features.trainingManagement}`);

    console.log('\n=== Plan Status ===');
    console.log(`Is Active: ${basicPlan.isActive}`);
    console.log(`Is Default: ${basicPlan.isDefault}`);
    console.log(`Sort Order: ${basicPlan.sortOrder}`);

  } catch (error) {
    console.error('Error in check script:', error);
  } finally {
    await mongoose.disconnect();
    console.log('Disconnected from MongoDB');
  }
}

// Run the check script
checkBasicPlan(); 