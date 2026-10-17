import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../../../../../app/di/injector.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/feedback.dart';
import '../../../../../core/widgets/module_scaffold.dart';
import '../../../../../core/widgets/pos_button.dart';
import '../../domain/repositories/barcode_product_repository.dart';
import '../../domain/usecases/barcode_product_usecases.dart';

/// Stock in tab: scan the delivered items, correct counts, then post them
/// all to stock at once (or reject the delivery).
class StockInPanel extends StatefulWidget {
  const StockInPanel({super.key});

  @override
  State<StockInPanel> createState() => _StockInPanelState();
}

class _StockInPanelState extends State<StockInPanel> {
  final _scan = TextEditingController();
  final _scanFocus = FocusNode();
  final _count = TextEditingController();
  final _lines = <StockInLine>[];
  int? _selected;
  bool _posting = false;

  @override
  void dispose() {
    _scan.dispose();
    _scanFocus.dispose();
    _count.dispose();
    super.dispose();
  }

  /// Each scan of the same product adds one more.
  Future<void> _add() async {
    final result = await getIt<FindStockInProduct>()(_scan.text);
    if (!mounted) return;
    _scan.clear();
    _scanFocus.requestFocus();
    switch (result) {
      case Ok(value: final p):
        final i = _lines.indexWhere((l) => l.productId == p.id);
        setState(() {
          if (i < 0) {
            _lines.add((productId: p.id!, barcode: p.barcode, description: p.description, quantity: 1));
            _select(_lines.length - 1);
          } else {
            final l = _lines[i];
            _lines[i] = (productId: l.productId, barcode: l.barcode, description: l.description, quantity: l.quantity + 1);
            _select(i);
          }
        });
      case Err(:final failure):
        showToast(context, failure.message, error: true);
    }
  }

  void _select(int? i) {
    _selected = i;
    _count.text = i == null ? '' : '${_lines[i].quantity}';
  }

  /// A count of 0 takes the line off the list.
  void _update() {
    final i = _selected;
    if (i == null) return;
    final qty = int.tryParse(_count.text.trim()) ?? 0;
    setState(() {
      final l = _lines[i];
      if (qty <= 0) {
        _lines.removeAt(i);
        _select(null);
      } else {
        _lines[i] = (productId: l.productId, barcode: l.barcode, description: l.description, quantity: qty);
      }
    });
  }

  Future<void> _post() async {
    setState(() => _posting = true);
    final result = await getIt<ReceiveStock>()(List.of(_lines));
    if (!mounted) return;
    setState(() => _posting = false);
    switch (result) {
      case Ok():
        final units = _lines.fold(0, (s, l) => s + l.quantity);
        showToast(context, 'Stocked in $units units across ${_lines.length} products');
        setState(() {
          _lines.clear();
          _select(null);
        });
      case Err(:final failure):
        showToast(context, failure.message, error: true);
    }
  }

  Future<void> _reject() async {
    if (!await confirm(context, title: 'Reject delivery?', message: 'All ${_lines.length} lines will be cleared without changing stock.', confirmLabel: 'Reject')) return;
    setState(() {
      _lines.clear();
      _select(null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final list = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _scan,
                focusNode: _scanFocus,
                autofocus: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _add(),
                decoration: const InputDecoration(hintText: 'Scan barcode / type description', prefixIcon: Icon(Icons.qr_code_scanner_rounded)),
              ),
            ),
            const SizedBox(width: 10),
            PosButton(label: 'Add', height: 56, style: PosButtonStyle.primary, onPressed: _add),
          ],
        ),
        const SizedBox(height: 14),
        Expanded(child: _table(context)),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: PosButton(label: 'Stock in', icon: Icons.download_rounded, height: 54, style: PosButtonStyle.primary, onPressed: _lines.isEmpty || _posting ? null : _post),
            ),
            const SizedBox(width: 10),
            Expanded(child: PosButton(label: 'Reject', height: 54, style: PosButtonStyle.voidTint, onPressed: _lines.isEmpty || _posting ? null : _reject)),
          ],
        ),
      ],
    );
    return LayoutBuilder(
      builder: (context, box) {
        final wide = box.maxWidth >= 820;
        return Padding(
          padding: EdgeInsets.all(wide ? 26 : 12),
          child: wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [Expanded(child: list), const SizedBox(width: 20), SizedBox(width: 340, child: _editor(context))],
                )
              : Column(children: [Expanded(child: list), if (_selected != null) ...[const SizedBox(height: 12), _editor(context)]]),
        );
      },
    );
  }

  Widget _editor(BuildContext context) {
    final c = context.colors;
    final i = _selected;
    return Panel(
      child: i == null
          ? Text('Select a line to change its count', style: TextStyle(color: c.muted))
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Edit Stock', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: c.ink)),
                const SizedBox(height: 6),
                Text(_lines[i].description, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: c.inkSecondary)),
                const SizedBox(height: 14),
                LabeledField(
                  label: 'Stock Count',
                  child: TextField(
                    controller: _count,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onSubmitted: (_) => _update(),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: PosButton(label: 'Cancel', height: 48, style: PosButtonStyle.secondary, onPressed: () => setState(() => _select(null)))),
                    const SizedBox(width: 10),
                    Expanded(child: PosButton(label: 'Update', height: 48, style: PosButtonStyle.primary, onPressed: _update)),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _table(BuildContext context) {
    final c = context.colors;
    final head = TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.1, color: c.muted);
    Widget cols(List<Widget> cells) => Row(
      children: [
        SizedBox(width: 56, child: cells[0]),
        SizedBox(width: 150, child: cells[1]),
        Expanded(child: cells[2]),
        SizedBox(width: 70, child: Align(alignment: Alignment.centerRight, child: cells[3])),
      ],
    );
    return Panel(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: cols([Text('ID', style: head), Text('BARCODE', style: head), Text('DESCRIPTION', style: head), Text('QTY', style: head)]),
          ),
          Divider(height: 1, color: c.line),
          Expanded(
            child: _lines.isEmpty
                ? Center(child: Text('Scan delivered items to start', style: TextStyle(color: c.muted)))
                : ListView.builder(
                    itemCount: _lines.length,
                    itemExtent: 54,
                    itemBuilder: (context, i) {
                      final l = _lines[i];
                      final on = i == _selected;
                      final body = TextStyle(fontSize: 15, color: c.inkSecondary);
                      return Material(
                        color: on ? c.selection : c.surface,
                        child: InkWell(
                          onTap: () => setState(() => _select(i)),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: c.rowLine),
                                left: BorderSide(color: on ? AppColors.amber : Colors.transparent, width: 4),
                              ),
                            ),
                            child: cols([
                              Text('${l.productId}', style: body),
                              Text(l.barcode, overflow: TextOverflow.ellipsis, style: body),
                              Text(l.description, overflow: TextOverflow.ellipsis, style: body.copyWith(fontWeight: FontWeight.w800, color: c.ink)),
                              Text('+${l.quantity}', style: body.copyWith(fontWeight: FontWeight.w800, color: AppColors.success)),
                            ]),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
