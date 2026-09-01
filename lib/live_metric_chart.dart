part of 'main.dart';

class LiveMetricChart extends StatefulWidget {
  final String title;
  final List<double> data;
  final Color color;
  final String unit;
  final double maxValue;
  final String? totalCapacity;

  const LiveMetricChart({
    super.key,
    required this.title,
    required this.data,
    required this.color,
    this.unit = '%',
    this.maxValue = 100.0,
    this.totalCapacity,
  });

  @override
  State<LiveMetricChart> createState() => _LiveMetricChartState();
}

class _LiveMetricChartState extends State<LiveMetricChart> {
  int? _hoverIndex;
  bool _isHovered = false;

  static const double leftGutter = 44.0;
  static const double rightGutter = 12.0;
  static const double topGutter = 8.0;
  static const double bottomGutter = 24.0;

  void _updateHover(Offset localPos, double totalWidth) {
    if (widget.data.isEmpty || totalWidth <= (leftGutter + rightGutter)) return;
    final plotWidth = totalWidth - leftGutter - rightGutter;
    final relativeX = (localPos.dx - leftGutter).clamp(0.0, plotWidth);
    final count = widget.data.length;
    final idx = (count > 1)
        ? ((relativeX / plotWidth) * (count - 1)).round().clamp(0, count - 1)
        : 0;

    setState(() {
      _isHovered = true;
      _hoverIndex = idx;
    });
  }

  void _clearHover() {
    if (_isHovered) {
      setState(() {
        _isHovered = false;
        _hoverIndex = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final latestVal = widget.data.isNotEmpty ? widget.data.last : 0.0;
    final hoverVal = (_hoverIndex != null && _hoverIndex! < widget.data.length)
        ? widget.data[_hoverIndex!]
        : null;

    final displayedVal = hoverVal ?? latestVal;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xff27272a),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xff3f3f46), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: Color(0xffd4d4d8),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _isHovered
                          ? 'Hover Point'
                          : (widget.totalCapacity != null
                                ? 'Max Capacity: ${widget.totalCapacity}'
                                : 'Maximum: 100%'),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xff71717a),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xff18181b),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: const Color(0xff3f3f46),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '${displayedVal.toStringAsFixed(1)}${widget.unit}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: widget.color,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 180,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final chartWidth = constraints.maxWidth;
                  final chartHeight = constraints.maxHeight;
                  final plotWidth = chartWidth - leftGutter - rightGutter;
                  final plotHeight = chartHeight - topGutter - bottomGutter;

                  Offset? activePoint;
                  String? timeOffsetStr;
                  if (_hoverIndex != null &&
                      widget.data.isNotEmpty &&
                      plotWidth > 0) {
                    final count = widget.data.length;
                    final x =
                        leftGutter +
                        (count > 1
                            ? (_hoverIndex! / (count - 1)) * plotWidth
                            : plotWidth / 2);
                    final v = widget.data[_hoverIndex!];
                    final y =
                        topGutter +
                        plotHeight -
                        (v / widget.maxValue * plotHeight).clamp(
                          0.0,
                          plotHeight,
                        );
                    activePoint = Offset(x, y);

                    final secAgo = ((count - 1 - _hoverIndex!) * 0.75);
                    timeOffsetStr = secAgo <= 0.1
                        ? 'Now'
                        : '${secAgo.toStringAsFixed(1)}s ago';
                  }

