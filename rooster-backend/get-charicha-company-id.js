const Company = require('./models/Company');
const mongoose = require('mongoose');

async function getCharichaCompanyId() {
  try {
    await mongoose.connect('mongodb://localhost:27017/sns-rooster');
    console.log('Connected to MongoDB');
    
    const charichaCompany = await Company.findOne({ 
      name: { $regex: /charicha/i } 
    });
    
    if (charichaCompany) {
      console.log('Charicha Company Found:');
      console.log('ID:', charichaCompany._id);
      console.log('Name:', charichaCompany.name);
      console.log('Domain:', charichaCompany.domain);
      console.log('Subscription Plan:', charichaCompany.subscriptionPlan);
    } else {
      console.log('Charicha company not found!');
    }
    
    await mongoose.connection.close();
  } catch (error) {
    console.error('Error:', error);
  }
}

getCharichaCompanyId(); 