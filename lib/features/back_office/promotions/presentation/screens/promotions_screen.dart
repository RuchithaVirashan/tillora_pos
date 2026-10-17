import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../app/di/injector.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../core/session/user_session.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/money.dart';
import '../../../../../core/widgets/crud_layout.dart';
import '../../../../../core/widgets/feedback.dart';
import '../../../../../core/widgets/module_scaffold.dart';
import '../../../../../core/widgets/pos_button.dart';
import '../../domain/entities/promotion.dart';
import '../../domain/usecases/promotion_usecases.dart';
import '../widgets/promotion_editor.dart';
import '../widgets/restore_promotions_panel.dart';

/// BOPromotions.dc.html: promotion list, add / edit and restore from XLSX.
/// [restore] opens on the Restore Promotions tab.
class PromotionsScreen extends StatefulWidget {
  const PromotionsScreen({super.key, required this.onBack, this.restore = false});

  final VoidCallback onBack;
  final bool restore;

  @override
  State<PromotionsScreen> createState() => _PromotionsScreenState();
}

class _PromotionsScreenState extends State<PromotionsScreen> {
  static const _tabs = ['Promotion Manager', 'Add Promotion', 'Restore Promotions'];

  final _access = getIt<SessionHolder>().value?.access;
  late final _canManage = _access?.can('promotionManagerAccess') ?? false;
  late final _canRestore = _access?.can('restorePromotionAccess') ?? false;
  final _query = TextEditingController();
  final _date = DateFormat('dd/MM/yyyy');
  late int _tab = widget.restore ? 2 : 0;
  List<PromotionSummary>? _rows;
  int? _selectedId;
  bool _confirming = false;

  /// The promotion open in the editor; null adds a new one.
  Promotion? _editing;
  int _editorKey = 0;

  PromotionSummary? get _selected => _rows?.where((r) => r.id == _selectedId).firstOrNull;

  @override
  void initState() {
    super.initState();
    if (_canManage) _load();
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final result = await getIt<GetPromotions>()(_query.text);
    if (!mounted) return;
    switch (result) {
      case Ok(:final value):
        setState(() => _rows = value);
      case Err(:final failure):
        showToast(context, failure.message, error: true);
    }
  }

  void _openTab(int i) => setState(() {
    if (i == 1 && _tab != 1) {
      _editing = null;
      _editorKey++;
    }
    _tab = i;
    _confirming = false;
  });

  Future<void> _edit() async {
    final result = await getIt<GetPromotion>()(_selectedId!);
    if (!mounted) return;
    switch (result) {
      case Ok(:final value):
        setState(() {
          _editing = value;
          _editorKey++;
          _tab = 1;
        });
      case Err(:final failure):
        showToast(context, failure.message, error: true);
    }
  }

  Future<void> _save(Promotion promotion) async {
    final result = await getIt<SavePromotion>()(promotion);
    if (!mounted) return;
    switch (result) {
      case Ok(:final value):
        showToast(context, promotion.id == null ? '${promotion.description.trim()} added' : 'Promotion updated');
        setState(() {
          _selectedId = value;
          _tab = 0;
        });
        _load();
      case Err(:final failure):
        showToast(context, failure.message, error: true);
    }
  }

