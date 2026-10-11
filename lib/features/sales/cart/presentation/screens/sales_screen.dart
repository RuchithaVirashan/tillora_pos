import 'package:material_ui/material_ui.dart';

import '../../../../../core/responsive/adaptive_layout.dart';

/// Sales screen. Desktop layout = Sales.dc.html; mobile layout stacks the
/// cart above a bottom keypad sheet. Put each in presentation/layouts/.
class SalesScreen extends StatelessWidget {
  const SalesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AdaptiveLayout(
        desktop: (_) => const Center(child: Text('Sales · desktop layout')),
        mobile: (_) => const Center(child: Text('Sales · mobile layout')),
      ),
    );
  }
}
