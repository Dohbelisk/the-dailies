import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/google_sign_in_service.dart';
import '../services/api_service.dart';

class GoogleSignInButton extends StatefulWidget {
  final VoidCallback? onSuccess;
  final Function(String)? onError;

  const GoogleSignInButton({
    super.key,
    this.onSuccess,
    this.onError,
  });

  @override
  State<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton> {
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    try {
      // Step 1: Get Google ID token
      final googleResult = await GoogleSignInService().signIn();

      if (googleResult.cancelled) {
        setState(() => _isLoading = false);
        return;
      }

      if (!googleResult.success) {
        widget.onError?.call(googleResult.error ?? 'Google Sign-In failed');
        setState(() => _isLoading = false);
        return;
      }

      // Step 2: Send to backend for verification
      if (!mounted) return;
      final apiService = Provider.of<ApiService>(context, listen: false);
      final result = await apiService.googleSignIn(googleResult.idToken!);

      if (result.success) {
        widget.onSuccess?.call();
      } else {
        widget.onError?.call(result.error ?? 'Sign-in failed');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SizedBox(
      height: 56,
      child: OutlinedButton(
        onPressed: _isLoading ? null : _handleGoogleSignIn,
        style: OutlinedButton.styleFrom(
          backgroundColor: isDark ? Colors.white : Colors.white,
          foregroundColor: Colors.black87,
          side: BorderSide(
            color: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black54),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Google "G" logo using custom paint
                  _GoogleLogo(size: 24),
                  const SizedBox(width: 12),
                  const Text(
                    'Continue with Google',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _GoogleLogo extends StatelessWidget {
  final double size;

  const _GoogleLogo({this.size = 24});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.width;
    final Paint paint = Paint()..style = PaintingStyle.fill;

    // Google logo colors
    const blue = Color(0xFF4285F4);
    const red = Color(0xFFEA4335);
    const yellow = Color(0xFFFBBC05);
    const green = Color(0xFF34A853);

    final center = Offset(s / 2, s / 2);
    final radius = s / 2;
    final innerRadius = radius * 0.55;

    // Blue arc (right side)
    paint.color = blue;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -0.4,
      1.6,
      true,
      paint,
    );

    // Green arc (bottom right)
    paint.color = green;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      1.2,
      0.9,
      true,
      paint,
    );

    // Yellow arc (bottom left)
    paint.color = yellow;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      2.1,
      0.9,
      true,
      paint,
    );

    // Red arc (top)
    paint.color = red;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      3.0,
      1.1,
      true,
      paint,
    );

    // White center circle (to create the "G" opening)
    paint.color = Colors.white;
    canvas.drawCircle(center, innerRadius, paint);

    // Blue horizontal bar for the "G"
    paint.color = blue;
    final barRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(s * 0.5, s * 0.4, s * 0.4, s * 0.2),
      const Radius.circular(1),
    );
    canvas.drawRRect(barRect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
