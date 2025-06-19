/// LiveClock widget displays the current time and updates every second.
///
/// This widget is isolated so that only the clock text rebuilds every second,
/// preventing unnecessary rebuilds of the parent widget tree.
import 'package:flutter/material.dart';

class LiveClock extends StatelessWidget {
  const LiveClock({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Stream.periodic(const Duration(seconds: 1)),
      builder: (context, snapshot) {
        final now = TimeOfDay.now();
        return Text(
          now.format(context),
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        );
      },
    );
  }
}
