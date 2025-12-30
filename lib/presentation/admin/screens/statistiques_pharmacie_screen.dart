import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:pharma/data/providers/dashboard_provider.dart';
import 'package:pharma/data/models/dashboard_admin_model.dart';
import '../../../shared/constants/colors.dart';

class StatistiqueAdminScreen extends StatefulWidget {
  const StatistiqueAdminScreen({super.key});

  @override
  State<StatistiqueAdminScreen> createState() => _StatistiqueAdminScreenState();
}

class _StatistiqueAdminScreenState extends State<StatistiqueAdminScreen> {
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
      _loadStatistics();
    });
  }

  // ============ CALCUL DES FILTRES SELON LA PÉRIODE ============
  Map<String, dynamic>? _buildFilters() {
    final now = DateTime.now();
    final dateFormat = DateFormat('yyyy-MM-dd');

    DateTime? startDate;
    DateTime? endDate;

    switch (_selectedPeriod) {
      case 'today':
        startDate = DateTime(now.year, now.month, now.day);
        endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;

      case 'week':
        startDate = now.subtract(Duration(days: now.weekday - 1));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        endDate = startDate.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
        break;

      case 'month':
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
        break;

      case 'year':
        startDate = DateTime(now.year, 1, 1);
        endDate = DateTime(now.year, 12, 31, 23, 59, 59);
        break;

      case 'custom':
        if (_startDate == null || _endDate == null) return null;
        startDate = _startDate!;
        endDate = _endDate!;
        break;

      case 'all':
      default:
        return null; // Pas de filtre pour "Tout"
    }

    if (startDate == null || endDate == null) return null;

    return {
      'start_date': dateFormat.format(startDate),
      'end_date': dateFormat.format(endDate),
      'period': _selectedPeriod
    };
  }

  // ============ CHARGEMENT DES STATISTIQUES ============
  Future<void> _loadStatistics() async {
    final provider = context.read<DashboardProvider>();
    final filters = _buildFilters();

    try {
      await provider.loadDashboardAdmin(filters: filters);
    } catch (e) {
      _showErrorSnackBar('Erreur lors du chargement des données');
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String get _displayPeriodLabel {
    if (_selectedPeriod == 'custom' && _startDate != null && _endDate != null) {
      final dateFormat = DateFormat('dd/MM/yyyy');
      return '${dateFormat.format(_startDate!)} - ${dateFormat.format(_endDate!)}';
    }
    return _periods[_selectedPeriod] ?? '';
  }

  Future<void> _handleRefresh() async {
    await _loadStatistics();
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
                        onPressed: (_isCustomDateRange &&
                            _startDate != null &&
                            _endDate != null) ||
                            !_isCustomDateRange
                            ? () {
                          if (_isCustomDateRange &&
                              _startDate != null &&
                              _endDate != null) {
                            setState(() {
                              _selectedPeriod = 'custom';
                            });
                          }
                          Navigator.pop(context);
                          _loadStatistics();
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
                            color: (_isCustomDateRange &&
                                _startDate != null &&
                                _endDate != null) ||
                                !_isCustomDateRange
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
      onTap: () {
        setState(() {
          _selectedPeriod = value;
          _isCustomDateRange = false;
        });
        setModalState(() {
          _isCustomDateRange = false;
        });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Statistiques',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
      body: Consumer<DashboardProvider>(
        builder: (context, provider, child) {
          // Afficher un loader initial pendant le premier chargement
          if (provider.isLoading && provider.dashboardData == null) {
            return _buildLoadingOverlay();
          }

          // Afficher une erreur si pas de données
          if (provider.errorMessage != null && provider.dashboardData == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.red[400], size: 64),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      provider.errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.red[700]),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _loadStatistics,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Réessayer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }

          // Pas de données disponibles
          if (provider.dashboardData == null) {
            return const Center(
              child: Text('Aucune donnée disponible'),
            );
          }

          // Extraire les données du dashboard admin
          final stats = provider.dashboardData!.widgets;
          final graph = provider.dashboardData!.graph;
          final topPharmacies = provider.dashboardData!.topPharmacies;
          final repartitionVilles = provider.dashboardData!.repartitionVilles;

          return Stack(
            children: [
              RefreshIndicator(
                onRefresh: _handleRefresh,
                color: AppColors.primary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPeriodFilter(),
                      const SizedBox(height: 20),
                      _buildKPICards(stats),
                      const SizedBox(height: 20),
                      _buildChartCard(graph),
                      const SizedBox(height: 20),
                      _buildTopPharmaciesCard(topPharmacies),
                      const SizedBox(height: 20),
                      _buildRepartitionCard(repartitionVilles),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),

              // Overlay de chargement pendant le refresh
              if (provider.isLoading && provider.dashboardData != null)
                _buildLoadingOverlay(),
            ],
          );
        },
      ),
    );
  }

  // ============ WIDGET LOADING OVERLAY ============
  Widget _buildLoadingOverlay() {
    return Container(
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
                    onTap: () {
                      setState(() {
                        _selectedPeriod = 'all';
                        _startDate = null;
                        _endDate = null;
                        _isCustomDateRange = false;
                      });
                      _loadStatistics();
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
      onTap: () {
        setState(() {
          _selectedPeriod = value;
          _isCustomDateRange = false;
        });
        _loadStatistics();
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

  Widget _buildKPICards(WidgetsDataAdmin stats) {
    return Container(
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
      child: Row(
        children: [
          Expanded(
            child: _buildKPIItem(
              '${stats.totalPharmacies}',
              'Total\nPharmacies',
            ),
          ),
          _buildDivider(),
          Expanded(
            child: _buildKPIItem(
              '${stats.pharmaciesActives}',
              'Actives',
            ),
          ),
          _buildDivider(),
          Expanded(
            child: _buildKPIItem(
              '${stats.tauxActivite}%',
              'Taux\nActivité',
            ),
          ),
          _buildDivider(),
          Expanded(
            child: _buildKPIItem(
              '+${stats.nouvellesInscriptions}',
              'Nouvelles\nInscriptions',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKPIItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
            height: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 50,
      color: Colors.grey.shade300,
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  Widget _buildChartCard(GraphDataAdmin graph) {
    return Container(
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
          Text(
            _getChartTitle(),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 24),
          _buildBarChart(graph.time, graph.nbInscriptions),
        ],
      ),
    );
  }

  String _getChartTitle() {
    switch (_selectedPeriod) {
      case 'today':
        return "Inscriptions aujourd'hui";
      case 'week':
        return 'Inscriptions cette semaine';
      case 'month':
        return 'Inscriptions ce mois';
      case 'year':
        return 'Inscriptions cette année';
      case 'custom':
        return 'Inscriptions période personnalisée';
      default:
        return 'Évolution des inscriptions';
    }
  }

  Widget _buildBarChart(List<String> labels, List<int> data) {
    if (data.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('Aucune donnée disponible'),
        ),
      );
    }

    final maxValue = data.reduce((a, b) => a > b ? a : b).toDouble();

    return SizedBox(
      height: 180,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(data.length, (index) {
          final value = data[index].toDouble();
          final height = maxValue > 0 ? (value / maxValue) * 140 : 0;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: double.infinity,
                    height: height.toDouble(),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    labels[index],
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTopPharmaciesCard(List<TopPharmacieData> topPharmacies) {
    return Container(
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
          const Text(
            'Top 5 Pharmacies Performantes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          _buildPharmaciesList(topPharmacies),
        ],
      ),
    );
  }

  Widget _buildPharmaciesList(List<TopPharmacieData> topPharmacies) {
    if (topPharmacies.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('Aucune donnée disponible'),
        ),
      );
    }

    final maxCount = topPharmacies.first.demandes;

    return Column(
      children: List.generate(topPharmacies.length, (index) {
        final pharma = topPharmacies[index];
        final percentage = maxCount > 0 ? (pharma.demandes / maxCount) * 100 : 0;

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pharma.nom,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      pharma.ville,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 80,
                child: Stack(
                  children: [
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: percentage / 100,
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 40,
                child: Text(
                  '${pharma.demandes}',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildRepartitionCard(Map<String, int> repartitionVilles) {
    return Container(
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
          const Text(
            'Répartition Géographique',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          if (repartitionVilles.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('Aucune donnée disponible'),
              ),
            )
          else
            ...repartitionVilles.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildRepartitionItem(
                  entry.key,
                  entry.value,
                  repartitionVilles,
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildRepartitionItem(
      String ville, int count, Map<String, int> repartitionVilles) {
    final total = repartitionVilles.values.reduce((a, b) => a + b);
    final percentage = total > 0 ? (count / total) * 100 : 0;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  ville,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage / 100,
            minHeight: 6,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ],
    );
  }
}