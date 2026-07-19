// lib/widgets/jjy_visualizer.dart
import 'package:flutter/material.dart';

class JJYSignalVisualizer extends StatefulWidget {
  final bool isTransmitting;
  const JJYSignalVisualizer({super.key, required this.isTransmitting});

  @override
  State<JJYSignalVisualizer> createState() => _JJYSignalVisualizerState();
}

class _JJYSignalVisualizerState extends State<JJYSignalVisualizer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    if (widget.isTransmitting) _controller.repeat();
  }

  @override
  void didUpdateWidget(JJYSignalVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isTransmitting && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isTransmitting && _controller.isAnimating) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160, width: 160,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              _buildRippleRing(value: _controller.value, delay: 0.5),
              _buildRippleRing(value: _controller.value, delay: 0.0),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.isTransmitting ? Colors.green.withAlpha(30) : Colors.blueAccent.withAlpha(20),
                ),
                padding: const EdgeInsets.all(20),
                child: Icon(
                  Icons.settings_input_antenna,
                  size: 48,
                  color: widget.isTransmitting ? Colors.greenAccent : Colors.blueAccent,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRippleRing({required double value, required double delay}) {
    if (!widget.isTransmitting) return const SizedBox.shrink();
    double progress = (value + delay) % 1.0;
    return Transform.scale(
      scale: 1.0 + (progress * 1.2),
      child: Opacity(
        opacity: (1.0 - progress).clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.greenAccent, width: 1.5),
          ),
          width: 80, height: 80,
        ),
      ),
    );
  }
}