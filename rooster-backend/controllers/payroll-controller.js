const Payroll = require('../models/Payroll');
const Employee = require('../models/Employee');
const PDFDocument = require('pdfkit');
const Notification = require('../models/Notification');
const path = require('path');

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
    const { employee, periodStart, periodEnd, totalHours, overtimeHours, overtimeMultiplier, grossPay, netPay, deductions, deductionsList, incomesList, issueDate, payPeriod } = req.body;
    console.log('DEBUG: createPayroll incomesList:', incomesList);
    
    // Load company information for payslip branding (same as scheduler)
    const AdminSettings = require('../models/AdminSettings');
    const settings = await AdminSettings.getSettings();
    
    const payroll = new Payroll({ 
      employee, 
      periodStart, 
      periodEnd, 
      totalHours, 
      overtimeHours: overtimeHours || 0,
      overtimeMultiplier: overtimeMultiplier || 1.5,
      grossPay, 
      netPay, 
      deductions, 
      deductionsList, 
      incomesList, 
      issueDate, 
      payPeriod,
      // Add company information for payslip branding
      companyInfo: {
        name: settings.companyInfo?.name || 'Your Company Name',
        logoUrl: settings.companyInfo?.logoUrl || '',
        address: settings.companyInfo?.address || '',
        phone: settings.companyInfo?.phone || '',
        email: settings.companyInfo?.email || '',
      },
    });
    await payroll.save();
    console.log('DEBUG: Saved incomesList:', payroll.incomesList);
    console.log('DEBUG: Saved companyInfo:', payroll.companyInfo);

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

