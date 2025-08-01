import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../config/api_config.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/admin_side_navigation.dart';

class EmployeeEventsScreen extends StatefulWidget {
  const EmployeeEventsScreen({super.key});

  @override
  State<EmployeeEventsScreen> createState() => _EmployeeEventsScreenState();
}

class _EmployeeEventsScreenState extends State<EmployeeEventsScreen> {
  List<Map<String, dynamic>> _events = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _filter = 'All'; // All, Upcoming, Past, My Events

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      final userId = authProvider.user?['_id'];

      if (token == null || userId == null) {
        throw Exception('Authentication required');
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/events'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _events = List<Map<String, dynamic>>.from(data['events'] ?? []);
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load events: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _joinEvent(String eventId) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      final userId = authProvider.user?['_id'];

      if (token == null || userId == null) {
        throw Exception('Authentication required');
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/events/$eventId/attendees'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'userId': userId,
        }),
      );

      if (response.statusCode == 200) {
        // Refresh events to update attendance status
        _fetchEvents();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully joined event!')),
        );
      } else {
        throw Exception('Failed to join event: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error joining event: $e')),
      );
    }
  }

  Future<void> _leaveEvent(String eventId) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      final userId = authProvider.user?['_id'];

      if (token == null || userId == null) {
        throw Exception('Authentication required');
      }

      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/events/$eventId/attendees/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        // Refresh events to update attendance status
        _fetchEvents();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully left event!')),
        );
      } else {
        throw Exception('Failed to leave event: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error leaving event: $e')),
      );
    }
  }

  List<Map<String, dynamic>> _getFilteredEvents() {
    final now = DateTime.now();
    final userId =
        Provider.of<AuthProvider>(context, listen: false).user?['_id'];

    switch (_filter) {
      case 'Upcoming':
        return _events.where((event) {
          final eventDate = DateTime.parse(event['startDate'] ?? '');
          return eventDate.isAfter(now);
        }).toList();
      case 'Past':
        return _events.where((event) {
          final eventDate = DateTime.parse(event['startDate'] ?? '');
          return eventDate.isBefore(now);
        }).toList();
      case 'Active':
        return _events.where((event) {
          final eventDate = DateTime.parse(event['startDate'] ?? '');
          return eventDate.isBefore(now) || eventDate.isAtSameMomentAs(now);
        }).toList();
      case 'My Events':
        return _events.where((event) {
          final attendees =
              List<Map<String, dynamic>>.from(event['attendees'] ?? []);
          return attendees.any((attendee) => attendee['user'] == userId);
        }).toList();
      default:
        return _events;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Not logged in. Please log in.')),
      );
    }
    final isAdmin = user['role'] == 'admin';
    if (isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Events')),
        body: const Center(child: Text('Access denied')),
        drawer: const AdminSideNavigation(currentRoute: '/events'),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Events'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchEvents,
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          // Filter section
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text('Filter: ',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _filter,
                  items: ['All', 'Upcoming', 'Active', 'Past', 'My Events']
                      .map((filter) => DropdownMenuItem(
                            value: filter,
                            child: Text(filter),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _filter = value!;
                    });
                  },
                ),
              ],
            ),
          ),
          // Events list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Error: $_errorMessage'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _fetchEvents,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _getFilteredEvents().isEmpty
                        ? const Center(
                            child: Text('No events found.'),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _getFilteredEvents().length,
                            itemBuilder: (context, index) {
                              final event = _getFilteredEvents()[index];
                              return _EventCard(
                                event: event,
                                onJoin: () => _joinEvent(event['_id']),
                                onLeave: () => _leaveEvent(event['_id']),
                                currentUserId: authProvider.user?['_id'],
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final Map<String, dynamic> event;
  final VoidCallback onJoin;
  final VoidCallback onLeave;
  final String? currentUserId;

  const _EventCard({
    required this.event,
    required this.onJoin,
    required this.onLeave,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final eventDate = DateTime.parse(event['startDate'] ?? '');
    final now = DateTime.now();
    final isUpcoming = eventDate.isAfter(now);
    final isStarted =
        eventDate.isBefore(now) || eventDate.isAtSameMomentAs(now);
    final canJoin = isStarted && !isUpcoming; // Can join when event has started
    final attendees = List<Map<String, dynamic>>.from(event['attendees'] ?? []);
    final isAttending =
        attendees.any((attendee) => attendee['user'] == currentUserId);
    final isPublic = event['isPublic'] ?? false;
    final createdBy = event['createdBy'];

    // Debug logging
    print(
        'Event debug: ${event['title']} - isUpcoming: $isUpcoming, isStarted: $isStarted, canJoin: $canJoin, isPublic: $isPublic, createdBy: $createdBy, currentUserId: $currentUserId, isAttending: $isAttending');

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event['title'] ?? 'Untitled Event',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        event['description'] ?? 'No description',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (isPublic)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Public',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  DateFormat('MMM dd, yyyy').format(eventDate),
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(width: 16),
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  DateFormat('HH:mm').format(eventDate),
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
            if (event['location'] != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    event['location'],
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.people, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  '${attendees.length} attending',
                  style: theme.textTheme.bodyMedium,
                ),
                const Spacer(),
                if (canJoin)
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: isAttending ? onLeave : onJoin,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isAttending
                              ? Colors.red
                              : theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isAttending ? 'Leave' : 'Join',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  )
                else if (isUpcoming)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Upcoming',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
