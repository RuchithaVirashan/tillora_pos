import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';

/// Home launcher. Build tiles to match Main.dc.html in the design canvas.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tillora')),
      body: Center(
        child: FilledButton(onPressed: () => context.go(Routes.sales), child: const Text('Sales')),
      ),
    );
  }
}
