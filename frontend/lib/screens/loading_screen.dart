import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LoadingScreen extends StatelessWidget {
  final String? message;
  
  const LoadingScreen({
    Key? key,
    this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.1),
            Theme.of(context).colorScheme.surface,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: SizedBox(
                width: 80,
                height: 80,
                child: _buildAnimatedWLogo(context),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              message ?? 'Finding Your Perfect Home...',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedWLogo(BuildContext context) {
    // Get the current theme colors to dynamically color the SVG
    final primaryColor = Theme.of(context).colorScheme.primary;
    final primaryColorHex = '#${primaryColor.value.toRadixString(16).substring(2)}';
    
    const svgString = '''
<svg viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="blueGradient" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#1A237E;stop-opacity:1" />
      <stop offset="50%" style="stop-color:#283593;stop-opacity:1" />
      <stop offset="100%" style="stop-color:#3949AB;stop-opacity:1" />
    </linearGradient>
    <filter id="shadow" x="-50%" y="-50%" width="200%" height="200%">
      <feDropShadow dx="2" dy="4" stdDeviation="4" flood-opacity="0.2"/>
    </filter>
  </defs>
  
  <!-- Main W structure with house roofline -->
  <g filter="url(#shadow)">
    <!-- W outline with Netflix-style animation -->
    <path d="M20 85 L35 45 L50 75 L65 25 L80 75 L95 45 L110 85" 
          fill="none" 
          stroke="url(#blueGradient)" 
          stroke-width="8" 
          stroke-linecap="round"
          stroke-linejoin="round"
          stroke-dasharray="300"
          stroke-dashoffset="300">
      <animate attributeName="stroke-dashoffset" 
               values="300;0;0;300" 
               dur="6s" 
               begin="0s"
               repeatCount="indefinite"
               keyTimes="0;0.5;0.9;1"
               fill="freeze"/>
    </path>
  </g>
  
  <!-- Subtle ground line with delayed animation -->
  <line x1="15" y1="90" x2="105" y2="90" 
        stroke="url(#blueGradient)" 
        stroke-width="2" 
        opacity="0.4"
        stroke-dasharray="120"
        stroke-dashoffset="120">
    <animate attributeName="stroke-dashoffset" 
             values="120;0;0;120" 
             dur="6s" 
             begin="2.5s"
             repeatCount="indefinite"
             keyTimes="0;0.4;0.8;1"
             fill="freeze"/>
  </line>
</svg>
    ''';

    return SvgPicture.string(
      svgString,
      fit: BoxFit.contain,
    );
  }
}