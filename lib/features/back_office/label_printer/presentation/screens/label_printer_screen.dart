import 'package:material_ui/material_ui.dart';

import '../../../../../app/di/injector.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../core/session/user_session.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/money.dart';
import '../../../../../core/widgets/crud_layout.dart';
import '../../../../../core/widgets/feedback.dart';
import '../../../../../core/widgets/module_scaffold.dart';
import '../../../../../core/widgets/pos_button.dart';
import '../../../departments/domain/entities/department.dart';
import '../../../departments/domain/usecases/department_usecases.dart';
import '../../domain/entities/label_product.dart';
import '../../domain/usecases/label_usecases.dart';

/// BOLabelPrinter.dc.html: pick products and print shelf or weight labels.
class LabelPrinterScreen extends StatefulWidget {
  const LabelPrinterScreen({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<LabelPrinterScreen> createState() => _LabelPrinterScreenState();
}

class _LabelPrinterScreenState extends State<LabelPrinterScreen> {
  final _allowed = getIt<SessionHolder>().value?.access.can('labelPrinterAccess') ?? false;
  final _code = TextEditingController();
  LabelType _type = LabelType.barcode;
  List<Department> _departments = const [];
  int? _departmentId;
  List<LabelProduct>? _products;

  /// Picked products in the order added, with their label counts.
  final _picked = <int, LabelLine>{};
  bool _printing = false;

  List<LabelLine> get _lines => _picked.values.toList();

  @override
  void initState() {
    super.initState();
    if (_allowed) _loadDepartments();
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _loadDepartments() async {
    if (await getIt<GetDepartments>()() case Ok(:final value) when mounted) {
      setState(() => _departments = value);
      if (value.isNotEmpty) _pickDepartment(value.first.id);
    }
  }

  Future<void> _pickDepartment(int? id) async {
    setState(() {
      _departmentId = id;
      _products = null;
    });
    if (id == null) return;
    final result = await getIt<GetLabelProducts>()(_type, departmentId: id);
    if (!mounted || id != _departmentId) return;
    switch (result) {
      case Ok(:final value):
        setState(() => _products = value);
      case Err(:final failure):
        showToast(context, failure.message, error: true);
    }
  }

  /// Weight and barcode labels print differently, so a new type starts
  /// a new selection.
  void _pickType(LabelType type) {
    if (type == _type) return;
    setState(() {
      _type = type;
      _picked.clear();
    });
    _pickDepartment(_departmentId);
  }

  void _add(LabelProduct p, [int count = 1]) => setState(() {
    final current = _picked[p.productId]?.count ?? 0;
    _picked[p.productId] = (product: p, count: current + count);
  });

  void _setCount(LabelProduct p, int count) => setState(() {
    if (count <= 0) {
      _picked.remove(p.productId);
    } else {
      _picked[p.productId] = (product: p, count: count);
    }
  });

  Future<void> _addCode() async {
    final result = await getIt<FindLabelProduct>()(_code.text, _type);
    if (!mounted) return;
    switch (result) {
      case Ok(:final value):
        _code.clear();
        _add(value);
      case Err(:final failure):
        showToast(context, failure.message, error: true);
    }
  }

  Future<void> _print(LabelFormat format) async {
    final lines = _lines;
    final labels = PrintLabels.labelCount(lines);
    final ok = await confirm(
      context,
      title: 'Confirm Printing',
      message: 'Print $labels labels for ${lines.length} items${format == LabelFormat.roll ? ' on the QL label printer' : ''}?',
      confirmLabel: 'Continue',
      cancelLabel: 'Cancel',
    );
    if (!ok || !mounted) return;
    setState(() => _printing = true);
    final result = await getIt<PrintLabels>()(lines, _type, format);
    if (!mounted) return;
    setState(() => _printing = false);
    switch (result) {
      case Ok():
        showToast(context, '$labels labels sent to the printer');
      case Err(:final failure):
        showToast(context, 'Could not print labels: ${failure.message}', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ModuleScaffold(
      eyebrow: 'BACK OFFICE · INVENTORY CONTROL',
      title: 'Label Printer',
      onBack: widget.onBack,
      backLabel: 'Back to Back Office',
      body: !_allowed
          ? const NoAccess(what: 'Label Printer')
          : LayoutBuilder(
              builder: (context, box) {
                final narrow = box.maxWidth < 800;
                // Phones scroll the whole page: the toolbar alone fills most of the height.
                if (box.maxWidth < 600) {
                  return ListView(
                    padding: const EdgeInsets.all(12),
                    children: [
                      _toolbar(context, narrow: true),
                      const SizedBox(height: 12),
                      SizedBox(height: 360, child: _categoryProducts(context)),
                      const SizedBox(height: 12),
                      SizedBox(height: 300, child: _selectedItems(context)),
                      const SizedBox(height: 12),
                      _actions(),
                    ],
                  );
                }
                final lists = [Expanded(child: _categoryProducts(context)), const SizedBox(width: 16, height: 12), Expanded(child: _selectedItems(context))];
                return Padding(
                  padding: EdgeInsets.all(narrow ? 12 : 26),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _toolbar(context, narrow: narrow),
                      const SizedBox(height: 14),
                      Expanded(
                        child: narrow
                            ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: lists)
                            : Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: lists),
                      ),
                      const SizedBox(height: 14),
                      _actions(),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _toolbar(BuildContext context, {required bool narrow}) {
    return Panel(
      padding: const EdgeInsets.all(18),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.end,
        children: [
          LabeledField(
            label: 'Select Type',
            child: SegmentedButton<LabelType>(
              showSelectedIcon: false,
              segments: [for (final t in LabelType.values) ButtonSegment(value: t, label: Text(t.label))],
              selected: {_type},
              onSelectionChanged: (s) => _pickType(s.first),
            ),
          ),
          SizedBox(
            width: narrow ? double.infinity : 220,
            child: LabeledField(
              label: 'Select Category',
              child: DropdownButtonFormField<int>(
                key: ValueKey(_departments.length),
                initialValue: _departmentId,
                isExpanded: true,
                items: [for (final d in _departments) DropdownMenuItem(value: d.id, child: Text(d.name, overflow: TextOverflow.ellipsis))],
                onChanged: _pickDepartment,
              ),
            ),
          ),
          SizedBox(
            width: narrow ? double.infinity : 260,
            child: LabeledField(
              label: 'Product Code / PLU Code',
              child: TextField(
                controller: _code,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _addCode(),
                decoration: const InputDecoration(hintText: 'Product Code / PLU Code', prefixIcon: Icon(Icons.qr_code_scanner_rounded)),
              ),
            ),
          ),
          PosButton(label: 'Add', icon: Icons.add_rounded, height: 52, style: PosButtonStyle.primary, onPressed: _addCode),
        ],
      ),
    );
  }

  Widget _categoryProducts(BuildContext context) {
    final c = context.colors;
    final products = _products;
    return Panel(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Text('Category Products', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: c.ink)),
          ),
          Divider(height: 1, color: c.line),
          Expanded(
            child: switch (products) {
              null when _departmentId == null => Center(child: Text('Select a category', style: TextStyle(color: c.muted))),
              null => const Center(child: CircularProgressIndicator()),
              [] => Center(
                child: Text(_type == LabelType.weight ? 'No weight products in this category' : 'No products in this category', style: TextStyle(color: c.muted)),
              ),
              _ => ListView.builder(
                itemCount: products.length,
                itemExtent: 60,
                itemBuilder: (context, i) {
                  final p = products[i];
                  return InkWell(
                    onTap: () => _add(p),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.rowLine))),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.description, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w800, color: c.ink)),
                                Text(p.pluCode ?? p.barcode, style: TextStyle(fontSize: 12, color: c.muted)),
                              ],
                            ),
                          ),
                          Text('${Money.lkr(Money.fromCents(p.priceCents))} · Add', style: TextStyle(fontWeight: FontWeight.w700, color: c.primary)),
                        ],
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

  Widget _selectedItems(BuildContext context) {
    final c = context.colors;
    final lines = _lines;
    return Panel(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 12, 8),
            child: Row(
              children: [
                Expanded(child: Text('Selected Items', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: c.ink))),
                TextButton(onPressed: lines.isEmpty ? null : () => setState(_picked.clear), child: const Text('Clear All')),
              ],
            ),
          ),
          Divider(height: 1, color: c.line),
          Expanded(
            child: lines.isEmpty
                ? Center(child: Text('No items to print', style: TextStyle(color: c.muted)))
                : ListView.builder(
                    itemCount: lines.length,
                    itemExtent: 56,
                    itemBuilder: (context, i) {
                      final (:product, :count) = lines[i];
                      return Container(
                        padding: const EdgeInsets.only(left: 20, right: 8),
                        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.rowLine))),
                        child: Row(
                          children: [
                            Expanded(child: Text(product.description, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w700, color: c.ink))),
                            IconButton(tooltip: 'One less', onPressed: () => _setCount(product, count - 1), icon: const Icon(Icons.remove_rounded, size: 18)),
                            SizedBox(
                              width: 44,
                              child: Text('× $count', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w800, color: c.inkSecondary)),
                            ),
                            IconButton(tooltip: 'One more', onPressed: () => _setCount(product, count + 1), icon: const Icon(Icons.add_rounded, size: 18)),
                            IconButton(tooltip: 'Remove ${product.description}', onPressed: () => _setCount(product, 0), icon: const Icon(Icons.close_rounded, size: 18)),
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

  Widget _actions() {
    final none = _picked.isEmpty || _printing;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.end,
      children: [
        PosButton(label: 'Clear', height: 52, style: PosButtonStyle.secondary, onPressed: _picked.isEmpty ? null : () => setState(_picked.clear)),
        PosButton(label: 'Print In QL', icon: Icons.label_outline_rounded, height: 52, style: PosButtonStyle.secondary, onPressed: none ? null : () => _print(LabelFormat.roll)),
        PosButton(label: 'Print', icon: Icons.print_outlined, height: 52, style: PosButtonStyle.primary, onPressed: none ? null : () => _print(LabelFormat.sheet)),
      ],
    );
  }
}
