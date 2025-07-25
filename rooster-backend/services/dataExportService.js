const fs = require('fs');
const path = require('path');
const csv = require('csv-writer').createObjectCsvWriter;
const PDFDocument = require('pdfkit');
const ExcelJS = require('exceljs');
const moment = require('moment');

/**
 * Data Export Service
 * Handles export of various data types in multiple formats
 */

class DataExportService {
  constructor() {
    this.exportDir = path.join(__dirname, '../exports');
    this.ensureExportDirectory();
  }

  /**
   * Ensure export directory exists
   */
  ensureExportDirectory() {
    if (!fs.existsSync(this.exportDir)) {
      fs.mkdirSync(this.exportDir, { recursive: true });
    }
  }

  /**
   * Export attendance data
   */
  async exportAttendanceData(companyId, filters = {}) {
    const Attendance = require('../models/Attendance');
    const User = require('../models/User');
    const Employee = require('../models/Employee');

    let query = { companyId };
    
    if (filters.startDate && filters.endDate) {
      query.date = {
        $gte: new Date(filters.startDate),
        $lte: new Date(filters.endDate)
      };
    }

    if (filters.employeeId) {
      query.user = filters.employeeId;
    }

    const attendance = await Attendance.find(query)
      .populate('user', 'firstName lastName email')
      .populate('employee', 'firstName lastName department position')
      .sort({ date: -1 });

    const data = attendance.map(record => ({
      Date: moment(record.date).format('YYYY-MM-DD'),
      'Employee Name': record.employee ? 
        `${record.employee.firstName} ${record.employee.lastName}` : 
        `${record.user.firstName} ${record.user.lastName}`,
      'Employee ID': record.employee?.employeeId || record.user.email,
      Department: record.employee?.department || 'Administration',
      'Check In': record.checkInTime ? moment(record.checkInTime).format('HH:mm:ss') : 'N/A',
      'Check Out': record.checkOutTime ? moment(record.checkOutTime).format('HH:mm:ss') : 'N/A',
      'Total Hours': record.totalHours ? record.totalHours.toFixed(2) : 'N/A',
      'Break Time': record.breakTime ? record.breakTime.toFixed(2) : 'N/A',
      Status: record.status || 'Present',
      Location: record.location || 'N/A'
    }));

    return {
      data,
      filename: `attendance_${companyId}_${moment().format('YYYY-MM-DD_HH-mm')}`,
      headers: Object.keys(data[0] || {})
    };
  }

  /**
   * Export leave data
   */
  async exportLeaveData(companyId, filters = {}) {
    const Leave = require('../models/Leave');
    const Employee = require('../models/Employee');
    const User = require('../models/User');

    let query = { companyId };
    
    if (filters.startDate && filters.endDate) {
      query.startDate = { $gte: new Date(filters.startDate) };
      query.endDate = { $lte: new Date(filters.endDate) };
    }

    if (filters.status) {
      query.status = filters.status;
    }

    const leaves = await Leave.find(query)
      .populate('employee', 'firstName lastName department employeeId')
      .populate('user', 'firstName lastName email')
      .populate('approvedBy', 'firstName lastName')
      .sort({ appliedAt: -1 });

    const data = leaves.map(leave => {
      const person = leave.employee || leave.user;
      const duration = moment(leave.endDate).diff(moment(leave.startDate), 'days') + 1;
      
      return {
        'Employee Name': `${person?.firstName || ''} ${person?.lastName || ''}`.trim(),
        'Employee ID': leave.employee?.employeeId || leave.user?.email || 'N/A',
        Department: leave.employee?.department || 'Administration',
        'Leave Type': leave.leaveType,
        'Start Date': moment(leave.startDate).format('YYYY-MM-DD'),
        'End Date': moment(leave.endDate).format('YYYY-MM-DD'),
        Duration: `${duration} days`,
        Reason: leave.reason || 'N/A',
        Status: leave.status,
        'Applied Date': moment(leave.appliedAt).format('YYYY-MM-DD'),
        'Approved By': leave.approvedBy ? 
          `${leave.approvedBy.firstName} ${leave.approvedBy.lastName}` : 'N/A',
        'Approved Date': leave.approvedAt ? moment(leave.approvedAt).format('YYYY-MM-DD') : 'N/A'
      };
    });

    return {
      data,
      filename: `leave_requests_${companyId}_${moment().format('YYYY-MM-DD_HH-mm')}`,
      headers: Object.keys(data[0] || {})
    };
  }

