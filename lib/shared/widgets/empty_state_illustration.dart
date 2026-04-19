import 'package:flutter/material.dart';

class EmptyStateIllustration extends StatelessWidget {
  const EmptyStateIllustration({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 180,
            height: 120,
            child: CustomPaint(painter: _BallotPainter()),
          ),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _BallotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final card = Paint()..color = const Color(0xFFFFF5ED);
    final accent = Paint()..color = const Color(0xFFFF6B35);
    final green = Paint()..color = const Color(0xFF1C8C5E);

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(12, 18, size.width - 24, size.height - 28),
      const Radius.circular(16),
    );
    canvas.drawRRect(rect, card);
    canvas.drawRect(const Rect.fromLTWH(45, 26, 90, 10), accent);
    canvas.drawCircle(const Offset(45, 63), 9, accent);
    canvas.drawRect(const Rect.fromLTWH(65, 57, 70, 12), green);
    canvas.drawCircle(const Offset(45, 90), 9, green);
    canvas.drawRect(const Rect.fromLTWH(65, 84, 55, 12), accent);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

