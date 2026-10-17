import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../app/di/injector.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../core/platform/report_output.dart';
import '../../../../../core/session/user_session.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/money.dart';
import '../../../../../core/widgets/crud_layout.dart';
import '../../../../../core/widgets/feedback.dart';
import '../../../../../core/widgets/module_scaffold.dart';
import '../../../../../core/widgets/pos_button.dart';
import '../../../../../core/widgets/report_export.dart';
import '../../../departments/domain/entities/department.dart';
import '../../../departments/domain/usecases/department_usecases.dart';
import '../../domain/entities/back_office_report.dart';
import '../../domain/usecases/back_office_report_usecases.dart';

/// BOReports.dc.html: Sale, Stock Movement and Stock Adjustment reports.
class BackOfficeReportsScreen extends StatefulWidget {
  const BackOfficeReportsScreen({super.key, required this.onBack, this.initial = BackOfficeReport.sale});

  final VoidCallback onBack;
  final BackOfficeReport initial;

  @override
  State<BackOfficeReportsScreen> createState() => _BackOfficeReportsScreenState();
}

/// One report column: header, width (null fills), right aligned, and
/// whether it shows on narrow screens.
typedef _Col = ({String name, double? width, bool right, bool narrow});

class _BackOfficeReportsScreenState extends State<BackOfficeReportsScreen> {
  final _access = getIt<SessionHolder>().value?.access;
  final _query = TextEditingController();
  final _at = DateFormat('dd/MM HH:mm');
  late BackOfficeReport _report = widget.initial;
  late DateTime _from = DateTime(_today.year, _today.month, 1);
  late DateTime _to = _today;
  List<Department> _departments = const [];
  int? _departmentId;
  bool _loading = false;
  List<SaleRow>? _sales;
  List<MovementRow>? _movement;
  List<AdjustmentRow>? _adjustments;

  static DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  bool get _allowed => _access?.can(_report.accessFlag) ?? false;

  ReportFilter get _filter => (from: _from, to: _to, departmentId: _departmentId, query: _query.text);

