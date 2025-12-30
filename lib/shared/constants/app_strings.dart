class AppStrings {
  // App
  static const String appName = 'Pharma Alerte';
  static const String appVersion = 'Version 1.0.0';
  static const String appTagline = 'Gestion des ruptures de stock';

  // Authentification
  static const String connexion = 'Connexion';
  static const String inscription = 'Inscription';
  static const String deconnexion = 'Se déconnecter';
  static const String email = 'Email';
  static const String motDePasse = 'Mot de passe';
  static const String confirmerMotDePasse = 'Confirmer le mot de passe';
  static const String motDePasseOublie = 'Mot de passe oublié ?';
  static const String seConnecter = 'Se connecter';
  static const String seDeconnecter = 'Se déconnecter';
  static const String creerCompte = 'Créer mon compte';
  static const String pasDeCompte = 'Pas encore de compte ?';
  static const String dejaInscrit = 'Déjà inscrit ?';
  static const String seSouvenirDeMoi = 'Se souvenir de moi';

  // Navigation
  static const String accueil = 'Accueil';
  static const String demandes = 'Demandes';
  static const String nouvelleDemande = 'Nouvelle Demande';
  static const String statistiques = 'Statistiques';
  static const String profil = 'Profil';

  // Demandes
  static const String listeDemandes = 'Toutes les Demandes';
  static const String detailDemande = 'Détail de la Demande';
  static const String creerDemande = 'Créer une demande';
  static const String enregistrerDemande = 'Enregistrer la demande';
  static const String annulerDemande = 'Annuler la demande';
  static const String marquerRecupere = 'Marquer comme récupéré';
  static const String envoyerSMS = 'Envoyer SMS (Médicament disponible)';

  // Statuts
  static const String enAttente = 'En attente';
  static const String disponible = 'Disponible';
  static const String alerte = 'Alerté';
  static const String notifie = 'Patient notifié';
  static const String recupere = 'Récupéré';
  static const String termine = 'Terminé';
  static const String annule = 'Annulé';

  // Patient
  static const String informationsPatient = 'Informations Patient';
  static const String nom = 'Nom';
  static const String prenom = 'Prénom';
  static const String nomComplet = 'Nom complet';
  static const String telephone = 'Téléphone';

  // Médicament
  static const String medicament = 'Médicament';
  static const String medicamentDemande = 'Médicament Demandé';
  static const String nomMedicament = 'Nom du médicament';
  static const String dosage = 'Dosage';
  static const String forme = 'Forme';
  static const String fabricant = 'Fabricant';

  // Pharmacie
  static const String pharmacie = 'Pharmacie';
  static const String nomPharmacie = 'Nom de la pharmacie';
  static const String adresse = 'Adresse';
  static const String informationsPharmacie = 'Informations Pharmacie';

  // Photo
  static const String prendrPhoto = 'Prendre une photo';
  static const String photographierMedicament = 'Photographier le médicament';
  static const String importerGalerie = 'Importer depuis la galerie';
  static const String extractionAutomatique = 'AWS Textract extraira automatiquement les informations';

  // Stats
  static const String tauxRecuperation = 'Taux de récupération';
  static const String delaiMoyen = 'Délai moyen';
  static const String totalDemandes = 'Total demandes';
  static const String demandesTraitees = 'Demandes traitées';
  static const String tauxSucces = 'Taux succès';
  static const String demandesParMois = 'Demandes par mois';
  static const String medicamentsPlusDemandes = 'Médicaments les plus demandés';
  static const String repartitionDemandes = 'Répartition des demandes';
  static const String mesPerformances = 'Mes Performances';

  // Profil
  static const String monProfil = 'Mon Profil';
  static const String modifierProfil = 'Modifier le profil';
  static const String pharmacienTitulaire = 'Pharmacien Titulaire';
  static const String parametres = 'Paramètres';
  static const String notifications = 'Notifications';
  static const String configurationSMS = 'Configuration SMS';
  static const String awsTextract = 'AWS Textract';
  static const String aideSupport = 'Aide & Support';

  // Messages
  static const String demandeEnregistree = 'Demande enregistrée avec succès !';
  static const String smsEnvoye = 'SMS envoyé avec succès';
  static const String demandeAnnulee = 'Demande annulée';
  static const String demandeMarqueeRecuperee = 'Demande marquée comme récupérée';
  static const String erreurChargement = 'Erreur lors du chargement';
  static const String erreurEnvoiSMS = 'Erreur lors de l\'envoi du SMS';
  static const String erreurMiseAJour = 'Erreur lors de la mise à jour';
  static const String erreurAnnulation = 'Erreur lors de l\'annulation';

  // Confirmations
  static const String confirmer = 'Confirmer';
  static const String annuler = 'Annuler';
  static const String confirmerDeconnexion = 'Êtes-vous sûr de vouloir vous déconnecter ?';
  static const String confirmerAnnulation = 'Êtes-vous sûr de vouloir annuler cette demande ? Cette action est irréversible.';
  static const String confirmerEnvoiSMS = 'Voulez-vous envoyer un SMS au patient pour l\'informer que le médicament est disponible ?';
  static const String confirmerRecuperation = 'Confirmer que le patient a récupéré le médicament ?';

  // Filtres
  static const String tous = 'Tous';
  static const String filtrer = 'Filtrer';
  static const String rechercher = 'Rechercher';

  // Historique
  static const String historique = 'Historique';
  static const String demandeEnregistreeHistorique = 'Demande enregistrée';
  static const String smsEnvoyeHistorique = 'SMS envoyé';
  static const String medicamentRecupereHistorique = 'Médicament récupéré';

  // Dates
  static const String demandeLe = 'Demandé le';
  static const String dateCreation = 'Date de création';
  static const String dateNotification = 'Date de notification';

  // Autres
  static const String ou = 'OU';
  static const String activees = 'Activées';
  static const String configure = 'Configuré';
  static const String notes = 'Notes';
  static const String details = 'Détails';
  static const String tableauBord = 'Tableau de Bord';
  static const String demandesRecentes = 'Demandes Récentes';
}