import 'package:material_ui/material_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../../app/di/injector.dart';
import '../../../../../core/session/user_session.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';

/// One tile on the Settings menu.
class SettingsTile {
  const SettingsTile(this.name, this.description, this.icon, this.ink, this.fill, this.route);

  final String name;
  final String description;
  final IconData icon;
  final Color ink;
  final Color fill;
  final String route;
}

/// Settings.dc.html: the Settings menu. Tiles come from the router so this
/// feature does not depend on the screens it opens.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.tiles, required this.onOpen, required this.onClose});

  final List<SettingsTile> tiles;
  final ValueChanged<String> onOpen;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final top = MediaQuery.paddingOf(context).top;
    final phone = MediaQuery.sizeOf(context).width < 700;
    final user = getIt<SessionHolder>().value?.userName ?? '';
    return Scaffold(
      backgroundColor: c.background,
      body: Column(
        children: [
          Container(
            height: 72 + top,
            color: AppColors.navy,
            padding: EdgeInsets.fromLTRB(phone ? 12 : 28, top, phone ? 12 : 28, 0),
            child: Row(
              children: [
                Material(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: onClose,
                    child: const SizedBox(width: 44, height: 44, child: Icon(Icons.arrow_back_rounded, color: Colors.white, semanticLabel: 'Back to home')),
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(child: Text('Settings', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white))),
                if (!phone)
                  FutureBuilder<PackageInfo>(
                    future: PackageInfo.fromPlatform(),
                    builder: (context, snap) => Text(
                      ['Admin $user', if (snap.data case final info?) 'Tillora POS ${info.version}', 'Local mode'].join(' · '),
                      style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFAFC0D8)),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.all(phone ? 12 : 28),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 420, mainAxisExtent: 96, crossAxisSpacing: 14, mainAxisSpacing: 14),
              itemCount: tiles.length,
              itemBuilder: (context, i) {
                final t = tiles[i];
                return Material(
                  color: c.surface,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: BorderSide(color: c.line)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => onOpen(t.route),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(color: context.tone(t.ink, t.fill).fill, borderRadius: BorderRadius.circular(14)),
                            child: Icon(t.icon, color: context.tone(t.ink, t.fill).ink),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(t.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: c.ink)),
                                const SizedBox(height: 2),
                                Text(t.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.muted)),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded, color: c.muted),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
