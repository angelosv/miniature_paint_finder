import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:miniature_paint_finder/screens/home_screen.dart';
import 'package:miniature_paint_finder/theme/app_theme.dart';
import 'package:miniature_paint_finder/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:miniature_paint_finder/screens/phone_auth_screen.dart';

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

  @override
  void initState() {
    super.initState();
    // Check if user is already logged in
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = Provider.of<IAuthService>(context, listen: false);
      if (authService.currentUser != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    });
  }

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

  // Verificar si estamos en iOS o macOS para mostrar el botón de Apple
  // También verificamos una variable de entorno para desarrollo
  bool get _isAppleSignInAvailable {
    // Condición que evalúa si la funcionalidad está disponible para el equipo de desarrollo
    // Establece esta variable como falsa para equipos sin Apple Developer
    const bool forceDisableAppleSignIn =
        false; // Cambiado a false para habilitar en esta rama

    return !forceDisableAppleSignIn &&
        (defaultTargetPlatform == TargetPlatform.iOS);
  }

  // Nuevo método para manejar el inicio de sesión con Apple
  Future<void> _handleAppleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<IAuthService>(context, listen: false);

      // Verificar si Apple Sign In está disponible
      if (!_isAppleSignInAvailable) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign in with Apple is not available on this device'),
            backgroundColor: Colors.red.shade700,
          ),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      await authService.signInWithApple();

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        if (e is AuthException && e.code == AuthErrorCode.cancelled) {
          // Si el usuario canceló el inicio de sesión, no mostramos error
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Sign in was cancelled')));
        } else if (e is AuthException &&
            e.code == AuthErrorCode.platformNotSupported) {
          // Si la plataforma no es compatible
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Sign in with Apple is not available on this device',
              ),
              backgroundColor: Colors.red.shade700,
            ),
          );
        } else {
          // Para cualquier otro error
          _showErrorDialog(
            e is AuthException ? e.message : 'Authentication failed',
          );
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

  // Perform direct login without validation
  void _performDirectLogin() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print(
        '🔒 Login: Intentando iniciar sesión con email: ${_emailController.text}',
      );

      if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
        throw AuthException(
          AuthErrorCode.invalidEmail,
          'Please enter email and password',
        );
      }

      // Use the auth service for login with the provided credentials
      final user = await _authService.signInWithEmailPassword(
        _emailController.text,
        _passwordController.text,
      );

      print('✅ Login exitoso: ${user.email} (${user.id})');

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
          headers: {'Content-Type': 'application/json'},
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
          if (responseData['data'] != null &&
              responseData['data']['customToken'] != null) {
            print('Custom token received, signing in with Firebase...');
            // Sign in with the custom token
            await _authService.signInWithCustomToken(
              responseData['data']['customToken'],
            );
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

  // Perform phone sign in
  void _performPhoneSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.signInWithPhone();

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Phone sign in failed: ${e.toString()}'),
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
    // Obtenemos el tamaño de la pantalla para hacer la UI responsive
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 700;

    // Additional responsive adjustments for different screen sizes
    final isVerySmallScreen = screenSize.height < 600;
    final imageHeight =
        isVerySmallScreen ? 200.0 : (isSmallScreen ? 240.0 : 330.0);
    final titleFontSize =
        isVerySmallScreen ? 22.0 : (isSmallScreen ? 24.0 : 28.0);
    final subtitleFontSize =
        isVerySmallScreen ? 14.0 : (isSmallScreen ? 16.0 : 18.0);
    final bulletSpacing = isVerySmallScreen ? 2.0 : 4.0;
    final contentPadding = screenSize.height < 750 ? 16.0 : 24.0;
    final buttonFontSize =
        isVerySmallScreen ? 13.0 : (isSmallScreen ? 14.0 : 16.0);
    final buttonVerticalPadding =
        isVerySmallScreen ? 12.0 : (isSmallScreen ? 16.0 : 20.0);

    return Container(
      color: AppTheme.darkBackground,
      padding: EdgeInsets.all(contentPadding),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Space Marine Image - optimized height based on screen size
                  Container(
                    width: double.infinity,
                    height: imageHeight,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/images/space_marine.png'),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: isVerySmallScreen ? 10 : (isSmallScreen ? 16 : 24),
                  ),
                  Text(
                    'Miniature Painter',
                    style: AppTheme.headingStyle.copyWith(
                      color: Colors.white,
                      fontSize: titleFontSize,
                    ),
                  ),
                  SizedBox(
                    height: isVerySmallScreen ? 4 : (isSmallScreen ? 8 : 12),
                  ),
                  Text(
                    'Your ultimate companion for miniature painting',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white70,
                      fontSize: subtitleFontSize,
                    ),
                  ),
                  SizedBox(
                    height: isVerySmallScreen ? 10 : (isSmallScreen ? 14 : 20),
                  ),
                  // Feature bullets - tighter spacing for small screens
                  ..._buildFeatureBullets(bulletSpacing),
                  // Extra bottom space to prevent overlap
                  SizedBox(
                    height: isVerySmallScreen ? 12 : (isSmallScreen ? 16 : 24),
                  ),
                ],
              ),
            ),
          ),
          // Bottom buttons section
          SafeArea(
            child: Column(
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
                          padding: EdgeInsets.symmetric(
                            vertical: buttonVerticalPadding,
                          ),
                        ),
                        child: Text(
                          'Register',
                          style: AppTheme.buttonStyle.copyWith(
                            fontSize: buttonFontSize,
                          ),
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
                          padding: EdgeInsets.symmetric(
                            vertical: buttonVerticalPadding,
                          ),
                        ),
                        child: Text(
                          'Sign In',
                          style: AppTheme.buttonStyle.copyWith(
                            color: Colors.white,
                            fontSize: buttonFontSize,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build feature bullets more efficiently
  List<Widget> _buildFeatureBullets(double verticalSpacing) {
    final features = [
      'Track your paint collection and never buy duplicates',
      'Find matching colors with **AI-powered image recognition** - 100% Free',
      'Create custom paint palettes',
      'Scan barcodes for quick paint lookup',
    ];

    return features
        .map(
          (text) => Padding(
            padding: EdgeInsets.symmetric(vertical: verticalSpacing),
            child: _buildFeatureBullet(text),
          ),
        )
        .toList();
  }

  Widget _buildFeatureBullet(String text) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 700;
    final bulletSize = isSmallScreen ? 6.0 : 8.0;
    final textSize = isSmallScreen ? 13.0 : 14.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.only(top: 6),
          width: bulletSize,
          height: bulletSize,
          decoration: BoxDecoration(
            color: AppTheme.marineGold,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text.rich(
            TextSpan(children: _processTextWithBold(text)),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white70,
              fontSize: textSize,
            ),
          ),
        ),
      ],
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
    final isSmallScreen = screenSize.height < 700;
    final isVerySmallScreen = screenSize.height < 600;

    // Responsive values
    final titleFontSize =
        isVerySmallScreen ? 22.0 : (isSmallScreen ? 24.0 : 28.0);
    final subtitleFontSize =
        isVerySmallScreen ? 14.0 : (isSmallScreen ? 16.0 : 18.0);
    final buttonHeight =
        isVerySmallScreen ? 44.0 : (isSmallScreen ? 48.0 : 56.0);
    final buttonSpacing =
        isVerySmallScreen ? 8.0 : (isSmallScreen ? 12.0 : 16.0);
    final topPadding = isVerySmallScreen ? 16.0 : (isSmallScreen ? 20.0 : 32.0);
    final contentPadding = screenSize.height < 750 ? 16.0 : 24.0;
    final optionsSpacing =
        isVerySmallScreen ? 24.0 : (isSmallScreen ? 32.0 : 48.0);

    return Stack(
      children: [
        Container(
          color: AppTheme.darkBackground,
          padding: EdgeInsets.all(contentPadding),
          child: Center(
            child: SingleChildScrollView(
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
                    SizedBox(height: topPadding),

                    // Title
                    Text(
                      "Sign in to your account",
                      style: AppTheme.headingStyle.copyWith(
                        color: Colors.white,
                        fontSize: titleFontSize,
                      ),
                    ),
                    SizedBox(
                      height: isVerySmallScreen ? 2 : (isSmallScreen ? 4 : 8),
                    ),
                    Text(
                      "Choose how you want to sign in",
                      style: AppTheme.subheadingStyle.copyWith(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: subtitleFontSize,
                      ),
                    ),
                    SizedBox(height: optionsSpacing),

                    // Login options
                    _buildAuthButton(
                      icon: Icons.email_outlined,
                      label: 'Continue with Email',
                      color: AppTheme.marineOrange,
                      onPressed: _showEmailLogin,
                      height: buttonHeight,
                    ),

                    SizedBox(height: buttonSpacing),

                    _buildAuthButton(
                      icon: Icons.g_mobiledata_rounded,
                      label: 'Continue with Google',
                      color: Colors.red.shade600,
                      onPressed: _handleGoogleSignIn,
                      height: buttonHeight,
                    ),

                    // Show Apple login on iOS and web
                    SizedBox(height: buttonSpacing),
                    _buildAuthButton(
                      icon: Icons.apple,
                      label: 'Continue with Apple',
                      color: Colors.white,
                      textColor: AppTheme.darkBackground,
                      onPressed:
                          _isAppleSignInAvailable ? _handleAppleSignIn : null,
                      height: buttonHeight,
                      // No mostrar el botón en Android
                      visible: _isAppleSignInAvailable,
                    ),

                    // Show Phone login for Android (and others)
                    // SizedBox(height: buttonSpacing),
                    // _buildAuthButton(
                    //   icon: Icons.phone_android,
                    //   label: 'Continue with Phone',
                    //   color: Colors.green.shade600,
                    //   onPressed: () {
                    //     Navigator.of(context).push(
                    //       MaterialPageRoute(
                    //         builder: (context) => const PhoneAuthScreen(),
                    //       ),
                    //     );
                    //   },
                    //   height: buttonHeight,
                    // ),
                    SizedBox(
                      height:
                          isVerySmallScreen ? 20 : (isSmallScreen ? 24 : 32),
                    ),

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
        ),

        // 3D floating cubes - only show on larger screens
        if (screenSize.height > 650) ...[
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
      ],
    );
  }

  Widget _buildRegisterOptions(Size screenSize) {
    final formMaxWidth = screenSize.width > 800 ? 400.0 : double.infinity;
    final isSmallScreen = screenSize.height < 700;
    final isVerySmallScreen = screenSize.height < 600;

    // Responsive values
    final titleFontSize =
        isVerySmallScreen ? 22.0 : (isSmallScreen ? 24.0 : 28.0);
    final subtitleFontSize =
        isVerySmallScreen ? 14.0 : (isSmallScreen ? 16.0 : 18.0);
    final buttonHeight =
        isVerySmallScreen ? 44.0 : (isSmallScreen ? 48.0 : 56.0);
    final buttonSpacing =
        isVerySmallScreen ? 8.0 : (isSmallScreen ? 12.0 : 16.0);
    final topPadding = isVerySmallScreen ? 16.0 : (isSmallScreen ? 20.0 : 32.0);
    final contentPadding = screenSize.height < 750 ? 16.0 : 24.0;
    final optionsSpacing =
        isVerySmallScreen ? 24.0 : (isSmallScreen ? 32.0 : 48.0);
    final disclaimerFontSize =
        isVerySmallScreen ? 9.0 : (isSmallScreen ? 10.0 : 12.0);

    return Stack(
      children: [
        Container(
          color: AppTheme.darkBackground,
          padding: EdgeInsets.all(contentPadding),
          child: Center(
            child: SingleChildScrollView(
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
                    SizedBox(height: topPadding),

                    // Title
                    Text(
                      "Create an account",
                      style: AppTheme.headingStyle.copyWith(
                        color: Colors.white,
                        fontSize: titleFontSize,
                      ),
                    ),
                    SizedBox(
                      height: isVerySmallScreen ? 2 : (isSmallScreen ? 4 : 8),
                    ),
                    Text(
                      "Choose how you want to register",
                      style: AppTheme.subheadingStyle.copyWith(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: subtitleFontSize,
                      ),
                    ),
                    SizedBox(height: optionsSpacing),

                    // Registration options
                    _buildAuthButton(
                      icon: Icons.email_outlined,
                      label: 'Continue with Email',
                      color: AppTheme.marineOrange,
                      onPressed: _showEmailRegisterForm,
                      height: buttonHeight,
                    ),

                    SizedBox(height: buttonSpacing),

                    _buildAuthButton(
                      icon: Icons.g_mobiledata_rounded,
                      label: 'Continue with Google',
                      color: Colors.red.shade600,
                      onPressed: _handleGoogleSignIn,
                      height: buttonHeight,
                    ),

                    // Show Apple login on iOS and web
                    SizedBox(height: buttonSpacing),
                    _buildAuthButton(
                      icon: Icons.apple,
                      label: 'Continue with Apple',
                      color: Colors.white,
                      textColor: AppTheme.darkBackground,
                      onPressed:
                          _isAppleSignInAvailable ? _handleAppleSignIn : null,
                      height: buttonHeight,
                      // No mostrar el botón en Android
                      visible: _isAppleSignInAvailable,
                    ),

                    // Show Phone login for Android (and others)
                    // SizedBox(height: buttonSpacing),
                    // _buildAuthButton(
                    //   icon: Icons.phone_android,
                    //   label: 'Continue with Phone',
                    //   color: Colors.green.shade600,
                    //   onPressed: () {
                    //     Navigator.of(context).push(
                    //       MaterialPageRoute(
                    //         builder: (context) => const PhoneAuthScreen(),
                    //       ),
                    //     );
                    //   },
                    //   height: buttonHeight,
                    // ),
                    SizedBox(
                      height:
                          isVerySmallScreen ? 16 : (isSmallScreen ? 20 : 32),
                    ),

                    // Terms and conditions
                    Center(
                      child: Text(
                        "By signing up, you agree to our Terms of Service and Privacy Policy",
                        textAlign: TextAlign.center,
                        style: AppTheme.bodyStyle.copyWith(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: disclaimerFontSize,
                        ),
                      ),
                    ),
                    // Extra space at the bottom for scrolling
                    SizedBox(height: isVerySmallScreen ? 12 : 16),
                  ],
                ),
              ),
            ),
          ),
        ),

        // 3D floating cubes - only show on larger screens
        if (screenSize.height > 650) ...[
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
      ],
    );
  }

  Widget _buildAuthButton({
    required IconData icon,
    required String label,
    required Color color,
    Color? textColor,
    required VoidCallback? onPressed,
    required double height,
    bool visible = true,
  }) {
    if (!visible) {
      return SizedBox.shrink(); // No mostrar el botón si no es visible
    }

    return SizedBox(
      width: double.infinity,
      height: height,
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
    final isSmallScreen = screenSize.height < 700;
    final isVerySmallScreen = screenSize.height < 600;

    // Responsive values
    final titleFontSize =
        isVerySmallScreen ? 22.0 : (isSmallScreen ? 24.0 : 28.0);
    final subtitleFontSize =
        isVerySmallScreen ? 14.0 : (isSmallScreen ? 16.0 : 18.0);
    final buttonHeight =
        isVerySmallScreen ? 44.0 : (isSmallScreen ? 48.0 : 56.0);
    final fieldSpacing =
        isVerySmallScreen ? 10.0 : (isSmallScreen ? 12.0 : 16.0);
    final topPadding = isVerySmallScreen ? 16.0 : (isSmallScreen ? 20.0 : 32.0);
    final contentPadding = screenSize.height < 750 ? 16.0 : 24.0;
    final buttonTopPadding =
        isVerySmallScreen ? 20.0 : (isSmallScreen ? 30.0 : 40.0);
    final fieldVerticalPadding = isVerySmallScreen ? 14.0 : 16.0;
    final buttonFontSize =
        isVerySmallScreen ? 13.0 : (isSmallScreen ? 14.0 : 16.0);
    final linkFontSize =
        isVerySmallScreen ? 12.0 : (isSmallScreen ? 13.0 : 14.0);

    return Stack(
      children: [
        Container(
          color: AppTheme.darkBackground,
          padding: EdgeInsets.all(contentPadding),
          child: Center(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
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
                      SizedBox(height: topPadding),

                      // Title
                      Text(
                        "Create an account",
                        style: AppTheme.headingStyle.copyWith(
                          color: Colors.white,
                          fontSize: titleFontSize,
                        ),
                      ),
                      SizedBox(
                        height: isVerySmallScreen ? 2 : (isSmallScreen ? 4 : 8),
                      ),
                      Text(
                        "Register with email and password",
                        style: AppTheme.subheadingStyle.copyWith(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: subtitleFontSize,
                        ),
                      ),
                      SizedBox(
                        height:
                            isVerySmallScreen ? 16 : (isSmallScreen ? 24 : 32),
                      ),

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
                          contentPadding: EdgeInsets.symmetric(
                            vertical: fieldVerticalPadding,
                            horizontal: 12,
                          ),
                        ),
                        style: TextStyle(fontSize: isVerySmallScreen ? 14 : 16),
                        textInputAction: TextInputAction.next,
                      ),
                      SizedBox(height: fieldSpacing),

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
                          contentPadding: EdgeInsets.symmetric(
                            vertical: fieldVerticalPadding,
                            horizontal: 12,
                          ),
                        ),
                        style: TextStyle(fontSize: isVerySmallScreen ? 14 : 16),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
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
                      SizedBox(height: fieldSpacing),

                      // Password field
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          hintText: 'Enter your password',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
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
                          contentPadding: EdgeInsets.symmetric(
                            vertical: fieldVerticalPadding,
                            horizontal: 12,
                          ),
                        ),
                        style: TextStyle(fontSize: isVerySmallScreen ? 14 : 16),
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                      ),
                      SizedBox(height: buttonTopPadding),

                      // Register button
                      SizedBox(
                        width: double.infinity,
                        height: buttonHeight,
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
                              fontSize: buttonFontSize,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: isVerySmallScreen ? 12 : 16),

                      // Login link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Already have an account?",
                            style: AppTheme.bodyStyle.copyWith(
                              color: Colors.white70,
                              fontSize: linkFontSize,
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
                                fontSize: linkFontSize,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isVerySmallScreen ? 12 : 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // 3D floating cubes - only show on larger screens
        if (screenSize.height > 650) ...[
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
      ],
    );
  }

  Widget _buildEmailLoginForm(Size screenSize) {
    final formMaxWidth = screenSize.width > 800 ? 400.0 : double.infinity;
    final isSmallScreen = screenSize.height < 700;
    final isVerySmallScreen = screenSize.height < 600;

    // Responsive values
    final titleFontSize =
        isVerySmallScreen ? 22.0 : (isSmallScreen ? 24.0 : 28.0);
    final subtitleFontSize =
        isVerySmallScreen ? 14.0 : (isSmallScreen ? 16.0 : 18.0);
    final buttonHeight =
        isVerySmallScreen ? 44.0 : (isSmallScreen ? 48.0 : 56.0);
    final fieldSpacing =
        isVerySmallScreen ? 10.0 : (isSmallScreen ? 12.0 : 16.0);
    final topPadding = isVerySmallScreen ? 16.0 : (isSmallScreen ? 20.0 : 32.0);
    final contentPadding = screenSize.height < 750 ? 16.0 : 24.0;
    final buttonTopPadding =
        isVerySmallScreen ? 16.0 : (isSmallScreen ? 24.0 : 40.0);
    final fieldVerticalPadding = isVerySmallScreen ? 14.0 : 16.0;
    final buttonFontSize =
        isVerySmallScreen ? 13.0 : (isSmallScreen ? 14.0 : 16.0);
    final linkFontSize =
        isVerySmallScreen ? 12.0 : (isSmallScreen ? 13.0 : 14.0);

    return Stack(
      children: [
        Container(
          color: AppTheme.darkBackground,
          padding: EdgeInsets.all(contentPadding),
          child: Center(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
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
                      SizedBox(height: topPadding),

                      // Title and subtitle
                      Text(
                        "Let's sign you in",
                        style: AppTheme.headingStyle.copyWith(
                          color: Colors.white,
                          fontSize: titleFontSize,
                        ),
                      ),
                      SizedBox(
                        height: isVerySmallScreen ? 2 : (isSmallScreen ? 4 : 8),
                      ),
                      Text(
                        "Welcome back!",
                        style: AppTheme.subheadingStyle.copyWith(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: subtitleFontSize,
                        ),
                      ),
                      SizedBox(
                        height:
                            isVerySmallScreen ? 24 : (isSmallScreen ? 32 : 48),
                      ),

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
                          contentPadding: EdgeInsets.symmetric(
                            vertical: fieldVerticalPadding,
                            horizontal: 12,
                          ),
                        ),
                        style: TextStyle(fontSize: isVerySmallScreen ? 14 : 16),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
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
                      SizedBox(height: fieldSpacing),

                      // Password field
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          hintText: 'Enter your password',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
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
                          contentPadding: EdgeInsets.symmetric(
                            vertical: fieldVerticalPadding,
                            horizontal: 12,
                          ),
                        ),
                        style: TextStyle(fontSize: isVerySmallScreen ? 14 : 16),
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
                            padding: EdgeInsets.symmetric(
                              vertical:
                                  isVerySmallScreen
                                      ? 8
                                      : (isSmallScreen ? 12 : 16),
                            ),
                          ),
                          child: Text(
                            'Forgot Password?',
                            style: AppTheme.bodyStyle.copyWith(
                              color: AppTheme.marineGold,
                              fontWeight: FontWeight.w500,
                              fontSize:
                                  isVerySmallScreen
                                      ? 12
                                      : (isSmallScreen ? 13 : 14),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: buttonTopPadding),

                      // Sign in button
                      SizedBox(
                        width: double.infinity,
                        height: buttonHeight,
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
                              fontSize: buttonFontSize,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(
                        height:
                            isVerySmallScreen ? 12 : (isSmallScreen ? 16 : 24),
                      ),

                      // Bottom section with Register
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account?",
                            style: AppTheme.bodyStyle.copyWith(
                              color: Colors.white70,
                              fontSize: linkFontSize,
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
                                fontSize: linkFontSize,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isVerySmallScreen ? 12 : 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // 3D floating cubes for sign in screen - only show on larger screens
        if (screenSize.height > 650) ...[
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
