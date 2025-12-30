import 'package:flutter/material.dart';
import 'package:pharma/data/providers/demande_provider.dart';
import 'package:pharma/presentation/controllers/demande_controller.dart';
import 'package:pharma/shared/shimmer/shimmer_liste.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart'; // ⭐ Ajout du package shimmer
import '../../../shared/constants/colors.dart';
import '../../../data/models/demande_model.dart';
import '../../../core/services/api_service.dart';
import 'detail_demande_screen.dart';
import 'package:intl/intl.dart';

class ListeDemandesScreen extends StatefulWidget {
  final Map<String, dynamic>? initialFilters;

  ListeDemandesScreen({
    Key? key,
    this.initialFilters,
  }) : super(key: key);

  @override
  State<ListeDemandesScreen> createState() => _ListeDemandesScreenState();
}

class _ListeDemandesScreenState extends State<ListeDemandesScreen> {
  String _currentFilter = 'tous';
  String _selectedPeriod = 'all';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isCustomDateRange = false;
  bool _isRefreshing = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  DemandeController? _demandeController;
  final bool _useApi = true;

  final Map<String, String> _periods = {
    'today': "Aujourd'hui",
    'week': 'Cette semaine',
    'month': 'Ce mois',
    'year': 'Cette année',
    'all': 'Tout',
    'custom': 'Période personnalisée',
  };

  final Map<String, String> _statuts = {
    'tous': 'Tous',
    'en_attente': 'En attente',
    'notifie': 'Notifiés',
    'recupere': 'Récupérés',
  };

  final List<DemandeModel> demandesStatiques = [];

