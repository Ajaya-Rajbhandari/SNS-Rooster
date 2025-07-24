const cron = require('node-cron');
const AdminSettings = require('./models/AdminSettings');
const Employee = require('./models/Employee');
const Payroll = require('./models/Payroll');
const Attendance = require('./models/Attendance');
const { calculateAllTaxes, generateDeductionsList } = require('./utils/tax-calculator');
const TrialService = require('./services/trialService');
// Remove the problematic import since check_break_violations.js doesn't export the function
// const checkAndNotifyBreakViolations = require('./check_break_violations');

console.log('SCHEDULER: initializing');

// Helper to check if a payroll already exists for employee & period start
async function payrollExists(employeeId, periodStart) {
  return await Payroll.findOne({ employee: employeeId, periodStart });
}

function daysInMonth(year, month) {
  return new Date(year, month + 1, 0).getDate();
}

function computeMonthlyPeriod(now, cutoffDay) {
  let start, end;
  if (now.getUTCDate() > cutoffDay) {
    start = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), cutoffDay + 1));
    end = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth() + 1, cutoffDay));
  } else {
    const prev = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth() - 1, 1));
    start = new Date(Date.UTC(prev.getUTCFullYear(), prev.getUTCMonth(), cutoffDay + 1));
    end = new Date(Date.UTC(prev.getUTCFullYear(), prev.getUTCMonth() + 1, cutoffDay));
  }
  return { start, end };
}

function computeSemiMonthlyPeriod(now) {
  // Semi-monthly: 1st-15th and 16th-end of month
  const mid = 15;
  let start, end;
  if (now.getUTCDate() <= mid) {
    // First half of current month (1-15)
    start = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), 1));
    end = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), mid));
  } else {
    // Second half of current month (16-end)
    start = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), mid + 1));
    // Last day of month in UTC
    end = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth() + 1, 0));
  }
  return { start, end };
}

function computeBiWeeklyPeriod(now, startRefDay) {
  // Bi-weekly: every 14 days from reference start date
  const startRef = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), startRefDay));
  const diff = Math.floor((now - startRef) / (1000 * 60 * 60 * 24));
  const cycles = Math.floor(diff / 14);
  const periodStart = new Date(startRef);
  periodStart.setUTCDate(startRef.getUTCDate() + (cycles * 14));
  const periodEnd = new Date(periodStart);
  periodEnd.setUTCDate(periodStart.getUTCDate() + 13);
  return { start: periodStart, end: periodEnd };
}

