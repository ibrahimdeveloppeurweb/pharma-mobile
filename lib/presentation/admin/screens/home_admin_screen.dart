import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pharma/presentation/admin/screens/pharmacie_detail_screen.dart';
import 'package:provider/provider.dart';
import 'package:pharma/data/providers/pharmacie_provider.dart';
import 'package:pharma/data/models/pharmacie_model.dart';
import '../../../shared/constants/colors.dart';

class HomeAdminScreen extends StatefulWidget {
  final Function(String statut)? onNavigateToDemandesWithFilter;

  const HomeAdminScreen({
    Key? key,
    this.onNavigateToDemandesWithFilter,
  }) : super(key: key);

  @override
  State<HomeAdminScreen> createState() => _HomeAdminScreenState();
}

class _HomeAdminScreenState extends State<HomeAdminScreen> {
  // 🎯 FILTRAGE PAR PÉRIODE
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

  /// Prépare les paramètres de filtre selon la période sélectionnée
  Map<String, dynamic> _buildFilterParams() {
    final now = DateTime.now();
    DateTime? startDate;
    DateTime? endDate;
    String? period;

    switch (_selectedPeriod) {
      case 'today':
        startDate = DateTime(now.year, now.month, now.day);
        endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        period = 'today';
        break;

      case 'week':
        final monday = now.subtract(Duration(days: now.weekday - 1));
        startDate = DateTime(monday.year, monday.month, monday.day);
        endDate = now;
        period = 'week';
        break;

      case 'month':
        startDate = DateTime(now.year, now.month, 1);
        endDate = now;
        period = 'month';
        break;

      case 'year':
        startDate = DateTime(now.year, 1, 1);
        endDate = now;
        period = 'year';
        break;

      case 'custom':
        startDate = _startDate;
        endDate = _endDate;
        period = 'custom';
        break;

      case 'all':
      default:
        period = 'all';
        break;
    }

    return {
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'period': period,
    };
  }

  Future<void> _loadData() async {
    final pharmacieProvider = Provider.of<PharmacieProvider>(context, listen: false);
    final filterParams = _buildFilterParams();
    await pharmacieProvider.loadPharmaciesStats(filterParams);
  }

  Future<void> _filterDataByPeriod() async {
    await _loadData();
  }

