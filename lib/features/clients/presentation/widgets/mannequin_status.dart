import 'package:flutter/material.dart';

class MannequinStatus extends StatelessWidget {
  final String gender;
  const MannequinStatus({super.key, required this.gender});

  @override
  Widget build(BuildContext context) {
    final String path = gender == 'FEMALE' 
        ? 'assets/models/female_mannequin.glb' 
        : 'assets/models/male_mannequin.glb';
    
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.black45,
      child: Text(
        'PATH VERIFY: $path', 
        style: const TextStyle(color: Colors.yellow, fontSize: 8, fontWeight: FontWeight.bold)
      ),
    );
  }
}