  /**
   * Export employee data
   */
  async exportEmployeeData(companyId, filters = {}) {
    const Employee = require('../models/Employee');
    const User = require('../models/User');

    let query = { companyId };
    
    if (filters.department) {
      query.department = filters.department;
    }

    if (filters.isActive !== undefined) {
      query.isActive = filters.isActive;
    }

    const employees = await Employee.find(query)
      .populate('userId', 'firstName lastName email')
      .sort({ firstName: 1 });

    const data = employees.map(emp => ({
      'Employee ID': emp.employeeId,
      'First Name': emp.firstName,
      'Last Name': emp.lastName,
      'Full Name': `${emp.firstName} ${emp.lastName}`,
      Email: emp.email,
      Department: emp.department || 'N/A',
      Position: emp.position || 'N/A',
      'Employee Type': emp.employeeType || 'N/A',
      'Employee Sub Type': emp.employeeSubType || 'N/A',
      'Hire Date': moment(emp.hireDate).format('YYYY-MM-DD'),
      'Hourly Rate': emp.hourlyRate ? `$${emp.hourlyRate.toFixed(2)}` : 'N/A',
      'Monthly Salary': emp.monthlySalary ? `$${emp.monthlySalary.toFixed(2)}` : 'N/A',
      Status: emp.isActive ? 'Active' : 'Inactive',
      'Performance Level': emp.performanceLevel || 'N/A',
      'Last Performance Review': emp.lastPerformanceReview ? 
        moment(emp.lastPerformanceReview).format('YYYY-MM-DD') : 'N/A',
      'Next Performance Review': emp.nextPerformanceReview ? 
        moment(emp.nextPerformanceReview).format('YYYY-MM-DD') : 'N/A'
    }));

    return {
      data,
      filename: `employees_${companyId}_${moment().format('YYYY-MM-DD_HH-mm')}`,
      headers: Object.keys(data[0] || {})
    };
  }

  /**
   * Export payroll data
   */
  async exportPayrollData(companyId, filters = {}) {
    const Payroll = require('../models/Payroll');
    const Employee = require('../models/Employee');

    let query = { companyId };
    
    if (filters.month && filters.year) {
      query.month = parseInt(filters.month);
      query.year = parseInt(filters.year);
    }

    if (filters.employeeId) {
      query.employee = filters.employeeId;
    }

    const payrolls = await Payroll.find(query)
      .populate('employee', 'firstName lastName department employeeId')
      .sort({ year: -1, month: -1 });

    const data = payrolls.map(payroll => ({
      'Employee ID': payroll.employee?.employeeId || 'N/A',
      'Employee Name': `${payroll.employee?.firstName || ''} ${payroll.employee?.lastName || ''}`.trim(),
      Department: payroll.employee?.department || 'N/A',
      'Pay Period': `${payroll.month}/${payroll.year}`,
      'Basic Salary': `$${payroll.basicSalary?.toFixed(2) || '0.00'}`,
      'Overtime Pay': `$${payroll.overtimePay?.toFixed(2) || '0.00'}`,
      'Allowances': `$${payroll.allowances?.toFixed(2) || '0.00'}`,
      'Deductions': `$${payroll.deductions?.toFixed(2) || '0.00'}`,
      'Net Salary': `$${payroll.netSalary?.toFixed(2) || '0.00'}`,
      'Working Days': payroll.workingDays || 0,
      'Overtime Hours': payroll.overtimeHours?.toFixed(2) || '0.00',
      Status: payroll.status || 'Pending',
      'Generated Date': moment(payroll.generatedAt).format('YYYY-MM-DD')
    }));

    return {
      data,
      filename: `payroll_${companyId}_${moment().format('YYYY-MM-DD_HH-mm')}`,
      headers: Object.keys(data[0] || {})
    };
  }

