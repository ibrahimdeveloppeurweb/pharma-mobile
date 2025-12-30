// fichier: lib/screens/address_search_page.dart
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:pharma/core/services/search_places_service.dart';
import 'package:pharma/shared/constants/colors.dart';

class AddressSearchPage extends StatefulWidget {
  final String title;
  final String hintText;

  const AddressSearchPage({
    Key? key,
    required this.title,
    this.hintText = 'Rechercher une adresse...',
  }) : super(key: key);

  @override
  _AddressSearchPageState createState() => _AddressSearchPageState();
}

class _AddressSearchPageState extends State<AddressSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final SearchPlacesService _searchService = SearchPlacesService();

  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    // Auto-focus sur le champ de recherche
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(FocusNode());
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      final results = await _searchService.searchPlaces(query);
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _searchResults = [];
      });
      toast('Erreur lors de la recherche');
    }
  }

  void _selectPlace(Map<String, dynamic> place) {
    // Retourner les données à la page précédente avec l'adresse décodée
    Navigator.pop(context, {
      'address': _decodeHtmlEntities(place['label']),
      'latitude': place['lat'],
      'longitude': place['lon'],
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Barre de recherche
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: TextStyle(color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[200]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[200]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                prefixIcon: Icon(Icons.search, color: AppColors.primary, size: 24),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey[600], size: 20),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchResults = [];
                      _hasSearched = false;
                    });
                  },
                )
                    : null,
              ),
              onChanged: (value) {
                setState(() {});
                // Recherche avec un petit délai
                Future.delayed(Duration(milliseconds: 400), () {
                  if (_searchController.text == value) {
                    _performSearch(value);
                  }
                });
              },
              onSubmitted: _performSearch,
            ),
          ),

          // Résultats de recherche
          Expanded(
            child: _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  // Fonction pour décoder les caractères HTML
  String _decodeHtmlEntities(String text) {
    return text
        .replaceAll('&#039;', "'")
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('Ã©', 'é')
        .replaceAll('Ã¨', 'è')
        .replaceAll('Ã§', 'ç')
        .replaceAll('Ã ', 'à')
        .replaceAll('Ã´', 'ô')
        .replaceAll('Ã®', 'î')
        .replaceAll('Ã¹', 'ù')
        .replaceAll('Ã«', 'ë')
        .replaceAll('Ã¯', 'ï')
        .replaceAll('Ã¢', 'â')
        .replaceAll('Ã', 'À')
        .replaceAll('Ã‰', 'É')
        .replaceAll('Ãˆ', 'È')
        .replaceAll('Ã‡', 'Ç');
  }

  Widget _buildSearchResults() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
            16.height,
            Text(
              'Recherche en cours...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    if (!_hasSearched) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.location_on_outlined,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            24.height,
            Text(
              'Recherchez une adresse',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            8.height,
            Text(
              'Commencez à taper pour voir les résultats',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off,
                size: 64,
                color: Colors.grey[600],
              ),
            ),
            24.height,
            Text(
              'Aucune adresse trouvée',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            8.height,
            Text(
              'Essayez avec d\'autres mots-clés',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.all(16),
      itemCount: _searchResults.length,
      separatorBuilder: (context, index) => Divider(height: 1),
      itemBuilder: (context, index) {
        final place = _searchResults[index];
        final decodedLabel = _decodeHtmlEntities(place['label']);

        return ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          leading: Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.location_on,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          title: Text(
            decodedLabel,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          trailing: Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Colors.grey[600],
          ),
          onTap: () => _selectPlace(place),
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}