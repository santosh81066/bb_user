import 'package:flutter/material.dart';

import '../models/get_properties_model.dart';

class HallSelection extends StatefulWidget {
  final Hall hall;
  final bool isSelected;

  const HallSelection({
    super.key,
    required this.hall,
    required this.isSelected,
  });

  @override
  State<HallSelection> createState() => _HallSelectionState();
}

class _HallSelectionState extends State<HallSelection> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: widget.isSelected
              ? [Colors.deepPurple.shade400, Colors.deepPurple.shade600]
              : [Colors.white, Colors.grey.shade50],
        ),
        boxShadow: [
          BoxShadow(
            color: widget.isSelected ? Colors.deepPurple.withOpacity(0.3) : Colors.grey.withOpacity(0.2),
            blurRadius: widget.isSelected ? 20 : 10,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            flex: 3,
            child: _buildEnhancedImageGallery(widget.hall, widget.isSelected),
          ),
          Expanded(
            flex: 1,
            child: _buildHallInfo(widget.hall, widget.isSelected),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedImageGallery(Hall hall, bool isSelected) {
    if (hall.images?.isEmpty != false) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
              const SizedBox(height: 10),
              Text('No images available', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
      child: Stack(
        children: [
          PageView.builder(
            itemCount: hall.images!.length,
            itemBuilder: (context, imageIndex) => Image.network(
              'http://www.gocodedesigners.com/banquetbookingz/${hall.images![imageIndex].url}',
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.grey.shade200,
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image, size: 50, color: Colors.grey),
                      Text("Image not available", style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (isSelected)
            Positioned(
              top: 15,
              right: 15,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(Icons.check_circle, color: Colors.green, size: 24),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHallInfo(Hall hall, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hall.name ?? 'No Hall Name',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.currency_rupee,
                color: isSelected ? Colors.amber : Colors.amber.shade700,
                size: 20,
              ),
              Text(
                '${hall.price ?? 0}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.amber : Colors.amber.shade700,
                ),
              ),
              const Spacer(),
              if (isSelected)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'SELECTED',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
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