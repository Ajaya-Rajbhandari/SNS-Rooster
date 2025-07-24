const cron = require('node-cron');
const TrialService = require('./trialService');

class SchedulerService {
  static init() {
    console.log('🕐 Initializing scheduler service...');
    
    // Check trial status daily at 9:00 AM
    cron.schedule('0 9 * * *', async () => {
      console.log('🔍 Running daily trial status check...');
      try {
        const result = await TrialService.checkTrialStatus();
        console.log(`✅ Trial check completed: ${result.checked} companies checked, ${result.expired} expired`);
        
        if (result.expired > 0) {
          console.log('⚠️  Expired companies:', result.expiredCompanies.map(c => c.name));
        }
      } catch (error) {
        console.error('❌ Error in daily trial check:', error);
      }
    }, {
      timezone: 'Asia/Kathmandu'
    });

    // Check trial status every hour during business hours (9 AM - 6 PM)
    cron.schedule('0 9-18 * * 1-5', async () => {
      console.log('🔍 Running hourly trial status check...');
      try {
        const result = await TrialService.checkTrialStatus();
        if (result.expired > 0) {
          console.log(`⚠️  Found ${result.expired} expired trials in hourly check`);
        }
      } catch (error) {
        console.error('❌ Error in hourly trial check:', error);
      }
    }, {
      timezone: 'Asia/Kathmandu'
    });

    console.log('✅ Scheduler service initialized');
  }

  static async runTrialCheck() {
    console.log('🔍 Running manual trial status check...');
    try {
      const result = await TrialService.checkTrialStatus();
      console.log(`✅ Manual trial check completed: ${result.checked} companies checked, ${result.expired} expired`);
      return result;
    } catch (error) {
      console.error('❌ Error in manual trial check:', error);
      throw error;
    }
  }
}

module.exports = SchedulerService; 