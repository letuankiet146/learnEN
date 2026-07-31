import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WordGameCompleteScreen extends StatelessWidget {
  const WordGameCompleteScreen({
    super.key,
    required this.totalWords,
    required this.onPlayAgain,
  });

  final int totalWords;
  final VoidCallback onPlayAgain;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/shin/cacban.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          color: Colors.white.withValues(alpha: 0.12),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFEA580C).withValues(alpha: 0.25),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text('🎉', style: TextStyle(fontSize: 72)),
                        const SizedBox(height: 12),
                        Text(
                          'Chúc mừng!',
                          style: GoogleFonts.fredoka(
                            fontSize: 42,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFEA580C),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Bé đã hoàn thành $totalWords từ!\nGiỏi lắm!',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.fredoka(
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF475569),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset(
                            'assets/images/shin/true/dihoc.png',
                            height: 140,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      onPressed: onPlayAgain,
                      child: Text(
                        'Chơi lại 🔄',
                        style: GoogleFonts.fredoka(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.9),
                        side: const BorderSide(
                          color: Color(0xFFEA580C),
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Chọn chủ đề khác 📚',
                        style: GoogleFonts.fredoka(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFEA580C),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