  @override
  void initState() {
    super.initState();

    if (widget.initialFilters != null) {
      _applyInitialFilters(widget.initialFilters!);
    }

    if (_useApi) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final apiService = context.read<ApiService>();
          _demandeController = DemandeController(apiService: apiService);
          _demandeController!.addListener(_onControllerUpdate);
          _loadDemandesFromApi();
        }
        context.read<DemandeProvider>().addListener(_onDemandeProviderUpdate);
      });
    }
  }

  void _applyInitialFilters(Map<String, dynamic> filters) {
    if (filters.containsKey('statut') && filters['statut'] != null) {
      final statut = filters['statut'] as String;
      if (_statuts.containsKey(statut)) {
        _currentFilter = statut;
      }
    }

    if (filters.containsKey('period') && filters['period'] != null) {
      final period = filters['period'] as String;
      if (_periods.containsKey(period)) {
        _selectedPeriod = period;
      }
    }

    if (filters.containsKey('start_date') && filters['start_date'] != null) {
      try {
        _startDate = DateTime.parse(filters['start_date'] as String);
      } catch (e) {
        debugPrint('Erreur parsing start_date: $e');
      }
    }

    if (filters.containsKey('end_date') && filters['end_date'] != null) {
      try {
        _endDate = DateTime.parse(filters['end_date'] as String);
      } catch (e) {
        debugPrint('Erreur parsing end_date: $e');
      }
    }

    if (_startDate != null && _endDate != null) {
      _isCustomDateRange = true;
      _selectedPeriod = 'custom';
    }
  }

  void _onControllerUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onDemandeProviderUpdate() {
    if (mounted && _useApi) {
      _loadDemandesFromApi();
    }
  }

  Future<void> _loadDemandesFromApi() async {
    if (!_useApi || !mounted || _demandeController == null) return;

    try {
      final data = _buildFilterData();
      await _demandeController!.loadDemandes(data);
    } catch (e) {
      debugPrint('Erreur lors du chargement des demandes: $e');
    }
  }

  Map<String, dynamic> _buildFilterData() {
    final data = <String, dynamic>{};
    data['statut'] = null;
    data['dateD'] = null;
    data['dateF'] = null;
    data['recherche'] = null;

    if (_currentFilter != 'tous') {
      data['statut'] = _currentFilter;
    }

    if (_selectedPeriod != 'all') {
      final now = DateTime.now();
      DateTime? startDate;
      DateTime? endDate = now;

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
          startDate = _startDate;
          endDate = _endDate;
          break;
      }

      if (startDate != null) {
        data['dateD'] = DateFormat('yyyy-MM-dd').format(startDate);
      }
      if (endDate != null) {
        data['dateF'] = DateFormat('yyyy-MM-dd').format(endDate);
      }
    }

    if (_searchQuery.isNotEmpty) {
      data['recherche'] = _searchQuery;
    }

    return data;
  }

  Map<String, dynamic> _demandeModelToMap(DemandeModel demande) {
    String medicamentNom = demande.medicament.nom;
    print("bbbbbbbb ${demande.statut}");
    return {
      'id': demande.id,
      'nom': demande.patient.nomComplet,
      'telephone': demande.patient.telephone,
      'medicament': medicamentNom,
      'date': demande.dateCreation,
      'statut': _getStatutString(demande.statut),
      'icon': _getStatutIcon(demande.statut),
      'color': _getStatutColor(demande.statut),
      'nbMedicaments': demande.info.demandeMedicaments.length,
      'prixTotal': 0.0,
    };
  }

  String _getStatutString(dynamic statut) {
    if (statut is String) return statut;
    print("nnnnnnnnnnnn ${statut}");
    final str = statut.toString().split('.').last;
    switch (str) {
      case 'enAttente':
      case 'en_attente':
        return 'en_attente';
      case 'notifie':
        return 'notifie';
      case 'recupere':
        return 'recupere';
      default:
        return 'en_attente';
    }
  }

  IconData _getStatutIcon(dynamic statut) {
    final str = _getStatutString(statut);
    switch (str) {
      case 'en_attente':
        return Icons.hourglass_empty;
      case 'notifie':
        return Icons.notifications_active;
      case 'recupere':
        return Icons.check_circle;
      default:
        return Icons.hourglass_empty;
    }
  }

  Color _getStatutColor(dynamic statut) {
    final str = _getStatutString(statut);
    switch (str) {
      case 'en_attente':
        return Colors.orange;
      case 'notifie':
        return Colors.blue;
      case 'recupere':
        return AppColors.primary;
      default:
        return Colors.grey;
    }
  }

  List<DemandeModel> get _demandes {
    if (_useApi && _demandeController != null) {
      return _demandeController!.demandes;
    }
    return demandesStatiques;
  }

  List<Map<String, dynamic>> get filteredDemandes {
    var demandesList = _demandes;

    if (!_useApi && _selectedPeriod != 'all') {
      final now = DateTime.now();
      DateTime? startDate;
      DateTime? endDate = now;

      switch (_selectedPeriod) {
        case 'today':
          startDate = DateTime(now.year, now.month, now.day);
          endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
          break;
        case 'week':
          startDate = now.subtract(const Duration(days: 7));
          break;
        case 'month':
          startDate = DateTime(now.year, now.month, 1);
          break;
        case 'year':
          startDate = DateTime(now.year, 1, 1);
          break;
        case 'custom':
          startDate = _startDate;
          endDate = _endDate;
          break;
      }

      if (startDate != null && endDate != null) {
        demandesList = demandesList.where((d) {
          return d.dateCreation.isAfter(startDate!.subtract(const Duration(days: 1))) &&
              d.dateCreation.isBefore(endDate!.add(const Duration(days: 1)));
        }).toList();
      }
    }

    if (!_useApi && _currentFilter != 'tous') {
      demandesList = demandesList.where((d) {
        return _getStatutString(d.statut) == _currentFilter;
      }).toList();
    }

    if (!_useApi && _searchQuery.isNotEmpty) {
      demandesList = demandesList.where((d) {
        final nom = d.patient.nomComplet.toLowerCase();
        final medicament = d.medicament.nom.toLowerCase();
        final query = _searchQuery.toLowerCase();

        return nom.contains(query) || medicament.contains(query);
      }).toList();
    }

    return demandesList.map((d) => _demandeModelToMap(d)).toList();
  }

  int get totalDemandes => filteredDemandes.length;

  String get _displayPeriodLabel {
    if (_selectedPeriod == 'custom' && _startDate != null && _endDate != null) {
      final dateFormat = DateFormat('dd/MM/yyyy');
      return '${dateFormat.format(_startDate!)} - ${dateFormat.format(_endDate!)}';
    }
    return _periods[_selectedPeriod] ?? '';
  }

  String get _displayFilterLabel {
    String label = _periods[_selectedPeriod] ?? '';
    if (_currentFilter != 'tous') {
      label += ' • ${_statuts[_currentFilter]}';
    }
    return label;
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _isRefreshing = true;
    });

    if (_useApi) {
      await _loadDemandesFromApi();
    } else {
      await Future.delayed(const Duration(milliseconds: 1500));
    }

    setState(() {
      _isRefreshing = false;
    });
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
            hintText: 'Nom du patient ou médicament...',
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
                Navigator.pop(context);
                if (_useApi) _loadDemandesFromApi();
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
              Navigator.pop(context);
              if (_useApi) _loadDemandesFromApi();
            },
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (_useApi) _loadDemandesFromApi();
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
                    const Text(
                      'Période',
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
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setModalState(() {
                                tempPeriod = 'all';
                                tempFilter = 'tous';
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
                                ? () {
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
                              Navigator.pop(context);
                              if (_useApi) _loadDemandesFromApi();
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
                      color:
                      date != null ? Colors.black87 : Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                size: 16, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  void _navigateToDetail(Map<String, dynamic> demande) async {
    final demandeProvider = context.read<DemandeProvider>();
    demandeProvider.clearError();

    final demandeModel = _demandes.firstWhere(
          (d) => d.id == demande['id'],
    );

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailDemandeScreen(
          demande: demandeModel,
        ),
      ),
    );

    if (result == true && _useApi) {
      _loadDemandesFromApi();
      if (mounted) {
        demandeProvider.clearError();
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _demandeController?.removeListener(_onControllerUpdate);
    _demandeController?.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    bool isLoading = false;
    String? errorMessage;

    if (_useApi && _demandeController != null) {
      isLoading = _demandeController!.isLoading;
      errorMessage = _demandeController!.errorMessage;
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Toutes les Demandes',
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
                if (_useApi) _loadDemandesFromApi();
              },
            ),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black87),
            onPressed: _showSearchDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
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
                      'Recherche: "$_searchQuery" - ${filteredDemandes.length} résultat(s)',
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
            child: isLoading
                ? ShimmerList()
                : errorMessage != null
                ? _buildErrorState(errorMessage)
                : RefreshIndicator(
              onRefresh: _handleRefresh,
              color: AppColors.primary,
              child: filteredDemandes.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: filteredDemandes.length,
                separatorBuilder: (context, index) =>
                const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final demande = filteredDemandes[index];
                  return _buildDemandeCard(demande);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
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
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.filter_list,
                        color: AppColors.primary, size: 20),
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
                    if (_selectedPeriod != 'all' || _currentFilter != 'tous')
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          totalDemandes.toString(),
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
          if (_selectedPeriod != 'all' || _currentFilter != 'tous') ...[
            const SizedBox(width: 12),
            InkWell(
              onTap: () {
                setState(() {
                  _selectedPeriod = 'all';
                  _currentFilter = 'tous';
                  _startDate = null;
                  _endDate = null;
                  _isCustomDateRange = false;
                });
                if (_useApi) _loadDemandesFromApi();
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

  Widget _buildErrorState(String errorMessage) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
          const SizedBox(height: 16),
          Text(
            'Erreur',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _handleRefresh,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Réessayer'),
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
            'Aucun résultat trouvé',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Essayez une autre recherche',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDemandeCard(Map<String, dynamic> demande) {
    final String statutLabel = demande['statut'] == 'en_attente'
        ? 'En attente'
        : demande['statut'] == 'notifie'
        ? 'Notifié'
        : 'Récupéré';

    final Color statusColor = demande['color'];
    final Color bgColor = demande['statut'] == 'en_attente'
        ? const Color(0xFFFFF9E6)
        : demande['statut'] == 'notifie'
        ? const Color(0xFFE3F2FD)
        : const Color(0xFFE8F5E9);

    final int nbMedicaments = demande['nbMedicaments'] ?? 0;

    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('HH:mm');

    final String dateLabel = dateFormat.format(demande['date']);
    final String timeLabel = timeFormat.format(demande['date']);

    return InkWell(
      onTap: () => _navigateToDetail(demande),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    demande['icon'],
                    color: statusColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        demande['nom'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      if (nbMedicaments > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Icon(
                                Icons.medication,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$nbMedicaments médicament${nbMedicaments > 1 ? 's' : ''}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    demande['medicament'],
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
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
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Voir détails',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: AppColors.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}