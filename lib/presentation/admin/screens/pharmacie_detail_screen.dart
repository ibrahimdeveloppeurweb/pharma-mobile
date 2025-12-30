import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pharma/presentation/admin/screens/ajour_pharmace_admin_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:pharma/data/providers/pharmacie_provider.dart';
import 'package:pharma/data/models/pharmacie_model.dart';
import '../../../shared/constants/colors.dart';

class PharmacieDetailScreen extends StatefulWidget {
  final PharmacieModel pharmacie;

  const PharmacieDetailScreen({
    Key? key,
    required this.pharmacie,
  }) : super(key: key);

  @override
  State<PharmacieDetailScreen> createState() => _PharmacieDetailScreenState();
}

class _PharmacieDetailScreenState extends State<PharmacieDetailScreen> {
  bool _isLoading = false;

  // Récupérer la pharmacie mise à jour depuis le Provider
  PharmacieModel get _currentPharmacie {
    final provider = Provider.of<PharmacieProvider>(context, listen: true);
    return provider.pharmacies.firstWhere(
          (p) => p.uuid == widget.pharmacie.uuid,
      orElse: () => widget.pharmacie, // Fallback si pas trouvée
    );
  }

  bool get isActive => _currentPharmacie.actif ?? false;
  bool get hasActiveSubscription => _currentPharmacie.abonnementActif ?? false;

  /// Appeler la pharmacie
  Future<void> _appelerPharmacie() async {
    final telephone = _currentPharmacie.telephone;
    if (telephone == null || telephone.isEmpty) {
      _showSnackBar('Numéro de téléphone non disponible', isError: true);
      return;
    }

    final url = 'tel:$telephone';
    try {
      final Uri telUri = Uri.parse(url);
      final bool launched = await launchUrl(
        telUri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        _showSnackBar('Impossible de composer le numéro', isError: true);
      }
    } on Exception catch (e) {
      debugPrint('Exception lors de l\'appel: $e');
      _showSnackBar('Erreur lors de la composition', isError: true);
    }
  }

  /// Envoyer un email
  Future<void> _envoyerEmail() async {
    final email = _currentPharmacie.email;
    if (email == null || email.isEmpty) {
      _showSnackBar('Email non disponible', isError: true);
      return;
    }

    final url = 'mailto:$email';
    try {
      final Uri emailUri = Uri.parse(url);
      final bool launched = await launchUrl(
        emailUri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        _showSnackBar('Impossible d\'ouvrir l\'application email', isError: true);
      }
    } on Exception catch (e) {
      debugPrint('Exception lors de l\'envoi email: $e');
      _showSnackBar('Erreur lors de l\'ouverture de l\'email', isError: true);
    }
  }

  /// Ouvrir dans Maps
  Future<void> _ouvrirDansMaps() async {
    final adresse = _currentPharmacie.adresse ?? _currentPharmacie.ville;
    final url = 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(adresse)}';