async function generatePayslips() {
  console.log('SCHEDULER: generatePayslips tick');
  const settings = await AdminSettings.getSettings();
  const cycle = settings.payrollCycle || {};
  if (!cycle.autoGenerate) {
    console.log('SCHEDULER: autoGenerate disabled, skipping');
    return;
  }
  const freq = (cycle.frequency || 'Monthly').toLowerCase();
  // Use UTC midnight for today
  const now = new Date();
  const today = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate(), 0, 0, 0, 0));
  let shouldRun = false;

  if (freq === 'monthly') {
    const payDay = cycle.payDay || 30;
    const payDate = new Date(Date.UTC(today.getUTCFullYear(), today.getUTCMonth(), payDay + (cycle.payOffset || 0)));
    shouldRun = payDate.toISOString().slice(0, 10) === today.toISOString().slice(0, 10);
  } else if (freq === 'semi-monthly') {
    const firstPayDay = cycle.payDay1 || 15; // First pay day of month
    const secondPayDay = cycle.payDay || 30; // Second pay day of month
    const offset = cycle.payOffset || 0;
    const firstPayDate = new Date(Date.UTC(today.getUTCFullYear(), today.getUTCMonth(), firstPayDay + offset));
    const secondPayDate = new Date(Date.UTC(today.getUTCFullYear(), today.getUTCMonth(), secondPayDay + offset));
    shouldRun = (firstPayDate.toISOString().slice(0, 10) === today.toISOString().slice(0, 10)) ||
                (secondPayDate.toISOString().slice(0, 10) === today.toISOString().slice(0, 10));
  } else if (freq === 'bi-weekly') {
    const startRef = new Date(Date.UTC(today.getUTCFullYear(), today.getUTCMonth(), cycle.cutoffDay || 1));
    const diff = Math.floor((today - startRef) / (1000 * 60 * 60 * 24));
    const offset = cycle.payOffset || 0;
    // Check if today is a bi-weekly interval (every 14 days) from start reference
    shouldRun = (diff >= 0) && ((diff + offset) % 14 === 0);
  } else if (freq === 'weekly') {
    const weekday = cycle.payWeekday || 5; // Friday default
    let payDate = new Date(today);
    payDate.setUTCDate(today.getUTCDay() + ((weekday - today.getUTCDay() + 7) % 7)); // next weekday
    // If today is the weekday consider offset
    if (payDate.toISOString().slice(0, 10) === today.toISOString().slice(0, 10)) {
      payDate = new Date(today);
    }
    payDate.setUTCDate(payDate.getUTCDate() + (cycle.payOffset || 0));
    shouldRun = payDate.toISOString().slice(0, 10) === today.toISOString().slice(0, 10);
  } else {
    console.log('SCHEDULER: frequency not yet supported:', freq);
    return;
  }

  if (!shouldRun) {
    console.log('SCHEDULER: not pay day, skipping');
    return;
  }

  console.log('SCHEDULER: generating payslips for frequency', freq);

  const employees = await Employee.find({ isActive: true });
  for (const emp of employees) {
    let periodStart, periodEnd;
    if (freq === 'monthly') {
      const period = computeMonthlyPeriod(today, cycle.cutoffDay || 25);
      periodStart = period.start;
      periodEnd = period.end;
    } else if (freq === 'semi-monthly') {
      const period = computeSemiMonthlyPeriod(today);
      periodStart = period.start;
      periodEnd = period.end;
    } else if (freq === 'bi-weekly') {
      const period = computeBiWeeklyPeriod(today, cycle.cutoffDay || 1);
      periodStart = period.start;
      periodEnd = period.end;
    } else {
      // weekly: previous Monday-Sunday (UTC)
      const start = new Date(today);
      start.setUTCDate(today.getUTCDate() - 6);
      periodStart = start;
      periodEnd = today;
    }

    // skip if exists
    if (await payrollExists(emp._id, periodStart)) continue;

    // compute total hours and overtime
    const attendances = await Attendance.find({
      user: emp.userId,
      date: { $gte: periodStart, $lte: periodEnd },
    });
    
    let totalMs = 0;
    let dailyHours = {}; // Track daily hours for overtime calculation
    
    attendances.forEach((a) => {
      if (a.checkInTime && a.checkOutTime) {
        const workMs = new Date(a.checkOutTime) - new Date(a.checkInTime) - (a.totalBreakDuration || 0);
        totalMs += workMs;
        
        // Track daily hours for overtime calculation
        const dateKey = a.date.toISOString().split('T')[0];
        const dayHours = workMs / (1000 * 60 * 60);
        dailyHours[dateKey] = (dailyHours[dateKey] || 0) + dayHours;
      }
    });
    
    const totalHours = +(totalMs / (1000 * 60 * 60)).toFixed(1);
    
    // Calculate overtime hours (hours over 8 per day)
    let overtimeHours = 0;
    if (cycle.overtimeEnabled) {
      Object.values(dailyHours).forEach(dayHours => {
        if (dayHours > 8) {
          overtimeHours += dayHours - 8;
        }
      });
    }
    overtimeHours = +overtimeHours.toFixed(1);

    // Gross pay calculation: regular pay + overtime pay
    const hourlyRate = emp.hourlyRate || cycle.defaultHourlyRate || 0;
    const regularHours = totalHours - overtimeHours;
    const overtimeMultiplier = cycle.overtimeMultiplier || 1.5;
    const regularPay = regularHours * hourlyRate;
    const overtimePay = overtimeHours * hourlyRate * overtimeMultiplier;
    const grossPay = +(regularPay + overtimePay).toFixed(2);

    // Calculate taxes using tax settings
    const taxCalculation = calculateAllTaxes(grossPay, settings.taxSettings || {});
    const deductionsList = generateDeductionsList(taxCalculation, settings.taxSettings?.currencySymbol || 'Rs.');
    
    const totalDeductions = taxCalculation.totalTaxes;
    const netPay = taxCalculation.netIncome;

    const payslip = new Payroll({
      employee: emp._id,
      periodStart,
      periodEnd,
      totalHours,
      overtimeHours,
      overtimeMultiplier: cycle.overtimeMultiplier || 1.5,
      grossPay,
      netPay,
      deductions: totalDeductions,
      deductionsList: deductionsList,
      payPeriod: periodStart.toISOString().split('T')[0] + ' - ' + periodEnd.toISOString().split('T')[0],
      issueDate: new Date(Date.UTC(today.getUTCFullYear(), today.getUTCMonth(), today.getUTCDate(), 0, 0, 0, 0)),
      status: 'pending',
      // Add company information for payslip branding
      companyInfo: {
        name: settings.companyInfo?.name || 'Your Company Name',
        logoUrl: settings.companyInfo?.logoUrl || '',
        address: settings.companyInfo?.address || '',
        phone: settings.companyInfo?.phone || '',
        email: settings.companyInfo?.email || '',
      },
    });
    await payslip.save();
    console.log('SCHEDULER: created payslip for', emp._id.toString());
  }
}

