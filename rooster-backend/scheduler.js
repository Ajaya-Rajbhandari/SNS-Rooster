const cron = require('node-cron');
const AdminSettings = require('./models/AdminSettings');
const Employee = require('./models/Employee');
const Payroll = require('./models/Payroll');
const Attendance = require('./models/Attendance');

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
    const netPay = grossPay; // TODO: subtract deductions

    const payslip = new Payroll({
      employee: emp._id,
      periodStart,
      periodEnd,
      totalHours,
      grossPay,
      netPay,
      deductions: 0,
      payPeriod: periodStart.toISOString().split('T')[0] + ' - ' + periodEnd.toISOString().split('T')[0],
      issueDate: new Date(),
      status: 'pending',
    });
    await payslip.save();
    console.log('SCHEDULER: created payslip for', emp._id.toString());
  }
}

// Schedule daily at 02:00 AM server time
cron.schedule('0 2 * * *', generatePayslips);

module.exports = { generatePayslips }; 