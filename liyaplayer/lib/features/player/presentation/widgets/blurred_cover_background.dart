import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';

class BlurredCoverBackground extends StatelessWidget {
  const BlurredCoverBackground({
    super.key,
    required this.albumArtPath,
    required this.child,
  });

  final String? albumArtPath;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFF1E1E1E),
      child: Stack(
        children: [
          if (albumArtPath != null && File(albumArtPath!).existsSync())
            ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Image.file(
                File(albumArtPath!),
                fit: BoxFit.cover,
              ),
            )
          else
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                ),
              ),
            ),
          Container(color: Colors.black.withValues(alpha: 0.4)),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}