# Analytics Report Generation Feature

## Overview
The Analytics Report Generation feature allows administrators to generate comprehensive PDF reports containing all analytics data from the system. This feature provides detailed insights into employee attendance, work hours, leave patterns, and payroll information.

## Setup Requirements

### Flutter Dependencies
Make sure to run the following command to install new dependencies:
```bash
cd sns_rooster
flutter pub get
```

### Android Setup
No additional permissions required - files are saved to the app's external storage directory.

### iOS Setup  
No additional setup required - files are saved to the app's Documents directory.

## Features

### 📊 Report Contents
The generated report includes:

1. **Executive Summary**
   - Total working hours for the period
   - Overtime hours calculation
   - Absence rate percentage
   - Present, absent, and leave days count

2. **Employee Overview**
   - Total number of employees
   - Active vs inactive employee counts
   - Employee status breakdown

3. **Monthly Hours Breakdown**
   - Hours worked aggregated by month
   - Trend analysis over the selected period

4. **Leave Type Distribution**
   - Breakdown of leave applications by type
   - Count of each leave type used

5. **Payroll Summary**
   - Total gross pay for the period
   - Total net pay calculations
   - Total deductions summary
   - Number of payroll records processed

### 🎯 Key Capabilities

#### Date Range Filtering
- **Default**: Last 30 days
- **Custom Range**: Select any start and end date
- **Quick Presets**: 
  - Last 7 days
  - Last 30 days
  - This month
  - This quarter
  - This year

#### Report Formats
- **PDF**: Comprehensive formatted report ready for sharing
- **JSON**: Raw data format for further processing

#### User Interface
- **Loading State**: Progress indicator during report generation
- **Error Handling**: Clear error messages for failed operations
- **Success Feedback**: Confirmation when report is generated successfully

## How to Use

### For Administrators

#### Accessing the Feature
1. Navigate to **Analytics & Reports** screen
2. Use the date range selector at the top to choose your reporting period
3. Click the **"Generate Report"** floating action button

#### Generating Reports
1. **Default Report**: Click "Generate Report" for last 30 days data
2. **Custom Period**: 
   - Tap the date range button (shows "Last 30d" by default)
   - Select custom start and end dates
   - Click "Generate Report"
3. **Quick Presets**:
   - Tap the three-dot menu (⋮) in the app bar
   - Select from predefined time periods
   - Click "Generate Report"

#### Report Download
- Reports are generated as PDF files
- Files are automatically downloaded to your device
- An "Open" button appears in the success message for immediate viewing
- File naming format: `analytics_report_[period]_[timestamp].pdf`

## Technical Implementation

### Backend Architecture

#### New Endpoint
```javascript
GET /api/analytics/admin/generate-report
```

**Query Parameters:**
- `start` (optional): Start date in YYYY-MM-DD format
- `end` (optional): End date in YYYY-MM-DD format  
- `format` (optional): 'pdf' or 'json' (default: 'pdf')

**Authentication:** Admin role required

#### Data Collection
The system aggregates data from multiple sources:
- **Attendance Records**: For hours worked and presence statistics
- **Employee Database**: For employee counts and status
- **Leave Applications**: For leave type distribution
- **Payroll Records**: For financial summaries

#### PDF Generation
- Uses PDFKit library for professional PDF formatting
- Includes company branding and structured layout
- Optimized for both viewing and printing

### Frontend Implementation

#### State Management
- Integrated with existing `AdminAnalyticsProvider`
- Loading states handled automatically
- Error handling with user-friendly messages

#### File Handling
- PDF bytes received from backend
- Platform-specific download handling
- Success/error feedback to users

## Security Features

### Access Control
- **Admin Only**: Only users with admin role can generate reports
- **JWT Authentication**: Secure token-based authentication required
- **Role Validation**: Double-checked on both frontend and backend

### Data Privacy
- Reports only include aggregated data
- Sensitive personal information is excluded
- Access logs for audit trails

## Performance Considerations

### Optimization
- **Async Processing**: Report generation doesn't block UI
- **Data Pagination**: Large datasets handled efficiently  
- **Caching**: Frequently accessed data cached for speed
- **Memory Management**: Large files handled with streams

