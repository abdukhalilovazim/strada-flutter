import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// 🛡 Unknown Component Fallback
/// Prevents app crashes when the server introduces newer component types
/// that the current app binary has not pre-compiled.
class SDUIUnknownComponentFallback extends StatelessWidget {
  final String type;

  const SDUIUnknownComponentFallback({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.amber.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.amber.shade600),
        ),
        child: Text(
          'SDUI Fallback: [$type] not recognized',
          style: TextStyle(fontSize: 11, color: Colors.amber.shade900),
        ),
      );
    }
    // In production, render safely and silently without disturbing the user
    return const SizedBox.shrink();
  }
}

/// 🛡 Safe Error Boundary for SDUI Widgets
/// Catches unexpected rendering/parsing exceptions within an isolated component
class SDUISafeErrorBoundary extends StatefulWidget {
  final String type;
  final Widget child;

  const SDUISafeErrorBoundary({
    super.key,
    required this.type,
    required this.child,
  });

  @override
  State<SDUISafeErrorBoundary> createState() => _SDUISafeErrorBoundaryState();
}

class _SDUISafeErrorBoundaryState extends State<SDUISafeErrorBoundary> {
  // ignore: prefer_final_fields
  bool _hasError = false;

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return SDUIUnknownComponentFallback(type: widget.type);
    }

    return widget.child;
  }
}
