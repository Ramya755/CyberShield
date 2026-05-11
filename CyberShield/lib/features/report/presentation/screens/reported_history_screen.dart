import 'package:flutter/material.dart';

class ReportedHistoryScreen extends StatelessWidget {
  const ReportedHistoryScreen({super.key});

  static const Color _bgTop = Color(0xFF030B2D);
  static const Color _bgBottom = Color(0xFF060C24);
  static const Color _violet = Color(0xFF9A63FF);
  static const Color _textMuted = Color(0xFFAAB6D3);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reported History'),
        leading: BackButton(
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: _bgBottom,
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_bgTop, _bgBottom],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(10),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withAlpha(18),
                    ),
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.history_toggle_off_rounded,
                        color: _violet,
                        size: 72,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Reported History',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'This screen is kept for reported history and stored reports later.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _textMuted,
                          fontSize: 14.5,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}