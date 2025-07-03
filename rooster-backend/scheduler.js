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
  if (now.getDate() > cutoffDay) {
    start = new Date(now.getFullYear(), now.getMonth(), cutoffDay + 1);
    end = new Date(now.getFullYear(), now.getMonth() + 1, cutoffDay);
  } else {
    const prev = new Date(now.getFullYear(), now.getMonth() - 1, 1);
    start = new Date(prev.getFullYear(), prev.getMonth(), cutoffDay + 1);
    end = new Date(prev.getFullYear(), prev.getMonth() + 1, cutoffDay);
  }
  return { start, end };
}

function computeSemiMonthlyPeriod(now) {
  // Semi-monthly: 1st-15th and 16th-end of month
  const mid = 15;
  let start, end;
  
  if (now.getDate() <= mid) {
    // First half of current month (1-15)
    start = new Date(now.getFullYear(), now.getMonth(), 1);
    end = new Date(now.getFullYear(), now.getMonth(), mid);
  } else {
    // Second half of current month (16-end)
    start = new Date(now.getFullYear(), now.getMonth(), mid + 1);
    end = new Date(now.getFullYear(), now.getMonth() + 1, 0); // last day of month
  }
  return { start, end };
}

function computeBiWeeklyPeriod(now, startRefDay) {
  // Bi-weekly: every 14 days from reference start date
  const startRef = new Date(now.getFullYear(), now.getMonth(), startRefDay);
  const diff = Math.floor((now - startRef) / (1000 * 60 * 60 * 24));
  const cycles = Math.floor(diff / 14);
  
  const periodStart = new Date(startRef);
  periodStart.setDate(startRef.getDate() + (cycles * 14));
  
  const periodEnd = new Date(periodStart);
  periodEnd.setDate(periodStart.getDate() + 13);
  
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
  const today = new Date();
  let shouldRun = false;

  if (freq === 'monthly') {
    const payDay = cycle.payDay || 30;
    const payDate = new Date(today.getFullYear(), today.getMonth(), payDay + (cycle.payOffset || 0));
    shouldRun = payDate.toDateString() === today.toDateString();
  } else if (freq === 'semi-monthly') {
    const firstPayDay = cycle.payDay1 || 15; // First pay day of month
    const secondPayDay = cycle.payDay || 30; // Second pay day of month
    const offset = cycle.payOffset || 0;
    
    const firstPayDate = new Date(today.getFullYear(), today.getMonth(), firstPayDay + offset);
    const secondPayDate = new Date(today.getFullYear(), today.getMonth(), secondPayDay + offset);
    
    shouldRun = (firstPayDate.toDateString() === today.toDateString()) || 
                (secondPayDate.toDateString() === today.toDateString());
  } else if (freq === 'bi-weekly') {
    const startRef = new Date(today.getFullYear(), today.getMonth(), cycle.cutoffDay || 1);
    const diff = Math.floor((today - startRef) / (1000 * 60 * 60 * 24));
    const offset = cycle.payOffset || 0;
    
    // Check if today is a bi-weekly interval (every 14 days) from start reference
    shouldRun = (diff >= 0) && ((diff + offset) % 14 === 0);
  } else if (freq === 'weekly') {
    const weekday = cycle.payWeekday || 5; // Friday default
    let payDate = new Date(today);
    payDate.setDate(today.getDate() + ((weekday - today.getDay() + 7) % 7)); // next weekday
    // If today is the weekday consider offset
    if (payDate.toDateString() === today.toDateString()) {
      payDate = new Date(today);
    }
    payDate.setDate(payDate.getDate() + (cycle.payOffset || 0));
    shouldRun = payDate.toDateString() === today.toDateString();
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
      // weekly: previous Monday-Sunday
      const start = new Date(today);
      start.setDate(today.getDate() - 6);
      periodStart = start;
      periodEnd = today;
    }

    // skip if exists
    if (await payrollExists(emp._id, periodStart)) continue;

    // compute total hours simple sum attendance
    const attendances = await Attendance.find({
      user: emp.userId,
      date: { $gte: periodStart, $lte: periodEnd },
    });
    let totalMs = 0;
    attendances.forEach((a) => {
      if (a.checkInTime && a.checkOutTime) {
        totalMs += new Date(a.checkOutTime) - new Date(a.checkInTime) - (a.totalBreakDuration || 0);
      }
    });
    const totalHours = +(totalMs / (1000 * 60 * 60)).toFixed(1);

    // Gross pay calculation: use employee.hourlyRate if present, otherwise default from settings or 0
    const hourlyRate = emp.hourlyRate || cycle.defaultHourlyRate || 0;
    const grossPay = +(totalHours * hourlyRate).toFixed(2);

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
      grossPay,
      netPay,
      deductions: totalDeductions,
      deductionsList: deductionsList,
      payPeriod: periodStart.toISOString().split('T')[0] + ' - ' + periodEnd.toISOString().split('T')[0],
      issueDate: new Date(),
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