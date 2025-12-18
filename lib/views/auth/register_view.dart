import 'package:flutter/material.dart';
import '../../controllers/auth_controller.dart';

class RegisterView extends StatefulWidget {
  final AuthController controller;

  const RegisterView({required this.controller, super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final TextEditingController nomController = TextEditingController();
  final TextEditingController prenomController = TextEditingController();
  final TextEditingController telephoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  final _formKey = GlobalKey<FormState>();
  final PageController _pageController = PageController();
  int _currentPage = 0;

  List<Map<String, dynamic>> formData = [];

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentPage++);
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentPage--);
    }
  }

  void handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline_rounded, color: Colors.red.shade100),
              const SizedBox(width: 10),
              const Text("Les mots de passe ne correspondent pas"),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    bool success = await widget.controller.register(
      nom: nomController.text.trim(),
      prenom: prenomController.text.trim(),
      telephone: telephoneController.text.trim(),
      email: email,
      password: password,
    );

    setState(() => isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.green.shade100),
              const SizedBox(width: 10),
              const Text("Compte créé avec succès !"),
            ],
          ),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

      await Future.delayed(const Duration(seconds: 1));
      Navigator.pushReplacementNamed(context, "/login");
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline_rounded, color: Colors.red.shade100),
              const SizedBox(width: 10),
              const Text("Erreur lors de l'inscription"),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Arrière-plan avec gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.blue.shade50,
                  Colors.white,
                  Colors.white,
                ],
              ),
            ),
          ),

          // Formes décoratives
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -60,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Bouton retour
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Titre et description
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Créez votre compte",
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Commencez à gérer vos finances intelligemment",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // Indicateur de progression
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: [
                          _buildProgressStep(0, "Info"),
                          Expanded(
                            child: Container(
                              height: 3,
                              decoration: BoxDecoration(
                                color: _currentPage >= 1
                                    ? Colors.blue.shade700
                                    : Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          _buildProgressStep(1, "Contact"),
                          Expanded(
                            child: Container(
                              height: 3,
                              decoration: BoxDecoration(
                                color: _currentPage >= 2
                                    ? Colors.blue.shade700
                                    : Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          _buildProgressStep(2, "Sécurité"),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Formulaire avec pages
                    Form(
                      key: _formKey,
                      child: Container(
                        height: 400,
                        child: PageView(
                          controller: _pageController,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            // Page 1 : Informations personnelles
                            _buildPersonalInfoPage(),
                            
                            // Page 2 : Informations de contact
                            _buildContactInfoPage(),
                            
                            // Page 3 : Sécurité
                            _buildSecurityPage(),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Boutons de navigation
                    Row(
                      children: [
                        if (_currentPage > 0)
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _previousPage,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.blue.shade700,
                                side: BorderSide(
                                  color: Colors.blue.shade700,
                                  width: 2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.arrow_back_rounded, size: 20),
                                  const SizedBox(width: 8),
                                  const Text(
                                    "Retour",
                                    style: TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (_currentPage > 0) const SizedBox(width: 12),
                        Expanded(
                          flex: _currentPage > 0 ? 1 : 2,
                          child: ElevatedButton(
                            onPressed: _currentPage < 2 ? _nextPage : handleRegister,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade700,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        _currentPage < 2 ? "Continuer" : "Créer mon compte",
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(
                                        _currentPage < 2
                                            ? Icons.arrow_forward_rounded
                                            : Icons.check_circle_rounded,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Lien vers la connexion
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pushReplacementNamed(context, "/login");
                        },
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: "Déjà un compte ? ",
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                              TextSpan(
                                text: "Se connecter",
                                style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Conditions d'utilisation
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        "En créant un compte, vous acceptez nos conditions d'utilisation et notre politique de confidentialité.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStep(int step, String label) {
    final isActive = _currentPage >= step;
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isActive ? Colors.blue.shade700 : Colors.white,
            border: Border.all(
              color: isActive ? Colors.blue.shade700 : Colors.grey.shade300,
              width: 2,
            ),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              (step + 1).toString(),
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey.shade400,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? Colors.blue.shade700 : Colors.grey.shade500,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalInfoPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Informations personnelles",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Remplissez vos informations de base",
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 25),
        
        // Nom
        _buildTextField(
          controller: nomController,
          label: "Nom",
          icon: Icons.person_rounded,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez saisir votre nom';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        
        // Prénom
        _buildTextField(
          controller: prenomController,
          label: "Prénom",
          icon: Icons.person_outline_rounded,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez saisir votre prénom';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildContactInfoPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Informations de contact",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Comment pouvons-nous vous contacter ?",
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 25),
        
        // Email
        _buildTextField(
          controller: emailController,
          label: "Adresse e-mail",
          icon: Icons.email_rounded,
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez saisir votre email';
            }
            if (!value.contains('@')) {
              return 'Email invalide';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        
        // Téléphone
        _buildTextField(
          controller: telephoneController,
          label: "Téléphone",
          icon: Icons.phone_rounded,
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez saisir votre numéro';
            }
            if (value.length < 8) {
              return 'Numéro invalide';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSecurityPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Sécurité du compte",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Créez un mot de passe sécurisé",
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 25),
        
        // Mot de passe
        _buildPasswordField(
          controller: passwordController,
          label: "Mot de passe",
          obscureText: _obscurePassword,
          onToggleVisibility: () {
            setState(() => _obscurePassword = !_obscurePassword);
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez saisir un mot de passe';
            }
            if (value.length < 6) {
              return '6 caractères minimum';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        
        // Confirmation mot de passe
        _buildPasswordField(
          controller: confirmPasswordController,
          label: "Confirmer le mot de passe",
          obscureText: _obscureConfirmPassword,
          onToggleVisibility: () {
            setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez confirmer votre mot de passe';
            }
            return null;
          },
        ),
        
        // Indicateur de force du mot de passe
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: Colors.blue.shade700, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    "Conseils de sécurité",
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "• Utilisez au moins 6 caractères\n• Combinez lettres et chiffres\n• Évitez les mots de passe courants",
                style: TextStyle(
                  color: Colors.blue.shade800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.black87,
        ),
        decoration: InputDecoration(
          hintText: label,
          hintStyle: TextStyle(color: Colors.grey.shade400),
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.blue.shade700,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(icon, color: Colors.blue.shade700),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    required String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.black87,
        ),
        decoration: InputDecoration(
          hintText: label,
          hintStyle: TextStyle(color: Colors.grey.shade400),
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.blue.shade700,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(Icons.lock_rounded, color: Colors.blue.shade700),
          suffixIcon: IconButton(
            icon: Icon(
              obscureText ? Icons.visibility_off_rounded : Icons.visibility_rounded,
              color: Colors.grey.shade500,
            ),
            onPressed: onToggleVisibility,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
        validator: validator,
      ),
    );
  }

  @override
  void dispose() {
    nomController.dispose();
    prenomController.dispose();
    telephoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    _pageController.dispose();
    super.dispose();
  }
}