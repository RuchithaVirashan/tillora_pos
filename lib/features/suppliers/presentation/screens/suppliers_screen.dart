import 'package:material_ui/material_ui.dart';

import '../../../../app/di/injector.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/responsive/breakpoints.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/feedback.dart';
import '../../../../core/widgets/module_scaffold.dart';
import '../../../../core/widgets/pos_button.dart';
import '../../domain/entities/supplier.dart';
import '../../domain/usecases/supplier_usecases.dart';
import '../widgets/supplier_form.dart';

/// Suppliers.dc.html: supplier list, details, add and edit.
class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

enum _Mode { view, add, edit }

class _SuppliersScreenState extends State<SuppliersScreen> {
  List<Supplier>? _suppliers;
  int? _selectedId;
  _Mode _mode = _Mode.view;

  Supplier? get _selected => _suppliers?.where((s) => s.id == _selectedId).firstOrNull;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({int? select}) async {
    final result = await getIt<GetSuppliers>()();
    if (!mounted) return;
    switch (result) {
      case Ok(:final value):
        setState(() {
          _suppliers = value;
          _selectedId = select ?? (value.any((s) => s.id == _selectedId) ? _selectedId : value.firstOrNull?.id);
        });
      case Err(:final failure):
        showToast(context, failure.message, error: true);
    }
  }

  Future<void> _save(Supplier supplier) async {
    final result = await getIt<SaveSupplier>()(supplier);
    if (!mounted) return;
    switch (result) {
      case Ok(:final value):
        showToast(context, supplier.id == null ? '${supplier.name.trim()} added' : 'Supplier updated');
        setState(() => _mode = _Mode.view);
        _load(select: value);
      case Err(:final failure):
        showToast(context, failure.message, error: true);
    }
  }

  Future<void> _delete(Supplier supplier) async {
    final ok = await confirm(context, title: 'Delete supplier', message: 'Delete ${supplier.name}?', confirmLabel: 'Delete', destructive: true);
    if (!ok || !mounted) return;
    if (await getIt<DeleteSupplier>()(supplier.id!) case Err(:final failure)) {
      if (mounted) showToast(context, failure.message, error: true);
      return;
    }
    setState(() => _selectedId = null);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final phone = Breakpoints.of(context) == DeviceClass.phone;
    final list = _list(context);
    final panel = _panel(context);
    return ModuleScaffold(
      title: 'Suppliers',
      onBack: widget.onBack,
      backLabel: 'Back to home',
      trailing: Material(
        color: AppColors.amber,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _mode = _Mode.add),
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.center,
            child: Row(
              children: [
                const Icon(Icons.add_rounded, color: AppColors.navy, size: 20),
                if (!phone) ...[
                  const SizedBox(width: 6),
                  const Text('Add New Supplier', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.navy)),
                ],
              ],
            ),
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(phone ? 12 : 26),
        child: phone
            ? (_mode == _Mode.view && _selected == null ? list : panel)
            : Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [SizedBox(width: 380, child: list), const SizedBox(width: 20), Expanded(child: panel)],
              ),
      ),
    );
  }

  Widget _list(BuildContext context) {
    final c = context.colors;
    final suppliers = _suppliers;
    if (suppliers == null) return const Center(child: CircularProgressIndicator());
    if (suppliers.isEmpty) {
      return Panel(child: Text('No suppliers yet. Tap Add New Supplier.', style: TextStyle(color: c.muted, fontWeight: FontWeight.w700)));
    }
    return ListView.separated(
      itemCount: suppliers.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final s = suppliers[i];
        final on = s.id == _selectedId && _mode != _Mode.add;
        return Material(
          color: c.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: on ? c.primary : c.line, width: on ? 2 : 1),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => setState(() {
              _selectedId = s.id;
              _mode = _Mode.view;
            }),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFFDFF3F3),
                    child: Text(s.initials, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0B6E6E))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.name, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: c.ink)),
                        if (s.address.district.isNotEmpty) Text(s.address.district, style: TextStyle(fontSize: 13, color: c.muted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _panel(BuildContext context) {
    final c = context.colors;
    final selected = _selected;
    if (_mode != _Mode.view) {
      return Panel(
        child: SupplierForm(
          key: ValueKey(_mode == _Mode.edit ? selected?.id : 'new'),
          initial: _mode == _Mode.edit ? selected : null,
          onCancel: () => setState(() => _mode = _Mode.view),
          onSave: _save,
        ),
      );
    }
    if (selected == null) {
      return Panel(child: Center(child: Text('Select a supplier', style: TextStyle(color: c.muted, fontWeight: FontWeight.w700))));
    }
    final details = [
      ('Name', selected.name),
      ('Address', selected.address.line),
      ('District', selected.address.district),
      ('Country', selected.address.country),
      ('Mobile Number', selected.phone),
      ('Email', selected.email),
    ];
    return Panel(
      child: ListView(
        children: [
          Row(
            children: [
              if (Breakpoints.of(context) == DeviceClass.phone)
                IconButton(tooltip: 'Back to list', icon: const Icon(Icons.arrow_back_rounded), onPressed: () => setState(() => _selectedId = null)),
              Expanded(child: Text('Supplier Details', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: c.ink))),
              PosButton(label: 'Edit', height: 44, style: PosButtonStyle.secondary, onPressed: () => setState(() => _mode = _Mode.edit)),
              const SizedBox(width: 8),
              PosButton(label: 'Delete', height: 44, style: PosButtonStyle.voidTint, onPressed: () => _delete(selected)),
            ],
          ),
          const SizedBox(height: 16),
          for (final (label, value) in details)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.rowLine))),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 160, child: Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: c.muted))),
                  Expanded(child: Text(value.isEmpty ? '—' : value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c.ink))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
