import 'package:flutter/material.dart';
import 'package:pharma/presentation/widgets/address_search_field.dart';
import 'package:provider/provider.dart';
import '../../../config/routes.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../shared/constants/colors.dart';

class InscriptionScreen extends StatefulWidget {
  const InscriptionScreen({Key? key}) : super(key: key);

  @override
  State<InscriptionScreen> createState() => _InscriptionScreenState();
}

class _InscriptionScreenState extends State<InscriptionScreen> {
  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();
  final _formKey3 = GlobalKey<FormState>();
  final _pageController = PageController();
  int _currentStep = 0;

  // Controllers
  final _nomCompletController = TextEditingController();
  final _emailController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _nomPharmacieController = TextEditingController();
  final _villeController = TextEditingController();
  final _adresseController = TextEditingController();
  final _numeroAutorisationController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _acceptTerms = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Track validation status of each step
  bool _step1Validated = false;
  bool _step2Validated = false;
  bool _step3Validated = false;

  @override
  void dispose() {
    _pageController.dispose();
    _nomCompletController.dispose();
    _emailController.dispose();
    _telephoneController.dispose();
    _nomPharmacieController.dispose();
    _villeController.dispose();
    _adresseController.dispose();
    _numeroAutorisationController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Mot de passe requis';
    if (value.length < 6) return 'Minimum 6 caractères';
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) return 'Confirmation requise';
    if (value != _passwordController.text) return 'Mots de passe différents';
    return null;
  }

  bool _validateCurrentStep() {
    if (_currentStep == 0) {
      return _formKey1.currentState?.validate() ?? false;
    } else if (_currentStep == 1) {
      return _formKey2.currentState?.validate() ?? false;
    } else if (_currentStep == 2) {
      return _formKey3.currentState?.validate() ?? false;
    }
    return false;
  }

  void _nextStep() {
    if (_validateCurrentStep()) {
      if (_currentStep < 2) {
        setState(() => _currentStep++);
        _pageController.animateToPage(
          _currentStep,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        _handleRegister();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Veuillez remplir tous les champs requis'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _handleRegister() async {
    // Valider tous les formulaires
    if (!(_formKey3.currentState?.validate() ?? false)) {
      return;
    }

    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Veuillez accepter les conditions'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();

    final successRegister = await authProvider.register(
      type: "ADMIN",
      nom_pharmacien: _nomCompletController.text.trim(),
      email: _emailController.text.trim(),
      telephone: _telephoneController.text.trim(),
      password: _passwordController.text,
      ville: _villeController.text.trim(),
      nom: _nomPharmacieController.text.trim(),
      adresse: _adresseController.text.trim(),
      numero: _numeroAutorisationController.text.trim().isEmpty
          ? null
          : _numeroAutorisationController.text.trim(),
    );

    if (!mounted) return;

    if (successRegister) {
      final successLogin = await authProvider.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (successLogin) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Inscription réussie !'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.of(context).pushReplacementNamed(AppRoutes.home);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Erreur d\'inscription'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildPersonalInfoStep(),
                  _buildPharmacyInfoStep(),
                  _buildSecurityStep(),
                ],
              ),
            ),
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              if (_currentStep > 0)
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _previousStep,
                ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Étape ${_currentStep + 1} sur 3',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (index) {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: index <= _currentStep
                                ? AppColors.primary
                                : Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              if (_currentStep > 0) const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _getStepTitle(),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            _getStepSubtitle(),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return 'Informations personnelles';
      case 1:
        return 'Votre pharmacie';
      case 2:
        return 'Sécurité';
      default:
        return '';
    }
  }

  String _getStepSubtitle() {
    switch (_currentStep) {
      case 0:
        return 'Commencez par vos coordonnées';
      case 1:
        return 'Parlez-nous de votre pharmacie';
      case 2:
        return 'Créez votre mot de passe';
      default:
        return '';
    }
  }

  Widget _buildPersonalInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey1,
        child: Column(
          children: [
            _buildAnimatedField(
              controller: _nomCompletController,
              label: 'Nom complet',
              hint: 'Dr. Ahmed Benali',
              icon: Icons.person_outline,
              validator: _validateName,
              delay: 100,
            ),
            const SizedBox(height: 20),
            _buildAnimatedField(
              controller: _emailController,
              label: 'Adresse email',
              hint: 'ahmed.benali@email.com',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: _validateEmail,
              delay: 200,
            ),
            const SizedBox(height: 20),
            _buildAnimatedField(
              controller: _telephoneController,
              label: 'Téléphone',
              hint: '06 12 34 56 78',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: _validatePhone,
              delay: 300,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPharmacyInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey2,
        child: Column(
          children: [
            _buildAnimatedField(
              controller: _nomPharmacieController,
              label: 'Nom de la pharmacie',
              hint: 'Pharmacie Centrale',
              icon: Icons.local_pharmacy_outlined,
              validator: _validateName,
              delay: 100,
            ),
            const SizedBox(height: 20),
            AddressSearchField(
              label: "Ville ",
              hintText: "Abidjan, Côte d'ivoire",
              controller: _villeController,
              onPlaceSelected: (address, lat, lon) {
                setState(() {
                //  pickupLatitude = lat;
                 // pickupLongitude = lon;
                });
                print('📍 Adresse enlèvement: $address');
                print('🌍 Coordonnées: Lat=$lat, Lon=$lon');
              },
            ),

            const SizedBox(height: 20),
            _buildAnimatedField(
              controller: _adresseController,
              label: 'Adresse complète',
              hint: '45 Avenue Thomas Ouattara, Port Bouet',
              icon: Icons.location_on_outlined,
              maxLines: 2,
             // validator: _validateName,
              delay: 300,
            ),
            const SizedBox(height: 20),
            _buildAnimatedField(
              controller: _numeroAutorisationController,
              label: 'Numéro d\'autorisation (optionnel)',
              hint: 'PH-123456',
              icon: Icons.badge_outlined,
              delay: 400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey3,
        child: Column(
          children: [
            _buildAnimatedField(
              controller: _passwordController,
              label: 'Mot de passe',
              hint: '••••••••',
              icon: Icons.lock_outline,
              obscureText: _obscurePassword,
              validator: _validatePassword,
              delay: 100,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.grey[600],
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            const SizedBox(height: 20),
            _buildAnimatedField(
              controller: _confirmPasswordController,
              label: 'Confirmer le mot de passe',
              hint: '••••••••',
              icon: Icons.lock_outline,
              obscureText: _obscureConfirmPassword,
              validator: _validateConfirmPassword,
              delay: 200,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.grey[600],
                ),
                onPressed: () =>
                    setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
              ),
            ),
            const SizedBox(height: 24),
            _buildTermsCheckbox(),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    int maxLines = 1,
    String? Function(String?)? validator,
    Widget? suffixIcon,
    int delay = 0,
  }) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 500 + delay),
      curve: Curves.easeOut,
      builder: (context, double value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
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
        padding: const EdgeInsets.all(20),
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
                  child: Icon(icon, size: 20, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
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
            const SizedBox(height: 12),
            TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              obscureText: obscureText,
              maxLines: maxLines,
              validator: validator,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: Colors.grey[400]),
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
                suffixIcon: suffixIcon,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsCheckbox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: _acceptTerms,
              onChanged: (value) => setState(() => _acceptTerms = value ?? false),
              activeColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Wrap(
              children: [
                Text('J\'accepte les ', style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                GestureDetector(
                  onTap: () {},
                  child: Text(
                    'conditions d\'utilisation',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              return SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: authProvider.isLoading ? null : _nextStep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: authProvider.isLoading
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : Text(
                    _currentStep == 2 ? 'Créer mon compte' : 'Continuer',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Déjà inscrit ? ', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Se connecter',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}