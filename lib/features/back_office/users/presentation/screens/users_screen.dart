import 'package:material_ui/material_ui.dart';

import '../../../../../app/di/injector.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../core/responsive/breakpoints.dart';
import '../../../../../core/session/user_session.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/crud_layout.dart';
import '../../../../../core/widgets/feedback.dart';
import '../../../../../core/widgets/module_scaffold.dart';
import '../../../../../core/widgets/pos_button.dart';
import '../../domain/repositories/user_repository.dart';
import '../../domain/usecases/user_usecases.dart';

/// BOUsers.dc.html: Manage Users.
class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key, required this.onBack, required this.onOpenRoleAccess});

  final VoidCallback onBack;
  final VoidCallback onOpenRoleAccess;

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  static const _flag = 'userManagerAccess';
  static const _tints = [
    (Color(0xFFE8EEFB), Color(0xFF2952A3)),
    (Color(0xFFE3F5EE), Color(0xFF0B7A55)),
    (Color(0xFFFFF3DC), Color(0xFF9A5B00)),
    (Color(0xFFEFEAFB), Color(0xFF5B3FB0)),
    (Color(0xFFEEF1F5), Color(0xFF3B4A60)),
    (Color(0xFFDFF3F3), Color(0xFF0B6E6E)),
  ];

  final _session = getIt<SessionHolder>().value;
  late final _allowed = _session?.access.can(_flag) ?? false;
  List<StaffUser>? _users;
  int? _selectedId;
  bool _adding = false;
  bool _confirming = false;

  StaffUser? get _selected => _users?.where((u) => u.id == _selectedId).firstOrNull;

  @override
  void initState() {
    super.initState();
    if (_allowed) _load();
  }

  Future<void> _load({int? select}) async {
    final result = await getIt<GetUsers>()();
    if (!mounted) return;
    switch (result) {
      case Ok(:final value):
        setState(() {
          _users = value;
          _selectedId = select ?? (value.any((u) => u.id == _selectedId) ? _selectedId : null);
        });
      case Err(:final failure):
        showToast(context, failure.message, error: true);
    }
  }

  void _startAdd() => setState(() {
    _adding = true;
    _confirming = false;
  });

  void _select(int id) => setState(() {
    _selectedId = id;
    _adding = false;
    _confirming = false;
  });

  Future<void> _save(String name, String password, int? roleId) async {
    final existing = _adding ? null : _selected;
    final result = await getIt<SaveUser>()(
      existing: existing,
      userName: name,
      password: password,
      roleId: roleId,
      all: _users ?? const [],
      session: _session!,
    );
    if (!mounted) return;
    switch (result) {
      case Ok(:final value):
        showToast(context, existing == null ? '${name.trim()} added' : 'User updated');
        setState(() => _adding = false);
        _load(select: value);
      case Err(:final failure):
        showToast(context, failure.message, error: true);
    }
  }

  Future<void> _delete() async {
    final user = _selected!;
    final result = await getIt<DeleteUser>()(user, all: _users ?? const [], session: _session!);
    if (!mounted) return;
    setState(() => _confirming = false);
    if (result case Err(:final failure)) return showToast(context, failure.message, error: true);
    showToast(context, '${user.userName} deleted');
    setState(() => _selectedId = null);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    final blocked = selected == null ? null : cannotDelete(selected, all: _users ?? const [], session: _session!);
    return ModuleScaffold(
      eyebrow: 'BACK OFFICE · MANAGEMENT',
      title: 'Manage Users',
      onBack: widget.onBack,
      backLabel: 'Back to Back Office',
      body: !_allowed
          ? const NoAccess(what: 'User Manager')
          : CrudLayout(
              hint: _adding ? 'Adding a new user' : (selected == null ? 'Please select an item to edit or delete' : 'Selected: ${selected.userName}'),
              onAdd: _startAdd,
              onEdit: selected == null ? null : () => setState(() => _adding = false),
              onDelete: selected == null ? null : () => setState(() => _confirming = true),
              formOpen: _adding || selected != null,
              onCloseForm: () => setState(() {
                _adding = false;
                _selectedId = null;
                _confirming = false;
              }),
              confirm: _confirming && selected != null
                  ? DeleteConfirm(
                      text: blocked ?? 'Are you sure you want to delete ${selected.userName}?',
                      onCancel: () => setState(() => _confirming = false),
                      onDelete: blocked == null ? _delete : null,
                    )
                  : null,
              list: _list(context),
              form: _adding || selected != null
                  ? _UserForm(
                      key: ValueKey(_adding ? 'new' : selected!.id),
                      initial: _adding ? null : selected,
                      onSave: _save,
                      onOpenRoleAccess: widget.onOpenRoleAccess,
                    )
                  : Center(child: Text('Select a user, or tap Add New', style: TextStyle(color: context.colors.muted))),
            ),
    );
  }

  Widget _list(BuildContext context) {
    final c = context.colors;
    final users = _users;
    if (users == null) return const Center(child: CircularProgressIndicator());
    final columns = Breakpoints.of(context) == DeviceClass.desktop ? 2 : 1;
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: columns, mainAxisSpacing: 10, crossAxisSpacing: 10, mainAxisExtent: 76),
      itemCount: users.length,
      itemBuilder: (context, i) {
        final u = users[i];
        final on = u.id == _selectedId && !_adding;
        final (fill, ink) = _tints[i % _tints.length];
        return Material(
          color: c.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: on ? c.primary : c.line, width: on ? 2 : 1)),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _select(u.id),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: context.tone(ink, fill).fill,
                    child: Text(
                      u.userName.length <= 2 ? u.userName.toUpperCase() : u.userName.substring(0, 2).toUpperCase(),
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: context.tone(ink, fill).ink),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(u.userName, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: c.ink)),
                        Text(Roles.name(u.roleId), style: TextStyle(fontSize: 13, color: c.muted)),
                      ],
                    ),
                  ),
                  if (u.onShift)
                    Container(
                      height: 24,
                      padding: const EdgeInsets.symmetric(horizontal: 9),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: context.colors.noteFill, borderRadius: BorderRadius.circular(999)),
                      child: Text('ON SHIFT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: context.colors.noteInk)),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _UserForm extends StatefulWidget {
  const _UserForm({super.key, required this.initial, required this.onSave, required this.onOpenRoleAccess});

  final StaffUser? initial;
  final Future<void> Function(String name, String password, int? roleId) onSave;
  final VoidCallback onOpenRoleAccess;

  @override
  State<_UserForm> createState() => _UserFormState();
}

