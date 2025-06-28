const mongoose = require('mongoose');

const PayrollSchema = new mongoose.Schema({
  employee: { type: mongoose.Schema.Types.ObjectId, ref: 'Employee', required: true },
  periodStart: { type: Date, required: true },
  periodEnd: { type: Date, required: true },
  totalHours: { type: Number, required: true },
  grossPay: { type: Number, required: true },
  netPay: { type: Number, required: true },
  deductions: { type: Number, default: 0 },
  deductionsList: [
    {
      type: { type: String, required: true },
      amount: { type: Number, required: true }
    }
  ],
  incomesList: [
    {
      type: { type: String, required: true },
      amount: { type: Number, required: true }
    }
  ],
  status: { type: String, enum: ['pending', 'approved', 'needs_review', 'acknowledged'], default: 'pending' },
  employeeComment: { type: String, default: '' },
  issueDate: { type: Date, required: true },
  payPeriod: { type: String, required: true },
  adminResponse: { type: String, default: '' },
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Payroll', PayrollSchema);
