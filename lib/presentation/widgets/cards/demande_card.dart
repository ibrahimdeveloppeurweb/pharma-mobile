import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/demande_model.dart';
import '../../../shared/constants/colors.dart';
import '../../../shared/enums/statut_demande.dart';

class DemandeCard extends StatelessWidget {
  final DemandeModel demande;
  final VoidCallback? onTap;

  const DemandeCard({
    Key? key,
    required this.demande,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildStatusIcon(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        demande.patient.nomComplet,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        demande.patient.telephone,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
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
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 12,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Demandé le ${_formatDate(demande.dateCreation)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    IconData iconData;
    Color iconColor;

    switch (demande.statut) {
      case StatutDemande.en_attente:
        iconData = Icons.schedule;
        iconColor = AppColors.warning;
        break;
      case StatutDemande.disponible:
      case StatutDemande.notifie:
        iconData = Icons.notifications_active;
        iconColor = AppColors.info;
        break;
      case StatutDemande.recupere:
        iconData = Icons.check_circle;
        iconColor = AppColors.success;
        break;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 20,
      ),
    );
  }

  Widget _buildStatusBadge() {
    String label;
    Color backgroundColor;
    Color textColor;
    Color borderColor;

    switch (demande.statut) {
      case StatutDemande.en_attente:
        label = 'En attente';
        backgroundColor = AppColors.warning.withOpacity(0.1);
        textColor = AppColors.warning;
        borderColor = AppColors.warning;
        break;
      case StatutDemande.disponible:
      case StatutDemande.notifie:
        label = 'Alerté';
        backgroundColor = AppColors.info.withOpacity(0.1);
        textColor = AppColors.info;
        borderColor = AppColors.info;
        break;
      case StatutDemande.recupere:
        label = 'Récupéré';
        backgroundColor = AppColors.success.withOpacity(0.1);
        textColor = AppColors.success;
        borderColor = AppColors.success;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }
}