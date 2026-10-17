import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../app/di/injector.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../core/session/user_session.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/feedback.dart';
import '../../../../../core/widgets/module_scaffold.dart';
import '../../../../../core/widgets/pos_button.dart';
import '../../../../../core/widgets/pos_dialog.dart';
import '../../domain/entities/exchange_rates.dart';
import '../../domain/usecases/exchange_rate_usecases.dart';

/// Converts an amount between rupees and the foreign currencies the shop
/// keeps rates for. Admins add and change the rates here.
class CurrencyConverterDialog extends StatefulWidget {
  const CurrencyConverterDialog({super.key});

  @override
  State<CurrencyConverterDialog> createState() => _CurrencyConverterDialogState();
}

class _CurrencyConverterDialogState extends State<CurrencyConverterDialog> {
  static final _decimal = [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,4}'))];
  static final _number = NumberFormat('#,##0.00', 'en_US');

  final _session = getIt<SessionHolder>().current;
  final _amount = TextEditingController(text: '1');
  final _code = TextEditingController();
  final _rate = TextEditingController();
  ExchangeRates? _rates;
  String _from = ExchangeRates.base;
  String _to = ExchangeRates.base;

  bool get _admin => _session.roleId == Roles.admin;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in [_amount, _code, _rate]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final result = await getIt<GetExchangeRates>()();
    if (!mounted) return;
    switch (result) {
      case Ok(:final value):
        _apply(value);
      case Err(:final failure):
        showToast(context, failure.message, error: true);
    }
  }

  /// Takes new rates, keeping the picked currencies when they still exist
  /// and defaulting to foreign currency → LKR.
  void _apply(ExchangeRates rates) => setState(() {
    _rates = rates;
    final foreign = rates.codes.skip(1).toList();
    if (!rates.codes.contains(_from) || (_from == ExchangeRates.base && _to == ExchangeRates.base)) {
      _from = foreign.firstOrNull ?? ExchangeRates.base;
    }
    if (!rates.codes.contains(_to)) _to = ExchangeRates.base;
  });

  Future<void> _saveRate() async {
    final result = await getIt<SetExchangeRate>()(_rates!, _code.text, double.tryParse(_rate.text.trim()), session: _session);
    if (!mounted) return;
    switch (result) {
      case Ok(:final value):
        showToast(context, '${_code.text.trim().toUpperCase()} rate saved');
        _code.clear();
        _rate.clear();
        _apply(value);
      case Err(:final failure):
        showToast(context, failure.message, error: true);
    }
  }

  Future<void> _remove(String code) async {
    final result = await getIt<RemoveExchangeRate>()(_rates!, code, session: _session);
    if (!mounted) return;
    switch (result) {
      case Ok(:final value):
        _apply(value);
      case Err(:final failure):
        showToast(context, failure.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final rates = _rates;
    return PosDialog(
      title: 'Currency Converter',
      icon: Icons.currency_exchange_rounded,
      iconColor: const Color(0xFF9A5B00),
      iconFill: const Color(0xFFFFF3DC),
      width: 640,
      child: rates == null
          ? const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (rates.rates.isEmpty)
                    Text(
                      _admin ? 'Add the rates your shop uses below.' : 'No exchange rates yet. Ask an admin to add them.',
                      style: TextStyle(fontWeight: FontWeight.w700, color: c.muted),
                    )
                  else
                    ..._converter(context, rates),
                  const SizedBox(height: 18),
                  Divider(height: 1, color: c.line),
                  const SizedBox(height: 14),
                  _rateList(context, rates),
                ],
              ),
            ),
    );
  }

  List<Widget> _converter(BuildContext context, ExchangeRates rates) {
    final c = context.colors;
    final amount = double.tryParse(_amount.text.trim()) ?? 0;
    final result = rates.convert(amount, from: _from, to: _to);
    final unit = rates.convert(1, from: _from, to: _to);
    Widget picker(String value, ValueChanged<String> onChanged) => DropdownButtonFormField<String>(
      key: ValueKey('${rates.codes.length}-$value'),
      initialValue: value,
      items: [for (final code in rates.codes) DropdownMenuItem(value: code, child: Text(code))],
      onChanged: (v) {
        if (v != null) setState(() => onChanged(v));
      },
    );
    return [
      LabeledField(
        label: 'Amount',
        child: TextField(
          controller: _amount,
          autofocus: true,
          inputFormatters: _decimal,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (_) => setState(() {}),
        ),
      ),
      const SizedBox(height: 12),
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: LabeledField(label: 'From Currency', child: picker(_from, (v) => _from = v)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: IconButton(tooltip: 'Swap currencies', onPressed: () => setState(_swap), icon: const Icon(Icons.swap_horiz_rounded)),
          ),
          Expanded(
            child: LabeledField(label: 'To Currency', child: picker(_to, (v) => _to = v)),
          ),
        ],
      ),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: c.selection, borderRadius: BorderRadius.circular(14)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CONVERTED AMOUNT',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.1, color: c.muted),
            ),
            const SizedBox(height: 4),
            Text(
              result == null ? '-' : '$_to ${_number.format(result)}',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: c.primary),
            ),
            if (unit != null) Text('1 $_from = ${unit.toStringAsFixed(4)} $_to', style: TextStyle(color: c.inkSecondary)),
          ],
        ),
      ),
    ];
  }

  void _swap() {
    final from = _from;
    _from = _to;
    _to = from;
  }

  Widget _rateList(BuildContext context, ExchangeRates rates) {
    final c = context.colors;
    final updated = rates.updated;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          updated == null ? 'Exchange rates (LKR per unit)' : 'Exchange rates (LKR per unit) · updated ${DateFormat('d MMM y, HH:mm').format(updated)}',
          style: TextStyle(fontWeight: FontWeight.w700, color: c.inkSecondary),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final code in rates.codes.skip(1))
              InputChip(
                label: Text('$code  ${rates.rateOf(code)}'),
                onPressed: _admin
                    ? () {
                        _code.text = code;
                        _rate.text = '${rates.rateOf(code)}';
                      }
                    : null,
                onDeleted: _admin ? () => _remove(code) : null,
                deleteButtonTooltipMessage: 'Remove $code',
              ),
          ],
        ),
        if (_admin) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                width: 110,
                child: TextField(
                  controller: _code,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[A-Za-z]')), LengthLimitingTextInputFormatter(3)],
                  decoration: const InputDecoration(hintText: 'USD', isDense: true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _rate,
                  inputFormatters: _decimal,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onSubmitted: (_) => _saveRate(),
                  decoration: const InputDecoration(hintText: 'Rupees for 1 unit', prefixText: 'Rs ', isDense: true),
                ),
              ),
              const SizedBox(width: 8),
              PosButton(label: 'Save Rate', height: 48, style: PosButtonStyle.secondary, onPressed: _saveRate),
            ],
          ),
        ],
        const SizedBox(height: 18),
        PosButton(label: 'Close', height: 52, style: PosButtonStyle.secondary, onPressed: () => Navigator.of(context).pop()),
      ],
    );
  }
}