class _UserFormState extends State<_UserForm> {
  late final _name = TextEditingController(text: widget.initial?.userName);
  final _password = TextEditingController();
  late int? _roleId = widget.initial?.roleId;
  bool _obscure = true;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await widget.onSave(_name.text, _password.text, _roleId);
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final editing = widget.initial != null;
    return ListView(
      children: [
        Text(editing ? 'Edit User' : 'Add New User', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: c.ink)),
        const SizedBox(height: 16),
        LabeledField(label: 'User Name', child: TextField(controller: _name, decoration: const InputDecoration(hintText: 'User Name'))),
        const SizedBox(height: 14),
        LabeledField(
          label: 'Password',
          child: TextField(
            controller: _password,
            obscureText: _obscure,
            decoration: InputDecoration(
              hintText: editing ? 'Leave blank to keep the current password' : 'Password',
              suffixIcon: IconButton(
                tooltip: _obscure ? 'Show password' : 'Hide password',
                icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
        ),
        if (editing) ...[
          const SizedBox(height: 6),
          Text('Changing the user name needs a new password.', style: TextStyle(fontSize: 12, color: c.muted)),
        ],
        const SizedBox(height: 14),
        LabeledField(
          label: 'Select Role',
          child: DropdownButtonFormField<int>(
            initialValue: _roleId,
            hint: const Text('Select Role'),
            items: [for (final r in const [Roles.cashier, Roles.manager, Roles.admin]) DropdownMenuItem(value: r, child: Text(Roles.name(r)))],
            onChanged: (v) => setState(() => _roleId = v),
          ),
        ),
        const SizedBox(height: 10),
        Text('Roles and their access are set in Role Access Manager.', style: TextStyle(fontSize: 13, color: c.muted)),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(onPressed: widget.onOpenRoleAccess, child: const Text('Open Role Access Control')),
        ),
        const SizedBox(height: 12),
        PosButton(label: 'Save', height: 54, fontSize: 16, style: PosButtonStyle.primary, onPressed: _saving ? null : _save),
      ],
    );
  }
}
