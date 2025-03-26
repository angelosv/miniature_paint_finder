import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:miniature_paint_finder/screens/home_screen.dart';
import 'package:miniature_paint_finder/theme/app_theme.dart';
import 'package:miniature_paint_finder/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

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
        print('Starting registration process...');
        print('Email: ${_emailController.text}');
        
        // First, make the POST request to the registration endpoint
        final response = await http.post(
          Uri.parse('https://paints-api.reachu.io/auth/register'),
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'username': _nameController.text,
            'email': _emailController.text,
            'password': _passwordController.text,
          }),
        );

        print('Backend response: ${response.body}');
        final responseData = jsonDecode(response.body);
        
        if (responseData['executed'] == true) {
          print('Backend registration successful');
          
          // Check if we got a custom token from the backend
          if (responseData['data'] != null && responseData['data']['customToken'] != null) {
            print('Custom token received, signing in with Firebase...');
            // Sign in with the custom token
            await _authService.signInWithCustomToken(responseData['data']['customToken']);
            print('Firebase login successful');

            if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            }
          } else {
            print('No custom token received in response');
            throw Exception('No custom token received from server');
          }
        } else {
          print('Backend registration failed: ${responseData['message']}');
          if (mounted) {
            _showErrorDialog(responseData['message'] ?? 'Registration failed');
          }
        }
      } catch (e) {
        print('Registration process error: $e');
        if (mounted) {
          _showErrorDialog('Registration failed: ${e.toString()}');
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

  // Perform Google sign in
  void _performGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.signInWithGoogle();

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
        case AuthErrorCode.cancelled:
          errorMessage = 'Google sign in was cancelled';
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
            content: Text('Google sign in failed: ${e.toString()}'),
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

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const AuthScreen()),
                  (route) => false,
                );
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<IAuthService>(context, listen: false);
      await authService.signInWithGoogle();
      // If we get here, executed was true
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (context.mounted) {
        if (e is AuthException) {
          _showErrorDialog(e.message);
        } else {
          _showErrorDialog('Authentication error');
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          switchInCurve: Curves.easeInOut,
          switchOutCurve: Curves.easeInOut,
          transitionBuilder: (Widget child, Animation<double> animation) {
            return Stack(
              children: [
                SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(1.0, 0.0),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(parent: animation, curve: Curves.easeInOut),
                  ),
                  child: FadeTransition(opacity: animation, child: child),
                ),
              ],
            );
          },
          layoutBuilder: (currentChild, previousChildren) {
            return Stack(
              children: <Widget>[
                ...previousChildren,
                if (currentChild != null) currentChild,
              ],
            );
          },
          child: _getCurrentScreen(screenSize),
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

  Widget _getCurrentScreen(Size screenSize) {
    return Container(
      key: ValueKey<String>(_getCurrentScreenKey()),
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
    );
  }

  String _getCurrentScreenKey() {
    if (_isShowingWelcome) return 'welcome';
    if (_isShowingRegisterOptions) return 'register_options';
    if (_isShowingEmailForm) return 'email_form';
    if (_isShowingLoginOptions) return 'login_options';
    return 'email_login';
  }

  Widget _buildWelcomeScreen() {
    return Container(
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
                  style: AppTheme.headingStyle.copyWith(
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
                _buildFeatureBullet('Create and share custom paint palettes'),
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
                    onPressed: _handleGoogleSignIn,
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
                    onPressed: _handleGoogleSignIn,
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
                      decoration: InputDecoration(
                        labelText: 'Name',
                        hintText: 'Enter your name',
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),

                    // Email field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        hintText: 'Enter your email',
                        prefixIcon: const Icon(Icons.email),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
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
                      decoration: InputDecoration(
                        labelText: 'Password',
                        hintText: 'Enter your password',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
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
                      decoration: InputDecoration(
                        labelText: 'Email',
                        hintText: 'Enter your email',
                        prefixIcon: const Icon(Icons.email),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
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
                      decoration: InputDecoration(
                        labelText: 'Password',
                        hintText: 'Enter your password',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
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
