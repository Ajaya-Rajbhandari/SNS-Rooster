const Payroll = require('../models/Payroll');
const Employee = require('../models/Employee');
const PDFDocument = require('pdfkit');
const Notification = require('../models/Notification');

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
    const { employee, periodStart, periodEnd, totalHours, grossPay, netPay, deductions, deductionsList, incomesList, issueDate, payPeriod } = req.body;
    console.log('DEBUG: createPayroll incomesList:', incomesList);
    const payroll = new Payroll({ employee, periodStart, periodEnd, totalHours, grossPay, netPay, deductions, deductionsList, incomesList, issueDate, payPeriod });
    await payroll.save();
    console.log('DEBUG: Saved incomesList:', payroll.incomesList);

    // Fetch the employee's userId for notification
    const emp = await Employee.findById(employee);
    if (emp && emp.userId) {
      const notification = new Notification({
        user: emp.userId,
        title: 'Payroll Processed',
        message: `Your payroll for ${payPeriod} has been processed.`,
        type: 'payroll',
        link: '/payroll',
        isRead: false,
      });
      await notification.save();
    }

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
    const { employee, periodStart, periodEnd, totalHours, grossPay, netPay, deductions, deductionsList, incomesList, issueDate, payPeriod, adminResponse } = req.body;
    console.log('DEBUG: Extracted fields from request body:');
    console.log('  - adminResponse:', adminResponse);
    console.log('  - payPeriod:', payPeriod);
    console.log('  - grossPay:', grossPay);
    console.log('  - deductions:', deductions);
    console.log('  - netPay:', netPay);
    console.log('DEBUG: updatePayroll incomesList:', incomesList);
    
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
    payslip.deductionsList = deductionsList;
    payslip.incomesList = incomesList;
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
    console.log('DEBUG: Saved incomesList:', payslip.incomesList);
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
    console.log('DEBUG: updatePayslipStatus called with:', { status, employeeComment, payslipId: req.params.payslipId });
    
    const payslip = await Payroll.findById(req.params.payslipId).populate('employee');
    if (!payslip) return res.status(404).json({ error: 'Payslip not found' });
    
    console.log('DEBUG: Found payslip:', {
      id: payslip._id,
      employee: payslip.employee ? {
        id: payslip.employee._id,
        name: `${payslip.employee.firstName} ${payslip.employee.lastName}`,
        userId: payslip.employee.userId
      } : 'No employee data',
      prevStatus: payslip.status,
      newStatus: status
    });
    
    const prevStatus = payslip.status;
    payslip.status = status;
    if (employeeComment !== undefined) payslip.employeeComment = employeeComment;
    await payslip.save();

    // Notify admins if acknowledged/approved
    if ((status === 'approved' || status === 'acknowledged') && prevStatus !== status) {
      const employee = payslip.employee;
      const payPeriod = payslip.payPeriod || '';
      console.log('DEBUG: Creating admin notification for payslip acknowledgment');
      const adminNotification = new Notification({
        role: 'admin',
        title: 'Payslip Acknowledged',
        message: `${employee.firstName} ${employee.lastName} has acknowledged their payslip for ${payPeriod}.`,
        type: 'payroll',
        link: '/admin/payroll_management',
        isRead: false,
      });
      await adminNotification.save();
      console.log('DEBUG: Admin notification created successfully');
    }

    // Notify employee of status change (except if status is unchanged)
    if (prevStatus !== status) {
      const employee = payslip.employee;
      const payPeriod = payslip.payPeriod || '';
      let title = 'Payslip Status Updated';
      let message = `Your payslip for ${payPeriod} status changed to ${status}.`;
      if (status === 'needs_review') {
        title = 'Payslip Needs Review';
        message = `Your payslip for ${payPeriod} needs your review. Please check and respond.`;
      } else if (status === 'approved' || status === 'acknowledged') {
        title = 'Payslip Acknowledged';
        message = `You have acknowledged your payslip for ${payPeriod}.`;
      }
      
      console.log('DEBUG: Creating employee notification:', {
        userId: employee.userId,
        title,
        message,
        type: 'payroll'
      });
      
      if (!employee.userId) {
        console.log('ERROR: Employee userId is missing, cannot create notification');
      } else {
        const employeeNotification = new Notification({
          user: employee.userId,
          title,
          message,
          type: 'payroll',
          link: '/payroll',
          isRead: false,
        });
        await employeeNotification.save();
        console.log('DEBUG: Employee notification created successfully');
      }
    } else {
      console.log('DEBUG: Status unchanged, no notification needed');
    }

    // Notify admins if employee requests review (needs_review)
    if (status === 'needs_review' && prevStatus !== status) {
      const employee = payslip.employee;
      const payPeriod = payslip.payPeriod || '';
      const adminNotification = new Notification({
        role: 'admin',
        title: 'Payslip Needs Review',
        message: `${employee.firstName} ${employee.lastName} has requested a review for their payslip for ${payPeriod}.`,
        type: 'review',
        link: '/admin/payroll_management',
        isRead: false,
      });
      await adminNotification.save();
    }

    res.json(payslip);
  } catch (err) {
    console.error('ERROR in updatePayslipStatus:', err);
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

exports.downloadAllPayslipsPdf = async (req, res) => {
  try {
    const employeeId = req.params.employeeId;
    const { start, end } = req.query;
    const match = { employee: employeeId };
    if (start && end) {
      match.periodStart = { $gte: new Date(start) };
      match.periodEnd = { $lte: new Date(end) };
    }
    const payslips = await Payroll.find(match).populate('employee');
    if (!payslips.length) {
      return res.status(404).json({ error: 'No payslips found for this employee.' });
    }
    const PDFDocument = require('pdfkit');
    const doc = new PDFDocument();
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', `attachment; filename=all-payslips-${employeeId}.pdf`);
    doc.pipe(res);
    payslips.forEach((payslip, idx) => {
      if (idx > 0) doc.addPage();
      doc.fontSize(20).fillColor('#1a237e').text('Salary Slip', 50, 60, { align: 'center', width: 500 });
      doc.moveDown();
      const monthStr = payslip.periodStart ? payslip.periodStart.toLocaleString('default', { month: 'long', year: 'numeric' }) : '-';
      doc.rect(50, 90, 500, 25).fill('#f7e6b3').stroke();
      doc.fillColor('black').font('Helvetica-Bold').fontSize(12).text(`Month: ${monthStr}`, 55, 97);
      doc.fillColor('black').fontSize(11);
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
      const incomes = Array.isArray(payslip.incomesList) && payslip.incomesList.length > 0
        ? payslip.incomesList.map(i => [i.type, i.amount])
        : [['Gross Pay', payslip.grossPay ?? '-']];
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
      doc.rect(50, y, 500, 30).fill('#b3d1f2').stroke();
      doc.font('Helvetica-Bold').fontSize(14).fillColor('black')
         .text('Net Salary (Deposited in Account)', 55, y + 7);
      doc.text((payslip.netPay ?? '-').toString(), 480, y + 7);
      doc.moveDown();
      doc.font('Helvetica-Bold').fontSize(12).fillColor('black').text(`Status: ${payslip.status || 'pending'}`);
      if (payslip.status === 'needs_review' && payslip.employeeComment) {
        doc.font('Helvetica').fontSize(11).fillColor('red').text(`Employee Comment: ${payslip.employeeComment}`);
      }
    });
    doc.end();
  } catch (err) {
    console.error('Error generating all payslips PDF:', err);
    res.status(500).json({ error: err.message });
  }
};

exports.downloadAllPayslipsCsv = async (req, res) => {
  try {
    const employeeId = req.params.employeeId;
    const { start, end } = req.query;
    const match = { employee: employeeId };
    if (start && end) {
      match.periodStart = { $gte: new Date(start) };
      match.periodEnd = { $lte: new Date(end) };
    }
    const payslips = await Payroll.find(match).populate('employee');
    if (!payslips.length) {
      return res.status(404).json({ error: 'No payslips found for this employee.' });
    }
    const fields = [
      'payPeriod', 'issueDate', 'periodStart', 'periodEnd', 'totalHours',
      'grossPay', 'netPay', 'deductions', 'status', 'employeeComment', 'adminResponse',
      'employee.firstName', 'employee.lastName', 'employee.employeeId', 'employee.position', 'employee.pan',
      'incomesList', 'deductionsList'
    ];
    // Build CSV header
    let csv = fields.join(',') + '\n';
    // Build CSV rows
    payslips.forEach(payslip => {
      const row = fields.map(field => {
        if (field.startsWith('employee.')) {
          const key = field.split('.')[1];
          return (payslip.employee && payslip.employee[key]) ? `"${payslip.employee[key]}"` : '';
        } else if (field === 'incomesList' || field === 'deductionsList') {
          return payslip[field] && payslip[field].length
            ? `"${payslip[field].map(i => `${i.type}:${i.amount}`).join('; ')}"`
            : '';
        } else if (payslip[field] instanceof Date) {
          return `"${payslip[field].toISOString()}"`;
        } else {
          return payslip[field] !== undefined ? `"${payslip[field]}"` : '';
        }
      });
      csv += row.join(',') + '\n';
    });
    res.setHeader('Content-Type', 'text/csv');
    res.setHeader('Content-Disposition', `attachment; filename=all-payslips-${employeeId}.csv`);
    res.send(csv);
  } catch (err) {
    console.error('Error generating all payslips CSV:', err);
    res.status(500).json({ error: err.message });
  }
};

exports.downloadAllPayslipsPdfForCurrentUser = async (req, res) => {
  try {
    console.log('Current user for PDF download:', req.user);
    // Find the employee record for this user
    const employee = await Employee.findOne({ userId: req.user.userId });
    if (!employee) {
      console.error('Employee not found for userId:', req.user.userId);
      return res.status(404).json({ error: 'Employee not found for this user.' });
    }
    console.log('employeeId used for PDF download:', employee._id);
    req.params.employeeId = employee._id;
    // Forward query params
    return exports.downloadAllPayslipsPdf(req, res);
  } catch (err) {
    console.error('Error generating PDF for current user:', err);
    res.status(500).send('Failed to generate PDF');
  }
};

exports.downloadAllPayslipsCsvForCurrentUser = async (req, res) => {
  try {
    console.log('Current user for CSV download:', req.user);
    const employee = await Employee.findOne({ userId: req.user.userId });
    if (!employee) {
      console.error('Employee not found for userId:', req.user.userId);
      return res.status(404).json({ error: 'Employee not found for this user.' });
    }
    console.log('employeeId used for CSV download:', employee._id);
    req.params.employeeId = employee._id;
    // Forward query params to shared function
    return exports.downloadAllPayslipsCsv(req, res);
  } catch (err) {
    console.error('Error generating CSV for current user:', err);
    res.status(500).send('Failed to generate CSV');
  }
};