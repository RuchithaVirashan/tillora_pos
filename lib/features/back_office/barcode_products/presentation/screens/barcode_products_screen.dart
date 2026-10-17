import 'package:material_ui/material_ui.dart';

import '../../../../../app/di/injector.dart';
import '../../../../../core/errors/result.dart';
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
import '../../domain/entities/barcode_product.dart';
import '../../domain/usecases/barcode_product_usecases.dart';
import '../widgets/barcode_product_form.dart';
import '../widgets/stock_in_panel.dart';

/// BOBarcodes.dc.html: Manage Barcode Products and Stock in.
/// [editId] opens that product's form straight away.
class BarcodeProductsScreen extends StatefulWidget {
  const BarcodeProductsScreen({super.key, required this.onBack, this.editId});

  final VoidCallback onBack;
  final int? editId;

  @override
  State<BarcodeProductsScreen> createState() => _BarcodeProductsScreenState();
}

class _BarcodeProductsScreenState extends State<BarcodeProductsScreen> {
  final _allowed = getIt<SessionHolder>().value?.access.can(AccessRights.productManager) ?? false;
  final _query = TextEditingController();
  int _tab = 0;
  List<BarcodeProduct>? _products;
  List<Department> _departments = const [];

  /// The product being edited; may not be in the current search results.
  BarcodeProduct? _selected;
  bool _adding = false;
  bool _confirming = false;

  @override
  void initState() {
    super.initState();
    if (!_allowed) return;
    _loadDepartments();
    _load();
    if (widget.editId case final id?) _open(id);
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
    final result = await getIt<GetBarcodeProducts>()(_query.text);
    if (!mounted) return;
    switch (result) {
      case Ok(:final value):
        setState(() => _products = value);
      case Err(:final failure):
        showToast(context, failure.message, error: true);
    }
  }

  Future<void> _open(int id) async {
    final result = await getIt<GetBarcodeProduct>()(id);
    if (!mounted) return;
    switch (result) {
      case Ok(:final value):
        _select(value);
      case Err(:final failure):
        showToast(context, failure.message, error: true);
    }
  }

  void _startAdd() => setState(() {
    _adding = true;
    _selected = null;
    _confirming = false;
  });

  void _select(BarcodeProduct? p) => setState(() {
    _selected = p;
    _adding = false;
    _confirming = false;
  });

  Future<void> _save(BarcodeProduct product) async {
    final isNew = product.id == null;
    final result = await getIt<SaveBarcodeProduct>()(product);
    if (!mounted) return;
    switch (result) {
      case Ok(:final value):
        showToast(context, isNew ? '${product.description.trim()} added' : 'Product updated');
        await _load();
        await _open(value);
      case Err(:final failure):
        showToast(context, failure.message, error: true);
    }
  }

