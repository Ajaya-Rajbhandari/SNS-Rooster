require('dotenv').config();
const mongoose = require('mongoose');
const BreakType = require('../models/BreakType');

async function cleanupBreakTypes() {
  try {
    // Connect to MongoDB
    await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/sns-rooster');
    console.log('Connected to MongoDB');

    console.log('\n🔍 Checking for break types without companyId...');
    
    // Find break types without companyId
    const breakTypesWithoutCompany = await BreakType.find({ companyId: { $exists: false } });
    console.log(`Found ${breakTypesWithoutCompany.length} break types without companyId`);
    
    if (breakTypesWithoutCompany.length > 0) {
      console.log('Break types without companyId:');
      breakTypesWithoutCompany.forEach(bt => {
        console.log(`- ${bt.name} (${bt.displayName})`);
      });
      
      // Delete break types without companyId
      const deleteResult = await BreakType.deleteMany({ companyId: { $exists: false } });
      console.log(`✅ Deleted ${deleteResult.deletedCount} break types without companyId`);
    }

    console.log('\n🔍 Checking for duplicate break type names...');
    
    // Find all break types and group by name
    const allBreakTypes = await BreakType.find({});
    const nameGroups = {};
    
    allBreakTypes.forEach(bt => {
      if (!nameGroups[bt.name]) {
        nameGroups[bt.name] = [];
      }
      nameGroups[bt.name].push(bt);
    });
    
    // Find duplicates
    const duplicates = Object.entries(nameGroups).filter(([name, types]) => types.length > 1);
    
    if (duplicates.length > 0) {
      console.log(`Found ${duplicates.length} duplicate break type names:`);
      
      for (const [name, types] of duplicates) {
        console.log(`\nDuplicate name: "${name}" (${types.length} instances)`);
        
        // Keep the one with companyId, delete others
        const withCompanyId = types.filter(t => t.companyId);
        const withoutCompanyId = types.filter(t => !t.companyId);
        
        if (withCompanyId.length > 0 && withoutCompanyId.length > 0) {
          console.log(`- Keeping ${withCompanyId.length} with companyId`);
          console.log(`- Deleting ${withoutCompanyId.length} without companyId`);
          
          const idsToDelete = withoutCompanyId.map(t => t._id);
          const deleteResult = await BreakType.deleteMany({ _id: { $in: idsToDelete } });
          console.log(`✅ Deleted ${deleteResult.deletedCount} duplicate break types`);
        } else if (withCompanyId.length > 1) {
          console.log(`- Multiple break types with companyId found for "${name}"`);
          console.log(`- Keeping the first one, deleting ${withCompanyId.length - 1} others`);
          
          const idsToDelete = withCompanyId.slice(1).map(t => t._id);
          const deleteResult = await BreakType.deleteMany({ _id: { $in: idsToDelete } });
          console.log(`✅ Deleted ${deleteResult.deletedCount} duplicate break types`);
        }
      }
    } else {
      console.log('✅ No duplicate break type names found');
    }

    console.log('\n🔍 Final break type count by company...');
    
    // Get final count
    const finalBreakTypes = await BreakType.find({});
    const companyGroups = {};
    
    finalBreakTypes.forEach(bt => {
      const companyId = bt.companyId ? bt.companyId.toString() : 'No Company';
      if (!companyGroups[companyId]) {
        companyGroups[companyId] = [];
      }
      companyGroups[companyId].push(bt);
    });
    
    console.log('Break types by company:');
    Object.entries(companyGroups).forEach(([companyId, types]) => {
      console.log(`- Company ${companyId}: ${types.length} break types`);
      types.forEach(bt => {
        console.log(`  * ${bt.name} (${bt.displayName})`);
      });
    });

    console.log('\n🎉 Break type cleanup completed successfully!');

  } catch (error) {
    console.error('❌ Error during cleanup:', error);
  } finally {
    await mongoose.disconnect();
    process.exit(0);
  }
}

cleanupBreakTypes(); 