# Test Company Creation Scripts

This directory contains scripts to create and test a company for the SNS Rooster application.

## Scripts Overview

### 1. `create-test-company.js`
Creates a test company with domain `snsrooster.com` for testing purposes.

**What it creates:**
- A company with domain `snsrooster.com` and subdomain `snsrooster`
- Professional subscription plan with trial status
- Complete feature set enabled (attendance, payroll, analytics, etc.)
- Default admin settings with company information
- 4 default break types (lunch, coffee, personal, meeting)

**Company Details:**
- **Name:** SNS Rooster Test Company
- **Domain:** snsrooster.com
- **Admin Email:** admin@snsrooster.com
- **Status:** Trial (14 days)
- **Subscription:** Professional plan
- **Max Employees:** 200
- **Max Storage:** 20GB

### 2. `test-company-creation.js`
Tests and validates the created company to ensure everything is working correctly.

**What it tests:**
- Company lookup by domain
- Feature availability
- Company context generation
- Admin settings validation
- Break types validation
- Company limits and settings
- Branding configuration

### 3. `cleanup-break-types.js`
Cleans up any existing break types that might cause duplicate key errors.

**What it does:**
- Removes break types without companyId
- Resolves duplicate break type names
- Shows final break type count by company
- Helps resolve E11000 duplicate key errors

## Usage

### Step 1: Clean Up Existing Data (if needed)

If you encounter duplicate key errors, run the cleanup script first:

```bash
# Navigate to the scripts directory
cd scripts

# Clean up existing break types
node cleanup-break-types.js
```

### Step 2: Create the Test Company

```bash
# Run the company creation script
node create-test-company.js
```

**Expected Output:**
```
Connected to MongoDB
✅ Test company created successfully!
Company ID: 507f1f77bcf86cd799439011
Company Name: SNS Rooster Test Company
Domain: snsrooster.com
Subdomain: snsrooster
Admin Email: admin@snsrooster.com
Status: trial
Subscription Plan: professional
Trial End Date: 2024-01-15T10:30:00.000Z

📋 Creating default admin settings...
✅ Admin settings created successfully!

☕ Creating default break types...
✅ Default break types created successfully!

🎉 Test company setup completed successfully!

📝 Summary:
- Company created with domain: snsrooster.com
- Admin settings configured
- 4 default break types created
- Company is in trial status

🔗 You can now test the application with this company context
```

### Step 3: Test the Company (Optional)

```bash
# Run the test script to validate everything
node test-company-creation.js
```

**Expected Output:**
```
Connected to MongoDB

🔍 Testing company lookup...
✅ Company found successfully!
Company ID: 507f1f77bcf86cd799439011
Company Name: SNS Rooster Test Company
Domain: snsrooster.com
Status: trial
Is Active: true

🔧 Testing company features...
Attendance enabled: true
Payroll enabled: true
Analytics enabled: true
API Access enabled: true

📋 Testing company context...
Company Context: {
  "id": "507f1f77bcf86cd799439011",
  "name": "SNS Rooster Test Company",
  "domain": "snsrooster.com",
  "subdomain": "snsrooster",
  "features": {...},
  "settings": {...},
  "branding": {...},
  "status": "trial"
}

⚙️ Testing admin settings...
✅ Admin settings found
Company Name: SNS Rooster Test Company
Max File Upload Size: 10 MB
Payroll Frequency: Monthly

☕ Testing break types...
✅ Found 4 break types:
  1. Lunch Break (lunch)
     Duration: 30-60 minutes
     Daily Limit: 1
     Is Paid: false
  2. Coffee Break (coffee)
     Duration: 5-15 minutes
     Daily Limit: 3
     Is Paid: true
  3. Personal Break (personal)
     Duration: 5-30 minutes
     Daily Limit: 2
     Is Paid: false
  4. Meeting Break (meeting)
     Duration: 15-120 minutes
     Daily Limit: 5
     Is Paid: true

📊 Testing company limits...
Max Employees: 200
Max Storage (GB): 20
Max API Calls/Day: 5000
Retention Days: 730

⏰ Testing company settings...
Timezone: America/New_York
Currency: USD
Working Hours: 09:00 - 17:00
Working Days: Monday, Tuesday, Wednesday, Thursday, Friday
Grace Period (minutes): 15

🎨 Testing company branding...
Company Name: SNS Rooster Test Company
Tagline: Innovative Workforce Management
Primary Color: #1976D2
Secondary Color: #424242

🎉 All tests passed successfully!

📝 Test Summary:
- Company lookup: ✅
- Feature checking: ✅
- Context generation: ✅
- Admin settings: ✅
- Break types: ✅
- Limits validation: ✅
- Settings validation: ✅
- Branding validation: ✅

🚀 The test company is ready for use!
You can now test the application with domain: snsrooster.com
```

## Testing the Application

Once the company is created, you can test the application using the domain `snsrooster.com`. The company context middleware will automatically resolve this domain to your test company.

### API Testing

You can test API endpoints by including the company context:

```bash
# Test company resolution
curl -X GET "http://localhost:3000/api/company/resolve?domain=snsrooster.com"

# Test with company header
curl -X GET "http://localhost:3000/api/attendance" \
  -H "X-Company-Id: YOUR_COMPANY_ID"
```

### Frontend Testing

For frontend testing, you can:
1. Set the hostname to `snsrooster.com` in your local development
2. Add an entry to your hosts file: `127.0.0.1 snsrooster.com`
3. Access the application via `http://snsrooster.com:3000`

## Cleanup

If you need to remove the test company:

```bash
# Connect to MongoDB and remove the company
mongo sns-rooster
> db.companies.deleteOne({domain: "snsrooster.com"})
> db.adminsettings.deleteMany({companyId: "COMPANY_ID"})
> db.breaktypes.deleteMany({companyId: "COMPANY_ID"})
```

## Notes

- The company is created with trial status and will expire after 14 days
- All features are enabled for comprehensive testing
- The company uses professional subscription limits
- Default break types are created for attendance testing
- Admin settings are pre-configured with realistic values
- The script is idempotent - running it multiple times won't create duplicates

## Troubleshooting

**Company already exists error:**
- The script will show existing company details and exit gracefully
- No duplicate companies will be created

**E11000 duplicate key error (break types):**
- This usually happens when there are existing break types without companyId
- Run the cleanup script first: `node cleanup-break-types.js`
- The script now handles this gracefully and skips existing break types

**MongoDB connection error:**
- Ensure MongoDB is running
- Check your `MONGODB_URI` environment variable
- Default fallback: `mongodb://localhost:27017/sns-rooster`

**Missing dependencies:**
- Ensure all required models are available
- Check that the Company, AdminSettings, and BreakType models exist

**Script improvements:**
- The scripts now check for existing data before creating new records
- Duplicate key errors are handled gracefully
- Better error messages and progress indicators 