/**
 * Tax Calculator Utility
 * Calculates various taxes based on configured tax settings
 */

/**
 * Calculate income tax based on progressive brackets
 * @param {number} grossIncome - The gross income amount
 * @param {Array} brackets - Array of tax brackets {minAmount, maxAmount, rate, description}
 * @returns {Object} - {tax: number, details: Array}
 */
function calculateIncomeTax(grossIncome, brackets = []) {
  if (!brackets || brackets.length === 0) {
    return { tax: 0, details: [] };
  }

  let totalTax = 0;
  const details = [];

  // Sort brackets by minAmount to ensure correct calculation
  const sortedBrackets = brackets.sort((a, b) => a.minAmount - b.minAmount);

  for (const bracket of sortedBrackets) {
    const { minAmount, maxAmount, rate, description } = bracket;
    
    // Skip if income is below this bracket
    if (grossIncome <= minAmount) {
      continue;
    }

    // Calculate taxable amount in this bracket
    const upperLimit = maxAmount || grossIncome;
    const taxableAmount = Math.min(grossIncome, upperLimit) - minAmount;
    
    if (taxableAmount > 0) {
      const bracketTax = (taxableAmount * rate) / 100;
      totalTax += bracketTax;
      
      details.push({
        bracket: description || `${minAmount} - ${maxAmount || 'unlimited'}`,
        rate: rate,
        taxableAmount: taxableAmount,
        tax: bracketTax
      });
    }
  }

  return {
    tax: Math.round(totalTax * 100) / 100, // Round to 2 decimal places
    details: details
  };
}

/**
 * Calculate social security contribution
 * @param {number} grossIncome - The gross income amount
 * @param {number} rate - Social security rate as percentage
 * @param {number|null} cap - Annual cap amount (null for no cap)
 * @returns {Object} - {tax: number, details: Object}
 */
function calculateSocialSecurity(grossIncome, rate = 0, cap = null) {
  if (rate === 0) {
    return { tax: 0, details: { rate: 0, cappedAt: null, taxableAmount: 0 } };
  }

  let taxableAmount = grossIncome;
  let cappedAt = null;

  // Apply cap if specified
  if (cap && grossIncome > cap) {
    taxableAmount = cap;
    cappedAt = cap;
  }

  const tax = (taxableAmount * rate) / 100;

  return {
    tax: Math.round(tax * 100) / 100,
    details: {
      rate: rate,
      cappedAt: cappedAt,
      taxableAmount: taxableAmount
    }
  };
}

/**
 * Calculate flat tax rates
 * @param {number} grossIncome - The gross income amount
 * @param {Array} flatRates - Array of flat tax rates {name, rate, enabled}
 * @returns {Object} - {totalTax: number, details: Array}
 */
function calculateFlatTaxes(grossIncome, flatRates = []) {
  let totalTax = 0;
  const details = [];

  for (const rate of flatRates) {
    if (!rate.enabled) continue;

    const tax = (grossIncome * rate.rate) / 100;
    totalTax += tax;

    details.push({
      name: rate.name,
      rate: rate.rate,
      tax: Math.round(tax * 100) / 100
    });
  }

  return {
    totalTax: Math.round(totalTax * 100) / 100,
    details: details
  };
}

/**
 * Calculate all taxes for a given gross income
 * @param {number} grossIncome - The gross income amount
 * @param {Object} taxSettings - The tax configuration settings
 * @returns {Object} - Complete tax breakdown
 */
function calculateAllTaxes(grossIncome, taxSettings = {}) {
  const result = {
    grossIncome: grossIncome,
    totalTaxes: 0,
    netIncome: grossIncome,
    breakdown: {
      incomeTax: { tax: 0, details: [] },
      socialSecurity: { tax: 0, details: {} },
      flatTaxes: { totalTax: 0, details: [] }
    }
  };

  // Return early if taxes are disabled
  if (!taxSettings.enabled) {
    return result;
  }

  // Calculate Income Tax
  if (taxSettings.incomeTaxEnabled && taxSettings.incomeTaxBrackets) {
    result.breakdown.incomeTax = calculateIncomeTax(
      grossIncome, 
      taxSettings.incomeTaxBrackets
    );
  }

  // Calculate Social Security
  if (taxSettings.socialSecurityEnabled) {
    result.breakdown.socialSecurity = calculateSocialSecurity(
      grossIncome,
      taxSettings.socialSecurityRate || 0,
      taxSettings.socialSecurityCap
    );
  }

  // Calculate Flat Taxes
  if (taxSettings.flatTaxRates && taxSettings.flatTaxRates.length > 0) {
    result.breakdown.flatTaxes = calculateFlatTaxes(
      grossIncome,
      taxSettings.flatTaxRates
    );
  }

  // Calculate totals
  result.totalTaxes = 
    result.breakdown.incomeTax.tax +
    result.breakdown.socialSecurity.tax +
    result.breakdown.flatTaxes.totalTax;

  result.netIncome = grossIncome - result.totalTaxes;

  // Round final amounts
  result.totalTaxes = Math.round(result.totalTaxes * 100) / 100;
  result.netIncome = Math.round(result.netIncome * 100) / 100;

  return result;
}

/**
 * Generate detailed deductions list for payroll
 * @param {Object} taxCalculation - Result from calculateAllTaxes
 * @param {string} currencySymbol - Currency symbol for formatting
 * @returns {Array} - Array of deduction objects for payroll
 */
function generateDeductionsList(taxCalculation, currencySymbol = 'Rs.') {
  const deductions = [];

  // Add income tax deductions
  if (taxCalculation.breakdown.incomeTax.tax > 0) {
    deductions.push({
      type: 'Income Tax',
      amount: taxCalculation.breakdown.incomeTax.tax
    });
  }

  // Add social security deductions
  if (taxCalculation.breakdown.socialSecurity.tax > 0) {
    deductions.push({
      type: 'Social Security',
      amount: taxCalculation.breakdown.socialSecurity.tax
    });
  }

  // Add flat tax deductions
  for (const flatTax of taxCalculation.breakdown.flatTaxes.details) {
    if (flatTax.tax > 0) {
      deductions.push({
        type: flatTax.name,
        amount: flatTax.tax
      });
    }
  }

  return deductions;
}

module.exports = {
  calculateIncomeTax,
  calculateSocialSecurity,
  calculateFlatTaxes,
  calculateAllTaxes,
  generateDeductionsList
}; 