import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../app/di/injector.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../core/config/terminal_info.dart';
import '../../../../../core/platform/report_output.dart';
import '../../../../../core/reports/shift_summary.dart';
import '../../../../../core/reports/shift_summary_document.dart';
import '../../../../../core/responsive/breakpoints.dart';
import '../../../../../core/session/user_session.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/feedback.dart';
import '../../../../../core/widgets/module_scaffold.dart';
import '../../../../../core/widgets/pos_button.dart';
import '../../../../../core/widgets/report_export.dart';
import '../../../../../core/widgets/shift_summary_sections.dart';
import '../../domain/repositories/shift_report_repository.dart';
import '../../domain/usecases/shift_report_usecases.dart';

/// ShiftReport.dc.html: Live Shift Report and All Shift Report tabs.
class ShiftReportScreen extends StatefulWidget {
  const ShiftReportScreen({super.key, required this.onBack, this.allShifts = false});

  final VoidCallback onBack;
  final bool allShifts;

  @override
  State<ShiftReportScreen> createState() => _ShiftReportScreenState();
}

class _ShiftReportScreenState extends State<ShiftReportScreen> {
  static const _liveFlag = 'liveShiftReportAccess';
  static const _allFlag = 'allShiftReportAccess';

  final _access = getIt<SessionHolder>().value?.access;
  final _shiftLabel = DateFormat('d MMM · HH:mm');
  late bool _all = widget.allShifts;
  DateTime _from = DateTime.now().subtract(const Duration(days: 7));
  DateTime _to = DateTime.now();
  List<UserOption> _users = const [];
  int? _userId;
  List<ShiftOption> _shifts = const [];
  int? _logId;
  ShiftSummary? _summary;

  bool get _allowed => _access?.can(_all ? _allFlag : _liveFlag) ?? false;

  @override
  void initState() {
    super.initState();
    getIt<GetReportUsers>()().then((r) {
      if (r case Ok(:final value) when mounted) setState(() => _users = value);
    });
    _loadShifts();
  }

  Future<void> _loadShifts() async {
    final result = _all ? await getIt<FindShifts>()(from: _from, to: _to, userId: _userId) : await getIt<GetLiveShifts>()();
    if (!mounted) return;
    switch (result) {
      case Ok(:final value):
        setState(() {
          _shifts = value;
          _logId = value.any((s) => s.logId == _logId) ? _logId : (value.isEmpty ? null : value.first.logId);
        });
      case Err(:final failure):
        showToast(context, failure.message, error: true);
    }
  }

  Future<void> _generate() async {
    final result = await getIt<GetShiftReport>()(_logId);
    if (!mounted) return;
    switch (result) {
      case Ok(:final value):
        setState(() => _summary = value);
      case Err(:final failure):
        showToast(context, failure.message, error: true);
    }
  }

  void _export() {
    final summary = _summary;
    if (summary == null) return showToast(context, 'Please generate report first', error: true);
    final terminal = getIt<TerminalInfoHolder>().value.terminalName;
    printOrExportReport(context, shiftSummaryDocument(summary, terminal: terminal, shiftId: _logId), getIt<ReportOutput>());
  }

