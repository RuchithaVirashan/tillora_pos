import 'package:material_ui/material_ui.dart';

import '../../../../../app/di/injector.dart';
import '../../../../../core/responsive/breakpoints.dart';
import '../../../../../core/session/user_session.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/module_scaffold.dart';

/// A report tile; [onOpen] is wired by the router.
class ReportLink {
  const ReportLink(this.name, this.description, this.icon, this.ink, this.fill, this.accessFlag, this.onOpen);

  final String name;
  final String description;
  final IconData icon;
  final Color ink;
  final Color fill;
  final String accessFlag;
  final VoidCallback onOpen;
}

/// QuickReport.dc.html.
class QuickReportScreen extends StatelessWidget {
  const QuickReportScreen({super.key, required this.links, required this.onBack});

  final List<ReportLink> links;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final access = getIt<SessionHolder>().value?.access;
    final phone = Breakpoints.of(context) == DeviceClass.phone;
    return ModuleScaffold(
      title: 'Quick Report',
      onBack: onBack,
      backLabel: 'Back to home',
      body: GridView.count(
        padding: EdgeInsets.all(phone ? 12 : 32),
        crossAxisCount: phone ? 1 : 2,
        mainAxisSpacing: 18,
        crossAxisSpacing: 18,
        childAspectRatio: phone ? 2.6 : 3.2,
        children: [for (final l in links) _Tile(link: l, enabled: access?.can(l.accessFlag) ?? false)],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.link, required this.enabled});

  final ReportLink link;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Material(
        color: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22), side: BorderSide(color: c.line)),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: enabled ? link.onOpen : null,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(color: link.fill, borderRadius: BorderRadius.circular(18)),
                  child: Icon(link.icon, color: link.ink, size: 30),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(link.name, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: c.ink)),
                      const SizedBox(height: 4),
                      Text(enabled ? link.description : 'No access', style: TextStyle(fontSize: 14, color: c.muted)),
                    ],
                  ),
                ),
                if (enabled) Icon(Icons.chevron_right_rounded, color: c.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
