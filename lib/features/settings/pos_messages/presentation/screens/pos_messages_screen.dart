import 'package:material_ui/material_ui.dart';

import '../../../../../app/di/injector.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/crud_layout.dart';
import '../../../../../core/widgets/feedback.dart';
import '../../../../../core/widgets/module_scaffold.dart';
import '../../../../../core/widgets/pos_button.dart';
import '../../../../../core/widgets/side_nav_layout.dart';
import '../../domain/entities/pos_message.dart';
import '../../domain/usecases/pos_message_usecases.dart';

/// SetPOSMessages.dc.html: the reasons staff pick for voids, no sale and
/// age refusals.
class PosMessagesScreen extends StatefulWidget {
  const PosMessagesScreen({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<PosMessagesScreen> createState() => _PosMessagesScreenState();
}

class _PosMessagesScreenState extends State<PosMessagesScreen> {
  final _text = TextEditingController();
  MessageType _type = MessageType.voidLine;
  Map<MessageType, int> _counts = const {};
  List<PosMessage>? _messages;
  int? _selectedId;

  /// The inline editor: null closed, `(null)` adding, or the reason edited.
  ({PosMessage? message})? _editing;
  bool _confirming = false;

  PosMessage? get _selected => _messages?.where((m) => m.id == _selectedId).firstOrNull;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final type = _type;
    final (messages, counts) = (await getIt<GetPosMessages>()(type), await getIt<GetPosMessageCounts>()());
    if (!mounted || type != _type) return;
    setState(() {
      if (messages case Ok(:final value)) _messages = value;
      if (counts case Ok(:final value)) _counts = value;
    });
    if (messages case Err(:final failure)) showToast(context, failure.message, error: true);
  }

  void _pickType(int i) {
    setState(() {
      _type = MessageType.values[i];
      _messages = null;
      _selectedId = null;
      _editing = null;
      _confirming = false;
    });
    _load();
  }

  void _openEditor(PosMessage? message) => setState(() {
    _editing = (message: message);
    _confirming = false;
    _text.text = message?.text ?? '';
  });

  Future<void> _save() async {
    final editing = _editing!;
    final result = await getIt<SavePosMessage>()(_type, _text.text, existing: editing.message, all: _messages ?? const []);
    if (!mounted) return;
    switch (result) {
      case Ok():
        showToast(context, editing.message == null ? 'Reason added' : 'Reason updated');
        setState(() => _editing = null);
        _load();
      case Err(:final failure):
        showToast(context, failure.message, error: true);
    }
  }

  Future<void> _delete() async {
    final m = _selected!;
    final result = await getIt<DeletePosMessage>()(_type, m, all: _messages ?? const []);
    if (!mounted) return;
    setState(() => _confirming = false);
    if (result case Err(:final failure)) return showToast(context, failure.message, error: true);
    showToast(context, 'Reason deleted');
    setState(() => _selectedId = null);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return ModuleScaffold(
      eyebrow: 'SETTINGS',
      title: 'POS Record Messages',
      onBack: widget.onBack,
      backLabel: 'Back to Settings',
      body: SideNavLayout(
        navWidth: 260,
        scrollPanel: false,
        items: [for (final t in MessageType.values) SideNavItem(t.label, badge: '${_counts[t] ?? ''}')],
        selected: _type.index,
        onSelect: _pickType,
        child: _panel(context),
      ),
    );
  }

  Widget _panel(BuildContext context) {
    final c = context.colors;
    final selected = _selected;
    final messages = _messages;
    final editing = _editing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 220),
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: '${_type.label} reasons', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: c.ink)),
                    TextSpan(text: '  · shown as choices at the till', style: TextStyle(color: c.muted)),
                  ],
                ),
              ),
            ),
            PosButton(label: 'Add New', icon: Icons.add_rounded, height: 44, style: PosButtonStyle.primary, onPressed: () => _openEditor(null)),
            PosButton(label: 'Edit', height: 44, style: PosButtonStyle.secondary, onPressed: selected == null ? null : () => _openEditor(selected)),
            PosButton(
              label: 'Delete',
              height: 44,
              style: PosButtonStyle.voidTint,
              onPressed: selected == null ? null : () => setState(() {
                _confirming = true;
                _editing = null;
              }),
            ),
          ],
        ),
        if (_confirming && selected != null) ...[
          const SizedBox(height: 12),
          DeleteConfirm(text: 'Delete the reason "${selected.text}"?', onCancel: () => setState(() => _confirming = false), onDelete: _delete),
        ],
        if (editing != null) ...[
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: LabeledField(
                  label: editing.message == null ? 'Add Record' : 'Edit Record',
                  child: TextField(controller: _text, autofocus: true, onSubmitted: (_) => _save(), decoration: const InputDecoration(hintText: 'Record')),
                ),
              ),
              const SizedBox(width: 8),
              PosButton(label: 'Cancel', height: 52, style: PosButtonStyle.secondary, onPressed: () => setState(() => _editing = null)),
              const SizedBox(width: 8),
              PosButton(label: editing.message == null ? 'Add' : 'Save', height: 52, style: PosButtonStyle.primary, onPressed: _save),
            ],
          ),
        ],
        const SizedBox(height: 14),
        Divider(height: 1, color: c.line),
        Expanded(
          child: switch (messages) {
            null => const Center(child: CircularProgressIndicator()),
            [] => Center(child: Text('No reasons yet. The till needs at least one.', style: TextStyle(color: c.muted))),
            _ => ListView.builder(
              itemCount: messages.length,
              itemExtent: 56,
              itemBuilder: (context, i) {
                final m = messages[i];
                final on = m.id == _selectedId;
                return Material(
                  color: on ? c.selection : Colors.transparent,
                  child: InkWell(
                    onTap: () => setState(() {
                      _selectedId = m.id;
                      _confirming = false;
                    }),
                    onDoubleTap: () {
                      setState(() => _selectedId = m.id);
                      _openEditor(m);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: c.rowLine),
                          left: BorderSide(color: on ? AppColors.amber : Colors.transparent, width: 4),
                        ),
                      ),
                      child: Row(
                        children: [
                          SizedBox(width: 36, child: Text('${i + 1}', style: TextStyle(fontWeight: FontWeight.w800, color: c.muted))),
                          Expanded(child: Text(m.text, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c.ink))),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          },
        ),
      ],
    );
  }
}