  String get _displayPeriodLabel {
    if (_selectedPeriod == 'custom' && _startDate != null && _endDate != null) {
      final dateFormat = DateFormat('dd/MM/yyyy');
      return '${dateFormat.format(_startDate!)} - ${dateFormat.format(_endDate!)}';
    }
    return _periods[_selectedPeriod] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: Consumer<PharmacieProvider>(
        builder: (context, pharmacieProvider, child) {
          return Stack(
            children: [
              // Contenu principal
              _buildMainContent(pharmacieProvider),

              // 🎯 OVERLAY DE CHARGEMENT
              if (pharmacieProvider.isLoading && pharmacieProvider.widgetStats != null)
                _buildLoadingState()
            ],
          );
        },
      ),
    );
  }

  Widget _buildMainContent(PharmacieProvider pharmacieProvider) {
    // État de chargement initial (première fois)
    if (pharmacieProvider.isLoading && pharmacieProvider.widgetStats == null) {
      return _buildLoadingState();
    }

    // État d'erreur
    if (pharmacieProvider.errorMessage != null && pharmacieProvider.widgetStats == null) {
      return _buildErrorState(pharmacieProvider.errorMessage!);
    }

    // Pas de données
    if (pharmacieProvider.widgetStats == null) {
      return _buildEmptyState();
    }

    // Affichage des données avec RefreshIndicator
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPeriodFilter(),
            const SizedBox(height: 20),
            _buildStatsGrid(pharmacieProvider),
            const SizedBox(height: 32),
            _buildTopPharmaciesSection(pharmacieProvider),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  // 🎯 APP BAR - CORRECTION ICI
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Administration',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Gestion des pharmacies',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
      actions: [

        // 🎯 BOUTON DE RAFRAÎCHISSEMENT
        Consumer<PharmacieProvider>(
          builder: (context, provider, child) {
            return IconButton(
              icon: Icon(
                Icons.refresh,
                color: provider.isLoading ? Colors.grey : Colors.black87,
              ),
              onPressed: provider.isLoading ? null : _loadData,
            );
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // 🎯 ÉTATS DE CHARGEMENT
  Widget _buildLoadingState() {
    return Container(
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
    );
  }

  Widget _buildErrorState(String errorMessage) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info_outline, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Aucune donnée disponible',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            label: const Text('Actualiser'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  // 🎯 FILTRE DE PÉRIODE
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
          SizedBox(
            height: 45,
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Row(
                      children: _periods.entries
                          .where((e) => e.key != 'custom')
                          .map((entry) {
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
                  onPressed: _showPeriodBottomSheet,
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
                    ..._periods.entries
                        .where((e) => e.key != 'custom')
                        .map((entry) {
                      return _buildPeriodOption(entry.value, entry.key, setModalState);
                    }),
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
                          color: _isCustomDateRange
                              ? AppColors.primary.withOpacity(0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isCustomDateRange
                                ? AppColors.primary
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _isCustomDateRange
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_unchecked,
                              color: _isCustomDateRange ? AppColors.primary : Colors.grey,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Période personnalisée',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: _isCustomDateRange
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: _isCustomDateRange
                                    ? AppColors.primary
                                    : Colors.black87,
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
                        onPressed: (_isCustomDateRange &&
                            _startDate != null &&
                            _endDate != null) ||
                            !_isCustomDateRange
                            ? () async {
                          if (_isCustomDateRange &&
                              _startDate != null &&
                              _endDate != null) {
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
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade300,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Appliquer',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
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

  Widget _buildPeriodOption(
      String label, String value, StateSetter setModalState) {
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
          color: isSelected
              ? AppColors.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
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

  // 🎯 GRILLE DE STATISTIQUES
  Widget _buildStatsGrid(PharmacieProvider provider) {
    final stats = provider.widgetStats!;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.3,
      children: [
        _buildStatCard(
          title: 'Total Pharmacies',
          value: stats.totalPharmacies,
          icon: Icons.local_pharmacy,
          onTap: () => _navigateToDemandesWithFilter('toutes'),
        ),
        _buildStatCard(
          title: 'Pharmacies Actives',
          value: stats.pharmaciesActives,
          icon: Icons.check_circle,
          onTap: () => _navigateToDemandesWithFilter('actives'),
        ),
        _buildStatCard(
          title: 'Total Demandes',
          value: stats.totalDemandes,
          icon: Icons.inventory_2,
          onTap: () {},
        ),
        _buildStatCard(
          title: 'Notifications',
          value: stats.notificationsTotal,
          icon: Icons.notifications_active,
          onTap: () => _navigateToDemandesWithFilter('notifie'),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required int value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
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

  void _navigateToDemandesWithFilter(String statut) {
    if (widget.onNavigateToDemandesWithFilter != null) {
      widget.onNavigateToDemandesWithFilter!(statut);
    }
  }

  // 🎯 TOP 5 PHARMACIES
  Widget _buildTopPharmaciesSection(PharmacieProvider provider) {
    if (provider.pharmaciesStats.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.local_pharmacy, size: 48, color: Colors.grey[300]),
              const SizedBox(height: 12),
              Text(
                'Aucune donnée disponible',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.emoji_events,
              color: AppColors.primary,
              size: 28,
            ),
            const SizedBox(width: 8),
            const Text(
              'Top 5 Pharmacies Performantes',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Classement basé sur le nombre de demandes notifiées',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 20),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: provider.pharmaciesStats.length > 5
              ? 5
              : provider.pharmaciesStats.length,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final pharmacie = provider.pharmaciesStats[index];
            return _buildPharmacieRankCard(pharmacie, pharmacie.rang ?? (index + 1));
          },
        ),
      ],
    );
  }

  Widget _buildPharmacieRankCard(PharmacieModel pharmacie, int rang) {
    final IconData rankIcon = rang == 1
        ? Icons.emoji_events
        : rang == 2
        ? Icons.military_tech
        : rang == 3
        ? Icons.workspace_premium
        : Icons.star;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PharmacieDetailScreen(pharmacie: pharmacie),
          ),
        );
      },
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
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.primary.withOpacity(0.7)
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        rankIcon,
                        color: Colors.white,
                        size: rang <= 3 ? 24 : 20,
                      ),
                      Text(
                        '#$rang',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              pharmacie.nom,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: pharmacie.actif == true
                                  ? Colors.green
                                  : Colors.grey,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              pharmacie.ville,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: Colors.grey[200], height: 1),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.notifications_active,
                    label: 'Alertés',
                    value: pharmacie.demandesNotifiees.toString(),
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.grey[200],
                ),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.inventory_2,
                    label: 'Total',
                    value: pharmacie.totalDemandes.toString(),
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.grey[200],
                ),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.trending_up,
                    label: 'Taux',
                    value: pharmacie.tauxPerformance != null
                        ? '${pharmacie.tauxPerformance}%'
                        : 'N/A',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: pharmacie.tauxPerformance != null
                    ? pharmacie.tauxPerformance! / 100
                    : 0,
                minHeight: 8,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: AppColors.primary,
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}