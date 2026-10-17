import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/di/injector.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/responsive/breakpoints.dart';
import '../../../../core/session/user_session.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/feedback.dart';
import '../../../../core/widgets/module_scaffold.dart';
import '../../domain/repositories/staff_activity_repository.dart';
import '../../domain/usecases/get_staff_activity.dart';

/// StaffActivity.dc.html: who is on shift.
class StaffActivityScreen extends StatefulWidget {
  const StaffActivityScreen({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<StaffActivityScreen> createState() => _StaffActivityScreenState();
}

class _StaffActivityScreenState extends State<StaffActivityScreen> {
  static const _tints = [
    (Color(0xFFE8EEFB), Color(0xFF2952A3)),
    (Color(0xFFE3F5EE), Color(0xFF0B7A55)),
    (Color(0xFFFFF3DC), Color(0xFF9A5B00)),
    (Color(0xFFEFEAFB), Color(0xFF5B3FB0)),
    (Color(0xFFEEF1F5), Color(0xFF3B4A60)),
  ];

  final _format = DateFormat('d MMM y · HH:mm');
  List<StaffStatus>? _rows;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await getIt<GetStaffActivity>()();
    if (!mounted) return;
    switch (result) {
      case Ok(:final value):
        setState(() => _rows = value);
      case Err(:final failure):
        showToast(context, failure.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final phone = Breakpoints.of(context) == DeviceClass.phone;
    final rows = _rows;
    final head = TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.1, color: c.muted);

    return ModuleScaffold(
      title: 'Staff Activity',
      onBack: widget.onBack,
      backLabel: 'Back to home',
      trailing: IconButton(tooltip: 'Refresh', icon: const Icon(Icons.refresh_rounded, color: Colors.white), onPressed: _load),
      body: Padding(
        padding: EdgeInsets.all(phone ? 12 : 32),
        child: Panel(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                child: Row(
                  children: [
                    Expanded(flex: 3, child: Text('USER', style: head)),
                    if (!phone) Expanded(flex: 2, child: Text('SHIFT STARTED', style: head)),
                    SizedBox(width: 120, child: Text('STATUS', style: head)),
                  ],
                ),
              ),
              Divider(height: 1, color: c.line),
              Expanded(
                child: rows == null
                    ? const Center(child: CircularProgressIndicator())
                    : rows.isEmpty
                    ? Center(child: Text('No users', style: TextStyle(color: c.muted)))
                    : ListView.separated(
                        itemCount: rows.length,
                        separatorBuilder: (_, _) => Divider(height: 1, color: c.rowLine),
                        itemBuilder: (context, i) {
                          final r = rows[i];
                          final (fill, ink) = _tints[i % _tints.length];
                          final started = r.shiftStarted == null ? 'Never' : _format.format(r.shiftStarted!);
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: context.tone(ink, fill).fill,
                                        child: Text(
                                          r.userName.length <= 2 ? r.userName.toUpperCase() : r.userName.substring(0, 2).toUpperCase(),
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: context.tone(ink, fill).ink),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Flexible(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(r.userName, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: c.ink)),
                                            Text(phone ? started : Roles.name(r.roleId), style: TextStyle(fontSize: 12, color: c.muted)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (!phone) Expanded(flex: 2, child: Text(started, style: TextStyle(fontSize: 14, color: c.inkSecondary))),
                                SizedBox(width: 120, child: Align(alignment: Alignment.centerLeft, child: _StatusPill(onShift: r.onShift))),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.onShift});

  final bool onShift;

  @override
  Widget build(BuildContext context) => Container(
    height: 30,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: onShift ? context.colors.noteFill : context.colors.surfaceMuted,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(radius: 4, backgroundColor: onShift ? AppColors.success : const Color(0xFF98A2B3)),
        const SizedBox(width: 7),
        Text(
          onShift ? 'Running' : 'Stopped',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: onShift ? context.colors.noteInk : const Color(0xFF475467)),
        ),
      ],
    ),
  );
}
