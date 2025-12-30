// lib/presentation/screens/demande/nouvelle_demande_screen.dart
import 'package:flutter/material.dart';
import 'package:pharma/data/models/medicine_model.dart';
import 'package:pharma/shared/constants/colors.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../core/utils/validators.dart';
import '../../../data/providers/demande_provider.dart';
import '../../../data/providers/medicine_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';

class NouvelleDemandeScreen extends StatefulWidget {
  const NouvelleDemandeScreen({Key? key}) : super(key: key);

  @override
  State<NouvelleDemandeScreen> createState() => _NouvelleDemandeScreenState();
}

class _NouvelleDemandeScreenState extends State<NouvelleDemandeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomPatientController = TextEditingController();
  final _telephoneController = TextEditingController();

  // Liste pour stocker les médicaments
  List<MedicamentItem> _medicaments = [MedicamentItem()];

  // Mode de paiement
  String _modePaiement = 'non_paye'; // Valeur par défaut

  @override
  void dispose() {
    _nomPatientController.dispose();
    _telephoneController.dispose();
    for (var medicament in _medicaments) {
      medicament.dispose();
    }
    super.dispose();
  }

  void _addMedicament() {
    setState(() {
      _medicaments.add(MedicamentItem());
    });
  }

  void _removeMedicament(int index) {
    if (_medicaments.length > 1) {
      setState(() {
        _medicaments[index].dispose();
        _medicaments.removeAt(index);
      });
    }
  }

  Future<void> _selectMedicament(int index) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => const SelectMedicineScreen(),
      ),
    );

    if (result != null) {
      setState(() {
        _medicaments[index].uuid = result['uuid']?.toString();
        _medicaments[index].nomController.text = result['nom']?.toString() ?? '';
        _medicaments[index].prixController.text = result['prix']?.toString() ?? '';
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    // Vérifier qu'au moins un médicament est rempli
    bool hasMedicament = _medicaments.any((m) => m.nomController.text.trim().isNotEmpty);

    if (!hasMedicament) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez ajouter au moins un médicament'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final demandeProvider = context.read<DemandeProvider>();

    // Préparer la liste des médicaments avec UUID
    final medicamentsList = _medicaments
        .where((m) => m.nomController.text.trim().isNotEmpty)
        .map((m) => {
      'medicament': m.uuid, // Envoyer l'UUID du médicament
      'quantite': m.quantiteController.text.trim(),
      'prix': m.prixController.text.trim(),
    })
        .toList();

    final success = await demandeProvider.createDemande(
      nom_patient: _nomPatientController.text.trim(),
      telephone_patient: _telephoneController.text.trim(),
      medicaments: medicamentsList,
      modePaiement: _modePaiement,
    );

    if (!mounted) return;

    if (success) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(demandeProvider.errorMessage ?? 'Erreur d\'enregistrement'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Nouvelle Demande'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Patient section
              _buildPatientSection(),

              const SizedBox(height: 24),

              // Medicaments section
              _buildMedicamentsSection(),

              const SizedBox(height: 24),

              // Mode de paiement section
              _buildModePaiementSection(),

              const SizedBox(height: 32),

              // Submit button
              Consumer<DemandeProvider>(
                builder: (context, demandeProvider, _) {
                  return CustomButton(
                    text: 'Enregistrer la demande',
                    onPressed: _handleSubmit,
                    isLoading: demandeProvider.isLoading,
                  );
                },
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPatientSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Text(
                'Informations Patient',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _nomPatientController,
            label: 'Nom complet',
            hintText: 'Jean Dupont',
            prefixIcon: Icons.person,
            validator: (value) => Validators.validateName(value, fieldName: 'Le nom'),
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _telephoneController,
            label: 'Téléphone',
            hintText: '06 12 34 56 78',
            prefixIcon: Icons.phone,
            keyboardType: TextInputType.phone,
            validator: Validators.validatePhone,
          ),
        ],
      ),
    );
  }

  Widget _buildMedicamentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.medication, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Médicaments',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            TextButton.icon(
              onPressed: _addMedicament,
              icon: const Icon(Icons.add_circle),
              label: const Text('Ajouter'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...List.generate(_medicaments.length, (index) {
          return _buildMedicamentCard(index);
        }),
      ],
    );
  }

  Widget _buildModePaiementSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.payment, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Text(
                'Mode de Paiement',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildModePaiementOption(
            value: 'non_paye',
            title: 'Non Payé',
            subtitle: 'Le patient paiera plus tard',
            icon: Icons.schedule,
          ),
          const SizedBox(height: 12),
          _buildModePaiementOption(
            value: 'acompte',
            title: 'Acompte',
            subtitle: 'Le patient a payé un acompte',
            icon: Icons.payment,
          ),
          const SizedBox(height: 12),
          _buildModePaiementOption(
            value: 'totalite',
            title: 'Payé en Totalité',
            subtitle: 'Le patient a tout payé',
            icon: Icons.check_circle,
          ),
        ],
      ),
    );
  }

  Widget _buildModePaiementOption({
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _modePaiement == value;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        color: isSelected ? AppTheme.primaryColor.withOpacity(0.05) : Colors.transparent,
      ),
      child: RadioListTile<String>(
        value: value,
        groupValue: _modePaiement,
        onChanged: (String? newValue) {
          setState(() {
            _modePaiement = newValue!;
          });
        },
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isSelected ? AppTheme.primaryColor : Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade600,
          ),
        ),
        secondary: Icon(
          icon,
          color: isSelected ? AppTheme.primaryColor : Colors.grey.shade600,
        ),
        activeColor: AppTheme.primaryColor,
        controlAffinity: ListTileControlAffinity.trailing,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
      ),
    );
  }

  Widget _buildMedicamentCard(int index) {
    final medicament = _medicaments[index];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Médicament ${index + 1}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
              if (_medicaments.length > 1)
                IconButton(
                  onPressed: () => _removeMedicament(index),
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Champ de sélection du médicament
          InkWell(
            onTap: () => _selectMedicament(index),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(
                  color: medicament.nomController.text.isEmpty
                      ? Colors.grey.shade300
                      : AppTheme.primaryColor,
                  width: medicament.nomController.text.isEmpty ? 1 : 2,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.medication,
                    color: medicament.nomController.text.isEmpty
                        ? Colors.grey.shade400
                        : AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      medicament.nomController.text.isEmpty
                          ? 'Sélectionner un médicament'
                          : medicament.nomController.text,
                      style: TextStyle(
                        fontSize: 15,
                        color: medicament.nomController.text.isEmpty
                            ? Colors.grey.shade600
                            : Colors.black87,
                        fontWeight: medicament.nomController.text.isEmpty
                            ? FontWeight.normal
                            : FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
            ),
          ),
          if (index == 0 && medicament.nomController.text.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 12),
              child: Text(
                'Le médicament est requis',
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontSize: 12,
                ),
              ),
            ),

          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: medicament.quantiteController,
                  label: 'Quantité',
                  hintText: '2',
                  keyboardType: TextInputType.number,
                  validator: medicament.nomController.text.isNotEmpty
                      ? (value) => Validators.validateRequired(value, fieldName: 'La quantité')
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomTextField(
                  controller: medicament.prixController,
                  label: 'Prix (CFA)',
                  hintText: '25.00',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: medicament.nomController.text.isNotEmpty
                      ? (value) => Validators.validateRequired(value, fieldName: 'Le prix')
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Classe pour gérer les contrôleurs de chaque médicament
class MedicamentItem {
  final TextEditingController nomController = TextEditingController();
  final TextEditingController quantiteController = TextEditingController();
  final TextEditingController prixController = TextEditingController();
  String? uuid; // Stocker l'UUID du médicament sélectionné

  void dispose() {
    nomController.dispose();
    quantiteController.dispose();
    prixController.dispose();
  }
}

// ============================================================
// PAGE DE SÉLECTION DES MÉDICAMENTS
// ============================================================

class SelectMedicineScreen extends StatefulWidget {
  const SelectMedicineScreen({Key? key}) : super(key: key);

  @override
  State<SelectMedicineScreen> createState() => _SelectMedicineScreenState();
}

class _SelectMedicineScreenState extends State<SelectMedicineScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final medicineProvider = context.read<MedicineProvider>();

      // ⭐ Charger depuis le cache d'abord
      medicineProvider.loadFromCache().then((_) {
        debugPrint('📊 Après cache: ${medicineProvider.count} médicaments');

        // ⭐ Puis charger depuis l'API si pas complètement chargé
        if (!medicineProvider.isFullyLoaded) {
          debugPrint('🌐 Chargement depuis l\'API...');
          medicineProvider.loadAllMedicines();
        } else {
          debugPrint('✅ ${medicineProvider.count} médicaments déjà en cache');
        }
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Sélectionner un médicament'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              await context.read<MedicineProvider>().refreshMedicines();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche
          _buildSearchBar(),

          // ⭐ Indicateur de progression
          Consumer<MedicineProvider>(
            builder: (context, provider, _) {
              if (provider.isLoading && !provider.isFullyLoaded) {
                return _buildLoadingProgress(provider);
              }
              return const SizedBox.shrink();
            },
          ),

          // Liste des médicaments
          Expanded(
            child: _buildMedicineList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Rechercher un médicament...',
          prefixIcon: Icon(Icons.search, color: AppTheme.primaryColor),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              setState(() {
                _searchController.clear();
                _searchQuery = '';
              });
            },
          )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  // ⭐ Widget d'indicateur de progression
  Widget _buildLoadingProgress(MedicineProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.primaryColor.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chargement des médicaments...',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${provider.loadedCount} / ${provider.totalCount > 0 ? provider.totalCount : '...'} médicaments',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              if (provider.totalCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${(provider.loadingProgress * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: provider.loadingProgress,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicineList() {
    return Consumer<MedicineProvider>(
      builder: (context, medicineProvider, _) {
        // ⭐ Afficher un message si chargement initial
        if (medicineProvider.isLoading && medicineProvider.medicines.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: AppTheme.primaryColor),
                const SizedBox(height: 16),
                Text(
                  'Chargement initial...',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Veuillez patienter',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          );
        }

        // ⭐ Afficher erreur uniquement si aucun médicament
        if (medicineProvider.errorMessage != null && medicineProvider.medicines.isEmpty) {
          return _buildErrorWidget(medicineProvider);
        }

        // ⭐ Recherche locale
        final filteredMedicines = medicineProvider.searchMedicines(_searchQuery);

        if (filteredMedicines.isEmpty) {
          return _buildEmptyWidget();
        }

        // ⭐ Afficher la liste (même pendant le chargement)
        return Column(
          children: [
            // ⭐ Info en haut de la liste
            if (medicineProvider.isFullyLoaded)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.green.shade50,
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade700, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${medicineProvider.count} médicaments disponibles',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // ⭐ Liste
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredMedicines.length,
                itemBuilder: (context, index) {
                  final medicine = filteredMedicines[index];
                  return _buildMedicineItem(medicine);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildErrorWidget(MedicineProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(
            'Erreur de chargement',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              provider.errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              await provider.refreshMedicines();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Aucun médicament trouvé',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty ? 'La liste est vide' : 'Essayez un autre terme de recherche',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicineItem(MedicineModel medicine) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.pop(context, {
            'uuid': medicine.uuid,
            'nom': medicine.nom,
            'prix': medicine.prix,
          });
        },
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.medication,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medicine.nom,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    if (medicine.prix != null && medicine.prix!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '${medicine.prix} CFA',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}