import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../core/platform/customer_display.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/money.dart';
import '../../../../../core/widgets/brand_mark.dart';

/// CustomerDisplay.dc.html: the customer-facing second screen.
class CustomerDisplayScreen extends StatelessWidget {
  const CustomerDisplayScreen({super.key, required this.frames});

  final ValueListenable<DisplayFrame?> frames;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: ValueListenableBuilder<DisplayFrame?>(
        valueListenable: frames,
        builder: (context, frame, _) {
          final f = frame ?? const DisplayFrame(companyName: '');
          final wide = MediaQuery.sizeOf(context).width >= 900;
          final style = f.style;
          final left = style.adverts.isEmpty ? _BrandPanel(frame: f) : _AdvertPanel(images: style.adverts, seconds: style.advertSeconds);
          final right = MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(style.textScale)),
            child: _SalePanel(frame: f),
          );
          return wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [Expanded(flex: style.split.left, child: left), Expanded(flex: style.split.right, child: right)],
                )
              : Column(children: [SizedBox(height: 180, child: left), Expanded(child: right)]);
        },
      ),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel({required this.frame});

  final DisplayFrame frame;

  @override
  Widget build(BuildContext context) {
    final (headline, sub) = frame.complete
        ? (frame.refund ? 'Refund complete' : 'Thank you!', frame.changeCents > 0 ? 'Please take your change' : 'Have a great day')
        : frame.idle
        ? ('Welcome', 'Your items will appear here')
        : (frame.refund ? 'Refund in progress' : 'Your purchase', '${frame.itemCount} items');
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const BrandMark(size: 48, showName: false),
              const SizedBox(width: 14),
              Flexible(
                child: Text(
                  frame.companyName.isEmpty ? 'Tillora' : frame.companyName,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
              ),
              padding: const EdgeInsets.all(32),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      frame.complete ? Icons.check_circle_outline_rounded : Icons.shopping_basket_outlined,
                      size: 72,
                      color: frame.complete ? AppColors.live : AppColors.amber,
                    ),
                    const SizedBox(height: 16),
                    Text(headline, style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w800, color: Colors.white)),
                    const SizedBox(height: 8),
                    Text(sub, style: const TextStyle(fontSize: 20, color: Color(0xFFAFC0D8))),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SalePanel extends StatelessWidget {
  const _SalePanel({required this.frame});

  final DisplayFrame frame;

  static String _rs(int cents) => '${cents < 0 ? '−' : ''}${Money.lkr(Money.fromCents(cents.abs()))}';

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF0F1B2D);
    const muted = Color(0xFF667085);
    const line = Color(0xFFE3E8EF);
    const head = TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.1, color: muted);
    const nums = [FontFeature.tabularFigures()];
    Widget cols(List<Widget> c) => Row(
      children: [
        Expanded(child: c[0]),
        SizedBox(width: 50, child: Center(child: c[1])),
        SizedBox(width: 100, child: Align(alignment: Alignment.centerRight, child: c[2])),
        SizedBox(width: 110, child: Align(alignment: Alignment.centerRight, child: c[3])),
      ],
    );

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF6F8FB),
        borderRadius: BorderRadius.horizontal(left: Radius.circular(32)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: line)),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  Container(
                    color: const Color(0xFFF7F9FB),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    child: cols(const [Text('DESCRIPTION', style: head), Text('QTY', style: head), Text('PRICE', style: head), Text('AMOUNT', style: head)]),
                  ),
                  const Divider(height: 1, color: line),
                  Expanded(
                    child: frame.idle
                        ? const Center(child: Text('Welcome', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: muted)))
                        : ListView.separated(
                            reverse: false,
                            itemCount: frame.lines.length,
                            separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0xFFEEF1F5)),
                            itemBuilder: (context, i) {
                              final l = frame.lines[i];
                              final discount = l.quantity == 0;
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                                child: cols([
                                  Text(l.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: ink)),
                                  Text(discount ? '' : '${l.quantity}', style: const TextStyle(fontSize: 16, color: ink, fontFeatures: nums)),
                                  Text(discount ? '' : _rs(l.priceCents), style: const TextStyle(fontSize: 15, color: Color(0xFF475467), fontFeatures: nums)),
                                  Text(_rs(l.amountCents), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: ink, fontFeatures: nums)),
                                ]),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text('Items: ${frame.itemCount}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: muted)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _Figure('TOTAL', _rs(frame.totalCents), fill: const Color(0xFF163A6B), ink: Colors.white, labelInk: const Color(0xFFC7D4E6))),
              const SizedBox(width: 10),
              Expanded(child: _Figure('PAID', _rs(frame.paidCents), fill: Colors.white, ink: ink, labelInk: muted, border: line)),
              const SizedBox(width: 10),
              Expanded(
                child: _Figure(
                  'CHANGE',
                  _rs(frame.changeCents),
                  fill: frame.complete ? AppColors.success : Colors.white,
                  ink: frame.complete ? Colors.white : muted,
                  labelInk: frame.complete ? const Color(0xFFD7F3E7) : muted,
                  border: frame.complete ? null : line,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure(this.label, this.value, {required this.fill, required this.ink, required this.labelInk, this.border});

  final String label;
  final String value;
  final Color fill;
  final Color ink;
  final Color labelInk;
  final Color? border;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      color: fill,
      borderRadius: BorderRadius.circular(16),
      border: border == null ? null : Border.all(color: border!),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1.1, color: labelInk)),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: ink, fontFeatures: const [FontFeature.tabularFigures()])),
        ),
      ],
    ),
  );
}

/// Advert images shown in turn, [seconds] each, with a fade.
class _AdvertPanel extends StatefulWidget {
  const _AdvertPanel({required this.images, required this.seconds});

  final List<String> images;
  final int seconds;

  @override
  State<_AdvertPanel> createState() => _AdvertPanelState();
}

class _AdvertPanelState extends State<_AdvertPanel> {
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(_AdvertPanel old) {
    super.didUpdateWidget(old);
    if (old.seconds != widget.seconds || !listEquals(old.images, widget.images)) {
      _index = 0;
      _start();
    }
  }

  void _start() {
    _timer?.cancel();
    if (widget.images.length < 2) return;
    _timer = Timer.periodic(Duration(seconds: widget.seconds.clamp(2, 600)), (_) => setState(() => _index = (_index + 1) % widget.images.length));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final path = widget.images[_index % widget.images.length];
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      child: Image.file(
        File(path),
        key: ValueKey(path),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, _, _) => const SizedBox.expand(),
      ),
    );
  }
}
