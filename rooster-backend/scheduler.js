const cron = require('node-cron');
const AdminSettings = require('./models/AdminSettings');
const Employee = require('./models/Employee');
const Payroll = require('./models/Payroll');
const Attendance = require('./models/Attendance');
const { calculateAllTaxes, generateDeductionsList } = require('./utils/tax-calculator');

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

module.exports = { generatePayslips }; 