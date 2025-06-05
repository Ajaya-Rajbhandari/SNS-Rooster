// Placeholder for leave request screen
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sns_rooster/widgets/navigation_drawer.dart';

class LeaveRequestScreen extends StatefulWidget {
  const LeaveRequestScreen({Key? key}) : super(key: key);

  @override
  State<LeaveRequestScreen> createState() => _LeaveRequestScreenState();
}

class _LeaveRequestScreenState extends State<LeaveRequestScreen> {
  DateTime? fromDate;
  DateTime? toDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Mock data for leave requests
    final leaveRequests = List.generate(5, (index) => {
          'date': '2025-06-${index + 10}',
          'status': index % 2 == 0 ? 'Approved' : 'Pending',
        });

    final approvedCount = leaveRequests.where((req) => req['status'] == 'Approved').length;
    final pendingCount = leaveRequests.length - approvedCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave Requests'),
        backgroundColor: theme.primaryColor,
      ),
      drawer: const AppNavigationDrawer(),
      backgroundColor: theme.colorScheme.background,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _SummaryTile(label: 'Total', value: '${leaveRequests.length}'),
                    _SummaryTile(label: 'Approved', value: '$approvedCount'),
                    _SummaryTile(label: 'Pending', value: '$pendingCount'),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search leave requests...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onChanged: (value) {
                // Add search logic here
              },
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: leaveRequests.length,
              itemBuilder: (context, index) {
                final request = leaveRequests[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 1,
                  child: ListTile(
                    leading: Icon(
                      Icons.calendar_today,
                      color: request['status'] == 'Approved' ? Colors.green : Colors.orange,
                    ),
                    title: Text('Leave Date: ${request['date']}'),
                    subtitle: Text('Status: ${request['status']}'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      // Navigate to detailed leave request view
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (context) {
              return SafeArea(
                child: Padding(
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
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          readOnly: true,
                          controller: TextEditingController(
                            text: fromDate != null ? DateFormat('yyyy-MM-dd').format(fromDate!) : '',
                          ),
                          decoration: InputDecoration(
                            labelText: 'From Date',
                            prefixIcon: Icon(Icons.calendar_today),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            hintText: 'Select a date',
                          ),
                          onTap: () async {
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (pickedDate != null) {
                              setState(() {
                                fromDate = pickedDate;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          readOnly: true,
                          controller: TextEditingController(
                            text: toDate != null ? DateFormat('yyyy-MM-dd').format(toDate!) : '',
                          ),
                          decoration: InputDecoration(
                            labelText: 'To Date',
                            prefixIcon: Icon(Icons.calendar_today),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            hintText: 'Select a date',
                          ),
                          onTap: () async {
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate: fromDate ?? DateTime.now(),
                              firstDate: fromDate ?? DateTime.now(),
                              lastDate: DateTime(2100),
                            );
                            if (pickedDate != null) {
                              setState(() {
                                toDate = pickedDate;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'Leave Type',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          items: [
                            DropdownMenuItem(value: 'Sick Leave', child: Text('Sick Leave')),
                            DropdownMenuItem(value: 'Casual Leave', child: Text('Casual Leave')),
                            DropdownMenuItem(value: 'Paid Leave', child: Text('Paid Leave')),
                          ],
                          onChanged: (value) {
                            // Handle leave type selection
                          },
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          decoration: InputDecoration(
                            labelText: 'Reason',
                            prefixIcon: Icon(Icons.edit),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            if (fromDate == null || toDate == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Please select both From Date and To Date before submitting.'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            // Add logic to save the leave request
                            Navigator.pop(context);

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Leave request submitted successfully!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size(double.infinity, 50),
                          ),
                          child: const Text('Submit Request'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        backgroundColor: theme.primaryColor,
        icon: const Icon(Icons.add),
        label: const Text('New Request'),
      ),
    );
  }

  Widget _buildNavTile(BuildContext context, {required IconData icon, required String label, required String route, Widget? trailing}) {
    final theme = Theme.of(context);
    final isSelected = ModalRoute.of(context)?.settings.name == route;
    return ListTile(
      leading: Icon(icon, color: isSelected ? theme.colorScheme.primary : Colors.blueGrey, size: 26),
      title: Text(label, style: TextStyle(
        color: isSelected ? theme.colorScheme.primary : Colors.blueGrey[900],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 16,
      )),
      trailing: trailing,
      selected: isSelected,
      selectedTileColor: theme.colorScheme.primary.withOpacity(0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onTap: () {
        Navigator.pop(context);
        if (ModalRoute.of(context)?.settings.name != route) {
          Navigator.pushNamed(context, route);
        }
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
      horizontalTitleGap: 12,
      minLeadingWidth: 0,
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[700]),
        ),
      ],
    );
  }
}
