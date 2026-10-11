import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../app/di/injector.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../core/session/user_session.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/money.dart';
import '../../../../../core/widgets/choice_list.dart';
import '../../../../../core/widgets/feedback.dart';
import '../../../../../core/widgets/pos_button.dart';
import '../../../../../core/widgets/pos_dialog.dart';
import '../../domain/repositories/void_repository.dart';
import '../../domain/usecases/void_usecases.dart';

/// VoidReason.dc.html. Pops `true` once the void is recorded.
class VoidReasonScreen extends StatefulWidget {
  const VoidReasonScreen({super.key, required this.request});

  final VoidRequest request;

  @override
  State<VoidReasonScreen> createState() => _VoidReasonScreenState();
}

class _VoidReasonScreenState extends State<VoidReasonScreen> {
  final _session = getIt<SessionHolder>().current;
  late VoidKind _kind = widget.request.kind;
  VoidOptions? _options;
  String? _error;
  int? _selected;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _options = null;
      _error = null;
      _selected = null;
    });
    switch (await getIt<GetVoidOptions>()(_kind, _session)) {
      case Ok(:final value):
        setState(() => _options = value);
      case Err(:final failure):
        setState(() => _error = failure.message);
    }
  }

  String get _name => _kind == VoidKind.line ? 'Void Line' : 'Void Sale';

  Future<void> _confirm() async {
    final options = _options!;
    setState(() => _saving = true);
    final result = await getIt<RecordVoid>()(
      _kind,
      reason: options.reasons[_selected!],
      logId: _session.logId ?? 0,
      lines: widget.request.linesFor(_kind),
    );
    if (!mounted) return;
    if (result case Err(:final failure)) {
      setState(() => _saving = false);
      return showToast(context, failure.message, error: true);
    }
    context.pop(_kind);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final options = _options;
    final canConfirm = options != null && _selected != null && options.remaining > 0 && !_saving;

    return PosDialog(
      title: _name,
      width: 640,
      trailing: _KindTabs(
        selected: _kind,
        canVoidLine: widget.request.line != null,
        onChanged: (k) {
          setState(() => _kind = k);
          _load();
        },
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.dangerTint,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.dangerLine),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.request.labelFor(_kind),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.dangerInk),
                        ),
                        if (options != null)
                          Text('$_name count left: ${options.remaining}',
                              style: const TextStyle(fontSize: 13, color: AppColors.dangerDeep)),
                      ],
                    ),
                  ),
                  Text(
                    Money.lkr(Money.fromCents(widget.request.amountFor(_kind))),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.dangerInk),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (_error != null)
              Text(_error!, style: TextStyle(color: c.voidInk, fontWeight: FontWeight.w700))
            else if (options == null)
              const Center(child: CircularProgressIndicator())
            else if (options.remaining <= 0)
              Text('You have reached your $_name limit for this shift.',
                  style: TextStyle(color: c.voidInk, fontWeight: FontWeight.w700))
            else ...[
              Text('Reason for $_name:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.inkSecondary)),
              const SizedBox(height: 10),
              ChoiceList(
                options: options.reasons,
                selected: _selected,
                onSelected: (i) => setState(() => _selected = i),
                accent: AppColors.danger,
                accentFill: AppColors.dangerTint,
                semanticLabel: 'Reason',
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: PosButton(label: 'Cancel', height: 58, style: PosButtonStyle.secondary, onPressed: () => context.pop())),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: PosButton(
                    label: 'Confirm $_name',
                    height: 58,
                    fontSize: 16,
                    style: PosButtonStyle.danger,
                    onPressed: canConfirm ? _confirm : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _KindTabs extends StatelessWidget {
  const _KindTabs({required this.selected, required this.canVoidLine, required this.onChanged});

  final VoidKind selected;
  final bool canVoidLine;
  final ValueChanged<VoidKind> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget tab(VoidKind kind, String label) {
      final on = kind == selected;
      final enabled = kind == VoidKind.sale || canVoidLine;
      return Semantics(
        selected: on,
        button: true,
        child: Material(
          color: on ? c.surface : Colors.transparent,
          elevation: on ? 1 : 0,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: enabled ? () => onChanged(kind) : null,
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              alignment: Alignment.center,
              child: Text(label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: on ? AppColors.dangerInk : (enabled ? c.inkSecondary : c.line),
                  )),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: c.background, borderRadius: BorderRadius.circular(14)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [tab(VoidKind.line, 'Void Line'), const SizedBox(width: 4), tab(VoidKind.sale, 'Void Sale')]),
    );
  }
}
