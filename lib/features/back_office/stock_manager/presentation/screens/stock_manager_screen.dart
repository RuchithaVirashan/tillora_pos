import 'package:material_ui/material_ui.dart';

import '../../../../../app/di/injector.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../core/responsive/breakpoints.dart';
import '../../../../../core/session/access_rights.dart';
import '../../../../../core/session/user_session.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/money.dart';
import '../../../../../core/widgets/crud_layout.dart';
import '../../../../../core/widgets/feedback.dart';
import '../../../../../core/widgets/module_scaffold.dart';
import '../../../../../core/widgets/pos_button.dart';
import '../../../departments/domain/entities/department.dart';
import '../../../departments/domain/usecases/department_usecases.dart';
import '../../domain/entities/stock_entry.dart';
import '../../domain/usecases/stock_manager_usecases.dart';
import '../widgets/adjust_stock_dialog.dart';

/// BOStock.dc.html: stock levels and value, with Adjust Stock.
/// [onAmendProduct] opens the product in the Product Manager.
class StockManagerScreen extends StatefulWidget {
  const StockManagerScreen({super.key, required this.onBack, required this.onAmendProduct});

  final VoidCallback onBack;
  final ValueChanged<int> onAmendProduct;

  @override
  State<StockManagerScreen> createState() => _StockManagerScreenState();
}

class _StockManagerScreenState extends State<StockManagerScreen> {
  static const _flag = 'stockManagerAccess';

  final _access = getIt<SessionHolder>().value?.access;
  late final _allowed = _access?.can(_flag) ?? false;
  late final _canAmend = _access?.can(AccessRights.productManager) ?? false;
  final _query = TextEditingController();
  List<Department> _departments = const [];
  int? _departmentId;
  StockList? _stock;
  int? _selectedId;

  StockEntry? get _selected => _stock?.entries.where((e) => e.productId == _selectedId).firstOrNull;

  @override
  void initState() {
    super.initState();
    if (!_allowed) return;
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

  Future<void> _load() async {
    final result = await getIt<GetStock>()(query: _query.text, departmentId: _departmentId);
    if (!mounted) return;
    switch (result) {
      case Ok(:final value):
        setState(() => _stock = value);
      case Err(:final failure):
        showToast(context, failure.message, error: true);
    }
  }

  Future<void> _adjust() async {
    final entry = _selected!;
    final stock = await AdjustStockDialog.show(context, entry);
    if (stock == null || !mounted) return;
    showToast(context, 'Stock for ${entry.description} is now $stock');
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final phone = Breakpoints.of(context) == DeviceClass.phone;
    final selected = _selected;
    return ModuleScaffold(
      eyebrow: 'BACK OFFICE · INVENTORY CONTROL',
      title: 'Stock Manager',
      onBack: widget.onBack,
      backLabel: 'Back to Back Office',
      body: !_allowed
          ? const NoAccess(what: 'Stock Manager')
          : Padding(
              padding: EdgeInsets.all(phone ? 12 : 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      SizedBox(
                        width: phone ? double.infinity : 320,
                        child: TextField(
                          controller: _query,
                          textInputAction: TextInputAction.search,
                          onSubmitted: (_) => _load(),
                          decoration: const InputDecoration(hintText: 'Barcode / Description', prefixIcon: Icon(Icons.search_rounded)),
                        ),
                      ),
                      SizedBox(
                        width: 220,
                        child: DropdownButtonFormField<int?>(
                          initialValue: _departmentId,
                          isExpanded: true,
                          items: [
                            const DropdownMenuItem(value: null, child: Text('All categories')),
                            for (final d in _departments) DropdownMenuItem(value: d.id, child: Text(d.name, overflow: TextOverflow.ellipsis)),
                          ],
                          onChanged: (v) {
                            setState(() => _departmentId = v);
                            _load();
                          },
                        ),
                      ),
                      PosButton(label: 'Search', height: 52, style: PosButtonStyle.secondary, onPressed: _load),
                      PosButton(
                        label: 'Amend Product',
                        height: 52,
                        style: PosButtonStyle.secondary,
                        onPressed: selected == null || !_canAmend ? null : () => widget.onAmendProduct(selected.productId),
                      ),
                      PosButton(label: 'Adjust Stock', icon: Icons.tune_rounded, height: 52, style: PosButtonStyle.primary, onPressed: selected == null ? null : _adjust),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Expanded(child: _table(context)),
                  const SizedBox(height: 12),
                  _footer(context),
                ],
              ),
            ),
    );
  }

