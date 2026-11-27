import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/admin_state.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import 'admin/admin_dashboard_screen.dart';
import 'register_screen.dart';
import 'dashboard/dashboard_layout.dart';

class LoginScreen extends StatefulWidget {
  final bool openAddEventAfterLogin;
  final String? initialMessage;

  const LoginScreen({
    super.key,
    this.openAddEventAfterLogin = false,
    this.initialMessage,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginHeroClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height - 44)
      ..cubicTo(
        size.width * 0.72,
        size.height - 2,
        size.width * 0.3,
        size.height - 2,
        0,
        size.height - 34,
      )
      ..close();
  }

  @override
  bool shouldReclip(covariant _LoginHeroClipper oldClipper) => false;
}

class _LoginScreenState extends State<LoginScreen> {
  static const _savedAdminEmailKey = 'saved_admin_email';

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordController = TextEditingController();
  String? _savedAdminEmail;

  @override
  void initState() {
    super.initState();
    _loadSavedAdminEmail();
    if (widget.initialMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showSnackbar(widget.initialMessage!);
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocusNode.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedAdminEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        _savedAdminEmail = prefs.getString(_savedAdminEmailKey);
      });
    } catch (error) {
      debugPrint('Could not load the saved login email: $error');
    }
  }

  Future<void> _saveLoginEmail(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_savedAdminEmailKey, email);
    } catch (error) {
      debugPrint('Could not save the login email suggestion: $error');
    }
  }

  void _showSnackbar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? AppTheme.accentPink : AppTheme.successGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final appState = Provider.of<AppState>(context, listen: false);
    final adminState = context.read<AdminState>();

    try {
      final user = await appState.login(
        _emailController.text.trim(),
        _passwordController.text,
      );
      await _saveLoginEmail(_emailController.text.trim());
      if (user.isAdmin) {
        await adminState.activateAdminSession(user);
      }

      if (!mounted) return;
      _showSnackbar(
        user.isAdmin ? 'Login Admin Berhasil!' : 'Login Berhasil!',
        isError: false,
      );

      final destination = user.isAdmin
          ? const AdminDashboardScreen()
          : DashboardLayout(initialTab: widget.openAddEventAfterLogin ? 2 : 0);
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => destination),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      _showSnackbar(e.toString().replaceAll("Exception: ", ""));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 360,
            child: ClipPath(
              clipper: _LoginHeroClipper(),
              child: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.primaryNavy, Color(0xFF4F46E5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  Positioned(
                    top: -94,
                    right: -56,
                    child: _LoginHeroOrb(
                      size: 220,
                      color: Colors.white.withValues(alpha: 0.055),
                    ),
                  ),
                  Positioned(
                    bottom: 6,
                    left: -64,
                    child: _LoginHeroOrb(
                      size: 170,
                      color: AppTheme.secondaryIndigo.withValues(alpha: 0.12),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 24,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF4F46E5,
                                ).withValues(alpha: 0.35),
                                blurRadius: 22,
                                offset: const Offset(0, 9),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.calendar_month_rounded,
                            size: 32,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        'Eventify Campus',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.15,
                            ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Platform Kegiatan Mahasiswa Terintegrasi',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.78),
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.15,
                        ),
                      ),
                      const SizedBox(height: 28),

                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: colorScheme.onSurface.withValues(
                              alpha: 0.07,
                            ),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: isDark ? 0.25 : 0.06,
                              ),
                              blurRadius: 25,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Form Title & Tagline
                            Text(
                              'Selamat Datang',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? AppTheme.darkTextPrimary
                                    : AppTheme.lightTextPrimary,
                                letterSpacing: -0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Masuk untuk mengelola event kampus Anda',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? AppTheme.darkTextSecondary
                                    : AppTheme.lightTextSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),

                            const SizedBox(height: 28),

                            // Input Form
                            Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  RawAutocomplete<String>(
                                    textEditingController: _emailController,
                                    focusNode: _emailFocusNode,
                                    optionsBuilder: (textEditingValue) {
                                      final query = textEditingValue.text
                                          .trim()
                                          .toLowerCase();
                                      final savedEmail = _savedAdminEmail;
                                      if (query.isEmpty ||
                                          savedEmail == null ||
                                          !savedEmail.toLowerCase().startsWith(
                                            query,
                                          )) {
                                        return const Iterable<String>.empty();
                                      }
                                      return [savedEmail];
                                    },
                                    fieldViewBuilder:
                                        (
                                          context,
                                          controller,
                                          focusNode,
                                          onFieldSubmitted,
                                        ) {
                                          return CustomTextField(
                                            controller: controller,
                                            focusNode: focusNode,
                                            labelText: 'Alamat Email',
                                            hintText: 'nim@student.univ.ac.id',
                                            prefixIcon: Icons.email_rounded,
                                            keyboardType:
                                                TextInputType.emailAddress,
                                            validator: (val) {
                                              if (val == null ||
                                                  val.trim().isEmpty) {
                                                return 'Alamat email wajib diisi';
                                              }
                                              if (!RegExp(
                                                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                              ).hasMatch(val.trim())) {
                                                return 'Format email tidak valid';
                                              }
                                              return null;
                                            },
                                          );
                                        },
                                    optionsViewBuilder:
                                        (context, onSelected, options) {
                                          return Align(
                                            alignment: Alignment.topLeft,
                                            child: Material(
                                              elevation: 8,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              clipBehavior: Clip.antiAlias,
                                              child: ConstrainedBox(
                                                constraints: BoxConstraints(
                                                  maxWidth:
                                                      MediaQuery.of(
                                                        context,
                                                      ).size.width -
                                                      96,
                                                ),
                                                child: ListView(
                                                  padding: EdgeInsets.zero,
                                                  shrinkWrap: true,
                                                  children: options.map((
                                                    email,
                                                  ) {
                                                    return ListTile(
                                                      leading: const Icon(
                                                        Icons.email_outlined,
                                                      ),
                                                      title: Text(email),
                                                      onTap: () =>
                                                          onSelected(email),
                                                    );
                                                  }).toList(),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                  ),
                                  CustomTextField(
                                    controller: _passwordController,
                                    labelText: 'Password',
                                    hintText: 'Minimal 6 karakter',
                                    prefixIcon: Icons.lock_rounded,
                                    isPassword: true,
                                    validator: (val) {
                                      if (val == null || val.isEmpty) {
                                        return 'Password wajib diisi';
                                      }
                                      if (val.length < 6) {
                                        return 'Password minimal 6 karakter';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 8),

                                  // Submit Action Button
                                  Consumer<AppState>(
                                    builder: (context, appState, _) {
                                      return CustomButton(
                                        text: 'Masuk Ke Aplikasi',
                                        onPressed: _handleLogin,
                                        isLoading: appState.isLoading,
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            Divider(
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.08,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 4,
                              children: [
                                Text(
                                  'Belum punya akun?',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: colorScheme.onSurface.withValues(
                                          alpha: 0.62,
                                        ),
                                      ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => RegisterScreen(
                                          openAddEventAfterRegister:
                                              widget.openAddEventAfterLogin,
                                        ),
                                      ),
                                    );
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor: isDark
                                        ? AppTheme.secondaryIndigo
                                        : AppTheme.primaryIndigo,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 6,
                                    ),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text(
                                    'Daftar Sekarang',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginHeroOrb extends StatelessWidget {
  const _LoginHeroOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 18),
        gradient: RadialGradient(
          colors: [color.withValues(alpha: 0.5), Colors.transparent],
        ),
      ),
    );
  }
}
