const mongoose = require('mongoose');

const PayrollSchema = new mongoose.Schema({
  // Company Association
  companyId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Company',
    required: true,
    index: true
  },
  employee: { type: mongoose.Schema.Types.ObjectId, ref: 'Employee', required: true },
  periodStart: { type: Date, required: true },
  periodEnd: { type: Date, required: true },
  totalHours: { type: Number, required: true },
  overtimeHours: { type: Number, default: 0 },
  overtimeMultiplier: { type: Number, default: 1.5 },
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
  companyInfo: {
    name: { type: String, default: 'Your Company Name' },
    logoUrl: { type: String, default: '' },
    address: { type: String, default: '' },
    city: { type: String, default: '' },
    state: { type: String, default: '' },
    postalCode: { type: String, default: '' },
    country: { type: String, default: '' },
    phone: { type: String, default: '' },
    email: { type: String, default: '' },
    website: { type: String, default: '' },
    registrationNumber: { type: String, default: '' },
    taxId: { type: String, default: '' },
    legalName: { type: String, default: '' },
    industry: { type: String, default: '' },
    establishedYear: { type: Number, default: null },
    employeeCount: { type: String, default: '' },
    description: { type: String, default: '' }
  },
  createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Payroll', PayrollSchema);