// Schedule daily at 02:00 AM server time
cron.schedule('0 2 * * *', generatePayslips);

// Trial status check function
async function checkTrialStatus() {
  try {
    console.log('SCHEDULER: Running trial status check...');
    const result = await TrialService.checkTrialStatus();
    console.log(`SCHEDULER: Trial check completed: ${result.checked} companies checked, ${result.expired} expired`);
    
    if (result.expired > 0) {
      console.log('SCHEDULER: Expired companies:', result.expiredCompanies.map(c => c.name));
    }
  } catch (error) {
    console.error('SCHEDULER: Error in trial status check:', error);
  }
}

// Schedule trial status check daily at 9:00 AM
cron.schedule('0 9 * * *', checkTrialStatus);

// Schedule trial status check every hour during business hours (9 AM - 6 PM, weekdays)
cron.schedule('0 9-18 * * 1-5', checkTrialStatus);

// Break monitoring scheduler
async function monitorBreaks() {
  try {
    console.log('Starting break monitoring...');
    
    const Attendance = require('./models/Attendance');
    const BreakType = require('./models/BreakType');
    const Notification = require('./models/Notification');
    const FCMToken = require('./models/FCMToken');
    const { sendNotificationToUser } = require('./services/notificationService');
    
    // Use UTC midnight for consistency
    const now = new Date();
    const today = new Date(
      Date.UTC(
        now.getUTCFullYear(),
        now.getUTCMonth(),
        now.getUTCDate(),
        0,
        0,
        0,
        0
      )
    );

    // Find all attendance records with ongoing breaks
    const attendanceWithOngoingBreaks = await Attendance.find({
      date: today,
      'breaks.end': { $exists: false }
    }).populate('user', 'firstName lastName email')
      .populate('breaks.type', 'displayName maxDuration');

    let warningsSent = 0;
    let violationsSent = 0;

    for (const attendance of attendanceWithOngoingBreaks) {
      const lastBreak = attendance.breaks[attendance.breaks.length - 1];
      if (lastBreak && !lastBreak.end && lastBreak.type) {
        const breakStart = new Date(lastBreak.start);
        const currentDuration = now.getTime() - breakStart.getTime();
        const maxDuration = lastBreak.type.maxDuration * 1000 * 60; // Convert to milliseconds
        const warningThreshold = maxDuration * 0.8; // Warn at 80% of max duration

        // Check if we already sent a notification for this break in the last 5 minutes
        const recentNotification = await Notification.findOne({
          user: attendance.user._id,
          type: { $in: ['break_warning', 'break_violation'] },
          createdAt: { $gte: new Date(now.getTime() - 5 * 60 * 1000) } // Last 5 minutes
        });

        if (recentNotification) {
          continue; // Skip if we recently sent a notification
        }

        if (currentDuration >= maxDuration) {
          // Break time exceeded - send violation notification
          await sendBreakTimeViolationNotification(
            attendance.user._id,
            lastBreak.type,
            currentDuration
          );
          violationsSent++;
        } else if (currentDuration >= warningThreshold) {
          // Approaching limit - send warning notification
          await sendBreakTimeWarningNotification(
            attendance.user._id,
            lastBreak.type,
            currentDuration,
            maxDuration
          );
          warningsSent++;
        }
      }
    }

    console.log(`Break monitoring completed: ${warningsSent} warnings, ${violationsSent} violations sent`);
  } catch (error) {
    console.error('Break monitoring error:', error);
  }
}

