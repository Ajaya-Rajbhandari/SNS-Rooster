# Payroll Auto-Generation & Cycle Settings

Introduced in July 2025.

## Overview
The backend now creates draft payslips automatically on each pay-run day, based on the organisation's Payroll Cycle settings.  Admins can review / edit these drafts from **Admin ▸ Payroll Management**.

## Key Pieces
1. **Payroll Cycle Settings** (`/admin/settings/payroll-cycle`)
   • Frequency – Monthly | Semi-Monthly | Bi-Weekly | Weekly (all frequencies fully supported)  
   • Cut-off Day / Pay Day / Pay Weekday (+ optional offset)  
   • Default Hourly Rate (configurable fallback for employees without individual rates)
   • Enable Overtime & multiplier  
   • Auto-Generate Payslips (switch)

2. **Employee Model** (`models/Employee.js`)
   • Added fields `hourlyRate` and `monthlySalary` (defaults 0).  
   • Hourly rate can be set when adding/editing an employee in the admin UI.

3. **Scheduler** (`scheduler.js`)
   • Node-Cron job runs **02:00 server time** (`0 2 * * *`).  
   • Logic:  
     – Checks `AdminSettings.payrollCycle.autoGenerate`.  
     – Calculates whether *today* equals the configured pay-run day.  
     – For each active employee:  
       – Determines current period (`periodStart`, `periodEnd`).  
       – Totals attendance hours.  
       – Computes `grossPay = totalHours × hourlyRate` (or `defaultHourlyRate`).  
       – Creates a draft `Payroll` document (`status: pending`, `issueDate: today`).  
       – Skips if a payslip for that employee & period already exists.

4. **Exports** (PDF / CSV)  
   Download endpoints now accept `?start=` & `end=` query params, allowing **Cycle PDF / CSV** buttons in Payroll Management to fetch just the current period.

## Testing the Job
```bash
# Run once manually (uses existing Mongo connection)
node -e "require('./server'); const s=require('./scheduler'); s.generatePayslips().then(()=>process.exit());"
```
Set `payDay` (monthly) or `payWeekday` (weekly) to today and `autoGenerate=true` to force creation.

## Tax Configuration (NEW)
• **Tax Settings** (`/admin/settings/tax`) - Complete tax configuration system
  - Progressive income tax brackets with unlimited tiers
  - Social security contributions with optional caps
  - Custom flat tax rates (healthcare, municipal, etc.)
  - Currency and calculation method settings
• **Automatic Tax Calculations** - Scheduler now calculates accurate net pay
  - Income tax based on progressive brackets
  - Social security with rate and cap limits
  - All configured flat taxes applied automatically
  - Detailed tax breakdown in payslip records

## Company Information Settings (NEW)
• **Company Settings** (`/admin/settings/company`) - Complete company branding system
  - Company logo upload with image validation (JPEG, PNG, GIF up to 5MB)
  - Basic information: name, legal name, industry, size, description
  - Contact details: address, phone, email, website
  - Legal information: tax ID, registration number, established year
• **Payslip Branding** - Company information automatically included in payrolls
  - Company name, logo, and contact details on all payslips
  - Professional document appearance with custom branding
  - Logo served through secure static file serving

## Future Work
• Employee classification settings (full-time, part-time, contractor).
• Notifications on draft creation & publication.  
• Front-end banner showing last auto-generation run & upcoming pay-run.
• Holiday and weekend handling for payroll calculations.
• Advanced deduction templates and benefits management. 