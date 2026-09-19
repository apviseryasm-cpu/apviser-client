import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff9f9f9),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header section
            Container(
              color: const Color(0xff202124),
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
              width: double.infinity,
              child: Column(
                children: [
                  // Logo (replace with actual path or Image.asset)
                  SizedBox(
                    height: 80,
                    child: Image.asset(
                      'assets/images/logo.png', // Make sure to add it in pubspec.yaml
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Apviser',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Your network is your best advisor.\nGet real opinions from people you trust.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      // Navigate to web app
                      // You can use url_launcher package if needed
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xffd93025),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text("Join the Beta"),
                  ),
                ],
              ),
            ),

            // Middle section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Column(
                children: [
                  const Text(
                    '🚀 Ready to Make Smarter Decisions with Your People?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Apviser helps you get opinions and referrals — not from strangers, but from people you trust. Try our powerful polls and request-based features to crowdsource real advice.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                  const SizedBox(height: 32),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 16,
                    runSpacing: 12,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          // Android store link
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xffea4335),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text("Get it on Android"),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          // Web app link
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text("Use on Web (Beta)"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "iOS version coming soon",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),

            // Footer
            Container(
              color: const Color(0xff202124),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: const Center(
                child: Text(
                  "© 2025 Apviser | Built with ❤ by a passionate indie team",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
