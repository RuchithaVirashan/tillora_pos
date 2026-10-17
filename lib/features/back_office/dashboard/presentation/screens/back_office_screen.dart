import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../app/di/injector.dart';
import '../../../../../core/responsive/breakpoints.dart';
import '../../../../../core/session/user_session.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/module_scaffold.dart';

/// One Back Office tile: the screen it opens and the access it needs.
class BackOfficeTile {
  const BackOfficeTile(this.name, this.icon, this.route, this.accessFlag);

  final String name;
  final IconData icon;
  final String route;
  final String accessFlag;
}

class BackOfficeGroup {
  const BackOfficeGroup(this.title, this.ink, this.fill, this.tiles);

  final String title;
  final Color ink;
  final Color fill;
  final List<BackOfficeTile> tiles;
}

/// BackOffice.dc.html: Back Office menu by group.
class BackOfficeScreen extends StatelessWidget {
  const BackOfficeScreen({super.key, required this.groups, required this.onClose});

  final List<BackOfficeGroup> groups;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final session = getIt<SessionHolder>().value;
    final phone = Breakpoints.of(context) == DeviceClass.phone;
    return ModuleScaffold(
      title: 'Back Office',
      onBack: onClose,
      backLabel: 'Back to home',
      trailing: phone || session == null
          ? null
          : Text('Logged in as ${session.userName}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFAFC0D8))),
      body: ListView(
        padding: EdgeInsets.all(phone ? 12 : 28),
        children: [
          for (final g in groups) ...[
            _Group(group: g, can: (flag) => session?.access.can(flag) ?? false, columns: phone ? 2 : 4),
            const SizedBox(height: 22),
          ],
        ],
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.group, required this.can, required this.columns});

  final BackOfficeGroup group;
  final bool Function(String flag) can;
  final int columns;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 6, height: 18, decoration: BoxDecoration(color: group.ink, borderRadius: BorderRadius.circular(3))),
            const SizedBox(width: 10),
            Text(group.title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1.1, color: c.inkSecondary)),
          ],
        ),
        const SizedBox(height: 12),
        GridView(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            // Fixed height: icon plus a two-line name fits at any width.
            mainAxisExtent: 124,
          ),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (final t in group.tiles)
              Opacity(
                opacity: can(t.accessFlag) ? 1 : 0.45,
                child: Material(
                  color: c.surfaceMuted,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: c.line)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: can(t.accessFlag) ? () => context.push(t.route) : null,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(color: context.tone(group.ink, group.fill).fill, borderRadius: BorderRadius.circular(13)),
                            child: Icon(t.icon, color: context.tone(group.ink, group.fill).ink),
                          ),
                          Text(t.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: c.ink)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
