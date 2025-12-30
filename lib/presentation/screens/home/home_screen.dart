import 'package:flutter/material.dart';
import 'package:pharma/presentation/screens/demandes/liste_demandes_screen.dart';
import 'package:pharma/presentation/screens/demandes/detail_demande_screen.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/demande_provider.dart';
import '../../../data/models/demande_model.dart';
import '../../../shared/enums/statut_demande.dart';
import '../../../shared/constants/colors.dart';

class HomeScreen extends StatefulWidget {
  final Function(Map<String, dynamic> filters)? onNavigateToDemandesWithFilter;

  const HomeScreen({
    Key? key,
    this.onNavigateToDemandesWithFilter,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedPeriod = 'all';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isCustomDateRange = false;

  final Map<String, String> _periods = {
    'today': "Aujourd'hui",
    'week': 'Cette semaine',
    'month': 'Ce mois',
    'year': 'Cette année',
    'all': 'Tout',
    'custom': 'Période personnalisée',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final demandeProvider = context.read<DemandeProvider>();
    try {
      await demandeProvider.loadStatistiques(_getPeriodParams());
    } catch (e) {
      // Gérer silencieusement les erreurs de chargement initial
      print('Erreur lors du chargement des données: $e');
    }
  }

  Map<String, dynamic>? _getPeriodParams() {
    if (_selectedPeriod == 'all') {
      return null;
    }

    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate = now;

    switch (_selectedPeriod) {
      case 'today':
        startDate = DateTime(now.year, now.month, now.day);
        endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case 'week':
        startDate = now.subtract(Duration(days: now.weekday - 1));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        break;
      case 'month':
        startDate = DateTime(now.year, now.month, 1);
        break;
      case 'year':
        startDate = DateTime(now.year, 1, 1);
        break;
      case 'custom':
        if (_startDate == null || _endDate == null) return null;
        startDate = _startDate!;
        endDate = _endDate!;
        break;
      default:
        return null;
    }

    return {
      'period': _selectedPeriod,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
    };
  }

  List<DemandeModel> _getFilteredDemandes(List<DemandeModel> allDemandes) {
    if (_selectedPeriod == 'all') {
      return allDemandes;
    }

    final now = DateTime.now();
    DateTime filterStartDate;
    DateTime filterEndDate = now;

    switch (_selectedPeriod) {
      case 'today':
        filterStartDate = DateTime(now.year, now.month, now.day);
        break;
      case 'week':
        filterStartDate = now.subtract(Duration(days: now.weekday - 1));
        filterStartDate = DateTime(filterStartDate.year, filterStartDate.month, filterStartDate.day);
        break;
      case 'month':
        filterStartDate = DateTime(now.year, now.month, 1);
        break;
      case 'year':
        filterStartDate = DateTime(now.year, 1, 1);
        break;
      case 'custom':
        if (_startDate == null || _endDate == null) return allDemandes;
        filterStartDate = _startDate!;
        filterEndDate = _endDate!;
        break;
      default:
        return allDemandes;
    }

    return allDemandes.where((demande) {
      DateTime demandeDate;
      if (demande.dateCreation is String) {
        demandeDate = DateTime.parse(demande.dateCreation as String);
      } else if (demande.dateCreation is DateTime) {
        demandeDate = demande.dateCreation as DateTime;
      } else {
        return false;
      }

      return demandeDate.isAfter(filterStartDate.subtract(Duration(days: 1))) &&
          demandeDate.isBefore(filterEndDate.add(Duration(days: 1)));
    }).toList();
  }

  Future<void> _filterDataByPeriod() async {
    final demandeProvider = context.read<DemandeProvider>();
    try {
      await demandeProvider.loadStatistiques(_getPeriodParams());
    } catch (e) {
      print('Erreur lors du filtrage: $e');
    }
  }

  String get _displayPeriodLabel {
    if (_selectedPeriod == 'custom' && _startDate != null && _endDate != null) {
      final dateFormat = DateFormat('dd/MM/yyyy');
      return '${dateFormat.format(_startDate!)} - ${dateFormat.format(_endDate!)}';
    }
    return _periods[_selectedPeriod] ?? '';
  }

  // 🎯 NAVIGATION VERS LES DÉTAILS - AVEC ISOLATION DES ERREURS
  void _navigateToDemandeDetail(DemandeModel demande) async {
    // 🔥 IMPORTANT : Réinitialiser les erreurs avant la navigation
    final demandeProvider = context.read<DemandeProvider>();
    demandeProvider.clearError(); // Vous devez ajouter cette méthode dans le provider

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailDemandeScreen(
          demande: demande,
        ),
      ),
    );

    // ✅ Recharger uniquement si des changements ont été faits
    if (result == true && mounted) {
      await _loadData();
    }

    // Nettoyer les erreurs après le retour
    if (mounted) {
      demandeProvider.clearError();
    }
  }

