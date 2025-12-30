import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pharma/presentation/admin/screens/ajour_pharmace_admin_screen.dart';
import 'package:pharma/presentation/admin/screens/pharmacie_detail_screen.dart';
import 'package:pharma/shared/shimmer/shimmer_liste.dart';
import 'package:provider/provider.dart';
import 'package:pharma/data/providers/pharmacie_provider.dart';
import 'package:pharma/data/models/pharmacie_model.dart';
import 'package:shimmer/shimmer.dart'; // ⭐ Ajout du package shimmer
import '../../../shared/constants/colors.dart';

class PharmacieAdminScreen extends StatefulWidget {
  final String? statut;

  const PharmacieAdminScreen({
    Key? key,
    this.statut,
  }) : super(key: key);

  @override
  State<PharmacieAdminScreen> createState() => _PharmacieAdminScreenState();
}

class _PharmacieAdminScreenState extends State<PharmacieAdminScreen> {
  // 🎯 FILTRES
  String _currentFilter = 'toutes';
  String _selectedPeriod = 'all';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isCustomDateRange = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Map des périodes
  final Map<String, String> _periods = {
    'today': "Aujourd'hui",
    'week': 'Cette semaine',
    'month': 'Ce mois',
    'year': 'Cette année',
    'all': 'Tout',
    'custom': 'Période personnalisée',
  };

  // Map des statuts
  final Map<String, String> _statuts = {
    'toutes': 'Toutes',
    'actives': 'Actives',
    'inactives': 'Inactives',
    'notifie': 'Notifié',
  };