// Get current user's payroll slips
exports.getCurrentUserPayrolls = async (req, res) => {
  try {
    const userId = req.user.userId;
    const employee = await Employee.findOne({ userId });
    if (!employee) {
      return res.status(404).json({ error: 'Employee not found for this user.' });
    }
    const payrolls = await Payroll.find({ employee: employee._id })
      .populate('employee')
      .sort({ issueDate: -1 }); // Sort by issue date, newest first
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
    const { employee, periodStart, periodEnd, totalHours, overtimeHours, overtimeMultiplier, grossPay, netPay, deductions, deductionsList, incomesList, issueDate, payPeriod, adminResponse } = req.body;
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
    payslip.overtimeHours = overtimeHours || 0;
    payslip.overtimeMultiplier = overtimeMultiplier || 1.5;
    payslip.grossPay = grossPay;
    payslip.netPay = netPay;
    payslip.deductions = deductions;
    payslip.deductionsList = deductionsList;
    payslip.incomesList = incomesList;
    payslip.issueDate = issueDate;
    payslip.payPeriod = payPeriod;
    
    // Update company information if not present or outdated
    const AdminSettings = require('../models/AdminSettings');
    const settings = await AdminSettings.getSettings();
    payslip.companyInfo = {
      name: settings.companyInfo?.name || 'Your Company Name',
      logoUrl: settings.companyInfo?.logoUrl || '',
      address: settings.companyInfo?.address || '',
      phone: settings.companyInfo?.phone || '',
      email: settings.companyInfo?.email || '',
    };
    
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
  
  let currentY = 40;
  
  // Professional Header with Company Information
  if (payslip.companyInfo?.name) {
    // Company header section with border
    doc.rect(40, currentY, 520, 120).stroke();
    
    // Logo placeholder (left side)
    doc.rect(50, currentY + 10, 80, 80).stroke();
    
    // Try to display company logo if it exists
    console.log('=== LOGO LOADING DEBUG ===');
    console.log('Has logoUrl:', !!payslip.companyInfo?.logoUrl);
    console.log('LogoUrl value:', payslip.companyInfo?.logoUrl);
    
    if (payslip.companyInfo?.logoUrl) {
      try {
        const logoPath = payslip.companyInfo.logoUrl.startsWith('http') 
          ? payslip.companyInfo.logoUrl 
          : path.join(__dirname, '..', payslip.companyInfo.logoUrl);
        console.log('Constructed logo path:', logoPath);
        
        const fs = require('fs');
        const logoExists = fs.existsSync(logoPath);
        console.log('Logo file exists:', logoExists);
        
        if (logoExists) {
          doc.image(logoPath, 55, currentY + 15, { width: 70, height: 70 });
          console.log('Logo loaded successfully into PDF');
        } else {
          console.log('Logo file not found, showing placeholder');
          doc.fontSize(8).fillColor('#666666').text('LOGO', 85, currentY + 45, { align: 'center' });
        }
      } catch (error) {
        console.log('Logo loading error:', error.message);
        // If logo fails to load, show placeholder
        doc.fontSize(8).fillColor('#666666').text('LOGO', 85, currentY + 45, { align: 'center' });
      }
    } else {
      console.log('No logoUrl provided, showing placeholder');
      doc.fontSize(8).fillColor('#666666').text('LOGO', 85, currentY + 45, { align: 'center' });
    }
    console.log('========================');
    
    // Company information (right side)
    let companyX = 150;
    let companyY = currentY + 15;
    
    // Company name in black
    doc.fontSize(16).fillColor('#000000').font('Helvetica-Bold').text(payslip.companyInfo.name, companyX, companyY);
    companyY += 20;
    
    // Registration number - always show if available
    if (payslip.companyInfo.registrationNumber) {
      doc.fontSize(10).fillColor('#333333').font('Helvetica').text(`Registration No: ${payslip.companyInfo.registrationNumber}`, companyX, companyY);
      companyY += 12;
    }
    
    // Address with city and country
    if (payslip.companyInfo.address) {
      let fullAddress = payslip.companyInfo.address;
      if (payslip.companyInfo.city) {
        fullAddress += `, ${payslip.companyInfo.city}`;
      }
      if (payslip.companyInfo.country) {
        fullAddress += `, ${payslip.companyInfo.country}`;
      }
      doc.fontSize(10).fillColor('#333333').text(fullAddress, companyX, companyY, { width: 350 });
      companyY += 12;
    }
    
    // Contact information (Phone and Email)
    if (payslip.companyInfo.phone) {
      doc.fontSize(10).fillColor('#333333').text(`Phone: ${payslip.companyInfo.phone}`, companyX, companyY);
      companyY += 12;
    }
    
    if (payslip.companyInfo.email) {
      doc.fontSize(10).fillColor('#333333').text(`E-mail: ${payslip.companyInfo.email}`, companyX, companyY);
      companyY += 12;
    }
    
    // Pan No (VAT/Tax ID) - styled in blue like the original image
    if (payslip.companyInfo.taxId) {
      doc.fontSize(10).fillColor('#2c5aa0').font('Helvetica-Bold').text(`Pan No: ${payslip.companyInfo.taxId}`, companyX, companyY);
    }
    
    currentY += 140;
  }
  
  // Salary Slip Title in colored header
  doc.rect(40, currentY, 520, 30).fill('#2c5aa0').stroke();
  doc.fontSize(16).fillColor('white').text('Salary Slip', 50, currentY + 8, { align: 'center', width: 500 });
  currentY += 30;
  
  // DEBUG: Log company info for debugging
  console.log('=== PAYSLIP COMPANY INFO DEBUG ===');
  console.log('Company Name:', payslip.companyInfo?.name);
  console.log('Logo URL:', payslip.companyInfo?.logoUrl);
  console.log('Address:', payslip.companyInfo?.address);
  console.log('Phone:', payslip.companyInfo?.phone);
  console.log('Email:', payslip.companyInfo?.email);
  console.log('===================================');

    // Month header in blue background
    const monthStr = payslip.periodStart ? payslip.periodStart.toLocaleString('default', { month: 'long', year: 'numeric' }) : '-';
    doc.rect(440, currentY, 120, 25).fill('#2c5aa0').stroke();
    doc.fillColor('white').font('Helvetica-Bold').fontSize(10).text(`Month: ${monthStr}`, 445, currentY + 8);
    currentY += 35;

    // Employee information table
    doc.fillColor('black').fontSize(11);
    const info = [
      ['Employee Name', `${payslip.employee.firstName} ${payslip.employee.lastName}`],
      ['Employee Code', payslip.employee.employeeId || '-'],
      ['Designation', payslip.employee.position || '-'],
      ['PAN', payslip.employee.pan || '-'],
    ];
    
    info.forEach(([label, value]) => {
      // Left column (label)
      doc.rect(40, currentY, 180, 25).stroke();
      doc.fillColor('#f0f0f0').rect(40, currentY, 180, 25).fill().stroke();
      doc.fillColor('black').font('Helvetica-Bold').text(label, 45, currentY + 8);
      
      // Right column (value)
      doc.rect(220, currentY, 340, 25).stroke();
      doc.fillColor('white').rect(220, currentY, 340, 25).fill().stroke();
      doc.fillColor('black').font('Helvetica').text(value, 225, currentY + 8);
      currentY += 25;
    });

    currentY += 10;
    
    // Main table headers - Income and Deductions
    doc.rect(40, currentY, 260, 30).fill('#2c5aa0').stroke();
    doc.rect(300, currentY, 260, 30).fill('#2c5aa0').stroke();
    doc.fillColor('white').font('Helvetica-Bold').fontSize(14).text('Income', 45, currentY + 8);
    doc.text('Deductions', 305, currentY + 8);
    currentY += 30;

    // Column headers
    doc.rect(40, currentY, 130, 25).fill('#e6f2ff').stroke();
    doc.rect(170, currentY, 130, 25).fill('#e6f2ff').stroke();
    doc.rect(300, currentY, 130, 25).fill('#e6f2ff').stroke();
    doc.rect(430, currentY, 130, 25).fill('#e6f2ff').stroke();
    
    doc.fillColor('black').font('Helvetica-Bold').fontSize(11);
    doc.text('Particulars', 45, currentY + 8);
    doc.text('Amount (NPR)', 175, currentY + 8);
    doc.text('Particulars', 305, currentY + 8);
    doc.text('Amount (NPR)', 435, currentY + 8);
    currentY += 25;

    // Income and deductions data rows
    const incomesList = Array.isArray(payslip.incomesList) && payslip.incomesList.length > 0
      ? payslip.incomesList.map(i => [i.type, i.amount])
      : [['Gross Pay', payslip.grossPay ?? '-']];
    const deductionsList = Array.isArray(payslip.deductionsList) ? payslip.deductionsList : [];
    const deductions = deductionsList.length > 0
      ? deductionsList.map(d => [d.type, d.amount])
      : [];
    
    const maxRows = Math.max(incomesList.length, deductions.length, 3);
    
    // Data rows
    doc.font('Helvetica').fontSize(10);
    for (let i = 0; i < maxRows; i++) {
      const rowHeight = 25;
      
      // Income side
      doc.rect(40, currentY, 130, rowHeight).stroke();
      doc.rect(170, currentY, 130, rowHeight).stroke();
      if (incomesList[i]) {
        doc.fillColor('black').text(incomesList[i][0], 45, currentY + 8);
        doc.text(incomesList[i][1]?.toString() || '', 175, currentY + 8);
      }
      
      // Deductions side
      doc.rect(300, currentY, 130, rowHeight).stroke();
      doc.rect(430, currentY, 130, rowHeight).stroke();
      if (deductions[i]) {
        doc.fillColor('black').text(deductions[i][0], 305, currentY + 8);
        doc.text(deductions[i][1]?.toString() || '', 435, currentY + 8);
      }
      
      currentY += rowHeight;
    }
    
    // Totals row
    doc.rect(40, currentY, 130, 30).fill('#f0f0f0').stroke();
    doc.rect(170, currentY, 130, 30).fill('#f0f0f0').stroke();
    doc.rect(300, currentY, 130, 30).fill('#f0f0f0').stroke();
    doc.rect(430, currentY, 130, 30).fill('#f0f0f0').stroke();
    
    const totalIncome = payslip.grossPay ?? 0;
    const totalDeductions = payslip.deductions ?? 0;
    
    doc.font('Helvetica-Bold').fontSize(11).fillColor('black');
    doc.text('Total', 45, currentY + 10);
    doc.text(totalIncome.toString(), 175, currentY + 10);
    doc.text('Total', 305, currentY + 10);
    doc.text(totalDeductions.toString(), 435, currentY + 10);
    currentY += 40;
    
    // Net Salary section
    const netPay = payslip.netPay ?? 0;
    doc.rect(40, currentY, 520, 35).fill('#2c5aa0').stroke();
    doc.font('Helvetica-Bold').fontSize(14).fillColor('white');
    doc.text('Net Salary (Deposited in Account)', 45, currentY + 10);
    doc.text(netPay.toString(), 450, currentY + 10);
    currentY += 50;
    
    // Status information
    doc.font('Helvetica-Bold').fontSize(10).fillColor('black');
    doc.text(`Status: ${payslip.status || 'pending'}`, 40, currentY);
    
    if (payslip.status === 'needs_review' && payslip.employeeComment) {
      currentY += 15;
      doc.font('Helvetica').fontSize(9).fillColor('red');
      doc.text(`Employee Comment: ${payslip.employeeComment}`, 40, currentY, { width: 500 });
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
      
      let currentY = 40;
      
      // Professional Header with Company Information
      if (payslip.companyInfo?.name) {
        // Company header section with border
        doc.rect(40, currentY, 520, 120).stroke();
        
        // Logo placeholder (left side)
        doc.rect(50, currentY + 10, 80, 80).stroke();
        
        // Try to display company logo if it exists
        if (payslip.companyInfo?.logoUrl) {
          try {
            const logoPath = payslip.companyInfo.logoUrl.startsWith('http') 
              ? payslip.companyInfo.logoUrl 
              : path.join(__dirname, '..', payslip.companyInfo.logoUrl);
            doc.image(logoPath, 55, currentY + 15, { width: 70, height: 70 });
          } catch (error) {
            // If logo fails to load, show placeholder
            doc.fontSize(8).fillColor('#666666').text('LOGO', 85, currentY + 45, { align: 'center' });
          }
        } else {
          doc.fontSize(8).fillColor('#666666').text('LOGO', 85, currentY + 45, { align: 'center' });
        }
        
        // Company information (right side)
        let companyX = 150;
        let companyY = currentY + 15;
        
        // Company name in black
        doc.fontSize(16).fillColor('#000000').font('Helvetica-Bold').text(payslip.companyInfo.name, companyX, companyY);
        companyY += 20;
        
        // Registration number - always show if available
        if (payslip.companyInfo.registrationNumber) {
          doc.fontSize(10).fillColor('#333333').font('Helvetica').text(`Registration No: ${payslip.companyInfo.registrationNumber}`, companyX, companyY);
          companyY += 12;
        }
        
        // Address with city and country
        if (payslip.companyInfo.address) {
          let fullAddress = payslip.companyInfo.address;
          if (payslip.companyInfo.city) {
            fullAddress += `, ${payslip.companyInfo.city}`;
          }
          if (payslip.companyInfo.country) {
            fullAddress += `, ${payslip.companyInfo.country}`;
          }
          doc.fontSize(10).fillColor('#333333').text(fullAddress, companyX, companyY, { width: 350 });
          companyY += 12;
        }
        
        // Contact information (Phone and Email)
        if (payslip.companyInfo.phone) {
          doc.fontSize(10).fillColor('#333333').text(`Phone: ${payslip.companyInfo.phone}`, companyX, companyY);
          companyY += 12;
        }
        
        if (payslip.companyInfo.email) {
          doc.fontSize(10).fillColor('#333333').text(`E-mail: ${payslip.companyInfo.email}`, companyX, companyY);
          companyY += 12;
        }
        
        // Pan No (VAT/Tax ID) - styled in blue like the original image
        if (payslip.companyInfo.taxId) {
          doc.fontSize(10).fillColor('#2c5aa0').font('Helvetica-Bold').text(`Pan No: ${payslip.companyInfo.taxId}`, companyX, companyY);
        }
        
        currentY += 140;
      }
      
      // Salary Slip Title in colored header
      doc.rect(40, currentY, 520, 30).fill('#2c5aa0').stroke();
      doc.fontSize(16).fillColor('white').text('Salary Slip', 50, currentY + 8, { align: 'center', width: 500 });
      currentY += 30;
      
      // Month header in blue background
      const monthStr = payslip.periodStart ? payslip.periodStart.toLocaleString('default', { month: 'long', year: 'numeric' }) : '-';
      doc.rect(440, currentY, 120, 25).fill('#2c5aa0').stroke();
      doc.fillColor('white').font('Helvetica-Bold').fontSize(10).text(`Month: ${monthStr}`, 445, currentY + 8);
      currentY += 35;

      // Employee information table
      doc.fillColor('black').fontSize(11);
      const info = [
        ['Employee Name', `${payslip.employee.firstName} ${payslip.employee.lastName}`],
        ['Employee Code', payslip.employee.employeeId || '-'],
        ['Designation', payslip.employee.position || '-'],
        ['PAN', payslip.employee.pan || '-'],
      ];
      
      info.forEach(([label, value]) => {
        // Left column (label)
        doc.rect(40, currentY, 180, 25).stroke();
        doc.fillColor('#f0f0f0').rect(40, currentY, 180, 25).fill().stroke();
        doc.fillColor('black').font('Helvetica-Bold').text(label, 45, currentY + 8);
        
        // Right column (value)
        doc.rect(220, currentY, 340, 25).stroke();
        doc.fillColor('white').rect(220, currentY, 340, 25).fill().stroke();
        doc.fillColor('black').font('Helvetica').text(value, 225, currentY + 8);
        currentY += 25;
      });
      currentY += 10;
      
      // Main table headers - Income and Deductions
      doc.rect(40, currentY, 260, 30).fill('#2c5aa0').stroke();
      doc.rect(300, currentY, 260, 30).fill('#2c5aa0').stroke();
      doc.fillColor('white').font('Helvetica-Bold').fontSize(14).text('Income', 45, currentY + 8);
      doc.text('Deductions', 305, currentY + 8);
      currentY += 30;

      // Column headers
      doc.rect(40, currentY, 130, 25).fill('#e6f2ff').stroke();
      doc.rect(170, currentY, 130, 25).fill('#e6f2ff').stroke();
      doc.rect(300, currentY, 130, 25).fill('#e6f2ff').stroke();
      doc.rect(430, currentY, 130, 25).fill('#e6f2ff').stroke();
      
      doc.fillColor('black').font('Helvetica-Bold').fontSize(11);
      doc.text('Particulars', 45, currentY + 8);
      doc.text('Amount (NPR)', 175, currentY + 8);
      doc.text('Particulars', 305, currentY + 8);
      doc.text('Amount (NPR)', 435, currentY + 8);
      currentY += 25;
      // Income and deductions data rows
      const incomesList = Array.isArray(payslip.incomesList) && payslip.incomesList.length > 0
        ? payslip.incomesList.map(i => [i.type, i.amount])
        : [['Gross Pay', payslip.grossPay ?? '-']];
      const deductionsList = Array.isArray(payslip.deductionsList) ? payslip.deductionsList : [];
      const deductions = deductionsList.length > 0
        ? deductionsList.map(d => [d.type, d.amount])
        : [];
      
      const maxRows = Math.max(incomesList.length, deductions.length, 3);
      
      // Data rows
      doc.font('Helvetica').fontSize(10);
      for (let i = 0; i < maxRows; i++) {
        const rowHeight = 25;
        
        // Income side
        doc.rect(40, currentY, 130, rowHeight).stroke();
        doc.rect(170, currentY, 130, rowHeight).stroke();
        if (incomesList[i]) {
          doc.fillColor('black').text(incomesList[i][0], 45, currentY + 8);
          doc.text(incomesList[i][1]?.toString() || '', 175, currentY + 8);
        }
        
        // Deductions side
        doc.rect(300, currentY, 130, rowHeight).stroke();
        doc.rect(430, currentY, 130, rowHeight).stroke();
        if (deductions[i]) {
          doc.fillColor('black').text(deductions[i][0], 305, currentY + 8);
          doc.text(deductions[i][1]?.toString() || '', 435, currentY + 8);
        }
        
        currentY += rowHeight;
      }
      
      // Totals row
      doc.rect(40, currentY, 130, 30).fill('#f0f0f0').stroke();
      doc.rect(170, currentY, 130, 30).fill('#f0f0f0').stroke();
      doc.rect(300, currentY, 130, 30).fill('#f0f0f0').stroke();
      doc.rect(430, currentY, 130, 30).fill('#f0f0f0').stroke();
      
      const totalIncome = payslip.grossPay ?? 0;
      const totalDeductions = payslip.deductions ?? 0;
      
      doc.font('Helvetica-Bold').fontSize(11).fillColor('black');
      doc.text('Total', 45, currentY + 10);
      doc.text(totalIncome.toString(), 175, currentY + 10);
      doc.text('Total', 305, currentY + 10);
      doc.text(totalDeductions.toString(), 435, currentY + 10);
      currentY += 40;
      
      // Net Salary section
      const netPay = payslip.netPay ?? 0;
      doc.rect(40, currentY, 520, 35).fill('#2c5aa0').stroke();
      doc.font('Helvetica-Bold').fontSize(14).fillColor('white');
      doc.text('Net Salary (Deposited in Account)', 45, currentY + 10);
      doc.text(netPay.toString(), 450, currentY + 10);
      currentY += 50;
      
      // Status information
      doc.font('Helvetica-Bold').fontSize(10).fillColor('black');
      doc.text(`Status: ${payslip.status || 'pending'}`, 40, currentY);
      
      if (payslip.status === 'needs_review' && payslip.employeeComment) {
        currentY += 15;
        doc.font('Helvetica').fontSize(9).fillColor('red');
        doc.text(`Employee Comment: ${payslip.employeeComment}`, 40, currentY, { width: 500 });
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

// DEBUG: Force update payslips with latest company info
exports.updatePayslipsCompanyInfo = async (req, res) => {
  try {
    const AdminSettings = require('../models/AdminSettings');
    const settings = await AdminSettings.getSettings();
    
    const companyInfo = {
      name: settings.companyInfo?.name || 'Your Company Name',
      logoUrl: settings.companyInfo?.logoUrl || '',
      address: settings.companyInfo?.address || '',
      phone: settings.companyInfo?.phone || '',
      email: settings.companyInfo?.email || '',
      registrationNumber: settings.companyInfo?.registrationNumber || '',
    };
    
    const result = await Payroll.updateMany({}, { companyInfo });
    
    res.json({ 
      message: 'Payslips updated with latest company info',
      updatedCount: result.modifiedCount,
      companyInfo 
    });
  } catch (err) {
    console.error('Error updating payslips company info:', err);
    res.status(500).json({ error: err.message });
  }
};