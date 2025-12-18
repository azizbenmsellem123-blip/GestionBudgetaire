import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  final User? _user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  bool _notificationsEnabled = true;
  bool _darkMode = false;
  bool _biometricEnabled = false;
  bool _isLoading = false;
  
  Map<String, dynamic> _userStats = {
    'totalTransactions': 0,
    'totalBalance': 0.0,
    'activeBudgets': 0,
    'savedAmount': 0.0,
  };

  final List<Map<String, dynamic>> _quickActions = [
    {
      'icon': Icons.qr_code_rounded,
      'label': 'Mon code QR',
      'color': Colors.deepPurple,
    },
    {
      'icon': Icons.share_rounded,
      'label': 'Partager',
      'color': Colors.teal,
    },
    {
      'icon': Icons.backup_rounded,
      'label': 'Sauvegarde',
      'color': Colors.blue,
    },
    {
      'icon': Icons.settings_rounded,
      'label': 'Paramètres',
      'color': Colors.orange,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadUserStats();
  }

  Future<void> _loadUserStats() async {
    if (_user == null) return;

    setState(() => _isLoading = true);

    try {
      final userId = _user!.uid;
      final now = DateTime.now();
      final currentMonthId = "${now.year}-${now.month.toString().padLeft(2, '0')}";

      // Récupérer les transactions
      final transactionsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .get();

      // Récupérer les budgets
      final budgetsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('budgets')
          .where('monthId', isEqualTo: currentMonthId)
          .get();

      double totalIncome = 0;
      double totalExpense = 0;
      double savedAmount = 0;

      for (var doc in transactionsSnapshot.docs) {
        final data = doc.data();
        final amount = (data['amount'] ?? 0).toDouble();
        final type = data['type'] ?? 'dépense';
        
        if (type == 'revenu') {
          totalIncome += amount;
        } else {
          totalExpense += amount;
        }
      }

      // Calculer l'épargne
      savedAmount = totalIncome - totalExpense;
      if (savedAmount < 0) savedAmount = 0;

      setState(() {
        _userStats = {
          'totalTransactions': transactionsSnapshot.docs.length,
          'totalIncome': totalIncome,
          'totalExpense': totalExpense,
          'savedAmount': savedAmount,
          'activeBudgets': budgetsSnapshot.docs.length,
          'balance': totalIncome - totalExpense,
        };
        _isLoading = false;
      });
    } catch (e) {
      print('Erreur chargement stats: $e');
      setState(() => _isLoading = false);
    }
  }

  String _getInitials() {
    if (_user?.displayName != null && _user!.displayName!.isNotEmpty) {
      final names = _user!.displayName!.split(' ');
      return names.length >= 2
          ? '${names[0][0]}${names[1][0]}'.toUpperCase()
          : names[0][0].toUpperCase();
    }
    if (_user?.email != null) {
      return _user!.email![0].toUpperCase();
    }
    return "U";
  }

  String _formatDate(DateTime? date) {
    if (date == null) return "Date inconnue";
    final format = DateFormat('d MMMM yyyy', 'fr');
    return format.format(date);
  }

  String _formatCurrency(double amount) {
    final format = NumberFormat.currency(locale: 'fr_FR', symbol: 'TND');
    return format.format(amount);
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
              letterSpacing: 0.5,
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    Color? iconColor,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: iconColor?.withOpacity(0.1) ?? Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: iconColor ?? Colors.blue,
            size: 22,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        trailing: trailing,
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  void _showEditProfile() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        _getInitials(),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _user?.displayName ?? "Utilisateur",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _user?.email ?? "Non spécifié",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              _buildTextField("Nom complet", _user?.displayName ?? ""),
              const SizedBox(height: 12),
              _buildTextField("Email", _user?.email ?? "", enabled: false),
              const SizedBox(height: 12),
              _buildTextField("Téléphone", ""),
              
              const SizedBox(height: 32),
              
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text("Annuler"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // TODO: Sauvegarder les modifications
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text("Sauvegarder"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTextField(String label, String initialValue, {bool enabled = true}) {
    return TextFormField(
      initialValue: initialValue,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  void _showSecuritySettings() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              
              const Text(
                "Sécurité",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              
              _buildSecurityOption(
                icon: Icons.fingerprint_rounded,
                title: "Authentification biométrique",
                subtitle: "Déverrouiller avec l'empreinte digitale",
                value: _biometricEnabled,
                onChanged: (value) => setState(() => _biometricEnabled = value),
              ),
              const SizedBox(height: 12),
              
              _buildSecurityOption(
                icon: Icons.lock_rounded,
                title: "Code PIN",
                subtitle: "Protéger l'application avec un code",
                value: false,
                onChanged: (value) {},
              ),
              const SizedBox(height: 12),
              
              _buildSecurityOption(
                icon: Icons.notifications_rounded,
                title: "Alertes de sécurité",
                subtitle: "Notifications pour activités suspectes",
                value: true,
                onChanged: (value) {},
              ),
              
              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text("Appliquer"),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSecurityOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.deepPurple, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeColor: Colors.deepPurple,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.logout_rounded, color: Colors.red),
            const SizedBox(width: 12),
            const Text(
              "Déconnexion",
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: const Text(
          "Êtes-vous sûr de vouloir vous déconnecter ? Vous devrez vous reconnecter pour accéder à vos données.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Annuler",
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();
              Navigator.pushNamedAndRemoveUntil(
                context,
                "/login",
                (_) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text("Se déconnecter"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Colors.deepPurple;
    final Color backgroundColor = Colors.grey.shade50;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: CustomScrollView(
        slivers: [
          // Header avec infos utilisateur
          SliverAppBar(
            backgroundColor: primaryColor,
            expandedHeight: 180,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      primaryColor,
                      Colors.purple.shade500,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: _showEditProfile,
                              child: Stack(
                                children: [
                                  Container(
                                    width: 70,
                                    height: 70,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.white,
                                          Colors.grey.shade100,
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Text(
                                        _getInitials(),
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w800,
                                          color: primaryColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.1),
                                            blurRadius: 6,
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        Icons.edit_rounded,
                                        color: primaryColor,
                                        size: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _user?.displayName ?? "Utilisateur",
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _user?.email ?? "Email non spécifié",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today_rounded,
                                        size: 12,
                                        color: Colors.white.withOpacity(0.8),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        "Membre depuis ${_formatDate(_user?.metadata.creationTime)}",
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.white.withOpacity(0.8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
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
          ),

          // Statistiques rapides
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(20),
              child: Column(
                children: [
                  if (_isLoading)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Colors.deepPurple,
                        ),
                      ),
                    )
                  else
                    Row(
                      children: [
                        _buildStatCard(
                          "Transactions",
                          _userStats['totalTransactions'].toString(),
                          Icons.receipt_long_rounded,
                          Colors.blue,
                        ),
                        _buildStatCard(
                          "Revenus",
                          _formatCurrency(_userStats['totalIncome'] ?? 0),
                          Icons.arrow_upward_rounded,
                          Colors.green,
                        ),
                        _buildStatCard(
                          "Dépenses",
                          _formatCurrency(_userStats['totalExpense'] ?? 0),
                          Icons.arrow_downward_rounded,
                          Colors.red,
                        ),
                      ],
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildStatCard(
                        "Épargne",
                        _formatCurrency(_userStats['savedAmount'] ?? 0),
                        Icons.savings_rounded,
                        Colors.amber,
                      ),
                      _buildStatCard(
                        "Budgets",
                        _userStats['activeBudgets'].toString(),
                        Icons.flag_rounded,
                        Colors.purple,
                      ),
                      _buildStatCard(
                        "Solde",
                        _formatCurrency(_userStats['balance'] ?? 0),
                        Icons.account_balance_wallet_rounded,
                        Colors.teal,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Actions rapides
          SliverToBoxAdapter(
            child: _buildSection(
              "Actions rapides",
              [
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: _quickActions.map((action) {
                      return Column(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: action['color'].withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              action['icon'],
                              color: action['color'],
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            action['label'],
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Paramètres du compte
          SliverToBoxAdapter(
            child: _buildSection(
              "Mon compte",
              [
                _buildSettingItem(
                  icon: Icons.person_rounded,
                  title: "Profil",
                  subtitle: "Modifier vos informations personnelles",
                  iconColor: Colors.blue,
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: _showEditProfile,
                ),
                _buildSettingItem(
                  icon: Icons.security_rounded,
                  title: "Sécurité",
                  subtitle: "Gérer la sécurité de votre compte",
                  iconColor: Colors.green,
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: _showSecuritySettings,
                ),
                _buildSettingItem(
                  icon: Icons.notifications_rounded,
                  title: "Notifications",
                  subtitle: "Gérer vos préférences de notifications",
                  iconColor: Colors.orange,
                  trailing: Switch.adaptive(
                    value: _notificationsEnabled,
                    activeColor: primaryColor,
                    onChanged: (value) =>
                        setState(() => _notificationsEnabled = value),
                  ),
                ),
              ],
            ),
          ),

          // Préférences
          SliverToBoxAdapter(
            child: _buildSection(
              "Préférences",
              [
                _buildSettingItem(
                  icon: Icons.dark_mode_rounded,
                  title: "Mode sombre",
                  subtitle: "Activer l'apparence sombre",
                  iconColor: Colors.purple,
                  trailing: Switch.adaptive(
                    value: _darkMode,
                    activeColor: primaryColor,
                    onChanged: (value) => setState(() => _darkMode = value),
                  ),
                ),
                _buildSettingItem(
                  icon: Icons.language_rounded,
                  title: "Langue",
                  subtitle: "Français",
                  iconColor: Colors.teal,
                  trailing: const Icon(Icons.chevron_right_rounded),
                ),
                _buildSettingItem(
                  icon: Icons.currency_exchange_rounded,
                  title: "Devise",
                  subtitle: "Dinar tunisien (TND)",
                  iconColor: Colors.amber,
                  trailing: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
          ),

          // Support
          SliverToBoxAdapter(
            child: _buildSection(
              "Support",
              [
                _buildSettingItem(
                  icon: Icons.help_rounded,
                  title: "Centre d'aide",
                  subtitle: "Obtenir de l'aide",
                  iconColor: Colors.cyan,
                  trailing: const Icon(Icons.chevron_right_rounded),
                ),
                _buildSettingItem(
                  icon: Icons.feedback_rounded,
                  title: "Donner votre avis",
                  subtitle: "Partagez votre expérience",
                  iconColor: Colors.pink,
                  trailing: const Icon(Icons.chevron_right_rounded),
                ),
                _buildSettingItem(
                  icon: Icons.privacy_tip_rounded,
                  title: "Confidentialité",
                  subtitle: "Politique de confidentialité",
                  iconColor: Colors.indigo,
                  trailing: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
          ),

          // Déconnexion
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _showLogoutConfirmation,
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text(
                        "Se déconnecter",
                        style: TextStyle(fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade50,
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "BudgetMaster • v1.0.0",
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "© 2024 Tous droits réservés",
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}