  Future<void> _delete() async {
    final p = _selected!;
    final result = await getIt<DeletePromotion>()(p.id);
    if (!mounted) return;
    setState(() => _confirming = false);
    if (result case Err(:final failure)) return showToast(context, failure.message, error: true);
    showToast(context, '${p.description} deleted');
    setState(() => _selectedId = null);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final allowed = switch (_tab) {
      2 => _canRestore,
      _ => _canManage,
    };
    return ModuleScaffold(
      eyebrow: 'BACK OFFICE · PROMOTION',
      title: _tab == 1 && _editing != null ? 'Edit Promotion' : _tabs[_tab],
      onBack: widget.onBack,
      backLabel: 'Back to Back Office',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ModuleTabs(labels: [_tabs[0], _editing == null ? _tabs[1] : 'Edit Promotion', _tabs[2]], selected: _tab, onSelect: _openTab),
          Expanded(
            child: !allowed
                ? NoAccess(what: _tab == 2 ? 'Restore Promotions' : 'Promotion Manager')
                : switch (_tab) {
                    0 => _list(context),
                    1 => PromotionEditor(key: ValueKey(_editorKey), initial: _editing, onSave: _save),
                    _ => RestorePromotionsPanel(
                      onCancel: () => _openTab(0),
                      onDone: () {
                        if (_canManage) _load();
                        _openTab(0);
                      },
                    ),
                  },
          ),
        ],
      ),
    );
  }

  Widget _list(BuildContext context) {
    final selected = _selected;
    return LayoutBuilder(
      builder: (context, box) {
        final narrow = box.maxWidth < 760;
        return Padding(
          padding: EdgeInsets.all(narrow ? 12 : 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: narrow ? double.infinity : 320,
                    child: TextField(
                      controller: _query,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _load(),
                      decoration: const InputDecoration(hintText: 'ID / Description / Barcode', prefixIcon: Icon(Icons.search_rounded)),
                    ),
                  ),
                  PosButton(label: 'Search', height: 48, style: PosButtonStyle.secondary, onPressed: _load),
                  PosButton(label: 'Add New', icon: Icons.add_rounded, height: 48, style: PosButtonStyle.primary, onPressed: () => _openTab(1)),
                  PosButton(label: 'Edit', height: 48, style: PosButtonStyle.secondary, onPressed: selected == null ? null : _edit),
                  PosButton(label: 'Delete', height: 48, style: PosButtonStyle.voidTint, onPressed: selected == null ? null : () => setState(() => _confirming = true)),
                ],
              ),
              if (_confirming && selected != null) ...[
                const SizedBox(height: 12),
                DeleteConfirm(
                  text: 'Are you sure you want to delete promotion ${selected.description}?',
                  onCancel: () => setState(() => _confirming = false),
                  onDelete: _delete,
                ),
              ],
              const SizedBox(height: 14),
              Expanded(child: _table(context, narrow: narrow)),
            ],
          ),
        );
      },
    );
  }

  Widget _table(BuildContext context, {required bool narrow}) {
    final c = context.colors;
    final rows = _rows;
    final head = TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.1, color: c.muted);
    Widget cols(List<Widget> cells) => Row(
      children: [
        SizedBox(width: 64, child: cells[0]),
        Expanded(child: cells[1]),
        if (!narrow) SizedBox(width: 150, child: cells[2]),
        SizedBox(width: 110, child: Align(alignment: Alignment.centerRight, child: cells[3])),
        if (!narrow) ...[const SizedBox(width: 24), SizedBox(width: 110, child: cells[4]), SizedBox(width: 110, child: cells[5])],
      ],
    );
    final today = DateTime.now();
    return Panel(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: cols([
              Text('ID', style: head),
              Text('DESCRIPTION', style: head),
              Text('PROMO TYPE', style: head),
              Text('PRICE', style: head),
              Text('START DATE', style: head),
              Text('END DATE', style: head),
            ]),
          ),
          Divider(height: 1, color: c.line),
          Expanded(
            child: switch (rows) {
              null => const Center(child: CircularProgressIndicator()),
              [] => Center(child: Text('No promotions', style: TextStyle(color: c.muted))),
              _ => ListView.builder(
                itemCount: rows.length,
                itemExtent: 58,
                itemBuilder: (context, i) {
                  final r = rows[i];
                  final on = r.id == _selectedId;
                  final ended = r.end.isBefore(DateTime(today.year, today.month, today.day));
                  final body = TextStyle(fontSize: 15, color: ended ? c.muted : c.inkSecondary);
                  return Material(
                    color: on ? c.selection : c.surface,
                    child: InkWell(
                      onTap: () => setState(() {
                        _selectedId = r.id;
                        _confirming = false;
                      }),
                      onDoubleTap: () {
                        setState(() => _selectedId = r.id);
                        _edit();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: c.rowLine),
                            left: BorderSide(color: on ? AppColors.amber : Colors.transparent, width: 4),
                          ),
                        ),
                        child: cols([
                          Text('P${r.id.toString().padLeft(2, '0')}', style: body),
                          Text(
                            narrow ? '${r.description}\n${r.type.label} · ${_date.format(r.end)}' : r.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: body.copyWith(fontWeight: FontWeight.w800, color: ended ? c.muted : c.ink),
                          ),
                          Text(r.type.label, overflow: TextOverflow.ellipsis, style: body),
                          Text(Money.lkr(Money.fromCents(r.amountCents)), style: body.copyWith(color: ended ? c.muted : c.ink)),
                          Text(_date.format(r.start), style: body),
                          Text(_date.format(r.end), style: ended ? body.copyWith(color: AppColors.danger) : body),
                        ]),
                      ),
                    ),
                  );
                },
              ),
            },
          ),
        ],
      ),
    );
  }
}
