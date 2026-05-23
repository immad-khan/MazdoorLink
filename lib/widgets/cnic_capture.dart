import 'package:flutter/material.dart';

class CnicCapture extends StatelessWidget {
  final VoidCallback onCapture;
  final String label;
  CnicCapture({required this.onCapture, this.label = 'Capture CNIC'});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(Icons.photo_camera, size: 40),
        title: Text(label),
        subtitle: Text('Front / Back images required'),
        trailing: ElevatedButton(onPressed: onCapture, child: Text('Capture')),
      ),
    );
  }
}
