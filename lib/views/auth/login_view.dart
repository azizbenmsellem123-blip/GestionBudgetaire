import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/animation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../controllers/auth_controller.dart';

class LoginView extends StatefulWidget {
  final AuthController controller;

  const LoginView({required this.controller, super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> with TickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  String? _error;
  final _formKey = GlobalKey<FormState>();

  // Animations
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _waveController;
  late Animation<double> _waveAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialisation des animations
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _waveController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: Curves.elasticOut,
      ),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: Curves.easeOutCubic,
      ),
    );
    
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeInOut,
      ),
    );
    
    _waveAnimation = Tween<double>(begin: -0.05, end: 0.05).animate(
      CurvedAnimation(
        parent: _waveController,
        curve: Curves.easeInOutSine, // ✅ CORRECTION ICI (ligne 68)
      ),
    );

    // Démarrer les animations
    Future.delayed(const Duration(milliseconds: 300), () {
      _scaleController.forward();
      _slideController.forward();
      _fadeController.forward();
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _slideController.dispose();
    _fadeController.dispose();
    _waveController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // === LOGIN avec animation ===
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    // Animation de validation
    _scaleController.reset();
    await _scaleController.forward();

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    bool success = await widget.controller.login(email, password);

    if (success) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Animation de succès
        await _scaleController.forward(from: 0);
        
        // Navigation avec transition
        Navigator.pushReplacementNamed(
          context,
          "/home",
          arguments: user.uid,
        );
      }
    } else {
      // Animation d'erreur
      await _scaleController.forward(from: 0);
      setState(() {
        _error = "Email ou mot de passe incorrect";
      });
    }

    setState(() => _isLoading = false);
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _waveAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _waveAnimation.value * 20),
          child: child,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade50.withOpacity(0.8),
              Colors.purple.shade50.withOpacity(0.6),
              Colors.white.withOpacity(0.9),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );
  }

  Widget _buildParticles() {
    return IgnorePointer(
      child: SizedBox.expand(
        child: CustomPaint(
          painter: ParticlePainter(_waveController),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade700,
              Colors.purple.shade600,
              Colors.pink.shade500,
            ],
          ),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.4),
              blurRadius: 25,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: Colors.purple.withOpacity(0.2),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Effet de brillance
            Positioned(
              top: -15,
              left: -15,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // Icône
            const Center(
              child: Icon(
                Icons.account_balance_wallet_rounded,
                color: Colors.white,
                size: 45,
                shadows: [
                  Shadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
            ),
            // Effet de bordure
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    bool obscureText = false,
    bool? showSuffix,
    VoidCallback? onSuffixTap,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            decoration: InputDecoration(
              hintText: label,
              hintStyle: TextStyle(
                color: Colors.grey.shade400,
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: Container(
                margin: const EdgeInsets.only(left: 16, right: 12),
                child: Icon(
                  icon,
                  color: Colors.blue.shade700,
                  size: 22,
                ),
              ),
              suffixIcon: showSuffix != null
                  ? IconButton(
                      icon: Icon(
                        showSuffix
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        color: Colors.grey.shade500,
                        size: 20,
                      ),
                      onPressed: onSuffixTap,
                    )
                  : null,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 20,
                horizontal: 16,
              ),
            ),
            validator: validator,
          ),
        ),
      ),
    );
  }

  Widget _buildRememberMe() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: _rememberMe ? Colors.blue.shade700 : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: _rememberMe ? Colors.blue.shade700 : Colors.grey.shade400,
                width: 2,
              ),
            ),
            child: _rememberMe
                ? const Icon(
                    Icons.check_rounded,
                    size: 14,
                    color: Colors.white,
                  )
                : null,
          ),
          const SizedBox(width: 12),
          const Spacer(),
          GestureDetector(
            onTap: () {
              // TODO: Implémenter réinitialisation mot de passe
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLoginButton() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _login,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade700,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
            shadowColor: Colors.transparent,
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _isLoading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Connexion",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 12),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.blue,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorContainer() {
    if (_error == null) return const SizedBox.shrink();
    
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.red.shade100,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                color: Colors.red.shade600,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Erreur de connexion",
                    style: TextStyle(
                      color: Colors.red.shade800,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Colors.red.shade600,
                      fontSize: 13,
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

  Widget _buildDivider() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Row(
        children: [
          
         
        ],
      ),
    );
  }

 
  Widget _buildRegisterButton() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Nouveau sur BudgetMaster ? ",
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, "/register");
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [
                    Colors.purple.shade600,
                    Colors.pink.shade500,
                  ],
                ),
              ),
              child: Text(
                "S'inscrire",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Arrière-plan animé
          _buildAnimatedBackground(),
          
          // Particules flottantes
          _buildParticles(),
          
          // Contenu principal
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    
                    // Logo animé
                    Center(child: _buildLogo()),
                    
                    const SizedBox(height: 32),
                    
                    // Titre
                    SlideTransition(
                      position: _slideAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          children: [
                            Text(
                              "Bienvenue",
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w800,
                                foreground: Paint()
                                  ..shader = LinearGradient(
                                    colors: [
                                      Colors.blue.shade700,
                                      Colors.purple.shade600,
                                    ],
                                  ).createShader(
                                    const Rect.fromLTWH(0, 0, 200, 70),
                                  ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Connectez-vous pour gérer vos finances",
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Formulaire
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildInputField(
                            label: "Adresse e-mail",
                            icon: Icons.email_rounded,
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Email requis';
                              }
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                  .hasMatch(value)) {
                                return 'Email invalide';
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: 20),
                          
                          _buildInputField(
                            label: "Mot de passe",
                            icon: Icons.lock_rounded,
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            showSuffix: _obscurePassword,
                            onSuffixTap: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Mot de passe requis';
                              }
                              if (value.length < 6) {
                                return 'Minimum 6 caractères';
                              }
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Remember me & forgot password
                          _buildRememberMe(),
                          
                          const SizedBox(height: 24),
                          
                          // Erreur
                          _buildErrorContainer(),
                          
                          const SizedBox(height: 24),
                          
                          // Bouton de connexion
                          _buildLoginButton(),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Divider
                    _buildDivider(),
                    
                    const SizedBox(height: 30),
                    
                    
                    
                    const SizedBox(height: 40),
                    
                    // Lien d'inscription
                    _buildRegisterButton(),
                    
                    const SizedBox(height: 20),
                    
                    // Conditions
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          "En vous connectant, vous acceptez nos conditions générales et notre politique de confidentialité.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 11,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Painter pour les particules flottantes
class ParticlePainter extends CustomPainter {
  final AnimationController controller;

  ParticlePainter(this.controller) : super(repaint: controller);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final time = controller.value * 2 * 3.14159;

    // Dessiner des particules flottantes
    for (int i = 0; i < 15; i++) {
      final x = size.width * (0.1 + 0.8 * (i / 15));
      final y = size.height * 0.2 + 20 * sin(time + i * 0.5);
      final radius = 2 + sin(time + i) * 1;

      canvas.drawCircle(
        Offset(x, y),
        radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}