import 'package:material_ui/material_ui.dart';

import '../../../../../app/di/injector.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../core/responsive/breakpoints.dart';
import '../../../../../core/session/access_rights.dart';
import '../../../../../core/session/user_session.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/crud_layout.dart';
import '../../../../../core/widgets/feedback.dart';
import '../../../../../core/widgets/module_scaffold.dart';
import '../../../../../core/widgets/pos_button.dart';
import '../../domain/entities/access_areas.dart';
import '../../domain/repositories/role_access_repository.dart';
import '../../domain/usecases/role_access_usecases.dart';

/// BORoleAccess.dc.html: Role Access Control, per user.
class RoleAccessScreen extends StatefulWidget {
  const RoleAccessScreen({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<RoleAccessScreen> createState() => _RoleAccessScreenState();
}

class _RoleAccessScreenState extends State<RoleAccessScreen> {
  static const _flag = 'roleAccessManagerAccess';

  final _session = getIt<SessionHolder>().value;
  late final _allowed = _session?.access.can(_flag) ?? false;
  List<AccessUser>? _users;
  AccessUser? _user;
  AccessRights? _saved;
  AccessRights? _access;
  int _tab = 0;
  bool _saving = false;

  bool get _dirty => _access != null && _access != _saved;

  @override
  void initState() {
    super.initState();
    if (_allowed) _loadUsers();
  }

  Future<void> _loadUsers() async {
    final result = await getIt<GetAccessUsers>()();
    if (!mounted) return;
    switch (result) {
      case Ok(:final value):
        setState(() => _users = value);
        if (value.isNotEmpty) _pick(value.first);
      case Err(:final failure):
        showToast(context, failure.message, error: true);
    }
  }

  Future<void> _pick(AccessUser user) async {
    if (_dirty && !await confirm(context, title: 'Discard changes', message: 'Your changes for ${_user!.userName} are not saved. Discard them?')) {
      return;
    }
    final result = await getIt<GetUserAccess>()(user);
    if (!mounted) return;
    switch (result) {
      case Ok(:final value):
        setState(() {
          _user = user;
          _saved = value;
          _access = value;
        });
      case Err(:final failure):
        showToast(context, failure.message, error: true);
    }
  }

  void _set(String flag, String value) => setState(() => _access = _access!.copyWith({flag: value}));

  Future<void> _update() async {
    setState(() => _saving = true);
    final result = await getIt<SaveUserAccess>()(_user!, _access!, session: _session!);
    if (!mounted) return;
    setState(() => _saving = false);
    if (result case Err(:final failure)) return showToast(context, failure.message, error: true);
    setState(() => _saved = _access);
    showToast(context, 'Access updated for ${_user!.userName}. It applies from their next login.');
  }

  @override
  Widget build(BuildContext context) {
    final phone = Breakpoints.of(context) == DeviceClass.phone;
    return ModuleScaffold(
      eyebrow: 'BACK OFFICE · MANAGEMENT',
      title: 'Role Access Control',
      onBack: widget.onBack,
      backLabel: 'Back to Back Office',
      body: !_allowed
          ? const NoAccess(what: 'Role Access Manager')
          : Padding(
              padding: EdgeInsets.all(phone ? 12 : 26),
              child: phone
                  ? Column(children: [SizedBox(height: 260, child: _side(context)), const SizedBox(height: 12), Expanded(child: _main(context))])
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [SizedBox(width: 320, child: _side(context)), const SizedBox(width: 20), Expanded(child: _main(context))],
                    ),
            ),
    );
  }

  Widget _side(BuildContext context) {
    final c = context.colors;
    final users = _users;
    final access = _access;
    return Panel(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          Text('Select User', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.inkSecondary)),
          const SizedBox(height: 8),
          if (users == null) const Center(child: CircularProgressIndicator()),
          for (final u in users ?? const <AccessUser>[])
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: c.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: u.id == _user?.id ? c.primary : c.line, width: u.id == _user?.id ? 2 : 1),
                ),
                child: ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  onTap: () => _pick(u),
                  title: Text(u.userName, style: TextStyle(fontWeight: FontWeight.w800, color: c.ink)),
                  subtitle: Text(Roles.name(u.roleId), style: TextStyle(color: c.muted)),
                ),
              ),
            ),
          if (access != null) ...[
            const SizedBox(height: 12),
            Text('Set Count', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: c.inkSecondary)),
            const SizedBox(height: 8),
            for (final (label, flag) in accessCounts)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.ink))),
                    IconButton.filledTonal(
                      tooltip: 'Decrease',
                      icon: const Icon(Icons.remove_rounded),
                      onPressed: access.limit(flag) <= 0 ? null : () => _set(flag, '${access.limit(flag) - 1}'),
                    ),
                    SizedBox(width: 48, child: Text('${access.limit(flag)}', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, color: c.ink))),
                    IconButton.filledTonal(tooltip: 'Increase', icon: const Icon(Icons.add_rounded), onPressed: () => _set(flag, '${access.limit(flag) + 1}')),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _main(BuildContext context) {
    final c = context.colors;
    final access = _access;
    final user = _user;
    if (access == null || user == null) return Panel(child: Center(child: Text('Select a user', style: TextStyle(color: c.muted))));
    final (area, items) = accessAreas[_tab];
    final allowed = items.where((i) => access.can(i.$2)).length;
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SegmentedButton<int>(
                segments: [for (final (i, (name, _)) in accessAreas.indexed) ButtonSegment(value: i, label: Text(name))],
                selected: {_tab},
                onSelectionChanged: (s) => setState(() => _tab = s.first),
              ),
              Text('$allowed of ${items.length} $area permissions allowed for ${user.userName}', style: TextStyle(color: c.muted, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LayoutBuilder(
              builder: (context, box) => GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: box.maxWidth > 700 ? 2 : 1,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  mainAxisExtent: 60,
                ),
                itemCount: items.length,
                itemBuilder: (context, i) {
                  final (label, flag) = items[i];
                  return _AccessTile(label: label, on: access.can(flag), onChanged: (v) => _set(flag, v ? '1' : '0'));
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: 220,
              child: PosButton(label: 'Update', height: 54, fontSize: 16, style: PosButtonStyle.primary, onPressed: _dirty && !_saving ? _update : null),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccessTile extends StatelessWidget {
  const _AccessTile({required this.label, required this.on, required this.onChanged});

  final String label;
  final bool on;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: on ? c.noteFill : c.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13), side: BorderSide(color: on ? c.noteLine : c.line)),
      child: CheckboxListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
        controlAffinity: ListTileControlAffinity.leading,
        activeColor: AppColors.success,
        value: on,
        onChanged: (v) => onChanged(v ?? false),
        title: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.ink)),
      ),
    );
  }
}
