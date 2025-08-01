const express = require('express');
const router = express.Router();
const { authenticateToken } = require('../middleware/auth');
const { validateCompanyContext, validateUserCompanyAccess, requireFeature } = require('../middleware/companyContext');
const analyticsController = require('../controllers/analytics-controller');

// Employee Analytics endpoints
router.get('/attendance/:userId', authenticateToken, validateCompanyContext, validateUserCompanyAccess, analyticsController.getAttendanceAnalytics);
router.get('/work-hours/:userId', authenticateToken, validateCompanyContext, validateUserCompanyAccess, analyticsController.getWorkHoursAnalytics);
router.get('/summary/:userId', authenticateToken, validateCompanyContext, validateUserCompanyAccess, analyticsController.getAnalyticsSummary);
router.get('/late-checkins/:userId', authenticateToken, validateCompanyContext, validateUserCompanyAccess, analyticsController.getLateCheckins);
router.get('/avg-checkout/:userId', authenticateToken, validateCompanyContext, validateUserCompanyAccess, analyticsController.getAverageCheckoutTime);
router.get('/recent-activity/:userId', authenticateToken, validateCompanyContext, validateUserCompanyAccess, analyticsController.getRecentActivity);
router.get('/leave-types-breakdown', authenticateToken, validateCompanyContext, validateUserCompanyAccess, analyticsController.getLeaveTypesBreakdown);

// Admin Analytics endpoints
router.get('/admin/overview', authenticateToken, validateCompanyContext, validateUserCompanyAccess, analyticsController.getAdminOverview);

// admin only middleware
const adminOnly = (req, res, next) => {
  if (req.user.role !== 'admin') {
    return res.status(403).json({ message: 'Access denied. Admin only.' });
  }
  next();
};

// New leave approval status endpoint for admin analytics
router.get('/admin/leave-approval-status', authenticateToken, validateCompanyContext, validateUserCompanyAccess, adminOnly, requireFeature('analytics'), analyticsController.getLeaveApprovalStatus);

// New leave export endpoint
router.get('/admin/leave-export', authenticateToken, validateCompanyContext, validateUserCompanyAccess, adminOnly, requireFeature('analytics'), analyticsController.exportLeaveData);

router.get('/summary', authenticateToken, validateCompanyContext, validateUserCompanyAccess, adminOnly, requireFeature('analytics'), analyticsController.getSummary);

// Admin leave types breakdown (after adminOnly defined)
router.get('/admin/leave-types-breakdown', authenticateToken, validateCompanyContext, validateUserCompanyAccess, adminOnly, requireFeature('analytics'), analyticsController.getLeaveTypesBreakdownAdmin);
router.get('/admin/monthly-hours-trend', authenticateToken, validateCompanyContext, validateUserCompanyAccess, adminOnly, requireFeature('analytics'), analyticsController.getMonthlyHoursTrendAdmin);

// Payroll analytics
router.get('/admin/payroll-trend', authenticateToken, validateCompanyContext, validateUserCompanyAccess, adminOnly, requireFeature('analytics'), analyticsController.getPayrollTrendAdmin);
router.get('/admin/payroll-deductions-breakdown', authenticateToken, validateCompanyContext, validateUserCompanyAccess, adminOnly, requireFeature('analytics'), analyticsController.getPayrollDeductionsBreakdownAdmin);

// Report generation
router.get('/admin/generate-report', authenticateToken, validateCompanyContext, validateUserCompanyAccess, adminOnly, requireFeature('analytics'), analyticsController.generateReport);

// Add endpoint for all active employees and admins (for Total Employees modal)
router.get('/admin/active-users', authenticateToken, validateCompanyContext, validateUserCompanyAccess, requireFeature('analytics'), analyticsController.getActiveUsersList);