// Helper function to send break time violation notifications
async function sendBreakTimeViolationNotification(userId, breakTypeConfig, actualDuration) {
  try {
    const Notification = require('./models/Notification');
    const FCMToken = require('./models/FCMToken');
    const User = require('./models/User');
    const { sendNotificationToUser } = require('./services/notificationService');
    
    // Get user to find their company
    const user = await User.findById(userId);
    if (!user || !user.companyId) {
      console.warn(`User ${userId} not found or has no company`);
      return;
    }
    
    // Calculate duration in minutes
    const actualMinutes = Math.round(actualDuration / (1000 * 60));
    const maxMinutes = Math.round(breakTypeConfig.maxDuration);
    const overMinutes = actualMinutes - maxMinutes;
    
    const title = 'Break Time Exceeded';
    const message = `Your ${breakTypeConfig.displayName} exceeded the limit by ${overMinutes} minutes. Please be mindful of break time limits.`;
    
    // Create database notification
    const notification = new Notification({
      company: user.companyId,
      user: userId,
      title: title,
      message: message,
      type: 'break_violation',
      link: '/attendance',
      isRead: false,
    });
    await notification.save();
    
    // Send FCM push notification
    const tokenDoc = await FCMToken.findOne({ userId: userId });
    if (tokenDoc && tokenDoc.fcmToken) {
      await sendNotificationToUser(
        tokenDoc.fcmToken,
        title,
        message,
        { 
          type: 'break_violation', 
          breakType: breakTypeConfig.displayName,
          actualDuration: actualMinutes,
          maxDuration: maxMinutes,
          overMinutes: overMinutes
        }
      );
    }
  } catch (error) {
    console.error('Error sending break time violation notification:', error);
  }
}

// Helper function to send break time warning notifications
async function sendBreakTimeWarningNotification(userId, breakTypeConfig, currentDuration, maxDuration) {
  try {
    const Notification = require('./models/Notification');
    const FCMToken = require('./models/FCMToken');
    const User = require('./models/User');
    const { sendNotificationToUser } = require('./services/notificationService');
    
    // Get user to find their company
    const user = await User.findById(userId);
    if (!user || !user.companyId) {
      console.warn(`User ${userId} not found or has no company`);
      return;
    }
    
    // Calculate duration in minutes
    const currentMinutes = Math.round(currentDuration / (1000 * 60));
    const maxMinutes = Math.round(maxDuration / (1000 * 60));
    const remainingMinutes = maxMinutes - currentMinutes;
    
    const title = 'Break Time Warning';
    const message = `Your ${breakTypeConfig.displayName} is approaching the limit. You have approximately ${remainingMinutes} minutes remaining.`;
    
    // Create database notification
    const notification = new Notification({
      company: user.companyId,
      user: userId,
      title: title,
      message: message,
      type: 'break_warning',
      link: '/attendance',
      isRead: false,
    });
    await notification.save();
    
    // Send FCM push notification
    const tokenDoc = await FCMToken.findOne({ userId: userId });
    if (tokenDoc && tokenDoc.fcmToken) {
      await sendNotificationToUser(
        tokenDoc.fcmToken,
        title,
        message,
        { 
          type: 'break_warning', 
          breakType: breakTypeConfig.displayName,
          currentDuration: currentMinutes,
          maxDuration: maxMinutes,
          remainingMinutes: remainingMinutes
        }
      );
    }
  } catch (error) {
    console.error('Error sending break time warning notification:', error);
  }
}

// Schedule break monitoring every 5 minutes
setInterval(monitorBreaks, 5 * 60 * 1000); // 5 minutes
// Removed checkAndNotifyBreakViolations setInterval since the function is not exported

module.exports = { generatePayslips }; 