  /**
   * Export analytics data
   */
  async exportAnalyticsData(companyId, filters = {}) {
    const Attendance = require('../models/Attendance');
    const Leave = require('../models/Leave');
    const Employee = require('../models/Employee');

    const year = filters.year || new Date().getFullYear();
    const month = filters.month || new Date().getMonth() + 1;

    // Get attendance analytics
    const startDate = new Date(year, month - 1, 1);
    const endDate = new Date(year, month, 0);

    const attendanceStats = await Attendance.aggregate([
      {
        $match: {
          companyId: companyId,
          date: { $gte: startDate, $lte: endDate }
        }
      },
      {
        $group: {
          _id: '$user',
          totalDays: { $sum: 1 },
          totalHours: { $sum: '$totalHours' },
          avgHours: { $avg: '$totalHours' }
        }
      }
    ]);

    // Get leave analytics
    const leaveStats = await Leave.aggregate([
      {
        $match: {
          companyId: companyId,
          appliedAt: { $gte: startDate, $lte: endDate }
        }
      },
      {
        $group: {
          _id: '$leaveType',
          count: { $sum: 1 },
          totalDays: {
            $sum: {
              $add: [
                1,
                {
                  $divide: [
                    { $subtract: ['$endDate', '$startDate'] },
                    1000 * 60 * 60 * 24
                  ]
                }
              ]
            }
          }
        }
      }
    ]);

    const data = [
      {
        'Report Type': 'Monthly Analytics Report',
        'Period': `${month}/${year}`,
        'Generated Date': moment().format('YYYY-MM-DD HH:mm:ss'),
        'Total Attendance Records': attendanceStats.length,
        'Total Leave Requests': leaveStats.reduce((sum, item) => sum + item.count, 0),
        'Average Working Hours': attendanceStats.length > 0 ? 
          (attendanceStats.reduce((sum, item) => sum + item.avgHours, 0) / attendanceStats.length).toFixed(2) : '0.00'
      },
      ...leaveStats.map(stat => ({
        'Leave Type': stat._id,
        'Number of Requests': stat.count,
        'Total Days': stat.totalDays.toFixed(0)
      }))
    ];

    return {
      data,
      filename: `analytics_${companyId}_${year}_${month}_${moment().format('YYYY-MM-DD_HH-mm')}`,
      headers: Object.keys(data[0] || {})
    };
  }

  /**
   * Export to CSV
   */
  async exportToCSV(exportData) {
    const filePath = path.join(this.exportDir, `${exportData.filename}.csv`);
    
    const csvWriter = csv({
      path: filePath,
      header: exportData.headers.map(header => ({
        id: header,
        title: header
      }))
    });

    await csvWriter.writeRecords(exportData.data);
    return filePath;
  }

  /**
   * Export to PDF
   */
  async exportToPDF(exportData, title = 'Data Export Report') {
    const filePath = path.join(this.exportDir, `${exportData.filename}.pdf`);
    const doc = new PDFDocument();

    const stream = fs.createWriteStream(filePath);
    doc.pipe(stream);

    // Add title
    doc.fontSize(18).text(title, { align: 'center' });
    doc.moveDown();
    doc.fontSize(12).text(`Generated on: ${moment().format('YYYY-MM-DD HH:mm:ss')}`);
    doc.moveDown();

    // Add table
    if (exportData.data.length > 0) {
      const headers = exportData.headers;
      const rows = exportData.data;

      // Calculate column widths
      const pageWidth = 500;
      const colWidth = pageWidth / headers.length;

      // Draw headers
      doc.fontSize(10).font('Helvetica-Bold');
      headers.forEach((header, i) => {
        doc.text(header, 50 + (i * colWidth), doc.y, { width: colWidth - 5 });
      });

      doc.moveDown();

      // Draw data rows
      doc.fontSize(9).font('Helvetica');
      rows.forEach((row, rowIndex) => {
        if (doc.y > 700) {
          doc.addPage();
        }

        headers.forEach((header, i) => {
          const value = row[header] || '';
          doc.text(String(value), 50 + (i * colWidth), doc.y, { width: colWidth - 5 });
        });
        doc.moveDown(0.5);
      });
    }

    doc.end();

    return new Promise((resolve, reject) => {
      stream.on('finish', () => resolve(filePath));
      stream.on('error', reject);
    });
  }

