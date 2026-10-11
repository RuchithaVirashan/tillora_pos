import 'dart:async';

import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';

/// Amber rounded square with the Tillora bag, plus the wordmark.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 38, this.showName = true, this.nameSize = 21});

  final double size;
  final bool showName;
  final double nameSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: AppColors.amber, borderRadius: BorderRadius.circular(size * 0.29)),
          child: Icon(Icons.shopping_basket_outlined, size: size * 0.53, color: AppColors.navy),
        ),
        if (showName) ...[
          const SizedBox(width: 12),
          Text('Tillora', style: TextStyle(fontSize: nameSize, fontWeight: FontWeight.w800, color: Colors.white)),
        ],
      ],
    );
  }
}

/// Text that re-renders every [interval] with the current time.
class LiveClock extends StatefulWidget {
  const LiveClock({super.key, this.pattern = 'd MMM y · HH:mm', this.style, this.interval = const Duration(seconds: 15)});

  final String pattern;
  final TextStyle? style;
  final Duration interval;

  @override
  State<LiveClock> createState() => _LiveClockState();
}

class _LiveClockState extends State<LiveClock> {
  late final Timer _timer;
  late final DateFormat _format = DateFormat(widget.pattern);

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(widget.interval, (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Text(_format.format(DateTime.now()), style: widget.style);
}
