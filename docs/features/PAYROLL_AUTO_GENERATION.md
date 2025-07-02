# Payroll Auto-Generation & Cycle Settings

Introduced in July 2025.

## Overview
The backend now creates draft payslips automatically on each pay-run day, based on the organisation's Payroll Cycle settings.  Admins can review / edit these drafts from **Admin ▸ Payroll Management**.

## Key Pieces
1. **Payroll Cycle Settings** (`/admin/settings/payroll-cycle`)
   • Frequency – Monthly | Weekly (bi-weekly & semi-monthly coming soon)  
   • Cut-off Day / Pay Day / Pay Weekday (+ optional offset)  
   • Enable Overtime & multiplier  
   • Auto-Generate Payslips (switch)  
   • Default Hourly Rate (optional-–pending UI)

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

## Future Work
• Extend scheduler to semi-monthly & bi-weekly frequencies.  
• Deduction templates & accurate net-pay calc.  
• Notifications on draft creation & publication.  
• Front-end banner showing last auto-generation run & upcoming pay-run. 