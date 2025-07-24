const mongoose = require('mongoose');
require('dotenv').config();

// Import models
const Company = require('../models/Company');
const SubscriptionPlan = require('../models/SubscriptionPlan');

async function checkCompanySubscription() {
  try {
    // Connect to database
    const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/sns-rooster';
    await mongoose.connect(MONGODB_URI);
    console.log('Connected to MongoDB');

    // Find the company (using the company ID from the logs)
    const company = await Company.findById('687c6cf9fce054783b9af432').populate('subscriptionPlan');
    if (!company) {
      console.log('Company not found');
      return;
    }

    console.log('\n=== Company Details ===');
    console.log(`Name: ${company.name}`);
    console.log(`Status: ${company.status}`);
    console.log(`Subscription Plan: ${company.subscriptionPlan?.name || 'None'}`);
    
    if (company.subscriptionPlan) {
      console.log('\n=== Subscription Plan Features ===');
      console.log(`Location Based Attendance: ${company.subscriptionPlan.features?.locationBasedAttendance}`);
      console.log(`Multi Location Support: ${company.subscriptionPlan.features?.multiLocationSupport}`);
      console.log(`Max Employees: ${company.subscriptionPlan.features?.maxEmployees}`);
      console.log(`Analytics: ${company.subscriptionPlan.features?.analytics}`);
    }

    // Check all available subscription plans
    console.log('\n=== Available Subscription Plans ===');
    const allPlans = await SubscriptionPlan.find({ isActive: true }).sort('sortOrder');
    allPlans.forEach(plan => {
      console.log(`${plan.name}: Location=${plan.features?.locationBasedAttendance}, MaxEmployees=${plan.features?.maxEmployees}`);
    });

  } catch (error) {
    console.error('Error in check script:', error);
  } finally {
    await mongoose.disconnect();
    console.log('Disconnected from MongoDB');
  }
}

// Run the check script
checkCompanySubscription(); 