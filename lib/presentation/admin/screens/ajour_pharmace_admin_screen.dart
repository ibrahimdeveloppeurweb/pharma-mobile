import 'package:flutter/material.dart';
import 'package:pharma/data/models/pharmacie_model.dart';
import 'package:pharma/data/providers/auth_provider.dart';
import 'package:pharma/data/providers/pharmacie_provider.dart';
import 'package:pharma/main.dart';
import 'package:provider/provider.dart';
import '../../../shared/constants/colors.dart';

class CreatePharmacieAdminScreen extends StatefulWidget {
  final PharmacieModel? pharmacie;

  const CreatePharmacieAdminScreen({
    Key? key,
    this.pharmacie,
  }) : super(key: key);

  @override
  State<CreatePharmacieAdminScreen> createState() => _CreatePharmacieAdminScreenState();
}

class _CreatePharmacieAdminScreenState extends State<CreatePharmacieAdminScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isUpdate = false;

  // Controllers - Informations responsable
  final _nomCompletController = TextEditingController();
  final _emailController = TextEditingController();
  final _telephoneController = TextEditingController();

  // Controllers - Informations pharmacie
  final _nomPharmacieController = TextEditingController();
  final _villeController = TextEditingController();
  final _adresseController = TextEditingController();
  final _numeroAutorisationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _isUpdate = widget.pharmacie != null;
    if (_isUpdate) {
      _setFormValues(widget.pharmacie!);
    }
  }

  void _setFormValues(PharmacieModel pharmacie) {
    _nomCompletController.text = pharmacie.nom ?? "";
    _emailController.text = pharmacie.email ?? "";
    _telephoneController.text = pharmacie.telephone ?? "";
    _nomPharmacieController.text = pharmacie.nom ?? "";
    _villeController.text = pharmacie.ville ?? "";
    _adresseController.text = pharmacie.adresse ?? "";
    _numeroAutorisationController.text = pharmacie.numeroAutorisation ?? "";
  }

  @override
  void dispose() {
    _nomCompletController.dispose();
    _emailController.dispose();
    _telephoneController.dispose();
    _nomPharmacieController.dispose();
    _villeController.dispose();
    _adresseController.dispose();
    _numeroAutorisationController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) return 'Ce champ est requis';
    if (value.length < 3) return 'Minimum 3 caractères';
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Email requis';
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Email invalide';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) return 'Téléphone requis';
    if (value.replaceAll(RegExp(r'[^\d]'), '').length < 10) {
      return 'Numéro invalide';
    }
    return null;
  }

  Future<void> _handleCreatePharmacie() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    final pharmacieProvider = context.read<PharmacieProvider>();

    final data = {
      'type': "ADMIN",
      'nom_pharmacien': _nomCompletController.text.trim(),
      'email': _emailController.text.trim(),
      'telephone': _telephoneController.text.trim(),
      'password': _telephoneController.text.trim(),
      'ville': _villeController.text.trim(),
      'nom': _nomPharmacieController.text.trim(),
      'adresse': _adresseController.text.trim(),
      'numero': _numeroAutorisationController.text.trim().isEmpty
          ? null
          : _numeroAutorisationController.text.trim(),
    };

    final success = await pharmacieProvider.createPharmacie(data);

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (success) {
      pharmacieProvider.notifyPharmacieCreated();

      _showSuccessSnackBar('Pharmacie créée avec succès');
      Navigator.of(context).pop();
    } else {
      _showErrorSnackBar(authProvider.errorMessage ?? 'Erreur de création');
    }
  }

  Future<void> _handleUpdatePharmacie() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    final pharmacieProvider = context.read<PharmacieProvider>();

    final data = {
      'uuid': widget.pharmacie!.uuid,
      'type': "ADMIN",
      'nom_pharmacien': _nomCompletController.text.trim(),
      'email': _emailController.text.trim(),
      'telephone': _telephoneController.text.trim(),
      'ville': _villeController.text.trim(),
      'nom': _nomPharmacieController.text.trim(),
      'adresse': _adresseController.text.trim(),
      'numero': _numeroAutorisationController.text.trim().isEmpty
          ? null
          : _numeroAutorisationController.text.trim(),
    };

    final success = await pharmacieProvider.updatePharmacie(data["uuid"],data);

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (success) {
      pharmacieProvider.notifyPharmacieUpdated();

      _showSuccessSnackBar('Pharmacie modifiée avec succès');
      Navigator.of(context).pop();
    } else {
      _showErrorSnackBar(authProvider.errorMessage ?? 'Erreur de modification');
    }
  }

  void _showSuccessSnackBar(String message) {
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _saveForm() {
    if (!_formKey.currentState!.validate()) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(_isUpdate ? "Confirmer la modification" : "Confirmer la création"),
          content: Text(_isUpdate
              ? "Voulez-vous vraiment modifier cette pharmacie ?"
              : "Voulez-vous vraiment créer cette pharmacie ?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (_isUpdate) {
                  _handleUpdatePharmacie();
                } else {
                  _handleCreatePharmacie();
                }
              },
              child: Text(_isUpdate ? 'Modifier' : 'Créer'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _isUpdate ? 'Modifier la Pharmacie' : 'Nouvelle Pharmacie',
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Section Responsable
              _buildResponsableSection(),

              const SizedBox(height: 24),

              // Section Pharmacie
              _buildPharmacieSection(),

              const SizedBox(height: 32),

              // Bouton de création/modification
              _buildSubmitButton(),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResponsableSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.person,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Responsable de la pharmacie',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _nomCompletController,
            label: 'Nom complet',
            hint: 'Dr. KOUASSI Marie',
            icon: Icons.person_outline,
            validator: _validateName,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _emailController,
            label: 'Adresse email',
            hint: 'kouassi.marie@email.com',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: _validateEmail,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _telephoneController,
            label: 'Téléphone',
            hint: '+225 07 12 34 56 78',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            validator: _validatePhone,
          ),
        ],
      ),
    );
  }

  Widget _buildPharmacieSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.local_pharmacy,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Informations de la pharmacie',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _nomPharmacieController,
            label: 'Nom de la pharmacie',
            hint: 'Pharmacie Centrale',
            icon: Icons.local_pharmacy_outlined,
            validator: _validateName,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _villeController,
            label: 'Ville',
            hint: 'Abidjan',
            icon: Icons.location_city_outlined,
            validator: _validateName,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _adresseController,
            label: 'Adresse complète',
            hint: 'Avenue Chardy, Plateau',
            icon: Icons.location_on_outlined,
            maxLines: 2,
            validator: _validateName,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _numeroAutorisationController,
            label: 'Numéro d\'autorisation (optionnel)',
            hint: 'PH-123456',
            icon: Icons.badge_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey[300],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_isUpdate ? Icons.edit_outlined : Icons.check_circle_outline, size: 24),
            const SizedBox(width: 12),
            Text(
              _isUpdate ? 'Modifier la pharmacie' : 'Créer la pharmacie',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}