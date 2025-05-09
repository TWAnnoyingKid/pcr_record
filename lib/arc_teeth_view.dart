import 'dart:math' as math;
import 'package:flutter/material.dart';

class ArcTeethView extends StatefulWidget {
  final List<int> teethNumbers;
  final Map<int, List<bool>> teethColorStatus;
  final Map<int, bool> missingTeeth;
  final bool isUpper;
  final Function(int, int, bool) onSectionTap;
  final Function(int) onLongPress;
  final double height;

  const ArcTeethView({
    Key? key,
    required this.teethNumbers,
    required this.teethColorStatus,
    required this.missingTeeth,
    required this.isUpper,
    required this.onSectionTap,
    required this.onLongPress,
    required this.height,
  }) : super(key: key);

  @override
  _ArcTeethViewState createState() => _ArcTeethViewState();
}

class _ArcTeethViewState extends State<ArcTeethView> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height * 2.0, // 增加高度以適應文字和牙齒
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onLongPressStart: _handleLongPress,
        child: CustomPaint(
          painter: ArcTeethPainter(
            teethNumbers: widget.teethNumbers,
            teethColorStatus: widget.teethColorStatus,
            missingTeeth: widget.missingTeeth,
            isUpper: widget.isUpper,
            toothHeight: widget.height,
          ),
          size: Size(double.infinity, widget.height * 2.0),
        ),
      ),
    );
  }

  void _handleTapDown(TapDownDetails details) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final Offset localPosition = box.globalToLocal(details.globalPosition);

    // 遍歷所有牙齒查找點擊位置
    for (int i = 0; i < widget.teethNumbers.length; i++) {
      final int toothNum = widget.teethNumbers[i];

      // 如果牙齒已標記為缺失，跳過
      if (widget.missingTeeth[toothNum] == true) {
        continue;
      }

      // 計算牙齒的尺寸和位置
      final Size size = context.size ?? Size.zero;
      final double width = size.width;
      final double height = size.height;

      // 計算牙齒寬度和間距
      final toothWidth = (width / widget.teethNumbers.length) * 0.8;
      final toothSpacing = (width - toothWidth * widget.teethNumbers.length) / (widget.teethNumbers.length + 1);

      // 計算牙齒位置
      final double arcHeight = height * 0.4;
      final double x = toothSpacing + i * (toothWidth + toothSpacing) + toothWidth / 2;

      final double normalizedPosition = i / (widget.teethNumbers.length - 1) * 2 - 1;
      final double distanceFromCenter = normalizedPosition.abs();

      double y;
      if (widget.isUpper) {
        y = arcHeight * distanceFromCenter + height * 0.45;
      } else {
        y = height - (arcHeight * distanceFromCenter + height * 0.3);
      }

      // 計算牙齒的範圍
      final Rect toothRect = Rect.fromCenter(
        center: Offset(x, y),
        width: toothWidth * 0.8,
        height: widget.height,
      );

      // 檢查點擊是否在牙齒範圍內
      if (_isPointInEllipse(localPosition, toothRect.center, toothRect.width / 2, toothRect.height / 2)) {
        // 計算相對於牙齒左上角的位置
        final double relX = localPosition.dx - toothRect.left;
        final double relY = localPosition.dy - toothRect.top;

        // 確定區域索引
        int sectionIndex = -1;

        // 檢查是否在牙齒的上半部分
        if (relY < toothRect.height / 2) {
          // 上半部分
          if (relX < toothRect.width / 3) {
            sectionIndex = 0; // 左上
          } else if (relX < toothRect.width * 2 / 3) {
            sectionIndex = 1; // 中上
          } else {
            sectionIndex = 2; // 右上
          }
        } else {
          // 下半部分
          if (relX < toothRect.width / 3) {
            sectionIndex = 3; // 左下
          } else if (relX < toothRect.width * 2 / 3) {
            sectionIndex = 4; // 中下
          } else {
            sectionIndex = 5; // 右下
          }
        }

        if (sectionIndex >= 0) {
          widget.onSectionTap(
              toothNum,
              sectionIndex,
              !widget.teethColorStatus[toothNum]![sectionIndex]
          );
          return;
        }
      }
    }
  }

  // 檢測點是否在橢圓內
  bool _isPointInEllipse(Offset point, Offset center, double radiusX, double radiusY) {
    final double dx = point.dx - center.dx;
    final double dy = point.dy - center.dy;
    return (dx * dx) / (radiusX * radiusX) + (dy * dy) / (radiusY * radiusY) <= 1.0;
  }

  void _handleLongPress(LongPressStartDetails details) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final Offset localPosition = box.globalToLocal(details.globalPosition);

    // 遍歷所有牙齒查找長按位置
    for (int i = 0; i < widget.teethNumbers.length; i++) {
      final int toothNum = widget.teethNumbers[i];

      // 計算牙齒的尺寸和位置
      final Size size = context.size ?? Size.zero;
      final double width = size.width;
      final double height = size.height;

      // 計算牙齒寬度和間距
      final toothWidth = (width / widget.teethNumbers.length) * 0.8;
      final toothSpacing = (width - toothWidth * widget.teethNumbers.length) / (widget.teethNumbers.length + 1);

      // 計算牙齒位置
      final double arcHeight = height * 0.4;
      final double x = toothSpacing + i * (toothWidth + toothSpacing) + toothWidth / 2;

      final double normalizedPosition = i / (widget.teethNumbers.length - 1) * 2 - 1;
      final double distanceFromCenter = normalizedPosition.abs();

      double y;
      if (widget.isUpper) {
        y = arcHeight * distanceFromCenter + height * 0.45;
      } else {
        y = height - (arcHeight * distanceFromCenter + height * 0.3);
      }

      // 計算牙齒的範圍
      final Rect toothRect = Rect.fromCenter(
        center: Offset(x, y),
        width: toothWidth * 0.8,
        height: widget.height,
      );

      // 檢查長按是否在牙齒範圍內
      if (_isPointInEllipse(localPosition, toothRect.center, toothRect.width / 2, toothRect.height / 2)) {
        widget.onLongPress(toothNum);
        return;
      }
    }
  }
}

