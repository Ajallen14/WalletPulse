import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class ProcessingOverlay extends StatelessWidget {
  final String message;

  const ProcessingOverlay({
    super.key,
    this.message = 'Analyzing your receipt...',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset(
              'assets/animations/cat_mark_loading.json',
              width: 200,
              height: 200,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