  Widget _footer(BuildContext context) {
    final c = context.colors;
    final stock = _stock;
    if (stock == null) return const SizedBox.shrink();
    final shown = stock.entries.length < stock.matched ? 'Showing ${stock.entries.length} of ${stock.matched} products' : '${stock.matched} products';
    return Panel(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 6,
        children: [
          Text(shown, style: TextStyle(fontWeight: FontWeight.w700, color: c.muted)),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: 'Gross Total  ', style: TextStyle(fontWeight: FontWeight.w700, color: c.inkSecondary)),
                TextSpan(text: Money.lkr(Money.fromCents(stock.grossTotalCents)), style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: c.ink)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _table(BuildContext context) {
    final c = context.colors;
    final entries = _stock?.entries;
    final head = TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.1, color: c.muted);
    final device = Breakpoints.of(context);
    final desktop = device == DeviceClass.desktop;
    final phone = device == DeviceClass.phone;
    Widget right(Widget w) => Align(alignment: Alignment.centerRight, child: w);
    Widget cols(List<Widget> cells) => Row(
      children: [
        if (desktop) SizedBox(width: 60, child: cells[0]),
        if (!phone) SizedBox(width: 140, child: cells[1]),
        Expanded(child: cells[2]),
        SizedBox(width: 70, child: right(cells[3])),
        if (!phone) ...[const SizedBox(width: 16), SizedBox(width: 110, child: cells[4])],
        if (desktop) SizedBox(width: 110, child: cells[5]),
        if (!phone) SizedBox(width: 100, child: right(cells[6])),
        SizedBox(width: 110, child: right(cells[7])),
      ],
    );
    return Panel(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: cols([
              Text('ID', style: head),
              Text('BARCODE', style: head),
              Text('DESCRIPTION', style: head),
              Text('STOCK', style: head),
              Text('CATEGORY', style: head),
              Text('SUB-CATEGORY', style: head),
              Text('PRICE', style: head),
              Text('TOTAL', style: head),
            ]),
          ),
          Divider(height: 1, color: c.line),
          Expanded(
            child: switch (entries) {
              null => const Center(child: CircularProgressIndicator()),
              [] => Center(child: Text('No products found', style: TextStyle(color: c.muted))),
              _ => ListView.builder(
                itemCount: entries.length,
                itemExtent: 54,
                itemBuilder: (context, i) {
                  final e = entries[i];
                  final on = e.productId == _selectedId;
                  final body = TextStyle(fontSize: 15, color: c.inkSecondary);
                  final total = e.stock > 0 ? e.priceCents * e.stock : 0;
                  return Material(
                    color: on ? c.selection : c.surface,
                    child: InkWell(
                      onTap: () => setState(() => _selectedId = e.productId),
                      onDoubleTap: () {
                        setState(() => _selectedId = e.productId);
                        _adjust();
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
                          Text('${e.productId}', style: body),
                          Text(e.barcode, overflow: TextOverflow.ellipsis, style: body),
                          Text(e.description, overflow: TextOverflow.ellipsis, style: body.copyWith(fontWeight: FontWeight.w800, color: c.ink)),
                          Text('${e.stock}', style: body.copyWith(fontWeight: FontWeight.w800, color: e.stock <= 0 ? AppColors.danger : c.ink)),
                          Text(e.department, overflow: TextOverflow.ellipsis, style: body),
                          Text(e.subDepartment.isEmpty ? '—' : e.subDepartment, overflow: TextOverflow.ellipsis, style: body),
                          Text(Money.lkr(Money.fromCents(e.priceCents)), style: body),
                          Text(Money.lkr(Money.fromCents(total)), style: body.copyWith(color: c.ink)),
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