class ArcTeethPainter extends CustomPainter {
  final List<int> teethNumbers;
  final Map<int, List<bool>> teethColorStatus;
  final Map<int, bool> missingTeeth;
  final bool isUpper;
  final double toothHeight;

  ArcTeethPainter({
    required this.teethNumbers,
    required this.teethColorStatus,
    required this.missingTeeth,
    required this.isUpper,
    required this.toothHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double height = size.height;

    // 繪製背景弧形
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final path = Path();
    if (isUpper) {
      // 上排牙齒弧形（向上凹）
      path.moveTo(0, 0);
      path.lineTo(0, height);
      path.lineTo(width, height);
      path.lineTo(width, 0);
      path.quadraticBezierTo(width / 2, height * 0.6, 0, 0);
    } else {
      // 下排牙齒弧形（向下凹）
      path.moveTo(0, 0);
      path.lineTo(0, height);
      path.quadraticBezierTo(width / 2, height * 0.4, width, height);
      path.lineTo(width, 0);
      path.close();
    }
    canvas.drawPath(path, paint);

    // 計算每顆牙齒的寬度和間距
    final toothWidth = (width / teethNumbers.length) * 0.8; // 增加寬度至 80%
    final toothSpacing = (width - toothWidth * teethNumbers.length) / (teethNumbers.length + 1); // 計算間距

    // 計算弧線參數
    final double arcHeight = height * 0.4;

    // 為每顆牙齒添加項目
    for (int i = 0; i < teethNumbers.length; i++) {
      final int toothNum = teethNumbers[i];
      final bool isMissing = missingTeeth[toothNum] ?? false;

      // 計算牙齒的x座標中心
      final double x = toothSpacing + i * (toothWidth + toothSpacing) + toothWidth / 2;

      // 根據弧線計算y坐標
      // 正中間牙齒的凹度最大，向兩邊遞減
      final double normalizedPosition = i / (teethNumbers.length - 1) * 2 - 1; // -1 到 1
      final double distanceFromCenter = normalizedPosition.abs(); // 與中心的距離 (0 到 1)

      double y;
      if (isUpper) {
        // 上排牙齒的y座標 (值越大越向下)
        // 中心位置y值最小，向兩邊增加
        y = arcHeight * distanceFromCenter + height * 0.45; // 稍微調整上排牙齒位置
      } else {
        // 下排牙齒的y座標
        // 中心位置y值最大，向兩邊減少
        y = height - (arcHeight * distanceFromCenter + height * 0.3);
      }

      // 繪製牙齒號碼
      TextPainter textPainter = TextPainter(
        text: TextSpan(
          text: toothNum.toString(),
          style: TextStyle(
            color: Colors.black,
            fontSize: toothHeight / 6,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      double textY;
      if (isUpper) {
        // 上排牙齒的編號放在牙齒上方，但更靠近牙齒
        textY = y - toothHeight - textPainter.height + 25;
      } else {
        // 下排牙齒的編號放在牙齒下方，靠近牙齒
        textY = y + toothHeight - 25;
      }
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, textY));

      // 計算牙齒的Rect (橢圓形)
      final Rect toothRect = Rect.fromCenter(
        center: Offset(x, y),
        width: toothWidth * 0.8,
        height: toothHeight,
      );

      // 繪製牙齒
      final RRect toothRRect = RRect.fromRectAndRadius(
        toothRect,
        Radius.circular(toothHeight / 2),
      );

      if (isMissing) {
        // 繪製缺失牙齒
        final Paint greyPaint = Paint()
          ..color = Colors.grey.shade300
          ..style = PaintingStyle.fill;
        canvas.drawRRect(toothRRect, greyPaint);

        // 繪製禁止圖標
        final Paint iconPaint = Paint()
          ..color = Colors.grey.shade700
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
        canvas.drawLine(
          Offset(x - toothWidth * 0.3, y - toothHeight * 0.3),
          Offset(x + toothWidth * 0.3, y + toothHeight * 0.3),
          iconPaint,
        );
        canvas.drawLine(
          Offset(x + toothWidth * 0.3, y - toothHeight * 0.3),
          Offset(x - toothWidth * 0.3, y + toothHeight * 0.3),
          iconPaint,
        );
      } else {
        // 繪製正常牙齒底色
        final Paint whitePaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;
        canvas.drawRRect(toothRRect, whitePaint);

        // 獲取每個區域的矩形
        List<Rect> sectionRects = [];
        // 上半部三個區域
        for (int j = 0; j < 3; j++) {
          sectionRects.add(Rect.fromLTWH(
            toothRect.left + j * (toothRect.width / 3),
            toothRect.top,
            toothRect.width / 3,
            toothRect.height / 2,
          ));
        }
        // 下半部三個區域
        for (int j = 0; j < 3; j++) {
          sectionRects.add(Rect.fromLTWH(
            toothRect.left + j * (toothRect.width / 3),
            toothRect.top + toothRect.height / 2,
            toothRect.width / 3,
            toothRect.height / 2,
          ));
        }

        // 著色區域繪製
        final Paint redPaint = Paint()
          ..color = Colors.red.withOpacity(0.7)
          ..style = PaintingStyle.fill;

        final List<bool> sections = teethColorStatus[toothNum] ?? List.filled(6, false);

        // 由於橢圓形裁剪可能會影響點擊區域，我們使用透明度而不是路徑裁剪
        for (int j = 0; j < 6; j++) {
          if (sections[j]) {
            canvas.drawRect(sectionRects[j], redPaint);
          }
        }

        // 繪製牙齒外框和分隔線
        final Paint borderPaint = Paint()
          ..color = Colors.black
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;

        // 繪製外框
        canvas.drawRRect(toothRRect, borderPaint);

        // 繪製水平分隔線
        canvas.drawLine(
          Offset(toothRect.left, toothRect.top + toothRect.height / 2),
          Offset(toothRect.right, toothRect.top + toothRect.height / 2),
          borderPaint,
        );

        // 繪製垂直分隔線
        canvas.drawLine(
          Offset(toothRect.left + toothRect.width / 3, toothRect.top),
          Offset(toothRect.left + toothRect.width / 3, toothRect.bottom),
          borderPaint,
        );
        canvas.drawLine(
          Offset(toothRect.left + toothRect.width * 2 / 3, toothRect.top),
          Offset(toothRect.left + toothRect.width * 2 / 3, toothRect.bottom),
          borderPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldPainter) => true;
}