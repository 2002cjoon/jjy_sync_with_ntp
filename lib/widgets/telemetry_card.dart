// lib/widgets/telemetry_card.dart
import 'package:flutter/material.dart';

class TelemetryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const TelemetryCard({
    super.key,
    required this.label,
    required this.value,
    this.valueColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: valueColor, fontFamily: 'Courier')),
        ],
      ),
    );
  }
}