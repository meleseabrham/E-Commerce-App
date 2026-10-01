import 'package:flutter/material.dart';

class FullScreenImageViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const FullScreenImageViewer({
    super.key,
    required this.images,
    this.initialIndex = 0,
  });

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  late PageController _pageController;
  late int _currentIndex;
  final TransformationController _transformationController = TransformationController();
  double _currentScale = 1.0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _transformationController.addListener(_onTransformationChanged);
  }

  void _onTransformationChanged() {
    final scale = _transformationController.value.getMaxScaleOnAxis();
    if ((scale - _currentScale).abs() > 0.02) {
      setState(() {
        _currentScale = scale;
      });
    }
  }

  @override
  void dispose() {
    _transformationController.removeListener(_onTransformationChanged);
    _transformationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _resetZoom() {
    setState(() {
      _transformationController.value = Matrix4.identity();
      _currentScale = 1.0;
    });
  }

  void _zoomIn() {
    final newScale = (_currentScale + 0.5).clamp(1.0, 5.0);
    _setScale(newScale);
  }

  void _zoomOut() {
    final newScale = (_currentScale - 0.5).clamp(1.0, 5.0);
    _setScale(newScale);
  }

  void _setScale(double targetScale) {
    setState(() {
      _transformationController.value = Matrix4.identity()..scale(targetScale);
      _currentScale = targetScale;
    });
  }

  void _handleDoubleTap() {
    if (_currentScale > 1.2) {
      _resetZoom();
    } else {
      _setScale(2.5);
    }
  }

  Widget _buildImageWidget(String url) {
    if (url.startsWith('http')) {
      return Image.network(
        url,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(
            child: CircularProgressIndicator(color: Colors.white70),
          );
        },
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.broken_image, color: Colors.white54, size: 70),
              SizedBox(height: 8),
              Text('Unable to load image', style: TextStyle(color: Colors.white54)),
            ],
          ),
        ),
      );
    }
    if (url.isEmpty) {
      return const Center(
        child: Icon(Icons.image_not_supported, color: Colors.white54, size: 70),
      );
    }
    return Image.asset(
      url,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => const Center(
        child: Icon(Icons.broken_image, color: Colors.white54, size: 70),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.images.length;
    final isZoomed = _currentScale > 1.05;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Center Image with InteractiveViewer & PageView
            PageView.builder(
              controller: _pageController,
              itemCount: total,
              physics: isZoomed
                  ? const NeverScrollableScrollPhysics()
                  : const BouncingScrollPhysics(),
              onPageChanged: (index) {
                _resetZoom();
                setState(() => _currentIndex = index);
              },
              itemBuilder: (context, index) {
                return Center(
                  child: GestureDetector(
                    onDoubleTap: _handleDoubleTap,
                    child: InteractiveViewer(
                      transformationController: _transformationController,
                      minScale: 0.8,
                      maxScale: 5.0,
                      panEnabled: true,
                      scaleEnabled: true,
                      clipBehavior: Clip.none,
                      child: _buildImageWidget(widget.images[index]),
                    ),
                  ),
                );
              },
            ),

            // Top Bar: Back/Close button + Page counter
            Positioned(
              top: 12,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Close button
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24, width: 1),
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 24),
                    ),
                  ),
                  // Counter Badge
                  if (total > 1)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white24, width: 1),
                      ),
                      child: Text(
                        '${_currentIndex + 1} / $total',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  // Invisible spacer to balance close button
                  const SizedBox(width: 40),
                ],
              ),
            ),

            // Left Navigation Arrow (when multiple images)
            if (total > 1 && _currentIndex > 0)
              Positioned(
                left: 12,
                top: 0,
                bottom: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: () {
                      _resetZoom();
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24, width: 1),
                      ),
                      child: const Icon(Icons.chevron_left, color: Colors.white, size: 28),
                    ),
                  ),
                ),
              ),

            // Right Navigation Arrow (when multiple images)
            if (total > 1 && _currentIndex < total - 1)
              Positioned(
                right: 12,
                top: 0,
                bottom: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: () {
                      _resetZoom();
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24, width: 1),
                      ),
                      child: const Icon(Icons.chevron_right, color: Colors.white, size: 28),
                    ),
                  ),
                ),
              ),

            // Bottom Floating Zoom Control Bar
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white30, width: 1),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black45,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Zoom Out Button
                      IconButton(
                        icon: const Icon(Icons.zoom_out, color: Colors.white, size: 22),
                        tooltip: 'Zoom Out',
                        onPressed: _currentScale > 1.0 ? _zoomOut : null,
                      ),
                      // Zoom Scale Text
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          '${(_currentScale * 100).round()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // Zoom In Button
                      IconButton(
                        icon: const Icon(Icons.zoom_in, color: Colors.white, size: 22),
                        tooltip: 'Zoom In',
                        onPressed: _currentScale < 5.0 ? _zoomIn : null,
                      ),
                      const SizedBox(width: 4),
                      Container(width: 1, height: 22, color: Colors.white24),
                      const SizedBox(width: 4),
                      // Reset Button
                      TextButton.icon(
                        onPressed: (_currentScale - 1.0).abs() > 0.05 ? _resetZoom : null,
                        icon: const Icon(Icons.restart_alt, color: Colors.white, size: 18),
                        label: const Text(
                          'Reset',
                          style: TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
