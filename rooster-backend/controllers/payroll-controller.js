const Payroll = require('../models/Payroll');
const Employee = require('../models/Employee');
const PDFDocument = require('pdfkit');

// Get all payrolls
exports.getAllPayrolls = async (req, res) => {
  try {
    const payrolls = await Payroll.find().populate('employee');
    res.json(payrolls);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// Get payrolls for a specific employee
exports.getEmployeePayrolls = async (req, res) => {
  try {
    const payrolls = await Payroll.find({ employee: req.params.employeeId }).populate('employee');
    res.json(payrolls);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// Create a new payroll record
exports.createPayroll = async (req, res) => {
  try {
    const { employee, periodStart, periodEnd, totalHours, grossPay, netPay, deductions, issueDate, payPeriod } = req.body;
    const payroll = new Payroll({ employee, periodStart, periodEnd, totalHours, grossPay, netPay, deductions, issueDate, payPeriod });
    await payroll.save();
    res.status(201).json(payroll);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
};

// Get payrolls for a specific user (by userId)
exports.getUserPayrollsByUserId = async (req, res) => {
  try {
    const userId = req.params.userId;
    const employee = await Employee.findOne({ userId });
    if (!employee) {
      return res.status(404).json({ error: 'Employee not found for this user.' });
    }
    const payrolls = await Payroll.find({ employee: employee._id }).populate('employee');
    res.json(payrolls);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// Update a payroll record
exports.updatePayroll = async (req, res) => {
  console.log('DEBUG: updatePayroll controller called');
  console.log('DEBUG: payrollId from params:', req.params.payrollId);
  console.log('DEBUG: request body:', req.body);
  
  try {
    const { employee, periodStart, periodEnd, totalHours, grossPay, netPay, deductions, issueDate, payPeriod, adminResponse } = req.body;
    console.log('DEBUG: Extracted fields from request body:');
    console.log('  - adminResponse:', adminResponse);
    console.log('  - payPeriod:', payPeriod);
    console.log('  - grossPay:', grossPay);
    console.log('  - deductions:', deductions);
    console.log('  - netPay:', netPay);
    
    const payslip = await Payroll.findById(req.params.payrollId);
    console.log('DEBUG: Found payslip in database:', payslip ? 'YES' : 'NO');
    
    if (!payslip) {
      console.log('DEBUG: Payslip not found, returning 404');
      return res.status(404).json({ error: 'Payroll not found' });
    }
    
    console.log('DEBUG: Current payslip status:', payslip.status);
    console.log('DEBUG: Current payslip adminResponse:', payslip.adminResponse);
    
    // If status is needs_review and admin is responding, set to pending
    if (payslip.status === 'needs_review') {
      console.log('DEBUG: Status is needs_review, changing to pending');
      payslip.status = 'pending';
    } else {
      console.log('DEBUG: Status is not needs_review, keeping as:', payslip.status);
    }
    
    console.log('DEBUG: Updating payslip fields...');
    payslip.employee = employee;
    payslip.periodStart = periodStart;
    payslip.periodEnd = periodEnd;
    payslip.totalHours = totalHours;
    payslip.grossPay = grossPay;
    payslip.netPay = netPay;
    payslip.deductions = deductions;
    payslip.issueDate = issueDate;
    payslip.payPeriod = payPeriod;
    
    if (adminResponse !== undefined) {
      console.log('DEBUG: Setting adminResponse to:', adminResponse);
      payslip.adminResponse = adminResponse;
    } else {
      console.log('DEBUG: adminResponse is undefined, not updating');
    }
    
    console.log('DEBUG: About to save payslip...');
    await payslip.save();
    console.log('DEBUG: Payslip saved successfully');
    console.log('DEBUG: Final payslip status:', payslip.status);
    console.log('DEBUG: Final payslip adminResponse:', payslip.adminResponse);
    console.log('DEBUG: Updated Payslip:', payslip);
    
    res.json(payslip);
  } catch (err) {
    console.log('DEBUG: Error in updatePayroll:', err.message);
    res.status(400).json({ error: err.message });
  }
};

// Delete a payroll record
exports.deletePayroll = async (req, res) => {
  try {
    const deleted = await Payroll.findByIdAndDelete(req.params.payrollId);
    if (!deleted) {
      return res.status(404).json({ error: 'Payroll not found' });
    }
    res.status(204).send();
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
};

// PATCH /api/payroll/:payslipId/status
exports.updatePayslipStatus = async (req, res) => {
  try {
    const { status, employeeComment } = req.body;
    const payslip = await Payroll.findByIdAndUpdate(
      req.params.payslipId,
      { status, employeeComment },
      { new: true, runValidators: true }
    );
    if (!payslip) return res.status(404).json({ error: 'Payslip not found' });
    res.json(payslip);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
};

exports.downloadPayslipPdf = async (req, res) => {
  try {
    console.log('PDF download requested for payslipId:', req.params.payslipId);
    const payslip = await Payroll.findById(req.params.payslipId).populate('employee');
    if (!payslip) {
      console.log('Payslip not found for ID:', req.params.payslipId);
      return res.status(404).json({ error: 'Payslip not found' });
    }
    console.log('Payslip found:', payslip._id.toString());
    const doc = new PDFDocument();
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', `attachment; filename=payslip-${payslip._id}.pdf`);
    doc.pipe(res);
    doc.fontSize(20).fillColor('#1a237e').text('Salary Slip', 50, 60, { align: 'center', width: 500 });
    doc.moveDown();

    // Month row
    const monthStr = payslip.periodStart ? payslip.periodStart.toLocaleString('default', { month: 'long', year: 'numeric' }) : '-';
    doc.rect(50, 90, 500, 25).fill('#f7e6b3').stroke();
    doc.fillColor('black').font('Helvetica-Bold').fontSize(12).text(`Month: ${monthStr}`, 55, 97);

    doc.fillColor('black').fontSize(11);
    // Employee info rows
    const info = [
      ['Employee Name', `${payslip.employee.firstName} ${payslip.employee.lastName}`],
      ['Employee Code', payslip.employee.employeeId || '-'],
      ['Designation', payslip.employee.position || '-'],
      ['PAN', payslip.employee.pan || '-'],
    ];
    let y = 115;
    info.forEach(([label, value]) => {
      doc.rect(50, y, 150, 25).stroke();
      doc.rect(200, y, 350, 25).stroke();
      doc.font('Helvetica-Bold').text(label, 55, y + 7);
      doc.font('Helvetica').text(value, 205, y + 7);
      y += 25;
    });

    // Income/Deductions table headers
    const tableY = y;
    doc.rect(50, tableY, 250, 25).fill('#b3d1f2').stroke();
    doc.rect(300, tableY, 250, 25).fill('#b3d1f2').stroke();
    doc.fillColor('black').font('Helvetica-Bold').text('Income', 55, tableY + 7);
    doc.text('Deductions', 305, tableY + 7);
    y = tableY + 25;

    // Table columns
    const colHeaderY = y;
    doc.font('Helvetica-Bold').text('Particulars', 55, colHeaderY + 7);
    doc.text('Amount (NPR)', 180, colHeaderY + 7);
    doc.text('Particulars', 305, colHeaderY + 7);
    doc.text('Amount (NPR)', 430, colHeaderY + 7);
    doc.font('Helvetica');
    y += 20;

    // Income and deductions rows
    const incomes = [
      ['Gross Pay', payslip.grossPay ?? '-'],
    ];
    const deductionsList = Array.isArray(payslip.deductionsList) ? payslip.deductionsList : [];
    const deductions = deductionsList.length > 0
      ? deductionsList.map(d => [d.type, d.amount])
      : [['Deductions', payslip.deductions ?? '-']];
    const maxRows = Math.max(incomes.length, deductions.length, 5);
    for (let i = 0; i < maxRows; i++) {
      doc.text(incomes[i]?.[0] || '', 55, y + 7);
      doc.text(incomes[i]?.[1]?.toString() || '', 180, y + 7);
      doc.text(deductions[i]?.[0] || '', 305, y + 7);
      doc.text(deductions[i]?.[1]?.toString() || '', 430, y + 7);
      doc.moveTo(50, y).lineTo(550, y).stroke();
      y += 20;
    }
    // Totals
    const totalIncome = payslip.grossPay ?? '-';
    const totalDeductions = payslip.deductions ?? '-';
    doc.font('Helvetica-Bold').text('Total', 55, y + 7);
    doc.text(totalIncome.toString(), 180, y + 7);
    doc.text('Total', 305, y + 7);
    doc.text(totalDeductions.toString(), 430, y + 7);
    y += 30;
    // Net Salary row
    // Blue background
    const netPay = payslip.netPay ?? '-';
    doc.rect(50, y, 500, 30).fill('#b3d1f2').stroke();
    doc.font('Helvetica-Bold').fontSize(14).fillColor('black')
       .text('Net Salary (Deposited in Account)', 55, y + 7);
    doc.text(netPay.toString(), 480, y + 7);
    doc.moveDown();
    doc.font('Helvetica-Bold').fontSize(12).fillColor('black').text(`Status: ${payslip.status || 'pending'}`);
    if (payslip.status === 'needs_review' && payslip.employeeComment) {
      doc.font('Helvetica').fontSize(11).fillColor('red').text(`Employee Comment: ${payslip.employeeComment}`);
    }
    doc.end();
  } catch (err) {
    console.error('Error generating payslip PDF:', err);
    res.status(500).json({ error: err.message });
  }
};