                  return MouseRegion(
                    cursor: SystemMouseCursors.precise,
                    onHover: (e) => _updateHover(e.localPosition, chartWidth),
                    onExit: (_) => _clearHover(),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: InteractiveChartPainter(
                              data: widget.data,
                              color: widget.color,
                              maxValue: widget.maxValue,
                              unit: widget.unit,
                              hoverIndex: _hoverIndex,
                            ),
                          ),
                        ),
                        if (_isHovered &&
                            activePoint != null &&
                            timeOffsetStr != null)
                          Positioned(
                            left: (activePoint.dx - 45).clamp(
                              leftGutter,
                              chartWidth - rightGutter - 90,
                            ),
                            top: (activePoint.dy - 48).clamp(
                              0.0,
                              chartHeight - 40,
                            ),
                            child: IgnorePointer(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xff18181b),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: const Color(0xff52525b),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${displayedVal.toStringAsFixed(1)}${widget.unit}',
                                      style: TextStyle(
                                        color: widget.color,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                    Text(
                                      timeOffsetStr,
                                      style: const TextStyle(
                                        color: Color(0xffa1a1aa),
                                        fontSize: 9.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InteractiveChartPainter extends CustomPainter {
  final List<double> data;
  final Color color;
  final double maxValue;
  final String unit;
  final int? hoverIndex;

  InteractiveChartPainter({
    required this.data,
    required this.color,
    required this.maxValue,
    required this.unit,
    this.hoverIndex,
  });

  static const double leftGutter = 44.0;
  static const double rightGutter = 12.0;
  static const double topGutter = 8.0;
  static const double bottomGutter = 24.0;

  @override
  void paint(Canvas canvas, Size size) {
    final plotWidth = size.width - leftGutter - rightGutter;
    final plotHeight = size.height - topGutter - bottomGutter;
    if (plotWidth <= 0 || plotHeight <= 0) return;

    final axisPaint = Paint()
      ..color = const Color(0xff3f3f46)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final gridPaint = Paint()
      ..color = const Color(0xff333338)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final labelStyle = const TextStyle(
      color: Color(0xff71717a),
      fontSize: 9.5,
      fontWeight: FontWeight.w500,
      fontFamily: 'monospace',
    );

    final yLevels = [0.0, 0.25, 0.50, 0.75, 1.0];
    for (final level in yLevels) {
      final y = topGutter + plotHeight * (1.0 - level);

      if (level > 0.0) {
        canvas.drawLine(
          Offset(leftGutter, y),
          Offset(leftGutter + plotWidth, y),
          gridPaint,
        );
      }

      canvas.drawLine(
        Offset(leftGutter - 3, y),
        Offset(leftGutter, y),
        axisPaint,
      );

      String yText;
      if (unit.trim() == '%') {
        yText = '${(level * 100).toInt()}%';
      } else {
        final val = level * maxValue;
        yText = '${val.toStringAsFixed(0)}G';
      }

      final textSpan = TextSpan(text: yText, style: labelStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textAlign: TextAlign.right,
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(leftGutter - 6 - textPainter.width, y - textPainter.height / 2),
      );
    }

    final xSteps = [-40, -30, -20, -10, 0];
    for (final step in xSteps) {
      final fraction = (step + 40) / 40.0;
      final x = leftGutter + plotWidth * fraction;

      canvas.drawLine(
        Offset(x, topGutter + plotHeight),
        Offset(x, topGutter + plotHeight + 3),
        axisPaint,
      );

      final xText = step == 0 ? '0s' : '${step}s';

      final textSpan = TextSpan(text: xText, style: labelStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, topGutter + plotHeight + 6),
      );
    }

    canvas.drawLine(
      const Offset(leftGutter, topGutter),
      Offset(leftGutter, topGutter + plotHeight),
      axisPaint,
    );
    canvas.drawLine(
      Offset(leftGutter, topGutter + plotHeight),
      Offset(leftGutter + plotWidth, topGutter + plotHeight),
      axisPaint,
    );

    if (data.length < 2) return;

    final points = <Offset>[];
    for (var i = 0; i < data.length; i++) {
      final x = leftGutter + (i * plotWidth / (data.length - 1));
      final y =
          topGutter +
          plotHeight -
          (data[i] / maxValue * plotHeight).clamp(0.0, plotHeight);
      points.add(Offset(x, y));
    }

    final fillPath = Path();
    fillPath.moveTo(points.first.dx, topGutter + plotHeight);
    for (final pt in points) {
      fillPath.lineTo(pt.dx, pt.dy);
    }
    fillPath.lineTo(points.last.dx, topGutter + plotHeight);
    fillPath.close();

    final fillPaint = Paint()
      ..color = color.withAlpha(20)
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    final linePath = Path();
    for (var i = 0; i < points.length; i++) {
      if (i == 0) {
        linePath.moveTo(points[i].dx, points[i].dy);
      } else {
        linePath.lineTo(points[i].dx, points[i].dy);
      }
    }

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(linePath, linePaint);

    if (hoverIndex != null && hoverIndex! < points.length) {
      final hPoint = points[hoverIndex!];

      final hoverLinePaint = Paint()
        ..color = const Color(0x40ffffff)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;

      canvas.drawLine(
        Offset(hPoint.dx, topGutter),
        Offset(hPoint.dx, topGutter + plotHeight),
        hoverLinePaint,
      );

      final dotPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(hPoint, 3.0, dotPaint);
    } else {
      final lastPoint = points.last;
      final dotPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(lastPoint, 2.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant InteractiveChartPainter oldDelegate) => true;
}
