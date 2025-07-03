import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EditAttendanceDialog extends StatefulWidget {
  final Map<String, dynamic> initialData;
  final void Function(Map<String, dynamic> updated) onSave;

  const EditAttendanceDialog(
      {Key? key, required this.initialData, required this.onSave})
      : super(key: key);

  @override
  State<EditAttendanceDialog> createState() => _EditAttendanceDialogState();
}

class _EditAttendanceDialogState extends State<EditAttendanceDialog> {
  late DateTime? _checkInTime;
  late DateTime? _checkOutTime;
  List<Map<String, dynamic>> _breaks = [];

  @override
  void initState() {
    super.initState();
    _checkInTime = widget.initialData['checkInTime'] != null
        ? DateTime.tryParse(widget.initialData['checkInTime'])
        : null;
    _checkOutTime = widget.initialData['checkOutTime'] != null
        ? DateTime.tryParse(widget.initialData['checkOutTime'])
        : null;
    if (widget.initialData['breaks'] != null &&
        widget.initialData['breaks'] is List) {
      _breaks =
          (widget.initialData['breaks'] as List).map<Map<String, dynamic>>((b) {
        final map = Map<String, dynamic>.from(b as Map);
        if (map['start'] != null) {
          map['start'] = DateTime.tryParse(map['start'].toString());
        }
        if (map['end'] != null) {
          map['end'] = DateTime.tryParse(map['end'].toString());
        }
        return map;
      }).toList();
    }
  }

  Future<void> _pickTime(BuildContext context, bool isCheckIn) async {
    final initial = isCheckIn ? _checkInTime : _checkOutTime;
    final now = DateTime.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: initial != null
          ? TimeOfDay(
              hour: initial.toLocal().hour, minute: initial.toLocal().minute)
          : TimeOfDay(hour: now.hour, minute: now.minute),
    );
    if (picked != null) {
      final baseDate = (isCheckIn
                  ? (_checkInTime ??
                      (widget.initialData['date'] != null
                          ? DateTime.tryParse(widget.initialData['date'])
                          : null))
                  : (_checkOutTime ??
                      (widget.initialData['date'] != null
                          ? DateTime.tryParse(widget.initialData['date'])
                          : null)))
              ?.toLocal() ??
          now;
      final localDt = DateTime(baseDate.year, baseDate.month, baseDate.day,
          picked.hour, picked.minute);
      final utcDt = localDt.toUtc();
      setState(() {
        if (isCheckIn) {
          _checkInTime = utcDt;
        } else {
          _checkOutTime = utcDt;
        }
      });
    }
  }

  Future<void> _pickBreakTime(int idx, bool isStart) async {
    final breakItem = _breaks[idx];
    final dt = isStart
        ? breakItem['start'] as DateTime?
        : breakItem['end'] as DateTime?;
    final now = DateTime.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: dt != null
          ? TimeOfDay(hour: dt.toLocal().hour, minute: dt.toLocal().minute)
          : TimeOfDay(hour: now.hour, minute: now.minute),
    );
    if (picked != null) {
      final baseDate = (dt ??
                  (widget.initialData['date'] != null
                      ? DateTime.tryParse(widget.initialData['date'])
                      : null))
              ?.toLocal() ??
          now;
      final localDt = DateTime(baseDate.year, baseDate.month, baseDate.day,
          picked.hour, picked.minute);
      final utcDt = localDt.toUtc();
      setState(() {
        if (isStart) {
          _breaks[idx]['start'] = utcDt;
        } else {
          _breaks[idx]['end'] = utcDt;
        }
      });
    }
  }

  void _addBreak() {
    setState(() {
      _breaks.add({'start': null, 'end': null});
    });
  }

  void _removeBreak(int idx) {
    setState(() {
      _breaks.removeAt(idx);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Attendance'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Check In'),
              subtitle: Text(_checkInTime != null
                  ? DateFormat('HH:mm').format(_checkInTime!.toLocal())
                  : '-'),
              trailing: IconButton(
                icon: const Icon(Icons.access_time),
                onPressed: () => _pickTime(context, true),
              ),
            ),
            ListTile(
              title: const Text('Check Out'),
              subtitle: Text(_checkOutTime != null
                  ? DateFormat('HH:mm').format(_checkOutTime!.toLocal())
                  : '-'),
              trailing: IconButton(
                icon: const Icon(Icons.access_time),
                onPressed: () => _pickTime(context, false),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Breaks',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: _addBreak,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Break'),
                ),
              ],
            ),
            ..._breaks.asMap().entries.map((entry) {
              final idx = entry.key;
              final b = entry.value;
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Break ${idx + 1}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            Row(
                              children: [
                                const Text('Start: '),
                                Text(b['start'] != null
                                    ? DateFormat('HH:mm').format(
                                        (b['start'] as DateTime).toLocal())
                                    : '-'),
                                IconButton(
                                  icon: const Icon(Icons.access_time),
                                  onPressed: () => _pickBreakTime(idx, true),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                const Text('End:   '),
                                Text(b['end'] != null
                                    ? DateFormat('HH:mm').format(
                                        (b['end'] as DateTime).toLocal())
                                    : '-'),
                                IconButton(
                                  icon: const Icon(Icons.access_time),
                                  onPressed: () => _pickBreakTime(idx, false),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _removeBreak(idx),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_checkInTime == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Check-in time is required.')),
              );
              return;
            }
            final updated = {
              'checkInTime': _checkInTime!.toIso8601String(),
              'checkOutTime': _checkOutTime?.toIso8601String(),
              'breaks': _breaks
                  .map((b) => {
                        'start': b['start'] != null
                            ? (b['start'] as DateTime).toIso8601String()
                            : null,
                        'end': b['end'] != null
                            ? (b['end'] as DateTime).toIso8601String()
                            : null,
                        if (b['type'] != null) 'type': b['type'],
                        if (b['reason'] != null) 'reason': b['reason'],
                        if (b['approvedBy'] != null)
                          'approvedBy': b['approvedBy'],
                      })
                  .toList(),
            };
            print('DEBUG: Saving attendance: $updated');
            widget.onSave(updated);
            Navigator.pop(context, updated);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
