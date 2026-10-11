import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../app/di/injector.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../core/responsive/breakpoints.dart';
import '../../../../../core/session/user_session.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/feedback.dart';
import '../../../../../core/widgets/module_scaffold.dart';
import '../../../../../core/widgets/pos_button.dart';
import '../../domain/repositories/expired_items_repository.dart';
import '../../domain/usecases/get_expired_items.dart';

/// ExpiredItems.dc.html.
class ExpiredItemsScreen extends StatefulWidget {
  const ExpiredItemsScreen({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<ExpiredItemsScreen> createState() => _ExpiredItemsScreenState();
}

class _ExpiredItemsScreenState extends State<ExpiredItemsScreen> {
  static const _flag = 'expiredItemsAccess';

  final _allowed = getIt<SessionHolder>().value?.access.can(_flag) ?? false;
  final _format = DateFormat('d MMM y');

  /// Null shows everything expired by today ("All").
  DateTime? _before;
  List<ExpiredProduct>? _rows;

  @override
  void initState() {
    super.initState();
    if (_allowed) _load();
  }

  Future<void> _load() async {
    final result = await getIt<GetExpiredItems>()(before: _before);
    if (!mounted) return;
    switch (result) {
      case Ok(:final value):
        setState(() => _rows = value);
      case Err(:final failure):
        showToast(context, failure.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final phone = Breakpoints.of(context) == DeviceClass.phone;
    final rows = _rows;
    final head = TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.1, color: c.muted);
    Widget cols(List<Widget> cells) => Row(
      children: [
        if (!phone) SizedBox(width: 160, child: cells[0]),
        Expanded(flex: 2, child: cells[1]),
        if (!phone) Expanded(child: cells[2]),
        SizedBox(width: 110, child: cells[3]),
        SizedBox(width: 60, child: Align(alignment: Alignment.centerRight, child: cells[4])),
      ],
    );

    return ModuleScaffold(
      title: 'Expired Items Report',
      onBack: widget.onBack,
      backLabel: 'Back to Quick Report',
      body: Padding(
        padding: EdgeInsets.all(phone ? 12 : 26),
        child: !_allowed
            ? Panel(child: Text('You do not have access to this report.', style: TextStyle(color: c.voidInk, fontWeight: FontWeight.w700)))
            : Column(
                children: [
                  Panel(
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      crossAxisAlignment: WrapCrossAlignment.end,
                      children: [
                        SizedBox(
                          width: 280,
                          child: LabeledField(
                            label: 'Expired Before (Optional)',
                            child: DateField(
                              value: _before,
                              placeholder: 'All',
                              onChanged: (d) {
                                setState(() => _before = d);
                                _load();
                              },
                            ),
                          ),
                        ),
                        PosButton(
                          label: 'All',
                          height: 52,
                          style: _before == null ? PosButtonStyle.outline : PosButtonStyle.secondary,
                          onPressed: () {
                            setState(() => _before = null);
                            _load();
                          },
                        ),
                        PosButton(
                          label: 'Print Report',
                          height: 52,
                          style: PosButtonStyle.secondary,
                          onPressed: () => showToast(context, 'Report printing and export are not set up yet'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Expanded(
                    child: Panel(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            child: cols([Text('BARCODE', style: head), Text('DESCRIPTION', style: head), Text('DEPARTMENT', style: head), Text('EXPIRY', style: head), Text('STOCK', style: head)]),
                          ),
                          Divider(height: 1, color: c.line),
                          Expanded(
                            child: rows == null
                                ? const Center(child: CircularProgressIndicator())
                                : rows.isEmpty
                                ? Center(child: Text('No expired items', style: TextStyle(color: c.muted, fontWeight: FontWeight.w700)))
                                : ListView.separated(
                                    itemCount: rows.length,
                                    separatorBuilder: (_, _) => Divider(height: 1, color: c.rowLine),
                                    itemBuilder: (context, i) {
                                      final r = rows[i];
                                      final body = TextStyle(fontSize: 14, color: c.ink);
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                        child: cols([
                                          Text(r.barcode, style: body.copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
                                          Text(r.description, style: body.copyWith(fontWeight: FontWeight.w700)),
                                          Text(r.departmentName, style: body),
                                          Text(_format.format(r.expiryDate), style: body.copyWith(color: c.voidInk, fontWeight: FontWeight.w700)),
                                          Text('${r.stock}', style: body.copyWith(fontWeight: FontWeight.w700)),
                                        ]),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
