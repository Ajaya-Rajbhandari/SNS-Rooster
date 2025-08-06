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

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final isUpcoming = _filter == 'Upcoming';
    final isPast = _filter == 'Past';
    final isMyEvents = _filter == 'My Events';

    String title;
    String subtitle;
    IconData icon;
    Color iconColor;

    if (isUpcoming) {
      title = 'No Upcoming Events';
      subtitle =
          'There are no upcoming events scheduled at the moment. Check back later for new events!';
      icon = Icons.event_busy;
      iconColor = Colors.orange;
    } else if (isPast) {
      title = 'No Past Events';
      subtitle = 'There are no past events to display.';
      icon = Icons.history;
      iconColor = Colors.grey;
    } else if (isMyEvents) {
      title = 'No Events Joined';
      subtitle =
          'You haven\'t joined any events yet. Browse available events and join the ones that interest you!';
      icon = Icons.person_off;
      iconColor = Colors.blue;
    } else {
      title = 'No Events Available';
      subtitle =
          'There are currently no events scheduled. Events will appear here once they are created by administrators.';
      icon = Icons.event_note;
      iconColor = theme.colorScheme.primary;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Large icon with background
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 60,
                color: iconColor,
              ),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Subtitle
            Text(
              subtitle,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Action buttons
            if (_filter != 'All') ...[
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _filter = 'All';
                  });
                },
                icon: const Icon(Icons.list),
                label: const Text('View All Events'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Refresh button
            OutlinedButton.icon(
              onPressed: _fetchEvents,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),

            // Additional info for different filters
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getFilterInfoText(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getFilterInfoText() {
    switch (_filter) {
      case 'Upcoming':
        return 'Upcoming events are those scheduled for future dates.';
      case 'Past':
        return 'Past events are those that have already occurred.';
      case 'My Events':
        return 'My Events shows events you have joined or are attending.';
      case 'Active':
        return 'Active events are currently ongoing or have started.';
      default:
        return 'All events from your organization will be displayed here.';
    }
  }

  Widget _buildLoadingState() {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated loading icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const CircularProgressIndicator(
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),

          // Loading text
          Text(
            'Loading Events...',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),

          Text(
            'Please wait while we fetch your events',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Error icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 50,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 24),

            // Error title
            Text(
              'Failed to Load Events',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Error message
            Text(
              _errorMessage ?? 'An unknown error occurred',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Retry button
            ElevatedButton.icon(
              onPressed: _fetchEvents,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),

            const SizedBox(height: 16),

            // Alternative action
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _errorMessage = null;
                  _isLoading = true;
                });
                _fetchEvents();
              },
              icon: const Icon(Icons.settings),
              label: const Text('Check Connection'),
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
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
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.filter_list,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Filter Events',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withValues(alpha: 0.3),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<String>(
                    value: _filter,
                    underline: const SizedBox.shrink(),
                    icon: Icon(
                      Icons.keyboard_arrow_down,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    items: [
                      {
                        'value': 'All',
                        'label': 'All Events',
                        'icon': Icons.list
                      },
                      {
                        'value': 'Upcoming',
                        'label': 'Upcoming',
                        'icon': Icons.event
                      },
                      {
                        'value': 'Active',
                        'label': 'Active Now',
                        'icon': Icons.play_circle
                      },
                      {
                        'value': 'Past',
                        'label': 'Past Events',
                        'icon': Icons.history
                      },
                      {
                        'value': 'My Events',
                        'label': 'My Events',
                        'icon': Icons.person
                      },
                    ]
                        .map((item) => DropdownMenuItem(
                              value: item['value'] as String,
                              child: Row(
                                children: [
                                  Icon(
                                    item['icon'] as IconData,
                                    size: 18,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(item['label'] as String),
                                ],
                              ),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _filter = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          // Events list
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _errorMessage != null
                    ? _buildErrorState()
                    : _getFilteredEvents().isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            onRefresh: _fetchEvents,
                            child: ListView.builder(
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
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
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
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 14,
                          color: Colors.orange[700],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Upcoming',
                          style: TextStyle(
                            color: Colors.orange[700],
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
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
