import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../presentation/providers/tailor_finder_provider.dart';
import '../../../../theme/colors.dart';
import '../../../../core/widgets/tailor_finder_responsive.dart';

/// Tailor Map View Widget
/// Uses OpenStreetMap with CartoDB Dark Matter tiles
/// Mobile-optimized with performance improvements
class TailorMapView extends StatefulWidget {
  final List<TailorMarker> tailors;
  final TailorMarker? selectedTailor;
  final LatLng? userLocation;
  final Function(TailorMarker) onTailorSelected;
  final Function(LatLng)? onMapTap;
  final VoidCallback? onBack;
  /// Enable mobile optimizations for better touch handling
  final bool enableMobileOptimizations;

  const TailorMapView({
    super.key,
    required this.tailors,
    this.selectedTailor,
    this.userLocation,
    required this.onTailorSelected,
    this.onMapTap,
    this.onBack,
    this.enableMobileOptimizations = true,
  });

  @override
  State<TailorMapView> createState() => _TailorMapViewState();
}

class _TailorMapViewState extends State<TailorMapView> {
  late final MapController _mapController;
  bool _isDarkMode = true;
  bool _isMobile = false;
  
  static const _defaultCenter = LatLng(6.5244, 3.3792);
  static const _defaultZoom = 17.0;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    // Detect mobile for performance optimizations
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final width = MediaQuery.of(context).size.width;
        setState(() {
          _isMobile = width < TailorFinderBreakpoints.tablet;
        });
      }
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black, // Dark background while tiles load
      width: double.infinity,
      height: double.infinity, // Let parent Expanded handle sizing
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.userLocation ?? _defaultCenter,
              initialZoom: _defaultZoom,
              onTap: (_, position) {
                widget.onMapTap?.call(position);
              },
              // Mobile: enable interactive flags for better touch handling
              interactionOptions: _isMobile
                  ? const InteractionOptions(
                      flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                    )
                  : const InteractionOptions(),
            ),
children: [
              TileLayer(
                urlTemplate: _isDarkMode 
                    ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
                    : 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.desby.app',
                maxZoom: 19,
                retinaMode: RetinaMode.isHighDensity(context),
              ),
              if (widget.selectedTailor != null && widget.userLocation != null)
                PolylineLayer(
                  polylines: <Polyline>[
                    Polyline(
                      points: [
                        widget.userLocation!,
                        widget.selectedTailor!.location,
                      ],
                      color: AppColors.amber,
                      strokeWidth: 4,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: _buildTailorMarkers(),
              ),
              if (widget.userLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: widget.userLocation!,
                      width: 24,
                      height: 24,
                      child: const _UserLocationMarker(),
                    ),
                  ],
                ),
            ],
          ),
Positioned(
            right: 16,
            bottom: 16,
            child: _MapControls(
              onZoomIn: () {
                _mapController.move(
                  _mapController.camera.center,
                  _mapController.camera.zoom + 1,
                );
              },
              onZoomOut: () {
                _mapController.move(
                  _mapController.camera.center,
                  _mapController.camera.zoom - 1,
                );
              },
              onMyLocation: () {
                if (widget.userLocation != null) {
                  _mapController.move(widget.userLocation!, _defaultZoom);
                }
              },
              isDarkMode: _isDarkMode,
              onToggleMode: () {
                setState(() {
                  _isDarkMode = !_isDarkMode;
                });
              },
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _MapHeader(onBack: widget.onBack),
          ),
        ],
      ),
    );
  }

  List<Marker> _buildTailorMarkers() {
    return widget.tailors.map((tailor) {
      final isSelected = widget.selectedTailor?.id == tailor.id;
      return Marker(
        point: tailor.location,
        width: 50,
        height: 50,
        child: GestureDetector(
          onTap: () => widget.onTailorSelected(tailor),
          child: _TailorMapMarker(
            tailor: tailor,
            isSelected: isSelected,
          ),
        ),
      );
    }).toList();
  }
}

class _TailorMapMarker extends StatelessWidget {
  final TailorMarker tailor;
  final bool isSelected;

  const _TailorMapMarker({
    required this.tailor,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isSelected ? AppColors.amber : const Color(0xFF1E3A45), // DARKER BLUE-NAVY
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          tailor.name.isNotEmpty ? tailor.name[0].toUpperCase() : 'T',
          style: TextStyle(
            color: isSelected ? AppColors.darkNavy : AppColors.amber,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _UserLocationMarker extends StatefulWidget {
  const _UserLocationMarker();
  @override
  State<_UserLocationMarker> createState() => _UserLocationMarkerState();
}

class _UserLocationMarkerState extends State<_UserLocationMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: 0.5, end: 1.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 24 * _animation.value,
              height: 24 * _animation.value,
              decoration: BoxDecoration(
                color: AppColors.uberInfo.withValues(alpha: 0.3 / _animation.value),
                shape: BoxShape.circle,
              ),
            ),
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: AppColors.uberInfo,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MapHeader extends StatelessWidget {
  final VoidCallback? onBack;
  const _MapHeader({this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 12,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.darkNavy,
            AppColors.darkNavy.withValues(alpha: 0),
          ],
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack ?? () => Navigator.pop(context),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white10),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white10),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.my_location_rounded,
                  color: AppColors.amber,
                  size: 16,
                ),
                SizedBox(width: 8),
                Text(
                  'MY LOCATION',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white10),
            ),
            child: const Icon(
              Icons.tune_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _MapControls extends StatelessWidget {
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onMyLocation;
  final bool isDarkMode;
  final VoidCallback onToggleMode;

  const _MapControls({
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onMyLocation,
    required this.isDarkMode,
    required this.onToggleMode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ControlButton(icon: Icons.add_rounded, onTap: onZoomIn),
        const SizedBox(height: 8),
        _ControlButton(icon: Icons.remove_rounded, onTap: onZoomOut),
        const SizedBox(height: 16),
        _ControlButton(icon: Icons.my_location_rounded, onTap: onMyLocation, isPrimary: true),
        const SizedBox(height: 8),
        _ControlButton(
          icon: isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded, 
          onTap: onToggleMode,
        ),
      ],
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isPrimary;

  const _ControlButton({
    required this.icon,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.amber : AppColors.uberCard,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isPrimary ? AppColors.darkNavy : AppColors.uberTextPrimary,
          size: 20,
        ),
      ),
    );
  }
}
