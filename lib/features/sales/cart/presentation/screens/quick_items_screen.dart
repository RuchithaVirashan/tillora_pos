import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../core/responsive/breakpoints.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/pos_dialog.dart';
import '../../domain/entities/sellable_item.dart';
import '../widgets/till_controls.dart';

/// Every quick item, searchable. Pops the tapped [SellableItem].
class QuickItemsScreen extends StatefulWidget {
  const QuickItemsScreen({super.key, required this.items});

  final List<SellableItem> items;

  @override
  State<QuickItemsScreen> createState() => _QuickItemsScreenState();
}

class _QuickItemsScreenState extends State<QuickItemsScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final q = _query.trim().toLowerCase();
    final shown = q.isEmpty ? widget.items : widget.items.where((i) => i.description.toLowerCase().contains(q)).toList();
    final columns = switch (Breakpoints.of(context)) {
      DeviceClass.phone => 2,
      DeviceClass.tablet => 4,
      DeviceClass.desktop => 5,
    };

    return PosDialog(
      title: 'Quick Items',
      subtitle: '${widget.items.length} items · non-barcode items first',
      width: 1000,
      height: 720,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            autofocus: true,
            onChanged: (v) => setState(() => _query = v),
            decoration: const InputDecoration(hintText: 'Search items', prefixIcon: Icon(Icons.search_rounded)),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: shown.isEmpty
                ? Center(child: Text('No items match "$_query"', style: TextStyle(color: c.muted, fontWeight: FontWeight.w700)))
                : GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      mainAxisExtent: 76,
                    ),
                    itemCount: shown.length,
                    itemBuilder: (context, i) => QuickItemTile(item: shown[i], onTap: () => context.pop(shown[i])),
                  ),
          ),
        ],
      ),
    );
  }
}
