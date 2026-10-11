import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../app/di/injector.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../core/session/access_rights.dart';
import '../../../../../core/session/user_session.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/money.dart';
import '../../../../../core/widgets/feedback.dart';
import '../../../../../core/widgets/pos_button.dart';
import '../../../../../core/widgets/pos_dialog.dart';
import '../../domain/entities/price_check_item.dart';
import '../../domain/usecases/price_check_usecases.dart';

/// PriceCheck.dc.html.
class PriceCheckScreen extends StatefulWidget {
  const PriceCheckScreen({super.key, this.initialQuery = ''});

  final String initialQuery;

  @override
  State<PriceCheckScreen> createState() => _PriceCheckScreenState();
}

class _PriceCheckScreenState extends State<PriceCheckScreen> {
  final _session = getIt<SessionHolder>().current;
  late final _query = TextEditingController(text: widget.initialQuery);
  final _newPrice = TextEditingController();
  final _dateFormat = DateFormat('d MMM y');

  List<PriceCheckItem> _results = const [];
  PriceCheckItem? _item;
  bool _searched = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery.isNotEmpty) _search();
  }

  @override
  void dispose() {
    _query.dispose();
    _newPrice.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final result = await getIt<SearchProducts>()(_query.text);
    if (!mounted) return;
    switch (result) {
      case Ok(:final value):
        setState(() {
          _results = value;
          _item = value.isEmpty ? null : value.first;
          _searched = true;
        });
      case Err(:final failure):
        showToast(context, failure.message, error: true);
    }
  }

  Future<void> _refresh(String message) async {
    showToast(context, message);
    final barcode = _item!.barcode;
    _query.text = barcode;
    await _search();
  }

  Future<void> _updatePrice() async {
    final cents = Money.toCents(double.tryParse(_newPrice.text) ?? 0);
    final result = await getIt<UpdatePrice>()(_session, _item!, cents);
    if (!mounted) return;
    if (result case Err(:final failure)) return showToast(context, failure.message, error: true);
    _newPrice.clear();
    await _refresh('Price updated successfully');
  }

  Future<void> _confirmExpiry() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 5)),
      initialDate: _item!.expiryDate ?? now.add(const Duration(days: 7)),
      helpText: 'Expiry date',
    );
    if (date == null || !mounted) return;
    if (await getIt<SetExpiry>()(_item!, date) case Err(:final failure)) {
      if (mounted) showToast(context, failure.message, error: true);
      return;
    }
    if (mounted) await _refresh('Expiry date saved');
  }

  Future<void> _markExpired() async {
    final ok = await confirm(
      context,
      title: 'Mark as Expired',
      message: '${_item!.description} will warn at the till from today.',
      confirmLabel: 'Mark as Expired',
      destructive: true,
    );
    if (!ok || !mounted) return;
    if (await getIt<SetExpiry>()(_item!, DateTime.now()) case Err(:final failure)) {
      if (mounted) showToast(context, failure.message, error: true);
      return;
    }
    if (mounted) await _refresh('Marked as expired');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final item = _item;
    final canUpdate = _session.access.can(AccessRights.priceUpdate);

    return PosDialog(
      title: 'Price Check',
      width: 820,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _query,
                    autofocus: true,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _search(),
                    style: GoogleFonts.jetBrainsMono(fontSize: 17, color: c.ink),
                    decoration: const InputDecoration(hintText: 'Barcode / PLU code / Description'),
                  ),
                ),
                const SizedBox(width: 10),
                PosButton(label: 'Check', height: 56, fontSize: 16, style: PosButtonStyle.primary, onPressed: _search),
              ],
            ),
            const SizedBox(height: 18),
            if (_searched && item == null)
              Text('No product found', style: TextStyle(color: c.voidInk, fontWeight: FontWeight.w700)),
            if (_results.length > 1) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final r in _results)
                    ChoiceChip(
                      label: Text(r.description),
                      selected: r == item,
                      onSelected: (_) => setState(() => _item = r),
                    ),
                ],
              ),
              const SizedBox(height: 14),
            ],
            if (item != null) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), border: Border.all(color: c.line)),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.description, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: c.ink)),
                          const SizedBox(height: 4),
                          Text(
                            [
                              if (item.departmentName.isNotEmpty) item.departmentName,
                              'Stock ${item.stock}',
                              if (item.expiryDate != null) 'Expiry ${_dateFormat.format(item.expiryDate!)}',
                            ].join(' · '),
                            style: TextStyle(fontSize: 13, color: c.muted),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Current Price', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c.muted)),
                        Text(Money.lkr(Money.fromCents(item.priceCents)),
                            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: c.totalInk)),
                      ],
                    ),
                  ],
                ),
              ),
              if (canUpdate) ...[
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _newPrice,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onSubmitted: (_) => _updatePrice(),
                        decoration: const InputDecoration(labelText: 'New Price', prefixText: 'Rs '),
                      ),
                    ),
                    const SizedBox(width: 10),
                    PosButton(label: 'Update Price', height: 56, fontSize: 16, style: PosButtonStyle.success, onPressed: _updatePrice),
                  ],
                ),
              ],
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(child: PosButton(label: 'Confirm Expiration', height: 52, style: PosButtonStyle.secondary, onPressed: _confirmExpiry)),
                  const SizedBox(width: 10),
                  Expanded(child: PosButton(label: 'Mark as Expired', height: 52, style: PosButtonStyle.voidTint, onPressed: _markExpired)),
                ],
              ),
            ],
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.pop(),
                child: Text('Close', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.navy.withValues(alpha: 0.8))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
