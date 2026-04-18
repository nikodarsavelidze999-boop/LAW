import 'package:flutter/material.dart';
import 'package:slide_to_act/slide_to_act.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IntroScreen extends StatelessWidget {
  const IntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SizedBox.expand(
            child: Image.asset(
              'lib/assets/law.jpg',
              fit: BoxFit.cover,
            ),
          ),

          // Dark overlay
          Container(
            color: Colors.black.withAlpha(102),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 120),
              child: Text(
                "საქართველოს კანონმდებლობა",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      blurRadius: 10,
                      color: Colors.black,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: SlideAction(
              text: "დაიწყე აღმოჩენები",
              outerColor: Color(0xFF5B6F9F),
              innerColor: Colors.white,
              textStyle: TextStyle(color: Colors.white),
              onSubmit: () async {
                // ✅ SAVE THAT USER HAS SEEN INTRO
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('seenIntro', true);

                // ✅ NAVIGATE TO HOME
                Navigator.pushReplacementNamed(context, '/home');
              },
            ),
          ),
        ],
      ),
    );
  }
}