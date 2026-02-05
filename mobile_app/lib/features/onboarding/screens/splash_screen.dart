import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;

import '../../../core/services/storage_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _bookController;
  late AnimationController _waveController;
  
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _bookFlipAnimation;
  late Animation<double> _slideUpAnimation;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    _initializeAnimations();
    _initializeApp();
  }

  void _initializeAnimations() {
    // Main animation controller
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Book flip animation
    _bookController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Wave animation
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat();

    // Fade in
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
    ));

    // Scale with bounce
    _scaleAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
    ));

    // Book flip
    _bookFlipAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _bookController,
      curve: Curves.easeInOut,
    ));

    // Slide up
    _slideUpAnimation = Tween<double>(
      begin: 100.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.4, 0.9, curve: Curves.easeOutCubic),
    ));

    _mainController.forward();
    _bookController.repeat(reverse: true);
  }

  Future<void> _initializeApp() async {
    try {
      await Future.delayed(const Duration(milliseconds: 2000));

      if (!mounted) return;

      final authProvider = context.read<AuthProvider>();
      await authProvider.checkAuthStatus();

      if (!mounted) return;

      if (authProvider.isAuthenticated) {
        if (authProvider.user?.role.isStudent == true) {
          context.go('/student-dashboard');
        } else if (authProvider.user?.role.isTutor == true) {
          context.go('/tutor-dashboard');
        } else {
          context.go('/login');
        }
      } else {
        final onboardingCompleted = StorageService.getOnboardingCompleted();
        if (onboardingCompleted) {
          context.go('/login');
        } else {
          context.go('/onboarding');
        }
      }
    } catch (e) {
      if (mounted) {
        context.go('/login');
      }
    }
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
    _mainController.dispose();
    _bookController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              const Color(0xFF6B46C1), // Deep Purple
              const Color(0xFF805AD5), // Purple
              const Color(0xFF38B2AC), // Teal
              const Color(0xFF4FD1C5), // Light Teal
            ],
            stops: const [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Animated wave background
            ...List.generate(3, (index) => _buildWave(index, size)),
            
            // Floating books decoration
            ...List.generate(8, (index) => _buildFloatingBook(index, size)),
            
            // Main content
            Center(
              child: AnimatedBuilder(
                animation: _mainController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _slideUpAnimation.value),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Animated book logo
                            _buildBookLogo(),
                            
                            const SizedBox(height: 50),
                            
                            // App name with education theme
                            _buildAppName(),
                            
                            const SizedBox(height: 16),
                            
                            // Tagline with icon
                            _buildTagline(),
                            
                            const SizedBox(height: 70),
                            
                            // Progress indicator
                            _buildProgressIndicator(),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Bottom branding
            Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.verified_rounded,
                          color: Colors.amber[300],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Trusted Learning Platform',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWave(int index, Size size) {
    final delay = index * 0.3;
    final opacity = 0.1 - (index * 0.03);
    
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        return Positioned(
          bottom: -50 + (index * 30.0),
          left: 0,
          right: 0,
          child: Opacity(
            opacity: opacity,
            child: CustomPaint(
              size: Size(size.width, 200),
              painter: _WavePainter(
                (_waveController.value + delay) % 1.0,
                Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFloatingBook(int index, Size size) {
    final random = math.Random(index);
    final startX = random.nextDouble() * size.width;
    final startY = random.nextDouble() * size.height;
    final duration = 4000 + random.nextInt(2000);
    final size1 = 20.0 + random.nextDouble() * 15;
    
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        final progress = (_waveController.value + (index * 0.15)) % 1.0;
        final x = startX + (math.sin(progress * math.pi * 2) * 40);
        final y = startY + (math.cos(progress * math.pi * 2) * 60);
        final opacity = (math.sin(progress * math.pi) * 0.3).clamp(0.0, 0.3);
        final rotation = progress * math.pi * 2;
        
        return Positioned(
          left: x % size.width,
          top: y % size.height,
          child: Transform.rotate(
            angle: rotation,
            child: Icon(
              Icons.menu_book_rounded,
              size: size1,
              color: Colors.white.withOpacity(opacity),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBookLogo() {
    return AnimatedBuilder(
      animation: _bookFlipAnimation,
      builder: (context, child) {
        final angle = _bookFlipAnimation.value * math.pi * 0.2;
        
        return Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.amber[400]!,
                Colors.amber[600]!,
                Colors.orange[600]!,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withOpacity(0.4),
                blurRadius: 30,
                spreadRadius: 10,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Rotating ring
              Transform.rotate(
                angle: angle,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                ),
              ),
              // Book icon
              Transform.rotate(
                angle: -angle * 0.5,
                child: Icon(
                  Icons.auto_stories_rounded,
                  size: 70,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAppName() {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              Colors.white,
              Colors.amber[100]!,
              Colors.white,
            ],
          ).createShader(bounds),
          child: const Text(
            'EduConnect',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 2.0,
              height: 1.1,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'TUTORING PLATFORM',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.amber[300],
            letterSpacing: 3.0,
          ),
        ),
      ],
    );
  }

  Widget _buildTagline() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.15),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.lightbulb_outline_rounded,
            color: Colors.amber[300],
            size: 18,
          ),
          const SizedBox(width: 8),
          const Text(
            'Empowering Minds, Building Futures',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Column(
      children: [
        SizedBox(
          width: 200,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(Colors.amber[400]!),
              minHeight: 4,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Loading your learning journey...',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 13,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

class _WavePainter extends CustomPainter {
  final double progress;
  final Color color;

  _WavePainter(this.progress, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.5);

    for (double i = 0; i < size.width; i++) {
      final x = i;
      final y = size.height * 0.5 +
          math.sin((i / size.width * 2 * math.pi) + (progress * 2 * math.pi)) * 20;
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WavePainter oldDelegate) => true;
}