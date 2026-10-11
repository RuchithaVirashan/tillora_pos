import 'package:material_ui/material_ui.dart';

import '../reports/shift_summary.dart';
import '../theme/app_theme.dart';
import '../utils/money.dart';

/// Shift report as cards: cash flow, department, activity, hourly sale.
/// [columns] is 1 on phones, 2 on tablets, 3 on desktop.
class ShiftSummarySections extends StatelessWidget {
  const ShiftSummarySections({super.key, required this.summary, required this.columns});

  final ShiftSummary summary;
  final int columns;

  static String _rs(int cents) => Money.lkr(Money.fromCents(cents));

  static String _hour(int h) => '${h.toString().padLeft(2, '0')}:00';

  @override
  Widget build(BuildContext context) {
    final s = summary;
    final sections = <(String, List<(String, String)>, int)>[
      (
        'CASH FLOW',
        [
          ('Drawer float', _rs(s.drawerFloatCents)),
          for (final e in s.salesByMethod.entries) ('${e.key} sales', _rs(e.value)),
          ('Refunds', _rs(s.refundsCents)),
          ('Cash lifts', _rs(s.cashLiftsCents)),
          ('Expected in drawer', _rs(s.expectedInDrawerCents)),
        ],
        1,
      ),
      (
        'DEPARTMENT',
        s.salesByDepartment.isEmpty ? [('No sales', '')] : [for (final e in s.salesByDepartment.entries) (e.key, _rs(e.value))],
        1,
      ),
      (
        'ACTIVITY',
        [
          ('Transactions', '${s.transactionCount}'),
          ('Total takings', _rs(s.totalCents)),
          ('No sales', '${s.noSaleCount}'),
          ('Void lines', '${s.voidLineCount}'),
          ('Void sales', '${s.voidSaleCount}'),
        ],
        1,
      ),
      (
        'HOURLY SALE',
        s.salesByHour.isEmpty
            ? [('No sales', '')]
            : [for (final e in s.salesByHour.entries) ('${_hour(e.key)} – ${_hour(e.key + 1)}', _rs(e.value))],
        columns > 1 ? 2 : 1,
      ),
    ];

    return LayoutBuilder(
      builder: (context, box) {
        const gap = 14.0;
        final unit = (box.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final (title, rows, span) in sections)
              SizedBox(width: unit * span + gap * (span - 1), child: _SectionCard(title: title, rows: rows)),
          ],
        );
      },
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.rows});

  final String title;
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), border: Border.all(color: c.line)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1, color: c.muted)),
          const SizedBox(height: 6),
          for (final (label, value) in rows)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.rowLine))),
              child: Row(
                children: [
                  Expanded(child: Text(label, style: TextStyle(fontSize: 14, color: c.ink))),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: c.ink,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
