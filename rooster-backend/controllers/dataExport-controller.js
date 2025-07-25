const DataExportService = require('../services/dataExportService');
const path = require('path');
const fs = require('fs');

const exportService = new DataExportService();

/**
 * Export attendance data
 */
exports.exportAttendance = async (req, res) => {
  try {
    const { format = 'csv', startDate, endDate, employeeId } = req.query;
    const companyId = req.companyId;

    // Validate format
    const validFormats = ['csv', 'pdf', 'excel', 'xlsx'];
    if (!validFormats.includes(format.toLowerCase())) {
      return res.status(400).json({ 
        message: 'Invalid format. Supported formats: csv, pdf, excel' 
      });
    }

    const filters = {};
    if (startDate) filters.startDate = startDate;
    if (endDate) filters.endDate = endDate;
    if (employeeId) filters.employeeId = employeeId;

    const result = await exportService.exportData('attendance', companyId, format, filters);

    if (!result.success) {
      return res.status(500).json({ 
        message: 'Export failed', 
        error: result.error 
      });
    }

    // Send file
    res.download(result.filePath, result.filename, (err) => {
      if (err) {
        console.error('Download error:', err);
        res.status(500).json({ message: 'Error downloading file' });
      }
      
      // Clean up file after download (optional)
      setTimeout(() => {
        try {
          fs.unlinkSync(result.filePath);
        } catch (cleanupError) {
          console.error('File cleanup error:', cleanupError);
        }
      }, 5000);
    });

  } catch (error) {
    console.error('Export attendance error:', error);
    res.status(500).json({ 
      message: 'Error exporting attendance data', 
      error: error.message 
    });
  }
};

/**
 * Export leave data
 */
exports.exportLeave = async (req, res) => {
  try {
    const { format = 'csv', startDate, endDate, status } = req.query;
    const companyId = req.companyId;

    // Validate format
    const validFormats = ['csv', 'pdf', 'excel', 'xlsx'];
    if (!validFormats.includes(format.toLowerCase())) {
      return res.status(400).json({ 
        message: 'Invalid format. Supported formats: csv, pdf, excel' 
      });
    }

    const filters = {};
    if (startDate) filters.startDate = startDate;
    if (endDate) filters.endDate = endDate;
    if (status) filters.status = status;

    const result = await exportService.exportData('leave', companyId, format, filters);

    if (!result.success) {
      return res.status(500).json({ 
        message: 'Export failed', 
        error: result.error 
      });
    }

    // Send file
    res.download(result.filePath, result.filename, (err) => {
      if (err) {
        console.error('Download error:', err);
        res.status(500).json({ message: 'Error downloading file' });
      }
      
      // Clean up file after download
      setTimeout(() => {
        try {
          fs.unlinkSync(result.filePath);
        } catch (cleanupError) {
          console.error('File cleanup error:', cleanupError);
        }
      }, 5000);
    });

  } catch (error) {
    console.error('Export leave error:', error);
    res.status(500).json({ 
      message: 'Error exporting leave data', 
      error: error.message 
    });
  }
};

/**
 * Export employee data
 */
exports.exportEmployees = async (req, res) => {
  try {
    const { format = 'csv', department, isActive } = req.query;
    const companyId = req.companyId;

    // Validate format
    const validFormats = ['csv', 'pdf', 'excel', 'xlsx'];
    if (!validFormats.includes(format.toLowerCase())) {
      return res.status(400).json({ 
        message: 'Invalid format. Supported formats: csv, pdf, excel' 
      });
    }

    const filters = {};
    if (department) filters.department = department;
    if (isActive !== undefined) filters.isActive = isActive === 'true';

    const result = await exportService.exportData('employees', companyId, format, filters);

    if (!result.success) {
      return res.status(500).json({ 
        message: 'Export failed', 
        error: result.error 
      });
    }

    // Send file
    res.download(result.filePath, result.filename, (err) => {
      if (err) {
        console.error('Download error:', err);
        res.status(500).json({ message: 'Error downloading file' });
      }
      
      // Clean up file after download
      setTimeout(() => {
        try {
          fs.unlinkSync(result.filePath);
        } catch (cleanupError) {
          console.error('File cleanup error:', cleanupError);
        }
      }, 5000);
    });

  } catch (error) {
    console.error('Export employees error:', error);
    res.status(500).json({ 
      message: 'Error exporting employee data', 
      error: error.message 
    });
  }
};

/**
 * Export payroll data
 */
