import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:miniature_paint_finder/screens/home_screen.dart';
import 'package:miniature_paint_finder/theme/app_theme.dart';
import 'package:miniature_paint_finder/services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isShowingWelcome = true;
  bool _isShowingRegisterOptions = false;
  bool _isShowingEmailForm = false;
  bool _isShowingLoginOptions = false;
  bool _isShowingEmailLogin = false;

  // Auth service instance
  final AuthService _authService = AuthService();

  // Controllers
  final TextEditingController _emailController = TextEditingController(
    text: 'demo@miniaturepaintfinder.com',
  );
  final TextEditingController _passwordController = TextEditingController(
    text: 'password123',
  );
  final TextEditingController _nameController = TextEditingController(
    text: 'Demo Painter',
  );

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  // Perform direct login without validation
  void _performDirectLogin() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Use the auth service for login
      await _authService.signInWithEmailPassword(
        _emailController.text.isNotEmpty
            ? _emailController.text
            : 'demo@miniaturepaintfinder.com',
        _passwordController.text.isNotEmpty
            ? _passwordController.text
            : 'password123',
      );

      if (mounted) {
        // Navigate to home screen after successful login
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } on AuthException catch (e) {
      // Handle specific auth errors with user-friendly messages
      String errorMessage;

      switch (e.code) {
        case AuthErrorCode.invalidEmail:
          errorMessage = 'Please enter a valid email address';
          break;
        case AuthErrorCode.wrongPassword:
          errorMessage = 'Incorrect password, please try again';
          break;
        case AuthErrorCode.userNotFound:
          errorMessage = 'No account found with this email';
          break;
        case AuthErrorCode.tooManyRequests:
          errorMessage = 'Too many attempts. Please try again later';
          break;
        default:
          errorMessage = e.message;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } catch (e) {
      // Handle other errors
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login failed: ${e.toString()}'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Simulate registration with email/password
  void _performRegister() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Simulate registration
        await _authService.signUpWithEmailPassword(
          _emailController.text,
          _passwordController.text,
          _nameController.text,
        );

        if (mounted) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account created successfully!'),
              backgroundColor: Colors.green,
            ),
          );

          // Navigate to home screen after successful registration
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      } on AuthException catch (e) {
        // Handle specific auth errors with user-friendly messages
        String errorMessage;

        switch (e.code) {
          case AuthErrorCode.emailAlreadyInUse:
            errorMessage = 'This email is already in use';
            break;
          case AuthErrorCode.invalidEmail:
            errorMessage = 'Please enter a valid email address';
            break;
          case AuthErrorCode.weakPassword:
            errorMessage = 'Password is too weak. Use at least 8 characters';
            break;
          default:
            errorMessage = e.message;
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
      } catch (e) {
        // Handle other errors
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Registration failed: ${e.toString()}'),
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _showLoginOptions() {
    setState(() {
      _isShowingWelcome = false;
      _isShowingRegisterOptions = false;
      _isShowingEmailForm = false;
      _isShowingLoginOptions = true;
      _isShowingEmailLogin = false;
    });
  }

  void _showEmailLogin() {
    setState(() {
      _isShowingWelcome = false;
      _isShowingRegisterOptions = false;
      _isShowingEmailForm = false;
      _isShowingLoginOptions = false;
      _isShowingEmailLogin = true;
    });
  }

  void _showRegisterOptions() {
    setState(() {
      _isShowingWelcome = false;
      _isShowingRegisterOptions = true;
      _isShowingEmailForm = false;
      _isShowingLoginOptions = false;
      _isShowingEmailLogin = false;
    });
  }

  void _showEmailRegisterForm() {
    setState(() {
      _isShowingWelcome = false;
      _isShowingRegisterOptions = false;
      _isShowingEmailForm = true;
      _isShowingLoginOptions = false;
      _isShowingEmailLogin = false;
    });
  }

  void _goBack() {
    setState(() {
      if (_isShowingEmailForm) {
        _isShowingEmailForm = false;
        _isShowingRegisterOptions = true;
      } else if (_isShowingRegisterOptions) {
        _isShowingRegisterOptions = false;
        _isShowingWelcome = true;
      } else if (_isShowingLoginOptions) {
        _isShowingLoginOptions = false;
        _isShowingWelcome = true;
      } else if (_isShowingEmailLogin) {
        _isShowingEmailLogin = false;
        _isShowingLoginOptions = true;
      } else {
        _isShowingWelcome = true;
      }

      if (_isShowingWelcome) {
        _isShowingRegisterOptions = false;
        _isShowingEmailForm = false;
        _isShowingLoginOptions = false;
        _isShowingEmailLogin = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.05, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child:
              _isShowingWelcome
                  ? _buildWelcomeScreen()
                  : _isShowingRegisterOptions
                  ? _buildRegisterOptions(screenSize)
                  : _isShowingEmailForm
                  ? _buildEmailRegisterForm(screenSize)
                  : _isShowingLoginOptions
                  ? _buildLoginOptions(screenSize)
                  : _buildEmailLoginForm(screenSize),
        ),
      ),
      // Loading overlay
      bottomSheet:
          _isLoading
              ? Container(
                width: double.infinity,
                height: 4,
                color: AppTheme.marineOrange,
                child: const LinearProgressIndicator(
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppTheme.marineGold,
                  ),
                ),
              )
              : null,
    );
  }

  Widget _buildWelcomeScreen() {
    return Stack(
      children: [
        Container(
          color: AppTheme.darkBackground,
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Space Marine Image
                    Container(
                      width: double.infinity,
                      height: 400,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/images/space_marine.png'),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Miniature Paint Finder',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 28,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Your ultimate companion for miniature painting',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white70,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Feature bullets
                    _buildFeatureBullet(
                      'Track your paint collection and never buy duplicates',
                    ),
                    _buildFeatureBullet(
                      'Find matching colors with **AI-powered image recognition** - 100% Free',
                    ),
                    _buildFeatureBullet(
                      'Create and share custom paint palettes',
                    ),
                    _buildFeatureBullet('Scan barcodes for quick paint lookup'),
                  ],
                ),
              ),
              // Bottom buttons section
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _showRegisterOptions,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppTheme.darkBackground,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 20),
                          ),
                          child: Text(
                            'Register',
                            style: AppTheme.buttonStyle.copyWith(fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _showLoginOptions,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: Colors.white.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 20),
                          ),
                          child: Text(
                            'Sign In',
                            style: AppTheme.buttonStyle.copyWith(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ],
          ),
        ),

        // 3D floating cubes
        Positioned(
          top: 50,
          right: 40,
          child: _buildCube(AppTheme.marineOrange, size: 30, angle: 0.5),
        ),

        Positioned(
          bottom: 120,
          left: 40,
          child: _buildCube(AppTheme.marineBlueDark, size: 25, angle: 0.8),
        ),

        Positioned(
          top: 150,
          left: 80,
          child: _buildCube(AppTheme.marineBlueDark, size: 18, angle: 0.3),
        ),

        Positioned(
          right: 120,
          bottom: 200,
          child: _buildCube(AppTheme.marineGold, size: 20, angle: 1.2),
        ),
      ],
    );
  }

  Widget _buildFeatureBullet(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppTheme.marineGold,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(children: _processTextWithBold(text)),
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  List<TextSpan> _processTextWithBold(String text) {
    final parts = text.split('**');
    final List<TextSpan> spans = [];

    for (var i = 0; i < parts.length; i++) {
      spans.add(
        TextSpan(
          text: parts[i],
          style:
              i % 2 == 1
                  ? const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  )
                  : null,
        ),
      );
    }

    return spans;
  }

  Widget _buildLoginOptions(Size screenSize) {
    final formMaxWidth = screenSize.width > 800 ? 400.0 : double.infinity;

    return Stack(
      children: [
        Container(
          color: AppTheme.darkBackground,
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: formMaxWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Back button
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: _goBack,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Title
                  Text(
                    "Sign in to your account",
                    style: AppTheme.headingStyle.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Choose how you want to sign in",
                    style: AppTheme.subheadingStyle.copyWith(
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Login options
                  _buildAuthButton(
                    icon: Icons.email_outlined,
                    label: 'Continue with Email',
                    color: AppTheme.marineOrange,
                    onPressed: _showEmailLogin,
                  ),

                  const SizedBox(height: 16),

                  _buildAuthButton(
                    icon: Icons.g_mobiledata_rounded,
                    label: 'Continue with Google',
                    color: Colors.red.shade600,
                    onPressed: _performDirectLogin,
                  ),

                  // Show Apple login on iOS and web
                  const SizedBox(height: 16),
                  _buildAuthButton(
                    icon: Icons.apple,
                    label: 'Continue with Apple',
                    color: Colors.white,
                    textColor: AppTheme.darkBackground,
                    onPressed: _performDirectLogin,
                  ),

                  // Show Phone login for Android (and others)
                  const SizedBox(height: 16),
                  _buildAuthButton(
                    icon: Icons.phone_android,
                    label: 'Continue with Phone',
                    color: Colors.green.shade600,
                    onPressed: _performDirectLogin,
                  ),

                  const SizedBox(height: 32),

                  // Don't have an account yet?
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account?",
                        style: AppTheme.bodyStyle.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                      TextButton(
                        onPressed: _showRegisterOptions,
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.marineGold,
                          padding: const EdgeInsets.only(left: 8),
                        ),
                        child: Text(
                          'Register',
                          style: AppTheme.buttonStyle.copyWith(
                            color: AppTheme.marineGold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // 3D floating cubes
        Positioned(
          bottom: 100,
          right: 40,
          child: _buildCube(AppTheme.marineOrange, size: 25, angle: 0.7),
        ),

        Positioned(
          top: 120,
          right: 80,
          child: _buildCube(AppTheme.marineBlueDark, size: 18, angle: 0.4),
        ),

        Positioned(
          bottom: 200,
          left: 60,
          child: _buildCube(AppTheme.marineGold, size: 20, angle: 0.9),
        ),
      ],
    );
  }

  Widget _buildRegisterOptions(Size screenSize) {
    final formMaxWidth = screenSize.width > 800 ? 400.0 : double.infinity;

    return Stack(
      children: [
        Container(
          color: AppTheme.darkBackground,
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: formMaxWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Back button
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: _goBack,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Title
                  Text(
                    "Create an account",
                    style: AppTheme.headingStyle.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Choose how you want to register",
                    style: AppTheme.subheadingStyle.copyWith(
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Registration options
                  _buildAuthButton(
                    icon: Icons.email_outlined,
                    label: 'Continue with Email',
                    color: AppTheme.marineOrange,
                    onPressed: _showEmailRegisterForm,
                  ),

                  const SizedBox(height: 16),

                  _buildAuthButton(
                    icon: Icons.g_mobiledata_rounded,
                    label: 'Continue with Google',
                    color: Colors.red.shade600,
                    onPressed: _performDirectLogin,
                  ),

                  // Show Apple login on iOS and web
                  const SizedBox(height: 16),
                  _buildAuthButton(
                    icon: Icons.apple,
                    label: 'Continue with Apple',
                    color: Colors.white,
                    textColor: AppTheme.darkBackground,
                    onPressed: _performDirectLogin,
                  ),

                  // Show Phone login for Android (and others)
                  const SizedBox(height: 16),
                  _buildAuthButton(
                    icon: Icons.phone_android,
                    label: 'Continue with Phone',
                    color: Colors.green.shade600,
                    onPressed: _performDirectLogin,
                  ),

                  const SizedBox(height: 32),

                  // Terms and conditions
                  Center(
                    child: Text(
                      "By signing up, you agree to our Terms of Service and Privacy Policy",
                      textAlign: TextAlign.center,
                      style: AppTheme.bodyStyle.copyWith(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // 3D floating cubes
        Positioned(
          bottom: 100,
          right: 40,
          child: _buildCube(AppTheme.marineOrange, size: 25, angle: 0.7),
        ),

        Positioned(
          top: 120,
          right: 80,
          child: _buildCube(AppTheme.marineBlueDark, size: 18, angle: 0.4),
        ),

        Positioned(
          bottom: 200,
          left: 60,
          child: _buildCube(AppTheme.marineGold, size: 20, angle: 0.9),
        ),
      ],
    );
  }

  Widget _buildAuthButton({
    required IconData icon,
    required String label,
    required Color color,
    Color? textColor,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        icon: Icon(icon),
        label: Text(label),
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor ?? Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTheme.buttonStyle,
        ),
      ),
    );
  }

  Widget _buildEmailRegisterForm(Size screenSize) {
    final formMaxWidth = screenSize.width > 800 ? 400.0 : double.infinity;

    return Stack(
      children: [
        Container(
          color: AppTheme.darkBackground,
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Form(
              key: _formKey,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: formMaxWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Back button
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.1),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: _goBack,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Title
                    Text(
                      "Create an account",
                      style: AppTheme.headingStyle.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Register with email and password",
                      style: AppTheme.subheadingStyle.copyWith(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Name field
                    TextFormField(
                      controller: _nameController,
                      decoration: _buildInputDecoration(
                        hint: 'Full Name',
                        prefixIcon: const Icon(
                          Icons.person_outline,
                          color: Colors.white70,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Email field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _buildInputDecoration(
                        hint: 'Email Address',
                        prefixIcon: const Icon(
                          Icons.email_outlined,
                          color: Colors.white70,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        // Check if it's a demo account (allow it)
                        if (value == 'demo@miniaturepaintfinder.com') {
                          return null;
                        }
                        // Basic email validation
                        final emailRegex = RegExp(
                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$',
                        );
                        if (!emailRegex.hasMatch(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: _buildInputDecoration(
                        hint: 'Password',
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          color: Colors.white70,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: Colors.white70,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a password';
                        }
                        // Allow demo password
                        if (value == 'password123') {
                          return null;
                        }
                        // Password requirements
                        if (value.length < 8) {
                          return 'Password must be at least 8 characters';
                        }
                        // Check for mixed case, numbers, and special characters
                        final hasUppercase = value.contains(RegExp(r'[A-Z]'));
                        final hasLowercase = value.contains(RegExp(r'[a-z]'));
                        final hasNumbers = value.contains(RegExp(r'[0-9]'));
                        final hasSpecialChars = value.contains(
                          RegExp(r'[!@#$%^&*(),.?":{}|<>]'),
                        );

                        if (!hasUppercase ||
                            !hasLowercase ||
                            !hasNumbers ||
                            !hasSpecialChars) {
                          return 'Password must include uppercase, lowercase, \nnumbers and special characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 40),

                    // Register button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _performRegister,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.marineOrange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Create Account',
                          style: AppTheme.buttonStyle.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Login link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Already have an account?",
                          style: AppTheme.bodyStyle.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                        TextButton(
                          onPressed: _showLoginOptions,
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.marineGold,
                            padding: const EdgeInsets.only(left: 8),
                          ),
                          child: Text(
                            'Sign In',
                            style: AppTheme.buttonStyle.copyWith(
                              color: AppTheme.marineGold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // 3D floating cubes
        Positioned(
          bottom: 100,
          right: 40,
          child: _buildCube(AppTheme.marineOrange, size: 25, angle: 0.7),
        ),

        Positioned(
          top: 120,
          right: 80,
          child: _buildCube(AppTheme.marineBlueDark, size: 18, angle: 0.4),
        ),
      ],
    );
  }

  Widget _buildEmailLoginForm(Size screenSize) {
    final formMaxWidth = screenSize.width > 800 ? 400.0 : double.infinity;

    return Stack(
      children: [
        Container(
          color: AppTheme.darkBackground,
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Form(
              key: _formKey,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: formMaxWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Back button for login form
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.1),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: _goBack,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Title and subtitle
                    Text(
                      "Let's sign you in",
                      style: AppTheme.headingStyle.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Welcome back!",
                      style: AppTheme.subheadingStyle.copyWith(
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Email field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _buildInputDecoration(
                        hint: 'Email address',
                        prefixIcon: const Icon(
                          Icons.email_outlined,
                          color: Colors.white70,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        // Check if it's a demo account (always allow it)
                        if (value == 'demo@miniaturepaintfinder.com') {
                          return null;
                        }
                        // Basic email validation for non-demo emails
                        final emailRegex = RegExp(
                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$',
                        );
                        if (!emailRegex.hasMatch(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: _buildInputDecoration(
                        hint: 'Password',
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          color: Colors.white70,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: Colors.white70,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        // Always allow the demo password
                        if (value == 'password123') {
                          return null;
                        }
                        // For real passwords (not demo), enforce stronger requirements
                        if (_emailController.text !=
                            'demo@miniaturepaintfinder.com') {
                          if (value.length < 8) {
                            return 'Password must be at least 8 characters';
                          }
                        }
                        return null;
                      },
                    ),

                    // Forgot password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          // Forgot password functionality
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.marineGold,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          'Forgot Password?',
                          style: AppTheme.bodyStyle.copyWith(
                            color: AppTheme.marineGold,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Bottom section with Register
                    Column(
                      children: [
                        // Account existence check
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account?",
                              style: AppTheme.bodyStyle.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                            TextButton(
                              onPressed: _showRegisterOptions,
                              style: TextButton.styleFrom(
                                foregroundColor: AppTheme.marineGold,
                                padding: const EdgeInsets.only(left: 8),
                              ),
                              child: Text(
                                'Register',
                                style: AppTheme.buttonStyle.copyWith(
                                  color: AppTheme.marineGold,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Action button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _performDirectLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.marineOrange,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'Sign In',
                              style: AppTheme.buttonStyle.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // 3D floating cubes for sign in screen
        Positioned(
          bottom: 100,
          right: 40,
          child: _buildCube(AppTheme.marineOrange, size: 25, angle: 0.7),
        ),

        Positioned(
          top: 120,
          right: 80,
          child: _buildCube(AppTheme.marineBlueDark, size: 18, angle: 0.4),
        ),

        Positioned(
          bottom: 200,
          left: 60,
          child: _buildCube(AppTheme.marineGold, size: 20, angle: 0.9),
        ),
      ],
    );
  }

  Widget _buildCube(
    Color color, {
    required double size,
    required double angle,
  }) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hint,
    Widget? suffixIcon,
    Widget? prefixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white38),
      filled: true,
      fillColor: Colors.white.withOpacity(0.1),
      suffixIcon: suffixIcon,
      prefixIcon: prefixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppTheme.marineGold, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}
