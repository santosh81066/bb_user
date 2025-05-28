import 'package:flutter/material.dart';
import 'dart:async';

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
  PageController? _pageController;
  Timer? _timer;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeAutoScroll();
  }

  void _initializeAutoScroll() {
    // Only initialize if there are multiple images
    if (widget.hall.images?.isNotEmpty == true && widget.hall.images!.length > 1) {
      _pageController = PageController();
      _startAutoScroll();
    }
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 10), (Timer timer) {
      if (_pageController != null && widget.hall.images != null) {
        _currentImageIndex = (_currentImageIndex + 1) % widget.hall.images!.length;

        if (_pageController!.hasClients) {
          _pageController!.animateToPage(
            _currentImageIndex,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(HallSelection oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Restart auto-scroll if hall data changes
    if (oldWidget.hall != widget.hall) {
      _timer?.cancel();
      _pageController?.dispose();
      _currentImageIndex = 0;
      _initializeAutoScroll();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: widget.isSelected
              ? [Colors.green.shade400, Colors.green.shade600]
              : [Colors.deepPurple, Colors.grey.shade50],
        ),
        boxShadow: [
          BoxShadow(
            color: widget.isSelected ? Colors.green.withOpacity(0.3) : Colors.grey.withOpacity(0.2),
            blurRadius: widget.isSelected ? 20 : 10,
            offset: const Offset(0, 8),
          ),
        ],
        border: widget.isSelected
            ? Border.all(color: Colors.green.shade300, width: 3)
            : Border.all(color: Colors.deepPurple.shade300, width: 2),
      ),
      child: Column(
        children: [
          // Image section - 60% of the card
          Expanded(
            flex: 3,
            child: _buildImageSection(widget.hall, widget.isSelected),
          ),
          // Info section - 40% of the card
          Expanded(
            flex: 1,
            child: _buildHallInfo(widget.hall, widget.isSelected),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection(Hall hall, bool isSelected) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        color: Colors.grey.shade100,
      ),
      child: Stack(
        children: [
          // Image content
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: _buildImageContent(hall),
          ),
          // Selected indicator
          if (isSelected)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.green,
                  size: 20,
                ),
              ),
            ),
          // Image indicator dots (optional - shows current image)
          if (hall.images?.isNotEmpty == true && hall.images!.length > 1)
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  hall.images!.length,
                      (index) => Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentImageIndex == index
                          ? Colors.white
                          : Colors.white.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImageContent(Hall hall) {
    if (hall.images?.isEmpty != false) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.grey.shade200,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
              SizedBox(height: 8),
              Text(
                'No images available',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return PageView.builder(
      controller: _pageController,
      itemCount: hall.images!.length,
      onPageChanged: (index) {
        setState(() {
          _currentImageIndex = index;
        });
      },
      itemBuilder: (context, imageIndex) => Image.network(
        'http://www.gocodedesigners.com/banquetbookingz/${hall.images![imageIndex].url}',
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey.shade200,
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image, size: 40, color: Colors.grey),
                SizedBox(height: 8),
                Text(
                  "Image not available",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHallInfo(Hall hall, bool isSelected) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
        color: isSelected ? null : Colors.white,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Hall name
          Expanded(
            child: Text(
              hall.name ?? 'No Hall Name',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          const SizedBox(width: 12),

          // Price section
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.currency_rupee,
                color: isSelected ? Colors.amber.shade200 : Colors.amber.shade700,
                size: 18,
              ),
              Text(
                '${hall.price ?? 0}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.amber.shade200 : Colors.amber.shade700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}