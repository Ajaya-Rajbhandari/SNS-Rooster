import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class LeaveRequestModal extends StatefulWidget {
  final DateTime? initialFromDate;
  final DateTime? initialToDate;
  final String? initialLeaveType;
  final TextEditingController reasonController;
  final Function(
    DateTime fromDate,
    DateTime toDate,
    String leaveType,
    String reason,
  ) onSubmit;
  final bool disablePastDates; // Added parameter to disable past dates

  const LeaveRequestModal({
    super.key,
    this.initialFromDate,
    this.initialToDate,
    this.initialLeaveType,
    required this.reasonController,
    required this.onSubmit,
    this.disablePastDates = false, // Default value
  });

  @override
  State<LeaveRequestModal> createState() => _LeaveRequestModalState();
}

class _LeaveRequestModalState extends State<LeaveRequestModal> {
  DateTime? fromDate;
  DateTime? toDate;
  String? leaveType;
  bool isFromDateError = false;
  bool isToDateError = false;
  bool isLeaveTypeError = false;
  bool isReasonError = false;

  @override
  void initState() {
    super.initState();
    fromDate = widget.initialFromDate;
    toDate = widget.initialToDate;
    leaveType = widget.initialLeaveType;
  }

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: widget.disablePastDates ? DateTime.now() : DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != (isFromDate ? fromDate : toDate)) {
      setState(() {
        if (isFromDate) {
          fromDate = picked;
        } else {
          toDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        top: 16.0,
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'New Leave Request',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              readOnly: true,
              controller: TextEditingController(
                text: fromDate != null
                    ? DateFormat('yyyy-MM-dd').format(fromDate!)
                    : '',
              ),
              decoration: InputDecoration(
                labelText: 'From Date',
                prefixIcon: Icon(Icons.calendar_today),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: isFromDateError ? Colors.red : Colors.grey,
                  ),
                ),
                hintText: 'Select a date',
              ),
              onTap: () => _selectDate(context, true),
            ),
            const SizedBox(height: 16),
            TextField(
              readOnly: true,
              controller: TextEditingController(
                text: toDate != null
                    ? DateFormat('yyyy-MM-dd').format(toDate!)
                    : '',
              ),
              decoration: InputDecoration(
                labelText: 'To Date',
                prefixIcon: Icon(Icons.calendar_today),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: isToDateError ? Colors.red : Colors.grey,
                  ),
                ),
                hintText: 'Select a date',
              ),
              onTap: () => _selectDate(context, false),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Leave Type',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: isLeaveTypeError ? Colors.red : Colors.grey,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: isLeaveTypeError ? Colors.red : Colors.blue,
                  ),
                ),
              ),
              items: [
                DropdownMenuItem(
                  value: 'Sick Leave',
                  child: Text('Sick Leave'),
                ),
                DropdownMenuItem(
                  value: 'Casual Leave',
                  child: Text('Casual Leave'),
                ),
                DropdownMenuItem(
                  value: 'Paid Leave',
                  child: Text('Paid Leave'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  leaveType = value;
                  isLeaveTypeError = false;
                });
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: widget.reasonController,
              decoration: InputDecoration(
                labelText: 'Reason',
                prefixIcon: Icon(Icons.edit),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: isReasonError ? Colors.red : Colors.grey,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: isReasonError ? Colors.red : Colors.grey,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: isReasonError ? Colors.red : Colors.blue,
                  ),
                ),
                helperText: isReasonError ? 'Reason is required' : null,
                helperStyle: TextStyle(color: Colors.red),
              ),
              onChanged: (value) {
                setState(() {
                  isReasonError = value.isEmpty;
                });
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  isFromDateError = fromDate == null;
                  isToDateError = toDate == null;
                  isLeaveTypeError = leaveType == null;
                  isReasonError = widget.reasonController.text.isEmpty;
                });

                if (isFromDateError ||
                    isToDateError ||
                    isLeaveTypeError ||
                    isReasonError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Please fill all required fields before submitting.',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (toDate!.isBefore(fromDate!)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'To Date cannot be earlier than From Date.',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                widget.onSubmit(
                  fromDate!,
                  toDate!,
                  leaveType!,
                  widget.reasonController.text,
                );
              },
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
                backgroundColor: Theme.of(context).primaryColor,
                textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              child: const Text(
                'Submit',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'All fields are mandatory.',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