  Future<void> _delete() async {
    final p = _selected!;
    final result = await getIt<DeleteBarcodeProduct>()(p);
    if (!mounted) return;
    setState(() => _confirming = false);
    if (result case Err(:final failure)) return showToast(context, failure.message, error: true);
    showToast(context, '${p.description} deleted');
    _select(null);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return ModuleScaffold(
      eyebrow: 'BACK OFFICE · INVENTORY CONTROL',
      title: 'Product Manager',
      onBack: widget.onBack,
      backLabel: 'Back to Back Office',
      body: !_allowed
          ? const NoAccess(what: 'Product Manager')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ModuleTabs(labels: const ['Manage Barcode Products', 'Stock in'], selected: _tab, onSelect: (i) => setState(() => _tab = i)),
                Expanded(child: _tab == 0 ? _manage(context) : const StockInPanel()),
              ],
            ),
    );
  }

  Widget _manage(BuildContext context) {
    final selected = _selected;
    final formOpen = _adding || selected != null;
    return CrudLayout(
      formWidth: 520,
      hint: _adding ? 'Adding a new product' : (selected == null ? 'Please select a product to edit or delete' : 'Selected: ${selected.description}'),
      onAdd: _startAdd,
      onEdit: selected == null ? null : () => setState(() => _adding = false),
      onDelete: selected == null ? null : () => setState(() => _confirming = true),
      formOpen: formOpen,
      onCloseForm: () => _select(null),
      confirm: _confirming && selected != null
          ? DeleteConfirm(
              text: selected.inPromotion
                  ? 'Product is used in Promotion. Please remove it first.'
                  : 'Are you sure you want to delete ${selected.description}?',
              onCancel: () => setState(() => _confirming = false),
              onDelete: selected.inPromotion ? null : _delete,
            )
          : null,
      list: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _query,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _load(),
                  decoration: const InputDecoration(hintText: 'Barcode / Description', prefixIcon: Icon(Icons.search_rounded)),
                ),
              ),
              const SizedBox(width: 10),
              PosButton(label: 'Search', height: 56, style: PosButtonStyle.secondary, onPressed: _load),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(child: _table(context)),
        ],
      ),
      form: formOpen
          ? BarcodeProductForm(
              key: ValueKey(_adding ? 'new' : '${selected!.id}-${selected.hashCode}'),
              initial: _adding ? null : selected,
              departments: _departments,
              onSave: _save,
            )
          : Center(child: Text('Select a product, or tap Add New', style: TextStyle(color: context.colors.muted))),
    );
  }

  /// Narrow tables drop the barcode (shown under the description),
  /// department and VAT columns.
  Widget _table(BuildContext context) => LayoutBuilder(builder: (context, box) => _tableAt(context, narrow: box.maxWidth < 560));

  Widget _tableAt(BuildContext context, {required bool narrow}) {
    final c = context.colors;
    final products = _products;
    final head = TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.1, color: c.muted);
    Widget cols(List<Widget> cells) => Row(
      children: [
        if (!narrow) SizedBox(width: 140, child: cells[0]),
        Expanded(child: cells[1]),
        if (!narrow) SizedBox(width: 110, child: cells[2]),
        SizedBox(width: 100, child: Align(alignment: Alignment.centerRight, child: cells[3])),
        SizedBox(width: 64, child: Align(alignment: Alignment.centerRight, child: cells[4])),
        if (!narrow) SizedBox(width: 60, child: Align(alignment: Alignment.centerRight, child: cells[5])),
      ],
    );
    return Panel(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: cols([
              Text('BARCODE', style: head),
              Text('DESCRIPTION', style: head),
              Text('DEPARTMENT', style: head),
              Text('PRICE', style: head),
              Text('STOCK', style: head),
              Text('VAT', style: head),
            ]),
          ),
          Divider(height: 1, color: c.line),
          Expanded(
            child: switch (products) {
              null => const Center(child: CircularProgressIndicator()),
              [] => Center(child: Text('No products found', style: TextStyle(color: c.muted))),
              _ => ListView.builder(
                itemCount: products.length,
                itemExtent: 58,
                itemBuilder: (context, i) {
                  final p = products[i];
                  final on = p.id == _selected?.id && !_adding;
                  final body = TextStyle(fontSize: 15, color: c.inkSecondary);
                  return Material(
                    color: on ? c.selection : c.surface,
                    child: InkWell(
                      onTap: () => _open(p.id!),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: c.rowLine),
                            left: BorderSide(color: on ? AppColors.amber : Colors.transparent, width: 4),
                          ),
                        ),
                        child: cols([
                          Text(p.barcode, overflow: TextOverflow.ellipsis, style: body),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  narrow ? '${p.description}\n${p.barcode}' : p.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: body.copyWith(fontWeight: FontWeight.w800, color: c.ink),
                                ),
                              ),
                              if (p.inPromotion) ...[const SizedBox(width: 8), const _PromoBadge()],
                            ],
                          ),
                          Text(p.departmentName, overflow: TextOverflow.ellipsis, style: body),
                          Text(Money.lkr(Money.fromCents(p.priceCents)), style: body.copyWith(color: c.ink)),
                          Text('${p.stock}', style: body.copyWith(color: p.stock <= 0 ? AppColors.danger : c.inkSecondary)),
                          Text(p.vat == 0 ? '—' : '${_pct(p.vat)}%', style: body),
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

  static String _pct(double v) => v == v.roundToDouble() ? '${v.round()}' : '$v';
}

class _PromoBadge extends StatelessWidget {
  const _PromoBadge();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(color: AppColors.warningTint, borderRadius: BorderRadius.circular(6), border: Border.all(color: AppColors.warningLine)),
    child: const Text('IN PROMO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: AppColors.warningInk)),
  );
}