  void _switchTab(bool all) {
    setState(() {
      _all = all;
      _summary = null;
      _logId = null;
    });
    _loadShifts();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final phone = Breakpoints.of(context) == DeviceClass.phone;
    final columns = switch (Breakpoints.of(context)) {
      DeviceClass.phone => 1,
      DeviceClass.tablet => 2,
      DeviceClass.desktop => 3,
    };
    final summary = _summary;

    return ModuleScaffold(
      title: _all ? 'All Shift Report' : 'Live Shift Report',
      onBack: widget.onBack,
      backLabel: 'Back to Quick Report',
      trailing: phone ? null : _Tabs(all: _all, onChanged: _switchTab),
      body: ListView(
        padding: EdgeInsets.all(phone ? 12 : 26),
        children: [
          if (phone) ...[_Tabs(all: _all, onChanged: _switchTab, onLight: true), const SizedBox(height: 12)],
          if (!_allowed)
            Panel(child: Text('You do not have access to this report.', style: TextStyle(color: c.voidInk, fontWeight: FontWeight.w700)))
          else ...[
            Panel(child: _filters(context)),
            const SizedBox(height: 18),
            if (summary == null)
              Panel(child: Center(child: Text('Please generate report first', style: TextStyle(color: c.muted, fontWeight: FontWeight.w700))))
            else ...[
              Text(
                '${summary.userName} · ${_shiftLabel.format(summary.startedAt)}${_all ? ' – ${DateFormat('HH:mm').format(summary.endedAt)}' : ' – now'}',
                style: TextStyle(color: c.muted, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              ShiftSummarySections(summary: summary, columns: columns),
            ],
          ],
        ],
      ),
    );
  }

  Widget _filters(BuildContext context) {
    final shiftPicker = LabeledField(
      label: 'Shift',
      child: DropdownButtonFormField<int>(
        // Rebuild when the list or selection changes so the shown value follows.
        key: ValueKey('${_shifts.map((s) => s.logId).join(',')}:$_logId'),
        initialValue: _logId,
        hint: Text(_shifts.isEmpty ? (_all ? 'No shifts in this range' : 'No open shifts') : 'Please select Shift'),
        items: [
          for (final s in _shifts)
            DropdownMenuItem(value: s.logId, child: Text('#${s.logId} · ${s.userName} · ${_shiftLabel.format(s.startedAt)}${s.open ? ' (open)' : ''}')),
        ],
        onChanged: (v) => setState(() => _logId = v),
      ),
    );
    final buttons = Row(
      children: [
        Expanded(child: PosButton(label: 'Generate Report', height: 52, style: PosButtonStyle.primary, onPressed: _generate)),
        const SizedBox(width: 10),
        Expanded(
          child: PosButton(
            label: 'Print Report',
            height: 52,
            style: PosButtonStyle.secondary,
            onPressed: _export,
          ),
        ),
      ],
    );
    if (!_all) return Column(children: [shiftPicker, const SizedBox(height: 14), buttons]);

    return Column(
      children: [
        FieldGrid(
          children: [
            LabeledField(
              label: 'Start Date',
              child: DateField(value: _from, lastDate: DateTime.now(), onChanged: (d) {
                setState(() => _from = d);
                _loadShifts();
              }),
            ),
            LabeledField(
              label: 'End Date',
              child: DateField(value: _to, lastDate: DateTime.now(), onChanged: (d) {
                setState(() => _to = d);
                _loadShifts();
              }),
            ),
            LabeledField(
              label: 'User',
              child: DropdownButtonFormField<int?>(
                initialValue: _userId,
                items: [
                  const DropdownMenuItem<int?>(value: null, child: Text('All users')),
                  for (final u in _users) DropdownMenuItem<int?>(value: u.id, child: Text(u.name)),
                ],
                onChanged: (v) {
                  setState(() => _userId = v);
                  _loadShifts();
                },
              ),
            ),
            shiftPicker,
          ],
        ),
        const SizedBox(height: 14),
        buttons,
      ],
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({required this.all, required this.onChanged, this.onLight = false});

  final bool all;
  final ValueChanged<bool> onChanged;
  final bool onLight;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget tab(bool value, String label) {
      final on = value == all;
      return Semantics(
        selected: on,
        button: true,
        child: Material(
          color: on ? (onLight ? c.surface : Colors.white) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => onChanged(value),
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: on ? const Color(0xFF0D2547) : (onLight ? c.inkSecondary : const Color(0xFFC7D4E6)),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: onLight ? c.line : Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [tab(false, 'Live Shift Report'), const SizedBox(width: 4), tab(true, 'All Shift Report')],
      ),
    );
  }
}