// Advanced Reporting endpoints
router.get('/advanced-report', authenticateToken, validateCompanyContext, validateUserCompanyAccess, async (req, res) => {
  try {
    const { type, start, end, format = 'pdf', customFields } = req.query;
    
    // Check if advanced reporting is enabled for this company
    const company = await Company.findById(req.companyId);
    if (!company.features.advancedReporting) {
      return res.status(403).json({ 
        error: 'Advanced Reporting not available in your plan',
        message: 'Upgrade to Professional or Enterprise plan to access Advanced Reporting'
      });
    }

    // Generate advanced report based on type
    let reportData;
    switch (type) {
      case 'attendance':
        reportData = await generateAttendanceReport(start, end, req.companyId);
        break;
      case 'payroll':
        reportData = await generatePayrollReport(start, end, req.companyId);
        break;
      case 'leave':
        reportData = await generateLeaveReport(start, end, req.companyId);
        break;
      case 'performance':
        reportData = await generatePerformanceReport(start, end, req.companyId);
        break;
      case 'custom':
        reportData = await generateCustomReport(start, end, customFields, req.companyId);
        break;
      default:
        return res.status(400).json({ error: 'Invalid report type' });
    }

    // Generate file based on format
    let fileBuffer;
    let fileName;
    let contentType;

    switch (format.toLowerCase()) {
      case 'pdf':
        fileBuffer = await generatePDFReport(reportData, type);
        fileName = `${type}_report_${start}_${end}.pdf`;
        contentType = 'application/pdf';
        break;
      case 'excel':
        fileBuffer = await generateExcelReport(reportData, type);
        fileName = `${type}_report_${start}_${end}.xlsx`;
        contentType = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
        break;
      case 'csv':
        fileBuffer = await generateCSVReport(reportData, type);
        fileName = `${type}_report_${start}_${end}.csv`;
        contentType = 'text/csv';
        break;
      case 'json':
        fileBuffer = Buffer.from(JSON.stringify(reportData, null, 2));
        fileName = `${type}_report_${start}_${end}.json`;
        contentType = 'application/json';
        break;
      default:
        return res.status(400).json({ error: 'Invalid format' });
    }

    res.setHeader('Content-Type', contentType);
    res.setHeader('Content-Disposition', `attachment; filename="${fileName}"`);
    res.send(fileBuffer);

  } catch (error) {
    console.error('Error generating advanced report:', error);
    res.status(500).json({ error: 'Failed to generate report' });
  }
});

// Helper functions for report generation
async function generateAttendanceReport(start, end, companyId) {
  // Implementation for attendance report
  const attendanceData = await Attendance.find({
    companyId,
    date: { $gte: start, $lte: end }
  }).populate('employeeId');

  return {
    type: 'attendance',
    period: { start, end },
    summary: {
      totalDays: attendanceData.length,
      presentDays: attendanceData.filter(a => a.status === 'present').length,
      absentDays: attendanceData.filter(a => a.status === 'absent').length,
      leaveDays: attendanceData.filter(a => a.status === 'leave').length,
    },
    details: attendanceData
  };
}

async function generatePayrollReport(start, end, companyId) {
  // Implementation for payroll report
  const payrollData = await Payroll.find({
    companyId,
    periodStart: { $gte: start },
    periodEnd: { $lte: end }
  }).populate('employeeId');

  return {
    type: 'payroll',
    period: { start, end },
    summary: {
      totalGross: payrollData.reduce((sum, p) => sum + p.grossPay, 0),
      totalNet: payrollData.reduce((sum, p) => sum + p.netPay, 0),
      totalDeductions: payrollData.reduce((sum, p) => sum + p.totalDeductions, 0),
      recordCount: payrollData.length,
    },
    details: payrollData
  };
}

async function generateLeaveReport(start, end, companyId) {
  // Implementation for leave report
  const leaveData = await Leave.find({
    companyId,
    startDate: { $gte: start },
    endDate: { $lte: end }
  }).populate('employeeId');

  return {
    type: 'leave',
    period: { start, end },
    summary: {
      totalRequests: leaveData.length,
      approvedRequests: leaveData.filter(l => l.status === 'approved').length,
      pendingRequests: leaveData.filter(l => l.status === 'pending').length,
      rejectedRequests: leaveData.filter(l => l.status === 'rejected').length,
    },
    details: leaveData
  };
}

async function generatePerformanceReport(start, end, companyId) {
  // Implementation for performance report
  // This would include performance metrics, reviews, etc.
  return {
    type: 'performance',
    period: { start, end },
    summary: {
      totalReviews: 0,
      averageRating: 0,
      topPerformers: [],
    },
    details: []
  };
}

async function generateCustomReport(start, end, customFields, companyId) {
  // Implementation for custom report based on selected fields
  const fields = customFields ? JSON.parse(customFields) : [];
  
  // Build custom query based on selected fields
  let reportData = {};
  
  if (fields.includes('Employee Name') || fields.includes('Department')) {
    const employees = await Employee.find({ companyId });
    reportData.employees = employees;
  }
  
  if (fields.includes('Work Hours')) {
    const attendance = await Attendance.find({
      companyId,
      date: { $gte: start, $lte: end }
    });
    reportData.workHours = attendance;
  }
  
  // Add more field implementations as needed
  
  return {
    type: 'custom',
    period: { start, end },
    fields: fields,
    data: reportData
  };
}

// File generation helpers
async function generatePDFReport(data, type) {
  // Implementation for PDF generation
  // This would use a library like PDFKit
  return Buffer.from('PDF content would be generated here');
}

async function generateExcelReport(data, type) {
  // Implementation for Excel generation
  // This would use a library like ExcelJS
  return Buffer.from('Excel content would be generated here');
}

async function generateCSVReport(data, type) {
  // Implementation for CSV generation
  const csvContent = 'CSV content would be generated here';
  return Buffer.from(csvContent);
}

module.exports = router; 