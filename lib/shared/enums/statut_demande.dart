enum StatutDemande {
  en_attente,
  disponible,
  notifie,
  recupere,
}

extension StatutDemandeExtension on StatutDemande {
  String get label {
    switch (this) {
      case StatutDemande.en_attente:
        return 'En attente';
      case StatutDemande.disponible:
        return 'Disponible';
      case StatutDemande.notifie:
        return 'Alerté';
      case StatutDemande.recupere:
        return 'Récupéré';
    }
  }

  String get value {
    switch (this) {
      case StatutDemande.en_attente:
        return 'en_attente';
      case StatutDemande.disponible:
        return 'disponible';
      case StatutDemande.notifie:
        return 'notifie';
      case StatutDemande.recupere:
        return 'recupere';
    }
  }

  static StatutDemande fromString(String value) {
    switch (value) {
      case 'en_attente':
        return StatutDemande.en_attente;
      case 'disponible':
        return StatutDemande.disponible;
      case 'notifie':
        return StatutDemande.notifie;
      case 'recupere':
        return StatutDemande.recupere;
      default:
        return StatutDemande.en_attente;
    }
  }
}