exports.exportPayroll = async (req, res) => {
  try {
    const { format = 'csv', month, year, employeeId } = req.query;
    const companyId = req.companyId;

    // Validate format
    const validFormats = ['csv', 'pdf', 'excel', 'xlsx'];
    if (!validFormats.includes(format.toLowerCase())) {
      return res.status(400).json({ 
        message: 'Invalid format. Supported formats: csv, pdf, excel' 
      });
    }

    const filters = {};
    if (month) filters.month = month;
    if (year) filters.year = year;
    if (employeeId) filters.employeeId = employeeId;

    const result = await exportService.exportData('payroll', companyId, format, filters);

    if (!result.success) {
      return res.status(500).json({ 
        message: 'Export failed', 
        error: result.error 
      });
    }

    // Send file
    res.download(result.filePath, result.filename, (err) => {
      if (err) {
        console.error('Download error:', err);
        res.status(500).json({ message: 'Error downloading file' });
      }
      
      // Clean up file after download
      setTimeout(() => {
        try {
          fs.unlinkSync(result.filePath);
        } catch (cleanupError) {
          console.error('File cleanup error:', cleanupError);
        }
      }, 5000);
    });

  } catch (error) {
    console.error('Export payroll error:', error);
    res.status(500).json({ 
      message: 'Error exporting payroll data', 
      error: error.message 
    });
  }
};

/**
 * Export analytics data
 */
exports.exportAnalytics = async (req, res) => {
  try {
    const { format = 'csv', year, month } = req.query;
    const companyId = req.companyId;

    // Validate format
    const validFormats = ['csv', 'pdf', 'excel', 'xlsx'];
    if (!validFormats.includes(format.toLowerCase())) {
      return res.status(400).json({ 
        message: 'Invalid format. Supported formats: csv, pdf, excel' 
      });
    }

    const filters = {};
    if (year) filters.year = year;
    if (month) filters.month = month;

    const result = await exportService.exportData('analytics', companyId, format, filters);

    if (!result.success) {
      return res.status(500).json({ 
        message: 'Export failed', 
        error: result.error 
      });
    }

    // Send file
    res.download(result.filePath, result.filename, (err) => {
      if (err) {
        console.error('Download error:', err);
        res.status(500).json({ message: 'Error downloading file' });
      }
      
      // Clean up file after download
      setTimeout(() => {
        try {
          fs.unlinkSync(result.filePath);
        } catch (cleanupError) {
          console.error('File cleanup error:', cleanupError);
        }
      }, 5000);
    });

  } catch (error) {
    console.error('Export analytics error:', error);
    res.status(500).json({ 
      message: 'Error exporting analytics data', 
      error: error.message 
    });
  }
};

/**
 * Get available export formats
 */
exports.getExportFormats = async (req, res) => {
  try {
    const formats = [
      {
        id: 'csv',
        name: 'CSV (Comma Separated Values)',
        description: 'Simple text format, compatible with Excel and other spreadsheet applications',
        extension: '.csv',
        mimeType: 'text/csv'
      },
      {
        id: 'excel',
        name: 'Excel (XLSX)',
        description: 'Microsoft Excel format with formatting and multiple sheets support',
        extension: '.xlsx',
        mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
      },
      {
        id: 'pdf',
        name: 'PDF (Portable Document Format)',
        description: 'Portable document format suitable for printing and sharing',
        extension: '.pdf',
        mimeType: 'application/pdf'
      }
    ];

    res.json({
      formats,
      message: 'Available export formats retrieved successfully'
    });

  } catch (error) {
    console.error('Get export formats error:', error);
    res.status(500).json({ 
      message: 'Error retrieving export formats', 
      error: error.message 
    });
  }
};

/**
 * Get export statistics
 */
exports.getExportStats = async (req, res) => {
  try {
    const exportDir = path.join(__dirname, '../exports');
    
    if (!fs.existsSync(exportDir)) {
      return res.json({
        totalFiles: 0,
        totalSize: 0,
        filesByType: {},
        recentExports: []
      });
    }

    const files = fs.readdirSync(exportDir);
    let totalSize = 0;
    const filesByType = {};
    const recentExports = [];

    for (const file of files) {
      const filePath = path.join(exportDir, file);
      const stats = fs.statSync(filePath);
      const ext = path.extname(file).toLowerCase();
      
      totalSize += stats.size;
      
      if (!filesByType[ext]) {
        filesByType[ext] = { count: 0, size: 0 };
      }
      filesByType[ext].count++;
      filesByType[ext].size += stats.size;

      recentExports.push({
        filename: file,
        size: stats.size,
        created: stats.birthtime,
        modified: stats.mtime
      });
    }

    // Sort by modification time (most recent first)
    recentExports.sort((a, b) => b.modified - a.modified);

    res.json({
      totalFiles: files.length,
      totalSize,
      filesByType,
      recentExports: recentExports.slice(0, 10) // Last 10 exports
    });

  } catch (error) {
    console.error('Get export stats error:', error);
    res.status(500).json({ 
      message: 'Error retrieving export statistics', 
      error: error.message 
    });
  }
};

/**
 * Clean up old export files
 */
exports.cleanupExports = async (req, res) => {
  try {
    await exportService.cleanupOldExports();
    
    res.json({
      message: 'Export cleanup completed successfully',
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('Export cleanup error:', error);
    res.status(500).json({ 
      message: 'Error cleaning up exports', 
      error: error.message 
    });
  }
}; 