    try {
      final Uri mapsUri = Uri.parse(url);
      final bool launched = await launchUrl(
        mapsUri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        _showSnackBar('Impossible d\'ouvrir Maps', isError: true);
      }
    } on Exception catch (e) {
      debugPrint('Exception lors de l\'ouverture Maps: $e');
      _showSnackBar('Erreur lors de l\'ouverture de Maps', isError: true);
    }
  }

  /// Modifier la pharmacie
  Future<void> _modifierPharmacie() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreatePharmacieAdminScreen(pharmacie: _currentPharmacie),
      ),
    );

    if (result == true && mounted) {
      await _refreshPharmacieData();
    }
  }

  /// Rafraîchir les données de la pharmacie
  Future<void> _refreshPharmacieData() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final pharmacieProvider = context.read<PharmacieProvider>();
      await pharmacieProvider.loadPharmacies({});

      if (mounted) {
        setState(() => _isLoading = false);
      }

      _showSnackBar('Données mises à jour');

    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      _showSnackBar('Erreur lors du rafraîchissement', isError: true);
    }
  }

  /// Changer le statut (Activer/Désactiver)
  Future<void> _changerStatut() async {
    final confirmed = await _showConfirmDialog(
      isActive ? 'Désactiver la pharmacie' : 'Activer la pharmacie',
      isActive
          ? 'Voulez-vous vraiment désactiver cette pharmacie ?'
          : 'Voulez-vous vraiment activer cette pharmacie ?',
    );

    if (!confirmed) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Appel API pour changer le statut
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      _showSnackBar(
        isActive ? 'Pharmacie désactivée avec succès' : 'Pharmacie activée avec succès',
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      _showSnackBar('Erreur lors du changement de statut', isError: true);
    }
  }

  /// Renouveler l'abonnement
  Future<void> _renouvellerAbonnement() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildAbonnementModal(),
    );

    if (result == null) return;

    final typeRenouvellement = result['type'] as String;
    final dateFin = result['dateFin'] as DateTime?;

    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Appel API pour renouveler l'abonnement
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      _showSnackBar(
        typeRenouvellement == 'faveur'
            ? 'Faveur activée jusqu\'au ${DateFormat('dd/MM/yyyy').format(dateFin!)}'
            : 'Abonnement renouvelé pour 1 mois',
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      _showSnackBar('Erreur lors du renouvellement', isError: true);
    }
  }

  /// Modal de renouvellement d'abonnement
  Widget _buildAbonnementModal() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.workspace_premium,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Renouveler l\'abonnement',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Choisissez le type de renouvellement',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildRenewOption(
            icon: Icons.calendar_month,
            title: 'Abonnement mensuel',
            description: 'Renouveler pour 1 mois',
            color: AppColors.primary,
            onTap: () {
              Navigator.pop(context, {
                'type': 'abonnement',
                'dateFin': DateTime.now().add(const Duration(days: 30)),
              });
            },
          ),
          const SizedBox(height: 12),
          _buildRenewOption(
            icon: Icons.card_giftcard,
            title: 'Faveur temporaire',
            description: 'Activer une faveur avec date de fin',
            color: Colors.orange,
            onTap: () async {
              final dateFin = await _showDatePicker();
              if (dateFin != null) {
                Navigator.pop(context, {
                  'type': 'faveur',
                  'dateFin': dateFin,
                });
              }
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                'Annuler',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Option de renouvellement
  Widget _buildRenewOption({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: color),
          ],
        ),
      ),
    );
  }

  /// Sélecteur de date pour la faveur
  Future<DateTime?> _showDatePicker() async {
    final now = DateTime.now();
    final initialDate = now.add(const Duration(days: 7));
    final firstDate = now;
    final lastDate = now.add(const Duration(days: 365));

    return await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
      helpText: 'Sélectionner la date de fin de la faveur',
      cancelText: 'Annuler',
      confirmText: 'Confirmer',
    );
  }

  /// Supprimer la pharmacie
  Future<void> _supprimerPharmacie() async {
    final confirmed = await _showConfirmDialog(
      'Cacher la pharmacie',
      'Êtes-vous sûr de vouloir cacher cette pharmacie ? Cette action est irréversible.',
      isDestructive: true,
    );

    if (!confirmed) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final pharmacieProvider = context.read<PharmacieProvider>();
      final success = await pharmacieProvider.deletePharmacie(widget.pharmacie.uuid!,widget.pharmacie.id!);

      setState(() => _isLoading = false);

      if (!mounted) return;

      if (success) {
        Navigator.pop(context, false);

        Navigator.of(context).pop();
      } else {

      }
      await Future.delayed(const Duration(seconds: 1));

      _showSnackBar('Pharmacie supprimée');
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      _showSnackBar('Erreur lors de la suppression', isError: true);
    }
  }

  /// Dialogue de confirmation
  Future<bool> _showConfirmDialog(
      String title,
      String message, {
        bool isDestructive = false,
      }) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: isDestructive ? Colors.red : AppColors.primary,
            ),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    ) ??
        false;
  }

  /// Afficher un SnackBar
  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pharmacie = _currentPharmacie;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Détail de la Pharmacie',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPharmacieCard(pharmacie),
                const SizedBox(height: 16),
                _buildStatistiquesCard(pharmacie),
                const SizedBox(height: 16),
                _buildContactCard(pharmacie),
                const SizedBox(height: 16),
                _buildHistoriqueCard(pharmacie),
                const SizedBox(height: 24),
                _buildActionButtons(),
                const SizedBox(height: 16),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
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
                        'Traitement en cours...',
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
        ],
      ),
    );
  }

  /// Carte principale Pharmacie
  Widget _buildPharmacieCard(PharmacieModel pharmacie) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_pharmacy,
                  size: 32,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pharmacie.nom,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pharmacie.ville,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isActive ? 'Active' : 'Inactive',
                        style: TextStyle(
                          color: isActive ? Colors.green : Colors.grey,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: hasActiveSubscription
                            ? Colors.green.withOpacity(0.2)
                            : Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            hasActiveSubscription ? Icons.check_circle : Icons.cancel,
                            size: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            hasActiveSubscription ? 'Abonné' : 'Non abonné',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (pharmacie.rang != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.emoji_events,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Rang ${pharmacie.rang}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              if (pharmacie.telephone != null) ...[
                const SizedBox(width: 12),
                InkWell(
                  onTap: _appelerPharmacie,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.phone,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// Carte Statistiques
  Widget _buildStatistiquesCard(PharmacieModel pharmacie) {
    return Container(
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Statistiques',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Total',
                  pharmacie.totalDemandes.toString(),
                  Icons.list_alt,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  'Alertés',
                  pharmacie.demandesNotifiees.toString(),
                  Icons.notifications_active,
                  Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'En attente',
                  pharmacie.demandesEnAttente?.toString() ?? '0',
                  Icons.pending,
                  Colors.grey,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  'Récupérés',
                  pharmacie.demandesRecuperees?.toString() ?? '0',
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
            ],
          ),
          if (pharmacie.tauxPerformance != null) ...[
            const SizedBox(height: 16),
            _buildPerformanceBar(pharmacie),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceBar(PharmacieModel pharmacie) {
    final performance = pharmacie.tauxPerformance!;
    final percentage = performance / 100;
    Color barColor;

    if (performance >= 80) {
      barColor = Colors.green;
    } else if (performance >= 60) {
      barColor = Colors.blue;
    } else if (performance >= 40) {
      barColor = Colors.orange;
    } else {
      barColor = Colors.red;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Taux de performance',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '$performance% • ${pharmacie.performanceLabel}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: barColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: percentage,
            backgroundColor: Colors.grey[200],
            color: barColor,
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  /// Carte Contact
  Widget _buildContactCard(PharmacieModel pharmacie) {
    return Container(
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Coordonnées',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _buildContactItem(
            Icons.phone,
            'Téléphone',
            pharmacie.telephone ?? 'Non renseigné',
            onTap: pharmacie.telephone != null ? _appelerPharmacie : null,
          ),
          const SizedBox(height: 12),
          _buildContactItem(
            Icons.email,
            'Email',
            pharmacie.email ?? 'Non renseigné',
            onTap: pharmacie.email != null ? _envoyerEmail : null,
          ),
          const SizedBox(height: 12),
          _buildContactItem(
            Icons.location_on,
            'Adresse',
            pharmacie.adresse ?? pharmacie.ville,
            onTap: _ouvrirDansMaps,
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(
      IconData icon,
      String label,
      String value, {
        VoidCallback? onTap,
      }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 12),
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
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
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

  /// Carte Historique (Timeline)
  Widget _buildHistoriqueCard(PharmacieModel pharmacie) {
    final List<Map<String, dynamic>> historique = [];

    if (pharmacie.createdAt != null) {
      historique.add({
        'label': 'Pharmacie enregistrée',
        'date': pharmacie.createdAt!,
        'icon': Icons.add_circle_outline,
      });
    }

    if (pharmacie.updatedAt != null) {
      historique.add({
        'label': 'Dernière modification',
        'date': pharmacie.updatedAt!,
        'icon': Icons.edit,
      });
    }

    if (pharmacie.deletedAt != null) {
      historique.add({
        'label': 'Pharmacie supprimée',
        'date': pharmacie.deletedAt!,
        'icon': Icons.delete,
      });
    }

    if (historique.isEmpty) {
      return const SizedBox.shrink();
    }

    final dateFormat = DateFormat('dd/MM/yyyy à HH:mm');

    return Container(
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Historique',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          ...historique.asMap().entries.map((entry) {
            final isLast = entry.key == historique.length - 1;
            return _buildHistoriqueItem(
              entry.value['label'],
              dateFormat.format(entry.value['date']),
              entry.value['icon'],
              isLast,
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildHistoriqueItem(String label, String date, IconData icon, bool isLast) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 16,
                color: AppColors.primary,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                margin: const EdgeInsets.symmetric(vertical: 4),
                color: AppColors.primary.withOpacity(0.3),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Boutons d'action
  Widget _buildActionButtons() {
    return Column(
      children: [
        if (!hasActiveSubscription) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _renouvellerAbonnement,
              icon: const Icon(Icons.workspace_premium, size: 20),
              label: const Text(
                'Renouveler l\'abonnement',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _modifierPharmacie,
            icon: const Icon(Icons.edit, size: 20),
            label: const Text(
              'Modifier les informations',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ),
        // const SizedBox(height: 12),
        // SizedBox(
        //   width: double.infinity,
        //   child: ElevatedButton.icon(
        //     onPressed: _changerStatut,
        //     icon: Icon(
        //       isActive ? Icons.block : Icons.check_circle,
        //       size: 20,
        //     ),
        //     label: Text(
        //       isActive ? 'Désactiver la pharmacie' : 'Activer la pharmacie',
        //       style: const TextStyle(
        //         fontSize: 16,
        //         fontWeight: FontWeight.w600,
        //       ),
        //     ),
        //     style: ElevatedButton.styleFrom(
        //       backgroundColor: isActive ? Colors.orange : Colors.green,
        //       foregroundColor: Colors.white,
        //       padding: const EdgeInsets.symmetric(vertical: 16),
        //       shape: RoundedRectangleBorder(
        //         borderRadius: BorderRadius.circular(12),
        //       ),
        //       elevation: 0,
        //     ),
        //   ),
        // ),
        //const SizedBox(height: 12),
        // SizedBox(
        //   width: double.infinity,
        //   child: OutlinedButton(
        //     onPressed: _supprimerPharmacie,
        //     style: OutlinedButton.styleFrom(
        //       foregroundColor: Colors.red,
        //       side: const BorderSide(color: Colors.red, width: 1.5),
        //       padding: const EdgeInsets.symmetric(vertical: 16),
        //       shape: RoundedRectangleBorder(
        //         borderRadius: BorderRadius.circular(12),
        //       ),
        //     ),
        //     child: const Text(
        //       'Cacher la pharmacie',
        //       style: TextStyle(
        //         fontSize: 16,
        //         fontWeight: FontWeight.w600,
        //       ),
        //     ),
        //   ),
        // ),
      ],
    );
  }
}