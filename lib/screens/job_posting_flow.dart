import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../app_state.dart';
import '../services/location_service.dart';
import 'issue_selection_screen.dart';
import 'recommendation_arguments.dart';
import 'mazdoor_flow.dart'
    show
        bilingual,
        showToast,
        showExitMazdoorlinkDialog,
        MzScaffold,
        AppRoutes,
        LocationPickArguments;

class _JobPhotoAsset {
  const _JobPhotoAsset(this.label, this.asset, this.icon);
  final String label;
  final String asset;
  final IconData icon;
}

class _PhotoActionCard extends StatelessWidget {
  const _PhotoActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFF0D9488).withOpacity(0.12),
              child: Icon(icon, color: const Color(0xFF0D9488)),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
class FlowJobPostingScreen extends StatefulWidget {
  const FlowJobPostingScreen({super.key});

  @override
  State<FlowJobPostingScreen> createState() => _JobPostingScreenState();
}

class _JobPostingScreenState extends State<FlowJobPostingScreen> {
  int step = 0;
  bool asap = true;
  final desc = TextEditingController();
  final List<_JobPhotoAsset> _selectedPhotos = [];
  double _selectedPrice = 0.0;
  String _categoryKey = '';
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is JobPostingArguments) {
        final isUrdu = AppScope.of(context).isUrdu;
        desc.text = isUrdu ? args.descriptionUr : args.descriptionEn;
        _selectedPrice = args.price;
        _categoryKey = args.categoryKey;
      }
      _initialized = true;
    }
  }

  static const List<_JobPhotoAsset> _photoOptions = [
    _JobPhotoAsset(
      'Tap to capture',
      'assets/images/userImage.png',
      Icons.camera_alt_outlined,
    ),
    _JobPhotoAsset(
      'Gallery pick',
      'assets/images/helpImage.png',
      Icons.photo_library_outlined,
    ),
    _JobPhotoAsset(
      'Recent upload',
      'assets/images/inviteImage.png',
      Icons.image_outlined,
    ),
    _JobPhotoAsset(
      'Service issue',
      'assets/images/feedbackImage.png',
      Icons.broken_image_outlined,
    ),
    _JobPhotoAsset(
      'Workspace',
      'assets/images/supportIcon.png',
      Icons.work_outline,
    ),
  ];

  @override
  void dispose() {
    desc.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final choice = await showModalBottomSheet<_JobPhotoAsset>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.72,
          minChildSize: 0.45,
          maxChildSize: 0.92,
          builder: (_, controller) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    bilingual(
                      context,
                      'Add job photos',
                      'کام کی تصاویر شامل کریں',
                    ),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    bilingual(
                      context,
                      'Pick a recent photo or capture one for this request',
                      'حالیہ تصویر منتخب کریں یا نیا فوٹو شامل کریں',
                    ),
                    style: const TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _PhotoActionCard(
                          icon: Icons.photo_camera_outlined,
                          title: bilingual(
                            context,
                            'Open camera',
                            'کیمرہ کھولیں',
                          ),
                          subtitle: bilingual(
                            context,
                            'Capture a new photo',
                            'نئی تصویر لیں',
                          ),
                          onTap: () =>
                              Navigator.pop(context, _photoOptions.first),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _PhotoActionCard(
                          icon: Icons.photo_library_outlined,
                          title: bilingual(
                            context,
                            'Choose from gallery',
                            'گیلری سے منتخب کریں',
                          ),
                          subtitle: bilingual(
                            context,
                            'Pick from saved images',
                            'محفوظ تصاویر میں سے',
                          ),
                          onTap: () => Navigator.pop(context, _photoOptions[1]),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    bilingual(context, 'Recent options', 'حالیہ تصاویر'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _photoOptions.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1,
                        ),
                    itemBuilder: (_, index) {
                      final item = _photoOptions[index];
                      return InkWell(
                        onTap: () => Navigator.pop(context, item),
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.asset(item.asset, fit: BoxFit.cover),
                                Container(color: Colors.black26),
                                Positioned(
                                  left: 12,
                                  right: 12,
                                  bottom: 12,
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: Colors.white,
                                        child: Icon(
                                          item.icon,
                                          color: const Color(0xFF0D9488),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          item.label,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    if (choice == null) return;
    setState(() => _selectedPhotos.add(choice));
  }

  @override
  Widget build(BuildContext context) {
    return MzScaffold(
      showBottomNav: false,
      showBack: true,
      title: bilingual(context, 'Post a Job', 'کام پوسٹ کریں'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              bilingual(context, 'Step ${step + 1} of 2', '${step + 1} از 2'),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                child: step == 0 ? _stepOne(context) : _stepTwo(context),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  if (step == 0) {
                    setState(() => step = 1);
                  } else {
                    Navigator.pushReplacementNamed(
                      context,
                      AppRoutes.confirmLocation,
                      arguments: JobPostingArguments(
                        descriptionEn: desc.text,
                        descriptionUr: desc.text,
                        price: _selectedPrice > 0 ? _selectedPrice : 1000.0,
                        categoryKey: _categoryKey.isNotEmpty
                            ? _categoryKey
                            : 'electrician',
                      ),
                    );
                  }
                },
                child: Text(
                  step == 0
                      ? bilingual(context, 'Continue', 'جاری رکھیں')
                      : bilingual(context, 'Find Workers', 'ورکر تلاش کریں'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepOne(BuildContext context) {
    return ListView(
      key: const ValueKey('step1'),
      children: [
        Text(
          bilingual(context, 'What needs to be done?', 'کیا کام کرنا ہے؟'),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: desc,
          minLines: 4,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: bilingual(
              context,
              'E.g., My kitchen sink is leaking',
              'مثلاً کچن سنک لیک ہو رہا ہے',
            ),
          ),
        ),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: _pickPhoto,
          icon: const Icon(Icons.photo_camera_outlined),
          label: Text(
            bilingual(context, 'Add Photos (Optional)', 'تصاویر شامل کریں'),
          ),
        ),
        if (_selectedPhotos.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(
            bilingual(context, 'Selected photos', 'منتخب تصاویر'),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 94,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedPhotos.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final item = _selectedPhotos[index];
                return Container(
                  width: 140,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(item.asset, fit: BoxFit.cover),
                        Container(color: Colors.black26),
                        Positioned(
                          left: 10,
                          right: 10,
                          bottom: 10,
                          child: Text(
                            item.label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
        const SizedBox(height: 14),
      ],
    );
  }

  Widget _stepTwo(BuildContext context) {
    return ListView(
      key: const ValueKey('step2'),
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.location_on),
          title: Text(bilingual(context, 'Service Location', 'سروس لوکیشن')),
          subtitle: Text(
            bilingual(
              context,
              'House 42, Street 7, Sector F-8/4',
              'گھر 42، سٹریٹ 7، سیکٹر ایف-8/4',
            ),
          ),
          trailing: TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Location picker opened')),
              );
            },
            child: Text(bilingual(context, 'Change', 'تبدیل')),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFECFEFF),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                bilingual(context, 'Location', 'مقام'),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                bilingual(
                  context,
                  'Workers will be matched to your location.',
                  'ورکرز آپ کے مقام کے مطابق تلاش کیے جائیں گے۔',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ConfirmLocationScreen extends StatefulWidget {
  const ConfirmLocationScreen({super.key});

  @override
  State<ConfirmLocationScreen> createState() => _ConfirmLocationScreenState();
}

class _ConfirmLocationScreenState extends State<ConfirmLocationScreen> {
  GoogleMapController? _mapController;
  LatLng _selectedLocation = LocationService.defaultIslamabad;
  bool _loadingLocation = true;
  bool _initialized = false;
  final TextEditingController _searchController = TextEditingController();
  bool _searching = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final args = ModalRoute.of(context)?.settings.arguments;
    final lat = args is JobPostingArguments
        ? args.customerLatitude
        : args is RecommendationArguments
        ? args.customerLatitude
        : null;
    final lng = args is JobPostingArguments
        ? args.customerLongitude
        : args is RecommendationArguments
        ? args.customerLongitude
        : null;

    if (lat != null && lng != null) {
      _selectedLocation = LatLng(lat, lng);
      _loadingLocation = false;
    } else {
      _useCurrentLocation();
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _loadingLocation = true);
    final loc = await LocationService.instance.fetchCurrentGpsLocation(
      context: context,
    );
    if (!mounted) return;

    if (loc == null) {
      final cached = LocationService.instance.currentLocation;
      setState(() {
        _selectedLocation = LatLng(cached.latitude, cached.longitude);
        _loadingLocation = false;
      });
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_selectedLocation, 16),
      );
      return;
    }

    setState(() {
      _selectedLocation = LatLng(loc.latitude, loc.longitude);
      _loadingLocation = false;
    });

    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(_selectedLocation, 16),
    );
  }

  Future<void> _searchLocation(String query) async {
    if (query.trim().isEmpty) return;
    setState(() => _searching = true);
    try {
      final key = 'AIzaSyCGHY7A6zdFd-t27sflz0-AQTgulg_s_II';
      final uri = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(query)}&key=$key',
      );
      final res = await http.get(uri);
      if (!mounted) return;
      final data = json.decode(res.body);
      if (data['status'] == 'OK' && data['results'].isNotEmpty) {
        final loc = data['results'][0]['geometry']['location'];
        final latLng = LatLng(loc['lat'], loc['lng']);
        setState(() {
          _selectedLocation = latLng;
          _searching = false;
        });
        _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 16));
      } else {
        setState(() => _searching = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              bilingual(
                context,
                'Location not found. Try a different search.',
                'مقام نہیں ملا۔ مختلف تلاش کریں۔',
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _searching = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            bilingual(
              context,
              'Search failed. Try again.',
              'تلاش ناکام۔ دوبارہ کوشش کریں۔',
            ),
          ),
        ),
      );
    }
  }

  void _confirmLocation() {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is LocationPickArguments) {
      Navigator.pop(context, {
        'lat': _selectedLocation.latitude,
        'lng': _selectedLocation.longitude,
      });
      return;
    }
    if (args is JobPostingArguments) {
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.recommendations,
        arguments: JobPostingArguments(
          descriptionEn: args.descriptionEn,
          descriptionUr: args.descriptionUr,
          price: args.price,
          categoryKey: args.categoryKey,
          paymentMethod: args.paymentMethod,
          customerLatitude: _selectedLocation.latitude,
          customerLongitude: _selectedLocation.longitude,
        ),
      );
      return;
    }

    if (args is RecommendationArguments) {
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.recommendations,
        arguments: RecommendationArguments(
          selectedIssues: args.selectedIssues,
          categoryKey: args.categoryKey,
          paymentMethod: args.paymentMethod,
          customerLatitude: _selectedLocation.latitude,
          customerLongitude: _selectedLocation.longitude,
        ),
      );
      return;
    }

    Navigator.pushReplacementNamed(context, AppRoutes.recommendations);
  }

  @override
  Widget build(BuildContext context) {
    final isUrdu = AppScope.of(context).isUrdu;
    return MzScaffold(
      showBottomNav: false,
      showBack: true,
      title: bilingual(context, 'Confirm Location', 'لوکیشن کی تصدیق کریں'),
      child: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: CameraPosition(
              target: _selectedLocation,
              zoom: 16,
            ),
            markers: {
              Marker(
                markerId: const MarkerId('customer_location'),
                position: _selectedLocation,
                draggable: true,
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueBlue,
                ),
                infoWindow: InfoWindow(
                  title: bilingual(context, 'Service location', 'سروس لوکیشن'),
                ),
                onDragEnd: (position) =>
                    setState(() => _selectedLocation = position),
              ),
            },
            onTap: (position) => setState(() => _selectedLocation = position),
            onMapCreated: (controller) {
              _mapController = controller;
              controller.animateCamera(
                CameraUpdate.newLatLngZoom(_selectedLocation, 16),
              );
            },
            myLocationButtonEnabled: false,
            myLocationEnabled: false,
            zoomControlsEnabled: false,
          ),
          if (_loadingLocation)
            Container(
              color: Colors.white.withOpacity(0.65),
              child: const Center(child: CircularProgressIndicator()),
            ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 60,
            left: 12,
            right: 12,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
                decoration: InputDecoration(
                  hintText: bilingual(
                    context,
                    'Search place…',
                    'مقام تلاش کریں…',
                  ),
                  prefixIcon: _searching
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                onChanged: (_) => setState(() {}),
                onSubmitted: (value) => _searchLocation(value),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bilingual(
                      context,
                      'Set exact service point',
                      'درست سروس پوائنٹ منتخب کریں',
                    ),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    bilingual(
                      context,
                      'Drag the pin or tap the map. The worker will navigate to this exact point.',
                      'پن کو منتقل کریں یا نقشے پر ٹیپ کریں۔ ورکر اسی مقام پر آئے گا۔',
                    ),
                    style: const TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Color(0xFF0D9488),
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${_selectedLocation.latitude.toStringAsFixed(5)}, ${_selectedLocation.longitude.toStringAsFixed(5)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0D9488),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _loadingLocation
                              ? null
                              : () => _useCurrentLocation(),
                          icon: const Icon(Icons.my_location),
                          label: Text(isUrdu ? 'موجودہ لوکیشن' : 'Use current'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _loadingLocation ? null : _confirmLocation,
                          icon: const Icon(Icons.check),
                          label: Text(isUrdu ? 'تصدیق' : 'Confirm'),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF0D9488),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
