import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';

class WeatherSymbolWidget extends StatelessWidget {
  final String symbolName;
  final bool filled;
  final bool static;
  final double size;

  const WeatherSymbolWidget({
    super.key,
    required this.symbolName,
    this.filled = true,
    this.static = false,
    this.size = 48.0,
  });

  @override
  Widget build(BuildContext context) {
    final String symbolType = filled ? 'fill' : 'line';

    return static
        ? SvgPicture.asset(
            'assets/symbols/$symbolType/svg-static/$symbolName.svg',
            width: size,
            height: size,
            fit: BoxFit.contain,
            colorFilter: ColorFilter.matrix(
              <double>[
                0.9, 0, 0, 0, 0,
                0, 0.9, 0, 0, 0,
                0, 0, 0.9, 0, 0,
                0, 0, 0, 1.5, 0,
              ],
            ),
            errorBuilder: (context, error, stackTrace) {
              debugPrint('Error loading SVG: $error');
              return const Icon(Icons.error, size: 24, color: Colors.red);
            },
          )
        : SizedBox(
            width: size,
            height: size,
            child: Lottie.asset(
              'assets/symbols/$symbolType/$symbolName.json',
              width: size,
              height: size,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                // debugPrint('Error loading Lottie animation: $error');
                return SvgPicture.asset(
                  'assets/symbols/$symbolType/svg-static/$symbolName.svg',
                  width: size,
                  height: size,
                  fit: BoxFit.contain,
                  colorFilter: ColorFilter.matrix(
                    <double>[
                      0.9, 0, 0, 0, 0,
                      0, 0.9, 0, 0, 0,
                      0, 0, 0.9, 0, 0,
                      0, 0, 0, 1.5, 0,
                    ],
                  ),
                  errorBuilder: (context, error, stackTrace) {
                    debugPrint('Error loading SVG: $error');
                    return const Icon(Icons.error, size: 24, color: Colors.red);
                  },
                );
              },
            ),
          );
  }
}
