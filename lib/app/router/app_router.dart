import 'package:go_router/go_router.dart';

import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/sales/cart/presentation/screens/sales_screen.dart';
import 'routes.dart';

/// Add a GoRoute here as each feature screen is built.
final appRouter = GoRouter(
  initialLocation: Routes.home,
  routes: [
    GoRoute(path: Routes.home, builder: (_, _) => const HomeScreen()),
    GoRoute(path: Routes.sales, builder: (_, _) => const SalesScreen()),
  ],
);