### Limitations
- Reports limited to admin users only
- Maximum date range recommended: 1 year
- Large datasets may take longer to process

## Troubleshooting

### "Can't find downloaded reports"

#### Solution 1: Check File Location
1. **Android**: Open your device's file manager
2. Navigate to: `Android/data/com.example.sns_rooster/files/Reports/`
3. Look for files starting with `analytics_report_`

**For iOS:**
1. Open Files app 
2. Navigate to: On My iPhone > SNS HR
3. Look for your report files

#### Solution 2: Use the "Open" Button
1. Generate a new report
2. When the success message appears, tap **"Open"**
3. This will automatically open the PDF viewer

#### Solution 3: Check App Storage Directory
**For Android:**
1. Open File Manager app
2. Navigate to: `Android/data/com.example.sns_rooster/files/Reports/`
3. Look for files starting with `analytics_report_`

**For iOS:**
1. Open Files app
2. Go to: On My iPhone > SNS HR
3. Look for your report files

#### Solution 4: Alternative File Access
1. Connect device to computer
2. Enable file transfer mode
3. Browse device storage for the report files

### "Failed to generate report" Error
**Possible Causes:**
- No internet connection
- Server temporarily unavailable
- Authentication token expired
- Invalid date range selected

**Solutions:**
1. Check internet connection
2. Try logging out and back in
3. Select a smaller date range
4. Contact system administrator

### Reports Open Blank or Corrupted
**Fix:**
1. Ensure you have a PDF viewer app installed
2. Try opening with a different PDF app
3. Re-download the report
4. Check if file size is reasonable (should be > 0 bytes)

## Testing the Feature

### Quick Test
1. Open SNS HR app as admin
2. Navigate to **Analytics & Reports**
3. Click **"Generate Report"** (uses last 30 days by default)
4. Wait for success message
5. Tap **"Open"** to view the report immediately
6. Use file manager to check the app's Reports folder for saved files

### Custom Date Range Test
1. Tap the date range button (shows "Last 30d")
2. Select custom start and end dates
3. Generate report
4. Verify filename includes your custom date range

## Future Enhancements

### Planned Features
- **Excel Format**: Export to Excel for advanced analysis
- **Email Reports**: Send reports directly via email
- **Scheduled Reports**: Automatic generation at intervals
- **Chart Integration**: Include visual charts in PDF reports
- **Custom Templates**: Configurable report layouts
- **Department Filtering**: Reports by specific departments

### Data Expansion
- **Break Time Analysis**: Detailed break patterns
- **Location Tracking**: Work location analytics
- **Performance Metrics**: Productivity indicators
- **Cost Analysis**: Labor cost breakdowns

## API Reference

### Generate Report Endpoint

```http
GET /api/analytics/admin/generate-report?start=2024-01-01&end=2024-01-31&format=pdf
Authorization: Bearer <admin_jwt_token>
```

**Response (PDF):**
```
Content-Type: application/pdf
Content-Disposition: attachment; filename="analytics-report-2024-01-01-to-2024-01-31.pdf"
```

**Response (JSON):**
```json
{
  "reportPeriod": {
    "start": "2024-01-01",
    "end": "2024-01-31"
  },
  "summary": {
    "totalHours": 160.5,
    "overtimeHours": 12.0,
    "absenceRate": 5.2,
    "presentDays": 22,
    "absentDays": 1,
    "leaveDays": 2
  },
  "employees": {
    "total": 25,
    "active": 23,
    "inactive": 2
  }
}
```

## Integration Notes

### Mobile App Integration
- Seamless integration with existing analytics UI
- Native file download handling
- Responsive design for all screen sizes

### Web Compatibility
- Cross-browser PDF download support
- Progressive web app features
- Accessible design standards

---

## Version History

- **v1.9.0**: Initial release of report generation
- **Date**: January 2025
- **Status**: ✅ Production Ready

## Support

For technical support or feature requests related to analytics reporting:
- Create an issue in the project repository
- Contact the development team
- Check the troubleshooting section above

---

*This feature enhances the analytics capabilities of the SNS Rooster HR Management System by providing comprehensive reporting tools for administrators.* 