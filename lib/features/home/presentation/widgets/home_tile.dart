import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

enum HomeTint {
  blue(Color(0xFFE8EEFB), Color(0xFF2952A3)),
  green(Color(0xFFE3F5EE), Color(0xFF0B7A55)),
  amber(Color(0xFFFFF3DC), Color(0xFF9A5B00)),
  violet(Color(0xFFEFEAFB), Color(0xFF5B3FB0)),
  teal(Color(0xFFDFF3F3), Color(0xFF0B6E6E)),
  slate(Color(0xFFEEF1F5), Color(0xFF3B4A60));

  const HomeTint(this.fill, this.ink);
  final Color fill;
  final Color ink;
}

class HomeTileData {
  const HomeTileData(this.name, this.description, this.icon, this.tint, this.target);

  final String name;
  final String description;
  final IconData icon;
  final HomeTint tint;

  /// A route path, or a login module slug.
  final String target;
}

class HomeTile extends StatelessWidget {
  const HomeTile({super.key, required this.data, required this.onTap});

  final HomeTileData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: c.line)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(color: data.tint.fill, borderRadius: BorderRadius.circular(14)),
                child: Icon(data.icon, color: data.tint.ink, size: 26),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data.name, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: c.ink)),
                  const SizedBox(height: 4),
                  Text(data.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: c.muted)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The large navy Sales tile.
class SalesHeroTile extends StatelessWidget {
  const SalesHeroTile({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF163A6B),
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      elevation: 10,
      shadowColor: AppColors.navy.withValues(alpha: 0.6),
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            Positioned(
              right: -60,
              bottom: -70,
              child: Icon(Icons.point_of_sale_rounded, size: 320, color: Colors.white.withValues(alpha: 0.07)),
            ),
            Padding(
              padding: const EdgeInsets.all(34),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(color: AppColors.amber, borderRadius: BorderRadius.circular(18)),
                    child: const Icon(Icons.point_of_sale_rounded, color: AppColors.navy, size: 32),
                  ),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Sales', style: TextStyle(fontSize: 48, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -1)),
                      SizedBox(height: 8),
                      Text('Log in to open the till', style: TextStyle(fontSize: 17, color: Color(0xFFC7D4E6))),
                    ],
                  ),
                  Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Open Sales', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF163A6B))),
                        SizedBox(width: 10),
                        Icon(Icons.arrow_forward_rounded, size: 18, color: Color(0xFF163A6B)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
