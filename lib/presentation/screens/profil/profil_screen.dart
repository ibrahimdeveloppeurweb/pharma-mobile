


import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pharma/data/providers/auth_provider.dart';
import '../../../shared/constants/colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      // Vous pouvez ajouter une méthode refreshUser() si nécessaire
      // authProvider.refreshUser();
    });
  }

  void _showEditDialog(String field, String currentValue) {
    final controller = TextEditingController(text: currentValue);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Modifier $field'),
        content: TextField(
          controller: controller,
          keyboardType: field == 'Email'
              ? TextInputType.emailAddress
              : field == 'Téléphone'
              ? TextInputType.phone
              : TextInputType.text,
          decoration: InputDecoration(
            labelText: field,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) {
                Navigator.of(dialogContext).pop();
                _showErrorSnackBar('Le champ ne peut pas être vide');
                return;
              }

              // ✅ Fermer le dialog de saisie
              Navigator.of(dialogContext).pop();

              // ✅ Afficher le dialog de chargement
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (loadingContext) => WillPopScope(
                  onWillPop: () async => false,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: AppColors.primary),
                          const SizedBox(height: 16),
                          const Text(
                            'Mise à jour...',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );

              try {
                final authProvider =
                Provider.of<AuthProvider>(context, listen: false);
                final user = authProvider.currentUser;
                // Préparer les données à mettre à jour
                Map<String, dynamic> updateData = {};

                updateData['uuid'] = user?.uuid;
                updateData['refreshToken'] = user?.refreshToken;
                if (field == 'Nom') {
                  updateData['nom'] = controller.text.trim();
                } else if (field == 'Email') {
                  updateData['email'] = controller.text.trim();
                } else if (field == 'Téléphone') {
                  updateData['telephone'] = controller.text.trim();
                }

                // Appeler la méthode de mise à jour du provider
                await authProvider.updateProfile(updateData);

                // Simuler un délai pour le test
                await Future.delayed(const Duration(seconds: 1));

                if (mounted) {
                  Navigator.of(context).pop(); // Fermer le loading
                  _showSuccessSnackBar('$field modifié avec succès');
                }
              } catch (e) {
                if (mounted) {
                  Navigator.of(context).pop(); // Fermer le loading
                  _showErrorSnackBar('Erreur: ${e.toString()}');
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Changer le mot de passe'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Nouveau mot de passe',
                prefixIcon: const Icon(Icons.lock),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirmer le mot de passe',
                prefixIcon: const Icon(Icons.lock),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Validation
              if (newPasswordController.text.isEmpty ||
                  confirmPasswordController.text.isEmpty) {
                Navigator.of(dialogContext).pop();
                _showErrorSnackBar('Tous les champs sont obligatoires');
                return;
              }

              if (newPasswordController.text.length < 6) {
                Navigator.of(dialogContext).pop();
                _showErrorSnackBar(
                    'Le mot de passe doit contenir au moins 6 caractères');
                return;
              }

              if (newPasswordController.text != confirmPasswordController.text) {
                Navigator.of(dialogContext).pop();
                _showErrorSnackBar('Les mots de passe ne correspondent pas');
                return;
              }

              // ✅ Fermer le dialog de saisie
              Navigator.of(dialogContext).pop();

              // ✅ Afficher le dialog de chargement
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (loadingContext) => WillPopScope(
                  onWillPop: () async => false,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: AppColors.primary),
                          const SizedBox(height: 16),
                          const Text(
                            'Modification en cours...',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );

              try {
                final authProvider =
                Provider.of<AuthProvider>(context, listen: false);
                final user = authProvider.currentUser;

                // Appeler la méthode de changement de mot de passe
                await authProvider.changePassword(
                  newPasswordController.text,
                  confirmPasswordController.text,
                  user!.email,
                );

                if (mounted) {
                  Navigator.of(context).pop(); // Fermer le loading
                  _showSuccessSnackBar('Mot de passe modifié avec succès');
                }
              } catch (e) {
                if (mounted) {
                  Navigator.of(context).pop(); // Fermer le loading
                  _showErrorSnackBar('Erreur: ${e.toString()}');
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Changer'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              // ✅ Fermer le dialog de confirmation
              Navigator.of(dialogContext).pop();

              // ✅ Afficher le dialog de chargement
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (loadingContext) => WillPopScope(
                  onWillPop: () async => false,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: AppColors.primary),
                          const SizedBox(height: 16),
                          const Text(
                            'Déconnexion...',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );

              try {
                final authProvider =
                Provider.of<AuthProvider>(context, listen: false);
                final user = authProvider.currentUser;
                final param = {
                  'user': user?.uuid,
                  'refreshToken': user?.refreshToken,
                };

                await authProvider.logout(param);

                // ✅ Fermer le loading
                if (mounted) {
                  Navigator.of(context).pop();

                  // ✅ Navigation vers login
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/login',
                        (route) => false,
                  );
                }
              } catch (e) {
                // ✅ Fermer le loading
                if (mounted) {
                  Navigator.of(context).pop();

                  // ✅ Afficher l'erreur
                  _showErrorSnackBar('Erreur: ${e.toString()}');
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Profil',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.currentUser;

          // Si l'utilisateur n'est pas connecté
          if (user == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_off,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Utilisateur non connecté',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    icon: const Icon(Icons.login),
                    label: const Text('Se connecter'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // 🎯 EN-TÊTE PROFIL
                _buildProfileHeader(user),
                const SizedBox(height: 24),

                // 🎯 INFORMATIONS PERSONNELLES
                _buildSection(
                  title: 'Informations personnelles',
                  items: [
                    _buildInfoItem(
                      icon: Icons.person,
                      label: 'Nom',
                      value: user.nom ?? 'N/A',
                      onTap: () => _showEditDialog('Nom', user.nom ?? ''),
                    ),
                    _buildInfoItem(
                      icon: Icons.email,
                      label: 'Email',
                      value: user.email,
                      onTap: null
                    ),
                    _buildInfoItem(
                      icon: Icons.phone,
                      label: 'Téléphone',
                      value: user.contact ?? 'N/A',
                      onTap: () =>
                          _showEditDialog('Téléphone', user.contact ?? ''),
                    ),
                   // label: 'Rôle', value: user.role ?? 'N/A',
                    _buildInfoItem(
                      icon: Icons.admin_panel_settings,
                      label: 'Rôle',
                      value: 'Utilisateur',
                      onTap: null, // Non modifiable
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 🎯 SÉCURITÉ
                _buildSection(
                  title: 'Sécurité',
                  items: [
                    _buildActionItem(
                      icon: Icons.lock,
                      label: 'Changer le mot de passe',
                      onTap: _showChangePasswordDialog,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 🎯 BOUTON DÉCONNEXION
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _showLogoutDialog,
                    icon: const Icon(Icons.logout),
                    label: const Text(
                      'Déconnexion',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(dynamic user) {
    // Récupérer les initiales pour l'avatar
    String getInitials() {
      String initials = '';

      if (user.nom != null && user.nom!.isNotEmpty) {
        initials += user.nom![0].toUpperCase();
      }
      return initials.isNotEmpty ? initials : 'AD';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primary.withOpacity(0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                getInitials(),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
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
                  '${user.nom ?? ''}'.trim(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
               // user.role ?? 'Utilisateur',
                Text(
                  'Utilisateur',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'En ligne',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: items,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}