import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_state.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import 'admin/admin_dashboard_screen.dart';
import 'dashboard/dashboard_layout.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Animation configuration
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.65, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
      ),
    );

    _controller.forward();
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    // Wait for splash animations to play
    await Future.delayed(const Duration(milliseconds: 3000));

    if (!mounted) return;

    final appState = context.read<AppState>();
    await appState.initialized;
    if (!mounted) return;

    Widget destination;
    if (appState.authInitializationError != null) {
      destination = LoginScreen(
        initialMessage: appState.authInitializationError,
      );
    } else {
      final user = appState.currentUser;
      if (user?.isAdmin == true) {
        try {
          await context.read<AdminState>().activateAdminSession(user!);
          destination = const AdminDashboardScreen();
        } catch (error, stackTrace) {
          debugPrint('Could not restore the admin session: $error');
          debugPrintStack(stackTrace: stackTrace);
          try {
            await appState.logout();
          } catch (logoutError, logoutStackTrace) {
            debugPrint('Could not clear the failed admin session: $logoutError');
            debugPrintStack(stackTrace: logoutStackTrace);
          }
          destination = const LoginScreen(
            initialMessage: 'Sesi admin tidak dapat diverifikasi. Silakan masuk kembali.',
          );
        }
      } else {
        destination = const DashboardLayout();
      }
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => destination),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Decorative background glowing spots (Radial mesh style)
            Positioned(
              top: -size.height * 0.15,
              left: -size.width * 0.2,
              child: Container(
                width: size.width * 0.9,
                height: size.width * 0.9,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.primaryIndigo.withOpacity(0.25),
                      AppTheme.primaryIndigo.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -size.height * 0.15,
              right: -size.width * 0.2,
              child: Container(
                width: size.width * 0.9,
                height: size.width * 0.9,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.accentPink.withOpacity(0.18),
                      AppTheme.accentPink.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),

            // Core branding contents
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Glassmorphic App Icon Container with Premium Gradient Glow
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppTheme.premiumGradient,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.25),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryIndigo.withOpacity(0.4),
                                blurRadius: 35,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.event_note_rounded,
                            size: 60,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 28),

                        // App Name
                        const Text(
                          'Eventify Campus',
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Tagline
                        Text(
                          'Manage events. Simplify campus life.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.65),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // Bottom Loading Indicator and status text
            Positioned(
              bottom: 60,
              child: Column(
                children: [
                  const SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 2.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Mempersiapkan Aplikasi...',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.45),
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
