import 'package:flutter/material.dart';

class QuickActions extends StatelessWidget {
  final List<String> actions;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final void Function(String) onActionTap;

  const QuickActions({
    super.key,
    required this.actions,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final filteredActions = actions
        .where((action) =>
            action.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          decoration: InputDecoration(
            hintText: 'Search or start a quick action...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.grey[200],
          ),
          onChanged: onSearchChanged,
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: filteredActions
              .map((action) => ActionChip(
                    label: Text(action),
                    onPressed: () => onActionTap(action),
                  ))
              .toList(),
        ),
      ],
    );
  }
}