  /**
   * Export to Excel
   */
  async exportToExcel(exportData, title = 'Data Export Report') {
    const filePath = path.join(this.exportDir, `${exportData.filename}.xlsx`);
    const workbook = new ExcelJS.Workbook();
    const worksheet = workbook.addWorksheet('Data');

    // Add title
    worksheet.mergeCells('A1:' + String.fromCharCode(65 + exportData.headers.length - 1) + '1');
    worksheet.getCell('A1').value = title;
    worksheet.getCell('A1').font = { bold: true, size: 14 };
    worksheet.getCell('A1').alignment = { horizontal: 'center' };

    // Add headers
    worksheet.getRow(3).values = exportData.headers;
    worksheet.getRow(3).font = { bold: true };
    worksheet.getRow(3).fill = {
      type: 'pattern',
      pattern: 'solid',
      fgColor: { argb: 'FFE0E0E0' }
    };

    // Add data
    exportData.data.forEach((row, index) => {
      const rowData = exportData.headers.map(header => row[header] || '');
      worksheet.getRow(4 + index).values = rowData;
    });

    // Auto-fit columns
    worksheet.columns.forEach(column => {
      column.width = Math.max(
        column.header ? column.header.length : 10,
        ...column.values.map(v => String(v).length)
      );
    });

    await workbook.xlsx.writeFile(filePath);
    return filePath;
  }

  /**
   * Main export function
   */
  async exportData(dataType, companyId, format = 'csv', filters = {}) {
    try {
      let exportData;

      switch (dataType) {
        case 'attendance':
          exportData = await this.exportAttendanceData(companyId, filters);
          break;
        case 'leave':
          exportData = await this.exportLeaveData(companyId, filters);
          break;
        case 'employees':
          exportData = await this.exportEmployeeData(companyId, filters);
          break;
        case 'payroll':
          exportData = await this.exportPayrollData(companyId, filters);
          break;
        case 'analytics':
          exportData = await this.exportAnalyticsData(companyId, filters);
          break;
        default:
          throw new Error(`Unsupported data type: ${dataType}`);
      }

      let filePath;
      switch (format.toLowerCase()) {
        case 'csv':
          filePath = await this.exportToCSV(exportData);
          break;
        case 'pdf':
          filePath = await this.exportToPDF(exportData, `${dataType.toUpperCase()} Report`);
          break;
        case 'excel':
        case 'xlsx':
          filePath = await this.exportToExcel(exportData, `${dataType.toUpperCase()} Report`);
          break;
        default:
          throw new Error(`Unsupported format: ${format}`);
      }

      return {
        success: true,
        filePath,
        filename: path.basename(filePath),
        recordCount: exportData.data.length,
        format: format.toLowerCase()
      };
    } catch (error) {
      console.error('Export error:', error);
      return {
        success: false,
        error: error.message
      };
    }
  }

  /**
   * Clean up old export files (older than 7 days)
   */
  async cleanupOldExports() {
    try {
      const files = fs.readdirSync(this.exportDir);
      const sevenDaysAgo = moment().subtract(7, 'days');

      for (const file of files) {
        const filePath = path.join(this.exportDir, file);
        const stats = fs.statSync(filePath);
        
        if (moment(stats.mtime).isBefore(sevenDaysAgo)) {
          fs.unlinkSync(filePath);
          console.log(`Cleaned up old export file: ${file}`);
        }
      }
    } catch (error) {
      console.error('Error cleaning up old exports:', error);
    }
  }
}

module.exports = DataExportService; 