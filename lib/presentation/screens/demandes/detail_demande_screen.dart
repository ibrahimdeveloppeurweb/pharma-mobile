import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../shared/constants/colors.dart';
import '../../../data/models/demande_model.dart';
import '../../../data/providers/demande_provider.dart';

class DetailDemandeScreen extends StatefulWidget {
  final DemandeModel demande;

  const DetailDemandeScreen({
    Key? key,
    required this.demande,
  }) : super(key: key);

  @override
  State<DetailDemandeScreen> createState() => _DetailDemandeScreenState();
}

class _DetailDemandeScreenState extends State<DetailDemandeScreen> {
  late DemandeModel demande;
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    demande = widget.demande;
  }

  /// Appeler le patient
  Future<void> _appelerPatient() async {
    final telephone = demande.info.telephone;
    final url = 'tel:$telephone';

    try {
      if (telephone.isEmpty || telephone.length < 8) {
        _showSnackBar('Numéro de téléphone invalide', isError: true);
        return;
      }

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

  /// Envoyer un SMS pour notifier le patient
  Future<void> _envoyerSMS() async {
    final confirmed = await _showConfirmDialog(
      'Envoyer SMS',
      'Voulez-vous envoyer un SMS au patient pour l\'informer que le médicament est disponible ?',
      onConfirm: () async {
        final demandeProvider = context.read<DemandeProvider>();
        final success = await demandeProvider.sendAlert(demande.uuid);

        if (success) {
          _showSnackBar('SMS envoyé avec succès');

          final updatedDemande = demandeProvider.demandes.firstWhere(
                (d) => d.uuid == demande.uuid,
            orElse: () => demande,
          );

          if (mounted) {
            setState(() {
              demande = updatedDemande;
              _hasChanges = true;
            });
          }
        } else {
          _showSnackBar(
            demandeProvider.errorMessage ?? 'Erreur lors de l\'envoi du SMS',
            isError: true,
          );
        }
      },
    );
  }

  /// Marquer comme récupéré
  Future<void> _marquerRecupere() async {
    final confirmed = await _showConfirmDialog(
      'Marquer comme récupéré',
      'Confirmer que le patient a récupéré le médicament ?',
      onConfirm: () async {
        final demandeProvider = context.read<DemandeProvider>();
        final success = await demandeProvider.markAsRecovered(demande.uuid);

        if (success) {
          _showSnackBar('Demande marquée comme récupérée');

          final updatedDemande = demandeProvider.demandes.firstWhere(
                (d) => d.id == demande.id,
            orElse: () => demande,
          );

          if (mounted) {
            setState(() {
              demande = updatedDemande;
              _hasChanges = true;
            });
          }
        } else {
          _showSnackBar(
            demandeProvider.errorMessage ?? 'Erreur lors de la mise à jour',
            isError: true,
          );
        }
      },
    );
  }

  /// Annuler la demande
  Future<void> _annulerDemande() async {
    final confirmed = await _showConfirmDialog(
      'Annuler la demande',
      'Êtes-vous sûr de vouloir annuler cette demande ? Cette action est irréversible.',
      isDestructive: true,
      onConfirm: () async {
        final demandeProvider = context.read<DemandeProvider>();
        final success = await demandeProvider.cancelDemande(demande.id);

        if (success) {
          _showSnackBar('Demande annulée', isError: true);
          if (mounted) {
            Navigator.pop(context, true);
          }
        } else {
          _showSnackBar(
            demandeProvider.errorMessage ?? 'Erreur lors de l\'annulation',
            isError: true,
          );
        }
      },
    );
  }

  /// Dialogue de confirmation avec callback
  Future<bool> _showConfirmDialog(
      String title,
      String message, {
        bool isDestructive = false,
        required Future<void> Function() onConfirm,
      }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
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

    if (confirmed && mounted) {
      setState(() {
        _isLoading = true;
      });

      try {
        await onConfirm();
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }

    return confirmed;
  }

  /// Afficher un SnackBar
  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.red : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Convertir le statut du modèle en string
  String _getStatutString(dynamic statut) {
    if (statut is String) return statut;
    final str = statut.toString().split('.').last;
    switch (str) {
      case 'enAttente':
        return 'en_attente';
      case 'notifie':
        return 'notifie';
      case 'recupere':
        return 'recupere';
      default:
        return 'en_attente';
    }
  }

  /// Obtenir le label du statut
  String _getStatutLabel(dynamic statut) {
    final statutStr = _getStatutString(statut);
    switch (statutStr) {
      case 'en_attente':
        return 'En attente';
      case 'notifie':
        return 'Notifié';
      case 'recupere':
        return 'Récupéré';
      default:
        return 'En attente';
    }
  }

  /// Obtenir la couleur du statut
  Color _getStatutColor(dynamic statut) {
    final statutStr = _getStatutString(statut);
    switch (statutStr) {
      case 'en_attente':
        return Colors.orange;
      case 'notifie':
        return Colors.blue;
      case 'recupere':
        return AppColors.primary;
      default:
        return Colors.grey;
    }
  }

  /// Obtenir le label du mode de paiement
  String _getModePaiementLabel(String mode) {
    switch (mode.toLowerCase()) {
      case 'non_paye':
        return 'Non Payé';
      case 'acompte':
        return 'Acompte';
      case 'totalite':
        return 'Payé en Totalité';
      default:
        return mode.isNotEmpty ? mode : 'Non spécifié';
    }
  }

  /// Obtenir l'icône du mode de paiement
  IconData _getModePaiementIcon(String mode) {
    switch (mode.toLowerCase()) {
      case 'non_paye':
        return Icons.schedule;
      case 'acompte':
        return Icons.payment;
      case 'totalite':
        return Icons.check_circle;
      default:
        return Icons.payment;
    }
  }

  /// Obtenir la couleur du mode de paiement
  Color _getModePaiementColor(String mode) {
    switch (mode.toLowerCase()) {
      case 'non_paye':
        return Colors.orange;
      case 'acompte':
        return Colors.blue;
      case 'totalite':
        return AppColors.primary;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _hasChanges);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.black87),
            onPressed: () => Navigator.pop(context, _hasChanges),
          ),
          title: const Text(
            'Détail de la Demande',
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
                  _buildPatientCard(),
                  const SizedBox(height: 16),
                  _buildMedicamentCard(),
                  const SizedBox(height: 16),
                  _buildInfoSupplementairesCard(),
                  const SizedBox(height: 16),
                  _buildHistoriqueCard(),
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
      ),
    );
  }

  Widget _buildPatientCard() {
    final statutLabel = _getStatutLabel(demande.statut);
    final badgeColor = _getStatutColor(demande.statut);

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
                child: const Icon(Icons.person, size: 32, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      demande.patient.nomComplet,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      demande.patient.telephone,
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statutLabel,
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: _appelerPatient,
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.phone, color: AppColors.primary, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMedicamentCard() {
    final dateFormat = DateFormat('dd/MM/yyyy à HH:mm');
    final modePaiement = demande.info.mode_paiement;

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
              Icon(Icons.medication, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Médicament Demandé',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  demande.medicament.nom,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Demandé le ${dateFormat.format(demande.dateCreation)}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                // Affichage du mode de paiement
                if (modePaiement.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _getModePaiementColor(modePaiement).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _getModePaiementColor(modePaiement).withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getModePaiementIcon(modePaiement),
                          size: 18,
                          color: _getModePaiementColor(modePaiement),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _getModePaiementLabel(modePaiement),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _getModePaiementColor(modePaiement),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                // Affichage du prix total si disponible
                if (demande.prixTotal != null && demande.prixTotal! > 0) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        'Prix total:',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${demande.prixTotal!.toStringAsFixed(0)} FCFA',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSupplementairesCard() {
    if (demande.info.demandeMedicaments.isEmpty) {
      return const SizedBox.shrink();
    }
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
            'Détails de la demande',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          ...demande.info.demandeMedicaments.map((dm) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.medication_outlined,
                          size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          dm.medicament,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (dm.quantite > 0) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Quantité: ${dm.quantite}',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                  if (dm.prix > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Prix: ${dm.prix.toStringAsFixed(0)} FCFA',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildHistoriqueCard() {
    final List<Map<String, dynamic>> historique = [];
    final statutStr = _getStatutString(demande.statut);

    historique.add({
      'label': 'Demande enregistrée',
      'date': demande.dateCreation,
      'icon': Icons.add_circle_outline,
    });

    if (statutStr == 'notifie' || statutStr == 'recupere') {
      historique.add({
        'label': 'SMS envoyé',
        'date': demande.updatedAt ?? demande.dateCreation,
        'icon': Icons.send,
      });
    }

    if (statutStr == 'recupere') {
      historique.add({
        'label': 'Médicament récupéré',
        'date': demande.updatedAt ?? demande.dateCreation,
        'icon': Icons.check_circle,
      });
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

  Widget _buildHistoriqueItem(
      String label, String date, IconData icon, bool isLast) {
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
              child: Icon(icon, size: 16, color: AppColors.primary),
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
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    final statutStr = _getStatutString(demande.statut);

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _appelerPatient,
            icon: const Icon(Icons.phone, size: 20),
            label: const Text(
              'Appeler le patient',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
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
        if (statutStr == 'en_attente')
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _envoyerSMS,
              icon: const Icon(Icons.send, size: 20),
              label: const Text(
                'Envoyer SMS (Médicament disponible)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
        if (statutStr == 'notifie')
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _marquerRecupere,
              icon: const Icon(Icons.check_circle, size: 20),
              label: const Text(
                'Marquer comme récupéré',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
        if (statutStr != 'recupere') ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _annulerDemande,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Annuler la demande',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ],
    );
  }
}