  @override
  void initState() {
    super.initState();
    _loadDepartments();
    _load();
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _loadDepartments() async {
    if (await getIt<GetDepartments>()() case Ok(:final value) when mounted) setState(() => _departments = value);
  }

  void _pick(int i) {
    setState(() => _report = BackOfficeReport.values[i]);
    _load();
  }

  Future<void> _load() async {
    if (!_allowed) return;
    setState(() => _loading = true);
    final report = _report;
    final filter = _filter;
    final String? error;
    switch (report) {
      case BackOfficeReport.sale:
        final result = await getIt<GetSaleReport>()(filter);
        if (result case Ok(:final value)) _sales = value;
        error = result is Err<List<SaleRow>> ? result.failure.message : null;
      case BackOfficeReport.movement:
        final result = await getIt<GetStockMovement>()(filter);
        if (result case Ok(:final value)) _movement = value;
        error = result is Err<List<MovementRow>> ? result.failure.message : null;
      case BackOfficeReport.adjustment:
        final result = await getIt<GetStockAdjustments>()(filter);
        if (result case Ok(:final value)) _adjustments = value;
        error = result is Err<List<AdjustmentRow>> ? result.failure.message : null;
    }
    if (!mounted) return;
    setState(() => _loading = false);
    if (error != null) showToast(context, error, error: true);
  }

  void _print() {
    final category = _departments.where((d) => d.id == _departmentId).firstOrNull?.name;
    final doc = backOfficeReportDocument(
      _report,
      _filter,
      category: category,
      sales: _sales ?? const [],
      movement: _movement ?? const [],
      adjustments: _adjustments ?? const [],
    );
    printOrExportReport(context, doc, getIt<ReportOutput>());
  }

  @override
  Widget build(BuildContext context) {
    return ModuleScaffold(
      eyebrow: 'BACK OFFICE · REPORT',
      title: _report.title,
      onBack: widget.onBack,
      backLabel: 'Back to Back Office',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ModuleTabs(labels: [for (final r in BackOfficeReport.values) r.tab], selected: _report.index, onSelect: _pick),
          Expanded(
            child: !_allowed
                ? NoAccess(what: 'the ${_report.title}')
                : LayoutBuilder(
                    builder: (context, box) {
                      final narrow = box.maxWidth < 900;
                      // Phones scroll the whole page: the filters alone fill the height.
                      if (box.maxWidth < 600) {
                        return ListView(
                          padding: const EdgeInsets.all(12),
                          children: [
                            _filters(context, narrow: true),
                            if (_report == BackOfficeReport.sale && _sales != null) ...[const SizedBox(height: 12), _saleTotals(context)],
                            const SizedBox(height: 12),
                            SizedBox(height: 460, child: _table(context, narrow: true)),
                          ],
                        );
                      }
                      return Padding(
                        padding: EdgeInsets.all(narrow ? 12 : 26),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _filters(context, narrow: box.maxWidth < 700),
                            if (_report == BackOfficeReport.sale && _sales != null) ...[const SizedBox(height: 14), _saleTotals(context)],
                            const SizedBox(height: 14),
                            Expanded(child: _table(context, narrow: narrow)),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _filters(BuildContext context, {required bool narrow}) {
    final field = narrow ? double.infinity : 180.0;
    final adjustment = _report == BackOfficeReport.adjustment;
    return Panel(
      padding: const EdgeInsets.all(18),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.end,
        children: [
          SizedBox(
            width: field,
            child: LabeledField(
              label: 'Start Date',
              child: DateField(value: _from, lastDate: _today, onChanged: (d) => setState(() => _from = d)),
            ),
          ),
          SizedBox(
            width: field,
            child: LabeledField(
              label: 'End Date',
              child: DateField(value: _to, lastDate: _today, onChanged: (d) => setState(() => _to = d)),
            ),
          ),
          SizedBox(
            width: narrow ? double.infinity : 200,
            child: LabeledField(
              label: 'Category',
              child: DropdownButtonFormField<int?>(
                initialValue: _departmentId,
                isExpanded: true,
                items: [
                  const DropdownMenuItem(value: null, child: Text('All categories')),
                  for (final d in _departments) DropdownMenuItem(value: d.id, child: Text(d.name, overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (v) => setState(() => _departmentId = v),
              ),
            ),
          ),
          SizedBox(
            width: narrow ? double.infinity : 260,
            child: LabeledField(
              label: adjustment ? 'Barcode' : 'Barcode or Description',
              child: TextField(
                controller: _query,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _load(),
                decoration: InputDecoration(hintText: adjustment ? 'Search Barcode' : 'Search Barcode or Enter Description'),
              ),
            ),
          ),
          PosButton(label: 'Generate', height: 52, style: PosButtonStyle.primary, onPressed: _loading ? null : _load),
          PosButton(label: 'Print Report', icon: Icons.print_outlined, height: 52, style: PosButtonStyle.secondary, onPressed: _loading ? null : _print),
        ],
      ),
    );
  }

  Widget _saleTotals(BuildContext context) {
    final c = context.colors;
    final t = saleTotals(_sales!);
    Widget card(String label, int cents, Color color) => Container(
      constraints: const BoxConstraints(minWidth: 200),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: c.line)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: c.muted)),
          const SizedBox(height: 4),
          Text(Money.lkr(Money.fromCents(cents)), style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        card('TOTAL SALES', t.sales, c.ink),
        card('TOTAL COST', t.cost, c.inkSecondary),
        card('TOTAL PROFIT', t.profit, t.profit < 0 ? AppColors.danger : AppColors.success),
      ],
    );
  }

  Widget _table(BuildContext context, {required bool narrow}) {
    final c = context.colors;
    final (List<_Col> cols, List<List<String>>? rows) = switch (_report) {
      BackOfficeReport.sale => (
        const [
          (name: 'BARCODE', width: 150, right: false, narrow: false),
          (name: 'DESCRIPTION', width: null, right: false, narrow: true),
          (name: 'CATEGORY', width: 120, right: false, narrow: false),
          (name: 'QTY SOLD', width: 90, right: true, narrow: true),
          (name: 'UNIT PRICE', width: 120, right: true, narrow: false),
          (name: 'TOTAL AMOUNT', width: 130, right: true, narrow: true),
        ],
        _sales?.map((r) => [r.barcode, r.description, r.category, '${r.quantity}', _money(r.unitPriceCents), _money(r.totalCents)]).toList(),
      ),
      BackOfficeReport.movement => (
        const [
          (name: 'ID', width: 60, right: false, narrow: false),
          (name: 'BARCODE', width: 150, right: false, narrow: false),
          (name: 'DESCRIPTION', width: null, right: false, narrow: true),
          (name: 'CATEGORY', width: 120, right: false, narrow: false),
          (name: 'CURRENT STOCK', width: 120, right: true, narrow: true),
          (name: 'STOCK SOLD', width: 100, right: true, narrow: true),
          (name: 'PRICE', width: 120, right: true, narrow: false),
        ],
        _movement?.map((r) => ['${r.productId}', r.barcode, r.description, r.category, '${r.stock}', '${r.sold}', _money(r.priceCents)]).toList(),
      ),
      BackOfficeReport.adjustment => (
        const [
          (name: 'BARCODE', width: 140, right: false, narrow: false),
          (name: 'DESCRIPTION', width: null, right: false, narrow: true),
          (name: 'TYPE', width: 110, right: false, narrow: true),
          (name: 'BEFORE', width: 70, right: true, narrow: false),
          (name: 'AFTER', width: 70, right: true, narrow: false),
          (name: 'QTY', width: 70, right: true, narrow: true),
          (name: 'ADJUSTED AT', width: 120, right: false, narrow: false),
          (name: 'CATEGORY', width: 110, right: false, narrow: false),
        ],
        _adjustments
            ?.map((r) => [r.barcode, r.description, r.type, '${r.before}', '${r.after}', r.quantity > 0 ? '+${r.quantity}' : '${r.quantity}', _at.format(r.at), r.category])
            .toList(),
      ),
    };
    final shown = [for (final (i, col) in cols.indexed) if (!narrow || col.narrow) i];
    final head = TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.1, color: c.muted);
    Widget row(List<Widget> cells) => Row(
      children: [
        for (final i in shown)
          if (cols[i].width == null)
            Expanded(child: cells[i])
          else
            SizedBox(width: cols[i].width, child: cols[i].right ? Align(alignment: Alignment.centerRight, child: cells[i]) : cells[i]),
      ].expand((w) => [w, const SizedBox(width: 10)]).toList()..removeLast(),
    );
    return Panel(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: row([for (final col in cols) Text(col.name, style: head)]),
          ),
          Divider(height: 1, color: c.line),
          Expanded(
            child: switch (rows) {
              _ when _loading => const Center(child: CircularProgressIndicator()),
              null => const SizedBox.shrink(),
              [] => Center(child: Text('No data for this period', style: TextStyle(color: c.muted))),
              _ => ListView.builder(
                itemCount: rows.length,
                itemExtent: 52,
                itemBuilder: (context, i) {
                  final r = rows[i];
                  final descriptionAt = cols.indexWhere((col) => col.name == 'DESCRIPTION');
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.rowLine))),
                    child: row([
                      for (final (j, text) in r.indexed)
                        Text(
                          text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: j == descriptionAt ? 15 : 14,
                            fontWeight: j == descriptionAt ? FontWeight.w700 : FontWeight.w500,
                            color: j == descriptionAt ? c.ink : c.inkSecondary,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                    ]),
                  );
                },
              ),
            },
          ),
        ],
      ),
    );
  }

  static String _money(int cents) => Money.lkr(Money.fromCents(cents));
}
