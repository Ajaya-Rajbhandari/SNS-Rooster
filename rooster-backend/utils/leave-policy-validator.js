const moment = require('moment');

/**
 * Validate leave request dates and options against a leave-policy document.
 * @param {Object} policy Mongo document from LeavePolicy collection
 * @param {Date} start requested startDate (JS Date)
 * @param {Date} end requested endDate (JS Date)
 * @param {Boolean} isHalfDay true if employee wants half-day
 * @returns {null|string} null if valid, otherwise string with error message
 */
function validateLeaveAgainstPolicy(policy, start, end, isHalfDay = false) {
  if (!policy || !policy.rules) return null; // no rules – allow everything
  const rules = policy.rules;

  // Half-day allowed
  if (isHalfDay && rules.allowHalfDays === false) {
    return 'Half-day leave is not allowed by company policy.';
  }

  // minNoticeDays (compare dates ignoring time)
  if (rules.minNoticeDays != null) {
    const today = moment().startOf('day');
    const minStart = moment(today).add(rules.minNoticeDays, 'days');
    if (moment(start).isBefore(minStart)) {
      return `Leave requests must be submitted at least ${rules.minNoticeDays} day(s) in advance.`;
    }
  }

  // maxConsecutiveDays
  if (rules.maxConsecutiveDays != null) {
    const daysRequested = moment(end).endOf('day').diff(moment(start).startOf('day'), 'days') + 1;
    if (daysRequested > rules.maxConsecutiveDays) {
      return `Leave duration exceeds the maximum of ${rules.maxConsecutiveDays} consecutive days.`;
    }
  }
  return null;
}

module.exports = { validateLeaveAgainstPolicy }; 