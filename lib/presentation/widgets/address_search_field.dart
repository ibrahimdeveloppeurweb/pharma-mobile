// fichier: lib/widgets/address_search_field.dart
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:pharma/presentation/widgets/address_search_page.dart';
import 'package:pharma/shared/constants/colors.dart';

class AddressSearchField extends StatefulWidget {
  final String label;
  final Color? labelColor;
  final String hintText;
  final TextEditingController controller;
  final Function(String address, double lat, double lon) onPlaceSelected;
  final int delay;

  const AddressSearchField({
    Key? key,
    required this.label,
    this.labelColor,
    required this.hintText,
    required this.controller,
    required this.onPlaceSelected,
    this.delay = 0,
  }) : super(key: key);

  @override
  _AddressSearchFieldState createState() => _AddressSearchFieldState();
}

class _AddressSearchFieldState extends State<AddressSearchField> {
  Future<void> _openSearchPage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddressSearchPage(
          title: widget.label,
          hintText: widget.hintText,
        ),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      widget.controller.text = result['address'];
      widget.onPlaceSelected(
        result['address'],
        result['latitude'],
        result['longitude'],
      );
      toast('Adresse sélectionnée');
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 500 + widget.delay),
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
                  child: Icon(Icons.location_on, size: 20, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: widget.labelColor ?? Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Stack(
              children: [
                GestureDetector(
                  onTap: _openSearchPage,
                  child: AbsorbPointer(
                    absorbing: true,
                    child: TextField(
                      controller: widget.controller,
                      decoration: InputDecoration(
                        hintText: widget.hintText,
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
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        suffixIcon: widget.controller.text.isNotEmpty
                            ? null
                            : Icon(Icons.search, color: AppColors.primary, size: 20),
                      ),
                    ),
                  ),
                ),
                // Bouton clear positionné au-dessus
                if (widget.controller.text.isNotEmpty)
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: GestureDetector(
                      onTap: () {
                        widget.controller.clear();
                        setState(() {});
                      },
                      child: Container(
                        width: 48,
                        alignment: Alignment.center,
                        color: Colors.transparent,
                        child: Icon(Icons.clear, color: AppColors.primary, size: 20),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}