  void _navigateToDetail(String statut) {
    if (widget.onNavigateToDemandesWithFilter != null) {
      final filters = <String, dynamic>{
        'statut': statut,
        'period': _selectedPeriod,
        'start_date': _startDate?.toIso8601String(),
        'end_date': _endDate?.toIso8601String(),
      };
      widget.onNavigateToDemandesWithFilter!(filters);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final demandeProvider = context.watch<DemandeProvider>();
    final user = authProvider.currentUser;

    final currentDemandes = _getFilteredDemandes(demandeProvider.demandes);
    final currentStats = demandeProvider.statistiques;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Tableau de Bord',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              user?.nom ?? 'Pharmacie Centrale',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.notifications_outlined, color: Colors.black87),
        //     onPressed: () {},
        //   ),
        // ],
      ),
      body: demandeProvider.isLoading && demandeProvider.demandes.isEmpty
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : demandeProvider.errorMessage != null && demandeProvider.demandes.isEmpty
          ? _buildErrorState(demandeProvider.errorMessage!)
          : Stack(
        children: [
          RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _loadData,
            child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPeriodFilter(),
                  const SizedBox(height: 20),
                  _buildStatsGrid(currentStats),
                  const SizedBox(height: 32),
                  _buildRecentRequestsSection(currentDemandes),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
          if (demandeProvider.isLoading && demandeProvider.demandes.isNotEmpty)
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
                      Text(
                        'Chargement...',
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

  Widget _buildErrorState(String errorMessage) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Erreur',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // Réinitialiser l'erreur avant de recharger
                context.read<DemandeProvider>().clearError();
                _loadData();
              },
              icon: Icon(Icons.refresh),
              label: Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ... Le reste du code reste identique ...
  // (Tous les autres widgets _buildPeriodFilter, _buildPeriodChip, etc.)

  Widget _buildPeriodFilter() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 45,
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Row(
                      children: _periods.entries.where((e) => e.key != 'custom').map((entry) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: _buildPeriodChip(entry.value, entry.key),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 30,
                  color: Colors.grey[300],
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                ),
                IconButton(
                  icon: const Icon(Icons.tune, size: 20),
                  onPressed: () => _showPeriodBottomSheet(),
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
          if (_selectedPeriod == 'custom' && _startDate != null && _endDate != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.date_range, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _displayPeriodLabel,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () async {
                      setState(() {
                        _selectedPeriod = 'all';
                        _startDate = null;
                        _endDate = null;
                        _isCustomDateRange = false;
                      });
                      await _filterDataByPeriod();
                    },
                    child: Icon(Icons.close, size: 18, color: AppColors.primary),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPeriodChip(String label, String value) {
    final isSelected = _selectedPeriod == value;

    return InkWell(
      onTap: () async {
        setState(() {
          _selectedPeriod = value;
          _isCustomDateRange = false;
        });
        await _filterDataByPeriod();
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  void _showPeriodBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SingleChildScrollView(
              child: Container(
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 24,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Filtrer par période',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ..._periods.entries.where((e) => e.key != 'custom').map((entry) {
                      return _buildPeriodOption(entry.value, entry.key, setModalState);
                    }).toList(),
                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () {
                        setModalState(() {
                          _isCustomDateRange = true;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: _isCustomDateRange ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isCustomDateRange ? AppColors.primary : Colors.grey.shade300,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _isCustomDateRange ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                              color: _isCustomDateRange ? AppColors.primary : Colors.grey,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Période personnalisée',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: _isCustomDateRange ? FontWeight.w600 : FontWeight.normal,
                                color: _isCustomDateRange ? AppColors.primary : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_isCustomDateRange) ...[
                      const SizedBox(height: 16),
                      _buildDateSelector(
                        label: 'Date de début',
                        date: _startDate,
                        setModalState: setModalState,
                        onTap: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: _startDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: ColorScheme.light(
                                    primary: AppColors.primary,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (pickedDate != null) {
                            setModalState(() {
                              _startDate = pickedDate;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildDateSelector(
                        label: 'Date de fin',
                        date: _endDate,
                        setModalState: setModalState,
                        onTap: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: _endDate ?? DateTime.now(),
                            firstDate: _startDate ?? DateTime(2020),
                            lastDate: DateTime.now(),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: ColorScheme.light(
                                    primary: AppColors.primary,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (pickedDate != null) {
                            setModalState(() {
                              _endDate = pickedDate;
                            });
                          }
                        },
                      ),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (_isCustomDateRange && _startDate != null && _endDate != null) || !_isCustomDateRange
                            ? () async {
                          if (_isCustomDateRange && _startDate != null && _endDate != null) {
                            setState(() {
                              _selectedPeriod = 'custom';
                            });
                            await _filterDataByPeriod();
                          }
                          Navigator.pop(context);
                        }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          disabledBackgroundColor: Colors.grey.shade300,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Appliquer',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: (_isCustomDateRange && _startDate != null && _endDate != null) || !_isCustomDateRange
                                ? Colors.white
                                : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDateSelector({
    required String label,
    required DateTime? date,
    required StateSetter setModalState,
    required VoidCallback onTap,
  }) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: AppColors.primary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date != null ? dateFormat.format(date) : 'Sélectionner',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: date != null ? Colors.black87 : Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodOption(String label, String value, StateSetter setModalState) {
    final isSelected = _selectedPeriod == value && !_isCustomDateRange;

    return InkWell(
      onTap: () async {
        setState(() {
          _selectedPeriod = value;
          _isCustomDateRange = false;
        });
        setModalState(() {
          _isCustomDateRange = false;
        });
        await _filterDataByPeriod();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? AppColors.primary : Colors.grey,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? AppColors.primary : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(Map<String, int> stats) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.4,
      children: [
        _buildStatCard(
          title: 'En attente',
          value: stats['en_attente'] ?? 0,
          icon: Icons.inventory_2_outlined,
          color: AppColors.primary,
          statut: 'en_attente',
        ),
        _buildStatCard(
          title: 'Récupérés',
          value: stats['recupere'] ?? 0,
          icon: Icons.check_circle_outline,
          color: AppColors.primary,
          statut: 'recupere',
        ),
        _buildStatCard(
          title: 'Notifié',
          value: stats['notifie'] ?? 0,
          icon: Icons.notifications_outlined,
          color: AppColors.primary,
          statut: 'notifie',
        ),
        _buildStatCard(
          title: 'Total demandes',
          value: stats['total'] ?? 0,
          icon: Icons.show_chart,
          color: AppColors.primary,
          statut: 'tous',
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required int value,
    required IconData icon,
    required Color color,
    required String statut,
  }) {
    return InkWell(
      onTap: statut.isNotEmpty ? () => _navigateToDetail(statut) : null,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(
                  icon,
                  color: Colors.white.withOpacity(0.9),
                  size: 32,
                ),
                Text(
                  value.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Text(
              title,
              style: TextStyle(
                color: Colors.white.withOpacity(0.95),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentRequestsSection(List<DemandeModel> demandes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Demandes Récentes',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        demandes.isEmpty
            ? _buildEmptyState()
            : ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: demandes.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final demande = demandes[index];
            return _buildDemandeCard(demande);
          },
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune demande pour cette période',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDemandeCard(DemandeModel demande) {
    final String statutLabel = demande.statut == StatutDemande.en_attente
        ? 'En attente'
        : demande.statut == StatutDemande.notifie
        ? 'Notifié'
        : 'Récupéré';

    final IconData icon = demande.statut == StatutDemande.en_attente
        ? Icons.hourglass_empty
        : demande.statut == StatutDemande.notifie
        ? Icons.notifications_active
        : Icons.check_circle;

    final Color statusColor = demande.statut == StatutDemande.en_attente
        ? Colors.orange
        : demande.statut == StatutDemande.notifie
        ? Colors.blue
        : AppColors.primary;

    final Color bgColor = demande.statut == StatutDemande.en_attente
        ? const Color(0xFFFFF9E6)
        : demande.statut == StatutDemande.notifie
        ? const Color(0xFFE3F2FD)
        : const Color(0xFFE8F5E9);

    DateTime dateCreation;
    if (demande.dateCreation is String) {
      dateCreation = DateTime.parse(demande.dateCreation as String);
    } else if (demande.dateCreation is DateTime) {
      dateCreation = demande.dateCreation as DateTime;
    } else {
      dateCreation = DateTime.now();
    }

    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('HH:mm');
    final String dateLabel = dateFormat.format(dateCreation);
    final String timeLabel = timeFormat.format(dateCreation);

    final premierMedicament = demande.info.demandeMedicaments.isNotEmpty
        ? demande.info.demandeMedicaments[0].medicament
        : 'Aucun médicament';

    final nombreMedicaments = demande.info.demandeMedicaments.length;
    final autresMedicaments = nombreMedicaments > 1 ? ' +${nombreMedicaments - 1}' : '';

    return InkWell(
      onTap: () => _navigateToDemandeDetail(demande),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: statusColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    demande.info.patient,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$premierMedicament$autresMedicaments',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 13,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        dateLabel,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.access_time,
                        size: 13,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        timeLabel,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                statutLabel,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}