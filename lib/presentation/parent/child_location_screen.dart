import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChildLocationScreen extends StatefulWidget {
  final String childId;
  final String parentUid;
  final String childName;

  const ChildLocationScreen({
    super.key,
    required this.childId,
    required this.parentUid,
    required this.childName,
  });

  @override
  State<ChildLocationScreen> createState() => _ChildLocationScreenState();
}

class _ChildLocationScreenState extends State<ChildLocationScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late MapController _mapController;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8),
              ],
            ),
            child: IconButton(
              icon: AnimatedRotation(
                turns: _isRefreshing ? 1 : 0,
                duration: const Duration(milliseconds: 500),
                child: Icon(Icons.refresh, color: colorScheme.primary),
              ),
              onPressed: _refreshLocation,
            ),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.parentUid)
            .collection('children')
            .doc(widget.childId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: colorScheme.primary),
                  const SizedBox(height: 16),
                  Text(
                    'Loading location...',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>?;

          double lat = 13.7563;
          double lng = 100.5018;
          String timeString = "No Data";
          bool hasData = false;
          DateTime? lastUpdate;

          if (data != null && data.containsKey('currentLocation')) {
            final locationData =
                data['currentLocation'] as Map<String, dynamic>;
            lat = locationData['latitude'] ?? 13.7563;
            lng = locationData['longitude'] ?? 100.5018;
            final Timestamp? ts = locationData['timestamp'] as Timestamp?;

            if (ts != null) {
              lastUpdate = ts.toDate();
              timeString = _formatTime(lastUpdate);
            }
            hasData = true;
          }

          return Stack(
            children: [
              // Map
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: LatLng(lat, lng),
                  initialZoom: 16.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.seniorproject.kid_guard',
                  ),
                  if (hasData)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(lat, lng),
                          width: 120,
                          height: 120,
                          child: _buildAnimatedMarker(),
                        ),
                      ],
                    ),
                ],
              ),

              // Glassmorphism info card at bottom
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildGlassmorphismCard(
                  hasData: hasData,
                  timeString: timeString,
                  lastUpdate: lastUpdate,
                  lat: lat,
                  lng: lng,
                ),
              ),

              // Child name header
              Positioned(top: 100, left: 16, child: _buildNameBadge()),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAnimatedMarker() {
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Pulse ring
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.primary.withOpacity(0.2),
                ),
              ),
            );
          },
        ),
        // Inner marker
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [colorScheme.primary, colorScheme.tertiary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withOpacity(0.4),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white,
            child: Text(
              widget.childName[0].toUpperCase(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNameBadge() {
    final colorScheme = Theme.of(context).colorScheme;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(-20 * (1 - value), 0),
            child: child,
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.location_on,
                    color: colorScheme.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "${widget.childName}'s Location",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassmorphismCard({
    required bool hasData,
    required String timeString,
    required DateTime? lastUpdate,
    required double lat,
    required double lng,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              border: Border.all(color: Colors.white.withOpacity(0.5)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),

                // Status row
                Row(
                  children: [
                    // Status indicator
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: hasData
                              ? [colorScheme.primary, colorScheme.tertiary]
                              : [Colors.grey, Colors.grey.shade400],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        hasData ? Icons.gps_fixed : Icons.gps_off,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hasData
                                ? 'Location Active'
                                : 'Waiting for location...',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                hasData
                                    ? 'Last updated: $timeString'
                                    : 'No data yet',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (hasData) _buildTimeSinceBadge(lastUpdate),
                  ],
                ),

                if (hasData) ...[
                  const SizedBox(height: 20),
                  // Coordinates
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceVariant.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildCoordinateItem(
                          'Latitude',
                          lat.toStringAsFixed(4),
                          Icons.north,
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.grey[300],
                        ),
                        _buildCoordinateItem(
                          'Longitude',
                          lng.toStringAsFixed(4),
                          Icons.east,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Center on map button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _mapController.move(LatLng(lat, lng), 17),
                      icon: const Icon(Icons.my_location),
                      label: const Text('Center on Map'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeSinceBadge(DateTime? lastUpdate) {
    if (lastUpdate == null) return const SizedBox();

    final diff = DateTime.now().difference(lastUpdate);
    String timeAgo;
    Color color;

    if (diff.inMinutes < 2) {
      timeAgo = 'Now';
      color = Colors.green;
    } else if (diff.inMinutes < 10) {
      timeAgo = '${diff.inMinutes}m ago';
      color = Colors.green;
    } else if (diff.inHours < 1) {
      timeAgo = '${diff.inMinutes}m ago';
      color = Colors.orange;
    } else {
      timeAgo = '${diff.inHours}h ago';
      color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            timeAgo,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoordinateItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void _refreshLocation() {
    setState(() => _isRefreshing = true);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _isRefreshing = false);
    });
  }
}
