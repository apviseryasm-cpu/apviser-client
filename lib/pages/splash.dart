import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Ensure white background
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Spinner with logo inside
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    strokeWidth: 4,
                    color: Colors.blueAccent,
                  ),
                ),
                ClipOval(
                  child: Image.asset(
                    'assets/images/logo.png',
                    height: 40,
                    width: 40,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ).animate().fade(duration: 1000.ms).scale(),

            const SizedBox(height: 24),

            // Animated Text like web
            Text(
              "⚡ Hang tight! Launching Apviser...",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            )
                .animate()
                .fade(duration: 1000.ms, delay: 600.ms)
                .moveY(begin: 12, end: 0, duration: 800.ms),
          ],
        ),
      ),
    );
  }
}


// class SplashScreen extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white, // Ensure background is white
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             // Animated Logo
//             Image.asset('assets/images/logo.png', height: 100)
//                 .animate()
//                 .fade(duration: 800.ms) // Fade-in effect
//                 .scale(duration: 1200.ms, curve: Curves.easeOut), // Scale effect
//
//             SizedBox(height: 20),
//
//             // Animated Banner Text
//             Text(
//               "Your Advice Matters!",
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//                 //fontFamily: 'Signatra',
//                 color: Colors.black87,
//               ),
//             )
//                 .animate()
//                 .fade(duration: 1000.ms, delay: 500.ms) // Delayed fade-in effect
//                 .moveY(begin: 10, end: 0, duration: 800.ms), // Subtle slide-up
//
//             SizedBox(height: 30),
//
//             CircularProgressIndicator(), // Loader
//           ],
//         ),
//       ),
//     );
//   }
// }
