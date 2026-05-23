import 'package:flutter/material.dart';

class OneTapButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color color;

  OneTapButton({required this.label, required this.onTap, this.color = Colors.blue});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 16), backgroundColor: color),
      onPressed: onTap,
      child: Text(label, style: TextStyle(fontSize: 18)),
    );
  }
}
