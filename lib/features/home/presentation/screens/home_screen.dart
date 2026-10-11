import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/di/injector.dart';
import '../../../../app/router/routes.dart';
import '../../../../core/config/terminal_info.dart';
import '../../../../core/responsive/breakpoints.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/brand_mark.dart';
import '../widgets/home_tile.dart';

/// Home launcher, Main.dc.html.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _tiles = [
    HomeTileData('Product Management', 'Non-barcode, weight, payout, price change', Icons.inventory_2_outlined, HomeTint.blue, 'products'),
    HomeTileData('Suppliers', 'Supplier details', Icons.local_shipping_outlined, HomeTint.teal, Routes.suppliers),
    HomeTileData('Back Office', 'Management, inventory, promotions, reports', Icons.grid_view_rounded, HomeTint.violet, 'back-office'),
    HomeTileData('Quick Report', 'Live shift, all shifts, exceptions', Icons.bar_chart_rounded, HomeTint.green, 'reports'),
    HomeTileData('Staff Activity', 'Who is on shift', Icons.groups_2_outlined, HomeTint.amber, Routes.staffActivity),
    HomeTileData('Settings', 'Admin only', Icons.settings_outlined, HomeTint.slate, 'settings'),
  ];

  /// Tiles whose target is a module slug go through login first.
  static void _open(BuildContext context, String target) =>
      context.push(target.startsWith('/') ? target : Routes.loginFor(target));

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final phone = Breakpoints.of(context) == DeviceClass.phone;
    return Scaffold(
      body: ValueListenableBuilder<TerminalInfo>(
        valueListenable: getIt<TerminalInfoHolder>(),
        builder: (context, info, _) => Column(
          children: [
            _Header(info: info, compact: phone),
            Expanded(
              child: phone
                  ? ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        SizedBox(height: 260, child: SalesHeroTile(onTap: () => _open(context, 'sales'))),
                        const SizedBox(height: 12),
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.95,
                          children: [for (final t in _tiles) HomeTile(data: t, onTap: () => _open(context, t.target))],
                        ),
                      ],
                    )
                  : Padding(
                      padding: const EdgeInsets.all(32),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(flex: 2, child: SalesHeroTile(onTap: () => _open(context, 'sales'))),
                          const SizedBox(width: 18),
                          Expanded(
                            flex: 3,
                            child: Column(
                              children: [
                                for (var r = 0; r < 2; r++) ...[
                                  if (r > 0) const SizedBox(height: 18),
                                  Expanded(
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        for (var i = r * 3; i < r * 3 + 3; i++) ...[
                                          if (i > r * 3) const SizedBox(width: 18),
                                          Expanded(child: HomeTile(data: _tiles[i], onTap: () => _open(context, _tiles[i].target))),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            if (!phone)
              SizedBox(
                height: 40,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: DefaultTextStyle(
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.muted),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [Text('Tillora POS · v1.0.0'), Text('Local mode · all data stored on this terminal')],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.info, required this.compact});

  final TerminalInfo info;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    const muted = TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFFAFC0D8));
    return Container(
      color: AppColors.navy,
      padding: EdgeInsets.fromLTRB(compact ? 16 : 32, MediaQuery.paddingOf(context).top, compact ? 16 : 32, 0),
      height: 72 + MediaQuery.paddingOf(context).top,
      child: Row(
        children: [
          const BrandMark(),
          if (!compact) ...[
            Container(width: 1, height: 22, margin: const EdgeInsets.only(left: 24, right: 16), color: Colors.white24),
            Flexible(child: Text(info.companyName, overflow: TextOverflow.ellipsis, style: muted.copyWith(fontWeight: FontWeight.w500))),
          ],
          const Spacer(),
          if (!compact) ...[
            Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(999)),
              child: const Row(
                children: [
                  Icon(Icons.storage_rounded, size: 14, color: AppColors.amber),
                  SizedBox(width: 8),
                  Text('Local database', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFFD8E2F0))),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Text('Terminal ${info.terminalName}', style: muted),
            const SizedBox(width: 20),
          ],
          LiveClock(style: muted.copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
        ],
      ),
    );
  }
}
