import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/brand_mark.dart';
import 'sales_actions.dart';

/// Top bar: brand, SALES/REFUND pill, header actions. Turns red in refund mode.
class SalesHeader extends StatelessWidget {
  const SalesHeader({
    super.key,
    required this.companyName,
    required this.refund,
    required this.actions,
    this.compact = false,
  });

  final String companyName;
  final bool refund;
  final SalesActions actions;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final top = MediaQuery.paddingOf(context).top;
    return Container(
      height: 64 + top,
      padding: EdgeInsets.fromLTRB(compact ? 12 : 18, top, compact ? 8 : 14, 0),
      color: refund ? AppColors.dangerDeep : c.header,
      child: Row(
        children: [
          const BrandMark(size: 34, nameSize: 18),
          if (!compact) ...[
            const SizedBox(width: 12),
            Flexible(
              child: Text(companyName,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: c.headerMuted)),
            ),
          ],
          const Spacer(),
          _ModePill(refund: refund),
          const Spacer(),
          if (compact)
            PopupMenuButton<VoidCallback>(
              tooltip: 'Sales menu',
              icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
              onSelected: (action) => action(),
              itemBuilder: (_) => [
                PopupMenuItem(value: actions.transactions, child: const Text('Transactions')),
                PopupMenuItem(value: actions.noSale, child: const Text('No Sale')),
                PopupMenuItem(value: actions.logout, child: const Text('Logout')),
                PopupMenuItem(value: actions.endShift, child: const Text('End Shift')),
              ],
            )
          else ...[
            _HeaderButton(label: 'Transactions', icon: Icons.receipt_long_outlined, onTap: actions.transactions),
            _HeaderButton(label: 'No Sale', icon: Icons.point_of_sale_outlined, onTap: actions.noSale),
            _HeaderButton(label: 'Logout', icon: Icons.logout_rounded, onTap: actions.logout),
            _HeaderButton(label: 'End Shift', icon: Icons.power_settings_new_rounded, onTap: actions.endShift, danger: true),
          ],
        ],
      ),
    );
  }
}

class _ModePill extends StatelessWidget {
  const _ModePill({required this.refund});

  final bool refund;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: refund ? AppColors.danger : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(radius: 4, backgroundColor: refund ? Colors.white : AppColors.live),
            const SizedBox(width: 8),
            Text(refund ? 'REFUND' : 'SALES',
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
          ],
        ),
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({required this.label, required this.icon, required this.onTap, this.danger = false});

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Material(
        color: danger ? AppColors.danger : Colors.white.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: danger ? BorderSide.none : BorderSide(color: Colors.white.withValues(alpha: 0.14)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(icon, size: 17, color: Colors.white),
                const SizedBox(width: 7),
                Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RefundBanner extends StatelessWidget {
  const RefundBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.danger,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      child: const Row(
        children: [
          Icon(Icons.history_rounded, color: Colors.white, size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text('Refund mode — scanned items are refunded. Tap SALES to go back.',
                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class SalesFooter extends StatelessWidget {
  const SalesFooter({
    super.key,
    required this.loggedInAt,
    required this.terminal,
    required this.autoPrint,
    required this.userName,
    required this.refund,
  });

  final DateTime loggedInAt;
  final String terminal;
  final bool autoPrint;
  final String userName;
  final bool refund;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final style = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.7,
      color: c.headerMuted,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return Container(
      height: 34,
      color: refund ? AppColors.dangerDeep : c.header,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('LOG IN TIME: ${DateFormat('HH:mm').format(loggedInAt)}', style: style),
          Text('TERMINAL: $terminal', style: style),
          Text('AUTO PRINT: ${autoPrint ? 'ON' : 'OFF'}', style: style),
          LiveClock(pattern: "'TIME: 'HH:mm", style: style),
          Text('USER: ${userName.toUpperCase()}', style: style),
        ],
      ),
    );
  }
}
