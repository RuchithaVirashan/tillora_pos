import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../app/di/injector.dart';
import '../../../../../core/errors/result.dart';
import '../../../../../core/session/user_session.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/choice_list.dart';
import '../../../../../core/widgets/feedback.dart';
import '../../../../../core/widgets/pos_button.dart';
import '../../../../../core/widgets/pos_dialog.dart';
import '../../domain/usecases/no_sale_usecases.dart';

/// NoSale.dc.html. Pops `true` after the drawer opens.
class NoSaleScreen extends StatefulWidget {
  const NoSaleScreen({super.key});

  @override
  State<NoSaleScreen> createState() => _NoSaleScreenState();
}

class _NoSaleScreenState extends State<NoSaleScreen> {
  final _session = getIt<SessionHolder>().current;
  NoSaleOptions? _options;
  String? _error;
  int? _selected;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    getIt<GetNoSaleOptions>()(_session).then((result) {
      if (!mounted) return;
      setState(() => switch (result) {
        Ok(:final value) => _options = value,
        Err(:final failure) => _error = failure.message,
      });
    });
  }

  Future<void> _open() async {
    setState(() => _busy = true);
    final result = await getIt<OpenDrawerNoSale>()(reason: _options!.reasons[_selected!], logId: _session.logId ?? 0);
    if (!mounted) return;
    if (result case Err(:final failure)) {
      setState(() => _busy = false);
      return showToast(context, failure.message, error: true);
    }
    context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final options = _options;
    final ready = options != null && _selected != null && options.remaining > 0 && !_busy;

    return PosDialog(
      title: 'No Sale',
      subtitle: options == null ? null : 'No sale count left this shift: ${options.remaining}',
      icon: Icons.point_of_sale_outlined,
      iconColor: const Color(0xFF2952A3),
      iconFill: const Color(0xFFE8EEFB),
      width: 620,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null)
              Text(_error!, style: TextStyle(color: c.voidInk, fontWeight: FontWeight.w700))
            else if (options == null)
              const Center(child: CircularProgressIndicator())
            else if (options.remaining <= 0)
              Text('You have reached your no sale limit for this shift.', style: TextStyle(color: c.voidInk, fontWeight: FontWeight.w700))
            else ...[
              Text('Reason for no sale:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: c.inkSecondary)),
              const SizedBox(height: 10),
              ChoiceList(
                options: options.reasons,
                selected: _selected,
                onSelected: (i) => setState(() => _selected = i),
                accent: c.primary,
                accentFill: c.selection,
                semanticLabel: 'Reason for no sale',
              ),
              const SizedBox(height: 10),
              Text('Reasons are set in Settings › POS Record Messages', style: TextStyle(fontSize: 12, color: c.muted)),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: PosButton(label: 'Cancel', height: 58, style: PosButtonStyle.secondary, onPressed: () => context.pop())),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: PosButton(label: 'Open Cash Drawer', height: 58, fontSize: 16, style: PosButtonStyle.primary, onPressed: ready ? _open : null),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