  @override
  void initState() {
    super.initState();
    if (widget.statut != null) {
      _currentFilter = widget.statut!;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Prépare les paramètres de filtre selon la période et statut sélectionnés
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

    final filters = {
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'period': period,
      'statut': _currentFilter,
      'search': _searchQuery.isNotEmpty ? _searchQuery : null,
    };

    filters.removeWhere((key, value) => value == null);
    return filters;
  }

  Future<void> _loadData() async {
    final pharmacieProvider = Provider.of<PharmacieProvider>(context, listen: false);
    final filterParams = _buildFilterParams();
    await pharmacieProvider.loadPharmacies(filterParams);
  }

  String get _displayPeriodLabel {
    if (_selectedPeriod == 'custom' && _startDate != null && _endDate != null) {
      final dateFormat = DateFormat('dd/MM/yyyy');
      return '${dateFormat.format(_startDate!)} - ${dateFormat.format(_endDate!)}';
    }
    return _periods[_selectedPeriod] ?? '';
  }

  String get _displayFilterLabel {
    String label = _periods[_selectedPeriod] ?? '';
    if (_currentFilter != 'toutes') {
      label += ' • ${_statuts[_currentFilter]}';
    }
    return label;
  }

  Future<void> _handleRefresh() async {
    await _loadData();
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rechercher'),
        content: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Nom, ville ou responsable...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                });
                _loadData();
                Navigator.pop(context);
              },
            )
                : null,
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              _searchController.clear();
              setState(() {
                _searchQuery = '';
              });
              _loadData();
              Navigator.pop(context);
            },
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              _loadData();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Rechercher'),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet() {
    String tempPeriod = _selectedPeriod;
    String tempFilter = _currentFilter;
    DateTime? tempStartDate = _startDate;
    DateTime? tempEndDate = _endDate;
    bool tempIsCustom = _isCustomDateRange;

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
                          'Filtres',
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

                    // Section Période
                    const Text(
                      'Période d\'inscription',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._periods.entries
                        .where((e) => e.key != 'custom')
                        .map((entry) {
                      return _buildOption(
                        entry.value,
                        tempPeriod == entry.key && !tempIsCustom,
                            () {
                          setModalState(() {
                            tempPeriod = entry.key;
                            tempIsCustom = false;
                          });
                        },
                      );
                    }).toList(),
                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 8),
                    _buildOption(
                      'Période personnalisée',
                      tempIsCustom,
                          () {
                        setModalState(() {
                          tempIsCustom = true;
                        });
                      },
                    ),
                    if (tempIsCustom) ...[
                      const SizedBox(height: 16),
                      _buildDateSelector(
                        label: 'Date de début',
                        date: tempStartDate,
                        setModalState: setModalState,
                        onTap: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: tempStartDate ?? DateTime.now(),
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
                              tempStartDate = pickedDate;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildDateSelector(
                        label: 'Date de fin',
                        date: tempEndDate,
                        setModalState: setModalState,
                        onTap: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: tempEndDate ?? DateTime.now(),
                            firstDate: tempStartDate ?? DateTime(2020),
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
                              tempEndDate = pickedDate;
                            });
                          }
                        },
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Section Statut
                    const Text(
                      'Statut',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._statuts.entries.map((entry) {
                      return _buildOption(
                        entry.value,
                        tempFilter == entry.key,
                            () {
                          setModalState(() {
                            tempFilter = entry.key;
                          });
                        },
                      );
                    }).toList(),

                    const SizedBox(height: 24),

                    // Boutons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setModalState(() {
                                tempPeriod = 'all';
                                tempFilter = 'toutes';
                                tempStartDate = null;
                                tempEndDate = null;
                                tempIsCustom = false;
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(color: AppColors.primary),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Réinitialiser',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: (tempIsCustom &&
                                tempStartDate != null &&
                                tempEndDate != null) ||
                                !tempIsCustom
                                ? () async {
                              setState(() {
                                _selectedPeriod = tempPeriod;
                                _currentFilter = tempFilter;
                                _startDate = tempStartDate;
                                _endDate = tempEndDate;
                                _isCustomDateRange = tempIsCustom;
                                if (tempIsCustom &&
                                    tempStartDate != null &&
                                    tempEndDate != null) {
                                  _selectedPeriod = 'custom';
                                }
                              });
                              await _loadData();
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
                                color: (tempIsCustom &&
                                    tempStartDate != null &&
                                    tempEndDate != null) ||
                                    !tempIsCustom
                                    ? Colors.white
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildOption(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Gestion des Pharmacies',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.black87),
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _searchController.clear();
                });
                _loadData();
              },
            ),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black87),
            onPressed: _showSearchDialog,
          ),
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
      ),
      body: Consumer<PharmacieProvider>(
        builder: (context, pharmacieProvider, child) {
          return Stack(
            children: [
              _buildMainContent(pharmacieProvider),

              // 🎯 OVERLAY DE CHARGEMENT (uniquement si des données existent déjà)
              if (pharmacieProvider.isLoading && pharmacieProvider.pharmacies.isNotEmpty)
                Container(
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
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMainContent(PharmacieProvider pharmacieProvider) {
    // ⭐ Afficher shimmer au premier chargement (liste vide)
    if (pharmacieProvider.isLoading && pharmacieProvider.pharmacies.isEmpty) {
      return Column(
        children: [
          _buildFilterBar(0),
          Expanded(child: ShimmerList()),
        ],
      );
    }

    if (pharmacieProvider.errorMessage != null && pharmacieProvider.pharmacies.isEmpty) {
      return _buildErrorState(pharmacieProvider.errorMessage!);
    }

    final pharmacies = pharmacieProvider.pharmacies;

    return Column(
      children: [
        _buildFilterBar(pharmacies.length),
        if (_searchQuery.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.primary.withOpacity(0.1),
            child: Row(
              children: [
                Icon(Icons.search, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Recherche: "$_searchQuery" - ${pharmacies.length} résultat(s)',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _handleRefresh,
            color: AppColors.primary,
            child: pharmacies.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: pharmacies.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final pharmacie = pharmacies[index];
                return _buildPharmacieCard(pharmacie);
              },
            ),
          ),
        ),
      ],
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
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune pharmacie trouvée',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Essayez de modifier vos critères',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(int totalPharmacies) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
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
          Expanded(
            child: InkWell(
              onTap: _showFilterBottomSheet,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.filter_list, color: AppColors.primary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _displayFilterLabel,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_selectedPeriod != 'all' || _currentFilter != 'toutes')
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          totalPharmacies.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                  ],
                ),
              ),
            ),
          ),
          if (_selectedPeriod != 'all' || _currentFilter != 'toutes') ...[
            const SizedBox(width: 12),
            InkWell(
              onTap: () async {
                setState(() {
                  _selectedPeriod = 'all';
                  _currentFilter = 'toutes';
                  _startDate = null;
                  _endDate = null;
                  _isCustomDateRange = false;
                });
                await _loadData();
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Icon(Icons.close, color: Colors.red.shade700, size: 20),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPharmacieCard(PharmacieModel pharmacie) {
    final bool isActive = pharmacie.actif ?? false;
    final dateFormat = DateFormat('dd/MM/yyyy');

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.local_pharmacy,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pharmacie.nom,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: isActive ? Colors.green : Colors.grey,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isActive ? 'Active' : 'Inactive',
                            style: TextStyle(
                              fontSize: 12,
                              color: isActive ? Colors.green : Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.grey),
                  onSelected: (value) async {
                    if (value == 'edit') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CreatePharmacieAdminScreen(pharmacie: pharmacie),
                        ),
                      );
                    } else if (value == 'toggle') {
                      // TODO: Activer/Désactiver
                    } else if (value == 'delete') {
                      // TODO: Supprimer
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('Modifier'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'toggle',
                      child: Row(
                        children: [
                          Icon(
                            isActive ? Icons.block : Icons.check_circle,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(isActive ? 'Désactiver' : 'Activer'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Supprimer', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: Colors.grey[200], height: 1),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.location_on, pharmacie.ville),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.phone, pharmacie.telephone ?? 'N/A'),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.email, pharmacie.email ?? 'N/A'),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.calendar_today,
              pharmacie.createdAt != null
                  ? 'Inscrit le ${dateFormat.format(pharmacie.createdAt!)}'
                  : 'Date non disponible',
            ),
            const SizedBox(height: 12),
            Divider(color: Colors.grey[200], height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total',
                    pharmacie.totalDemandes.toString(),
                    Colors.blue,
                  ),
                ),
                Container(
                  width: 1,
                  height: 30,
                  color: Colors.grey[200],
                ),
                Expanded(
                  child: _buildStatItem(
                    'Alertés',
                    pharmacie.demandesNotifiees.toString(),
                    Colors.orange,
                  ),
                ),
                Container(
                  width: 1,
                  height: 30,
                  color: Colors.grey[200],
                ),
                Expanded(
                  child: _buildStatItem(
                    'En attente',
                    pharmacie.demandesEnAttente?.toString() ?? '0',
                    Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
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

  void _showPharmacieDetails(PharmacieModel pharmacie) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final bool isActive = pharmacie.actif ?? false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.local_pharmacy, color: AppColors.primary, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      pharmacie.nom,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildDetailRow('Nom', pharmacie.nom),
              _buildDetailRow('Téléphone', pharmacie.telephone ?? 'N/A'),
              _buildDetailRow('Email', pharmacie.email ?? 'N/A'),
              _buildDetailRow('Ville', pharmacie.ville),
              _buildDetailRow('Adresse', pharmacie.adresse ?? 'N/A'),
              _buildDetailRow('Code Postal', pharmacie.codePostal ?? 'N/A'),
              _buildDetailRow('N° Autorisation', pharmacie.numeroAutorisation ?? 'N/A'),
              _buildDetailRow(
                'Date d\'inscription',
                pharmacie.createdAt != null
                    ? dateFormat.format(pharmacie.createdAt!)
                    : 'N/A',
              ),
              _buildDetailRow('Statut', isActive ? 'Active' : 'Inactive'),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    // TODO: Navigation vers formulaire de modification
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Modifier',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}