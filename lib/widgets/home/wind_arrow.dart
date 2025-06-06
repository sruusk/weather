import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class WindArrow extends StatefulWidget {
  final double degrees;
  final double windSpeed;
  final double size;
  final bool autoCenter;

  const WindArrow({
    super.key,
    required this.degrees,
    required this.windSpeed,
    this.size = 50.0,
    this.autoCenter = true,
  });

  @override
  State<WindArrow> createState() => _WindArrowState();
}

class _WindArrowState extends State<WindArrow>
    with SingleTickerProviderStateMixin {
  _windRadians() {
    return (widget.degrees - 180).abs() * (pi / 180);
  }

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(
          0, widget.autoCenter ? (widget.size / 10) * cos(_windRadians()) : 0),
      child: Stack(
        children: [
          Transform.rotate(
            angle: _windRadians(),
            child: SvgPicture.asset(
              'assets/symbols/wind.svg',
              width: widget.size,
              height: widget.size,
              colorFilter: ColorFilter.mode(
                Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Color(0xFF0062B8),
                BlendMode.srcIn,
              ),
            ),
          ),
          Positioned.fill(
            child: Center(
              child: Text(
                widget.windSpeed.toStringAsFixed(0),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
