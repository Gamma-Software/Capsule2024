import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class LevelingBubble extends CustomPainter {
  double levelingBubbleX = 0.0;
  double levelingBubbleY = 0.0;
  bool leveled = false;

  LevelingBubble(
      {required this.levelingBubbleX, required this.levelingBubbleY});

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    const RadialGradient gradient = RadialGradient(
      center: Alignment(0.7, -0.6),
      radius: 0.2,
      colors: <Color>[
        Color.fromARGB(255, 0, 0, 0),
        Color.fromARGB(255, 0, 0, 0)
      ],
      stops: <double>[0.4, 1.0],
    );
    canvas.drawRect(
      rect,
      Paint()..shader = gradient.createShader(rect),
    );

    var paint = Paint()..color = Color.fromARGB(255, 255, 255, 255);
    canvas.drawLine(Offset(size.height / 2, size.width / 2 - 150),
        Offset(size.height / 2, size.width / 2 + 150), paint);
    canvas.drawLine(Offset(size.height / 2 - 150, size.width / 2),
        Offset(size.height / 2 + 150, size.width / 2), paint);
    if (levelingBubbleX <= 0.1 &&
        levelingBubbleX >= -0.1 &&
        levelingBubbleY <= 0.1 &&
        levelingBubbleY >= -0.1) {
      leveled = true;
    } else {
      leveled = false;
    }
    // Outer circle
    var paintOuterCircle = Paint()
      ..color = leveled
          ? const Color.fromARGB(255, 45, 162, 25)
          : const Color.fromARGB(255, 255, 2, 2)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    Offset center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(center, 150, paintOuterCircle);

    // Inner circle
    var paintInnerCircle = Paint()
      ..color = const Color.fromARGB(255, 45, 162, 25)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, 20, paintInnerCircle);

    // Bubble
    var paintBubble = Paint()
      ..color = const Color.fromARGB(255, 178, 184, 178)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
        Offset(levelingBubbleX * 150, levelingBubbleY * 150), 15, paintBubble);
  }

  @override
  SemanticsBuilderCallback get semanticsBuilder {
    return (Size size) {
      // Annotate a rectangle containing the picture of the sun
      // with the label "Sun". When text to speech feature is enabled on the
      // device, a user will be able to locate the sun on this picture by
      // touch.
      Rect rect = Offset.zero & size;
      final double width = size.shortestSide * 0.4;
      rect = const Alignment(0.8, -0.9).inscribe(Size(width, width), rect);
      return <CustomPainterSemantics>[
        CustomPainterSemantics(
          rect: rect,
          properties: const SemanticsProperties(
            label: 'Sun',
            textDirection: TextDirection.ltr,
          ),
        ),
      ];
    };
  }

  // Since this Sky painter has no fields, it always paints
  // the same thing and semantics information is the same.
  // Therefore we return false here. If we had fields (set
  // from the constructor) then we would return true if any
  // of them differed from the same fields on the oldDelegate.
  @override
  bool shouldRepaint(LevelingBubble oldDelegate) => true;
  @override
  bool shouldRebuildSemantics(LevelingBubble oldDelegate) => false;
}
