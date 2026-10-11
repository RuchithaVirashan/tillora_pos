import 'package:material_ui/material_ui.dart';

import '../../../../../app/di/injector.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/feedback.dart';
import '../../../../../core/widgets/module_scaffold.dart';
import '../../../../../core/widgets/pos_button.dart';
import '../../domain/repositories/payout_items_repository.dart';
import '../../domain/usecases/payout_items_usecases.dart';

/// Manage Payout Products: the reasons offered on the Payout screen.
class PayoutItemsPanel extends StatefulWidget {
  const PayoutItemsPanel({super.key});

  @override
  State<PayoutItemsPanel> createState() => _PayoutItemsPanelState();
}

class _PayoutItemsPanelState extends State<PayoutItemsPanel> {
  final _name = TextEditingController();
  List<PayoutItem>? _items;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final result = await getIt<GetPayoutItems>()();
    if (result case Ok(:final value) when mounted) setState(() => _items = value);
  }

  Future<void> _save() async {
    final result = await getIt<AddPayoutItem>()(_name.text, existing: _items ?? const []);
    if (!mounted) return;
    if (result case Err(:final failure)) return showToast(context, failure.message, error: true);
    showToast(context, '${_name.text.trim()} added');
    _name.clear();
    _reload();
  }

  Future<void> _delete(PayoutItem item) async {
    final ok = await confirm(context, title: 'Delete payout', message: 'Delete ${item.name}?', confirmLabel: 'Delete', destructive: true);
    if (!ok || !mounted) return;
    if (await getIt<DeletePayoutItem>()(item.id) case Err(:final failure)) {
      if (mounted) showToast(context, failure.message, error: true);
      return;
    }
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final items = _items;
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        LabeledField(
          label: 'Name',
          child: TextField(controller: _name, onSubmitted: (_) => _save(), decoration: const InputDecoration(hintText: 'Payout Name')),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: PosButton(label: 'Cancel', height: 54, style: PosButtonStyle.secondary, onPressed: _name.clear)),
            const SizedBox(width: 10),
            Expanded(flex: 2, child: PosButton(label: 'Save', height: 54, fontSize: 16, style: PosButtonStyle.primary, onPressed: _save)),
          ],
        ),
        const SizedBox(height: 24),
        Text('Payout items', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.6, color: c.muted)),
        const SizedBox(height: 8),
        if (items == null)
          const Center(child: CircularProgressIndicator())
        else if (items.isEmpty)
          Text('No payout items yet.', style: TextStyle(color: c.muted))
        else
          for (final item in items)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Text('#${item.id}', style: TextStyle(color: c.muted, fontWeight: FontWeight.w700)),
              title: Text(item.name, style: TextStyle(fontWeight: FontWeight.w700, color: c.ink)),
              trailing: IconButton(tooltip: 'Delete', icon: Icon(Icons.delete_outline_rounded, color: c.voidInk), onPressed: () => _delete(item)),
            ),
      ],
    );
  }
}
