import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class TwinCityArea {
  final String nameEn;
  final String nameUr;
  final String city; // 'Islamabad' or 'Rawalpindi'
  final double latitude;
  final double longitude;

  const TwinCityArea({
    required this.nameEn,
    required this.nameUr,
    required this.city,
    required this.latitude,
    required this.longitude,
  });
}

class AppLocation {
  final double latitude;
  final double longitude;
  final String city; // 'Islamabad' or 'Rawalpindi'
  final String area;
  final String fullAddress;
  final bool isInsideTwinCities;

  const AppLocation({
    required this.latitude,
    required this.longitude,
    required this.city,
    required this.area,
    required this.fullAddress,
    required this.isInsideTwinCities,
  });

  String get shortDisplayName {
    if (area.isNotEmpty && city.isNotEmpty) {
      if (area.toLowerCase().contains(city.toLowerCase())) {
        return area;
      }
      return '$area, $city';
    }
    if (fullAddress.isNotEmpty) return fullAddress;
    return city.isNotEmpty ? city : 'Islamabad';
  }

  String shortDisplayNameBilingual(bool isUrdu) {
    final areaName = isUrdu ? _translateAreaUrdu(area) : area;
    final cityName = isUrdu ? (city == 'Islamabad' ? 'اسلام آباد' : 'راولپنڈی') : city;
    if (areaName.isNotEmpty && cityName.isNotEmpty) {
      if (areaName.toLowerCase().contains(cityName.toLowerCase())) {
        return areaName;
      }
      return '$areaName، $cityName';
    }
    return isUrdu ? (city == 'Islamabad' ? 'اسلام آباد' : 'راولپنڈی') : city;
  }

  static String _translateAreaUrdu(String en) {
    for (final a in LocationService.supportedAreas) {
      if (a.nameEn.toLowerCase() == en.toLowerCase()) {
        return a.nameUr;
      }
    }
    return en;
  }

  Map<String, dynamic> toMap() => {
        'latitude': latitude,
        'longitude': longitude,
        'city': city,
        'area': area,
        'locationAddress': fullAddress,
        'isInsideTwinCities': isInsideTwinCities,
      };

  factory AppLocation.fromMap(Map<String, dynamic> map) {
    return AppLocation(
      latitude: (map['latitude'] as num?)?.toDouble() ?? 33.6844,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 73.0479,
      city: map['city']?.toString() ?? 'Islamabad',
      area: map['area']?.toString() ?? 'F-7',
      fullAddress: map['locationAddress']?.toString() ?? 'F-7, Islamabad',
      isInsideTwinCities: map['isInsideTwinCities'] as bool? ?? true,
    );
  }
}

class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  static const String googleApiKey = 'AIzaSyCGHY7A6zdFd-t27sflz0-AQTgulg_s_II';

  // Default coordinate: Islamabad F-7
  static const LatLng defaultIslamabad = LatLng(33.7215, 73.0563);
  static const LatLng defaultRawalpindi = LatLng(33.5950, 73.0540);

  // Twin cities bounding box:
  static const double minLat = 33.35;
  static const double maxLat = 33.88;
  static const double minLng = 72.70;
  static const double maxLng = 73.35;

  static const List<TwinCityArea> supportedAreas = [
    // Islamabad
    TwinCityArea(nameEn: 'F-6', nameUr: 'ایف 6', city: 'Islamabad', latitude: 33.7314, longitude: 73.0766),
    TwinCityArea(nameEn: 'F-7', nameUr: 'ایف 7', city: 'Islamabad', latitude: 33.7215, longitude: 73.0563),
    TwinCityArea(nameEn: 'F-8', nameUr: 'ایف 8', city: 'Islamabad', latitude: 33.7118, longitude: 73.0371),
    TwinCityArea(nameEn: 'F-10', nameUr: 'ایف 10', city: 'Islamabad', latitude: 33.6934, longitude: 73.0118),
    TwinCityArea(nameEn: 'F-11', nameUr: 'ایف 11', city: 'Islamabad', latitude: 33.6844, longitude: 72.9880),
    TwinCityArea(nameEn: 'Blue Area', nameUr: 'بلیو ایریا', city: 'Islamabad', latitude: 33.7100, longitude: 73.0600),
    TwinCityArea(nameEn: 'G-8', nameUr: 'جی 8', city: 'Islamabad', latitude: 33.7000, longitude: 73.0380),
    TwinCityArea(nameEn: 'G-9', nameUr: 'جی 9', city: 'Islamabad', latitude: 33.6896, longitude: 73.0336),
    TwinCityArea(nameEn: 'G-10', nameUr: 'جی 10', city: 'Islamabad', latitude: 33.6780, longitude: 73.0120),
    TwinCityArea(nameEn: 'G-11', nameUr: 'جی 11', city: 'Islamabad', latitude: 33.6682, longitude: 72.9975),
    TwinCityArea(nameEn: 'I-8', nameUr: 'آئی 8', city: 'Islamabad', latitude: 33.6689, longitude: 73.0747),
    TwinCityArea(nameEn: 'I-9', nameUr: 'آئی 9', city: 'Islamabad', latitude: 33.6550, longitude: 73.0500),
    TwinCityArea(nameEn: 'I-10', nameUr: 'آئی 10', city: 'Islamabad', latitude: 33.6450, longitude: 73.0350),
    TwinCityArea(nameEn: 'E-11', nameUr: 'ای 11', city: 'Islamabad', latitude: 33.7020, longitude: 72.9750),
    TwinCityArea(nameEn: 'Bahria Town Islamabad', nameUr: 'بحریہ ٹاؤن اسلام آباد', city: 'Islamabad', latitude: 33.5350, longitude: 73.1100),
    TwinCityArea(nameEn: 'DHA Phase 2', nameUr: 'ڈی ایچ اے فیز 2', city: 'Islamabad', latitude: 33.5180, longitude: 73.1550),

    // Rawalpindi
    TwinCityArea(nameEn: 'Saddar', nameUr: 'صدر', city: 'Rawalpindi', latitude: 33.5950, longitude: 73.0540),
    TwinCityArea(nameEn: 'Satellite Town', nameUr: 'سیٹلائٹ ٹاؤن', city: 'Rawalpindi', latitude: 33.6380, longitude: 73.0680),
    TwinCityArea(nameEn: 'Commercial Market', nameUr: 'کمرشل مارکیٹ', city: 'Rawalpindi', latitude: 33.6360, longitude: 73.0700),
    TwinCityArea(nameEn: 'Westridge', nameUr: 'ویسٹریج', city: 'Rawalpindi', latitude: 33.6060, longitude: 73.0200),
    TwinCityArea(nameEn: 'Chaklala Scheme III', nameUr: 'چکلالہ سکیم 3', city: 'Rawalpindi', latitude: 33.5850, longitude: 73.0900),
    TwinCityArea(nameEn: 'Raja Bazaar', nameUr: 'راجہ بازار', city: 'Rawalpindi', latitude: 33.6150, longitude: 73.0550),
    TwinCityArea(nameEn: 'Peshawar Road', nameUr: 'پشاور روڈ', city: 'Rawalpindi', latitude: 33.6120, longitude: 73.0100),
    TwinCityArea(nameEn: 'Bahria Town Rawalpindi', nameUr: 'بحریہ ٹاؤن راولپنڈی', city: 'Rawalpindi', latitude: 33.5350, longitude: 73.1100),
    TwinCityArea(nameEn: 'Shamsabad', nameUr: 'شمس آباد', city: 'Rawalpindi', latitude: 33.6480, longitude: 73.0800),
    TwinCityArea(nameEn: 'Adyala Road', nameUr: 'اڈیالہ روڈ', city: 'Rawalpindi', latitude: 33.5480, longitude: 73.0420),
  ];

  final ValueNotifier<AppLocation> currentLocationNotifier = ValueNotifier<AppLocation>(
    const AppLocation(
      latitude: 33.7215,
      longitude: 73.0563,
      city: 'Islamabad',
      area: 'F-7',
      fullAddress: 'F-7, Islamabad',
      isInsideTwinCities: true,
    ),
  );

  bool _initialized = false;
  bool _promptingUser = false;

  AppLocation get currentLocation => currentLocationNotifier.value;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final lat = prefs.getDouble('user_latitude');
      final lng = prefs.getDouble('user_longitude');
      final city = prefs.getString('user_city');
      final area = prefs.getString('user_area');
      final address = prefs.getString('user_location_address');

      if (lat != null && lng != null && city != null) {
        currentLocationNotifier.value = AppLocation(
          latitude: lat,
          longitude: lng,
          city: city,
          area: area ?? city,
          fullAddress: address ?? '$area, $city',
          isInsideTwinCities: isCoordinatesInTwinCities(lat, lng),
        );
      }
    } catch (e) {
      debugPrint('LocationService init error: $e');
    }
  }

  bool isCoordinatesInTwinCities(double lat, double lng) {
    return lat >= minLat && lat <= maxLat && lng >= minLng && lng <= maxLng;
  }

  bool isAddressInTwinCities(String address) {
    final lower = address.toLowerCase();
    return lower.contains('islamabad') ||
        lower.contains('rawalpindi') ||
        lower.contains('pindi') ||
        lower.contains('federal capital');
  }

  TwinCityArea findNearestArea(double lat, double lng) {
    TwinCityArea nearest = supportedAreas.first;
    double minDistance = double.infinity;

    for (final area in supportedAreas) {
      final d = _haversineDistance(lat, lng, area.latitude, area.longitude);
      if (d < minDistance) {
        minDistance = d;
        nearest = area;
      }
    }
    return nearest;
  }

  double _haversineDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295; // pi / 180
    final a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }

  /// Reverse geocode coordinates to extract locality, area, city, and formatted address.
  Future<AppLocation> reverseGeocode(double lat, double lng) async {
    final isWithinBounds = isCoordinatesInTwinCities(lat, lng);
    String detectedCity = lat > 33.64 ? 'Islamabad' : 'Rawalpindi';
    String detectedArea = '';
    String formattedAddress = '';

    try {
      // 1. Google Maps Geocoding API
      final uri = Uri.parse(
          'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$googleApiKey');
      final res = await http.get(uri).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['status'] == 'OK' && (data['results'] as List).isNotEmpty) {
          final first = data['results'][0];
          formattedAddress = first['formatted_address']?.toString() ?? '';

          final components = first['address_components'] as List? ?? [];
          for (final c in components) {
            final types = (c['types'] as List? ?? []).cast<String>();
            final longName = c['long_name']?.toString() ?? '';

            if (types.contains('locality') || types.contains('administrative_area_level_2')) {
              if (longName.toLowerCase().contains('islamabad')) {
                detectedCity = 'Islamabad';
              } else if (longName.toLowerCase().contains('rawalpindi')) {
                detectedCity = 'Rawalpindi';
              }
            }
            if (types.contains('sublocality') ||
                types.contains('sublocality_level_1') ||
                types.contains('neighborhood')) {
              if (detectedArea.isEmpty) {
                detectedArea = longName;
              }
            }
          }
        }
      }
    } catch (_) {}

    // Fallback if area wasn't extracted from Google or reverse geocode failed
    if (detectedArea.isEmpty || formattedAddress.isEmpty) {
      final nearest = findNearestArea(lat, lng);
      detectedArea = nearest.nameEn;
      detectedCity = nearest.city;
      formattedAddress = '$detectedArea, $detectedCity';
    }

    final insideTwinCities = isWithinBounds || isAddressInTwinCities(formattedAddress);

    return AppLocation(
      latitude: lat,
      longitude: lng,
      city: detectedCity,
      area: detectedArea,
      fullAddress: formattedAddress,
      isInsideTwinCities: insideTwinCities,
    );
  }

  /// Saves the resolved location in memory, SharedPreferences, and Firestore.
  Future<void> saveLocation(AppLocation loc, {bool updateFirestore = true}) async {
    currentLocationNotifier.value = loc;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('user_latitude', loc.latitude);
      await prefs.setDouble('user_longitude', loc.longitude);
      await prefs.setString('user_city', loc.city);
      await prefs.setString('user_area', loc.area);
      await prefs.setString('user_location_address', loc.fullAddress);
      await prefs.setBool('user_location_granted', true);
    } catch (_) {}

    if (updateFirestore) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
            'latitude': loc.latitude,
            'longitude': loc.longitude,
            'city': loc.city,
            'area': loc.area,
            'locationAddress': loc.fullAddress,
            'isInsideTwinCities': loc.isInsideTwinCities,
            'locationUpdatedAt': FieldValue.serverTimestamp(),
          });
        } catch (_) {}
      }
    }
  }

  /// Checks if location permission has already been granted.
  Future<bool> hasLocationPermission() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return false;
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always || permission == LocationPermission.whileInUse;
  }

  /// Automatically requests permission, fetches GPS position, checks twin cities restriction,
  /// and updates Firestore + dashboards.
  Future<AppLocation?> fetchCurrentGpsLocation({
    BuildContext? context,
    bool showCityPickerIfOutside = true,
  }) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (context != null && context.mounted) {
        final opened = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Location Services Disabled'),
            content: const Text(
                'Please turn on GPS/Location in your device settings to get real-time location in Rawalpindi & Islamabad.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  Geolocator.openLocationSettings();
                  Navigator.pop(ctx, true);
                },
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );
        if (opened != true) return null;
      } else {
        return null;
      }
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      if (context != null && context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Location Permission Required'),
            content: const Text(
                'Location access is permanently denied. Please enable it in App Settings to use real-time coordinates.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              FilledButton(
                onPressed: () {
                  Geolocator.openAppSettings();
                  Navigator.pop(ctx);
                },
                child: const Text('App Settings'),
              ),
            ],
          ),
        );
      }
      return null;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      final loc = await reverseGeocode(position.latitude, position.longitude);

      if (!loc.isInsideTwinCities && showCityPickerIfOutside && context != null && context.mounted) {
        // Outside Rawalpindi / Islamabad
        await showOutsideServiceAreaDialog(context, loc);
        return currentLocationNotifier.value;
      }

      await saveLocation(loc);
      return loc;
    } catch (e) {
      debugPrint('Error getting GPS position: $e');
      return null;
    }
  }

  /// Ensures user has configured location upon account creation / landing page.
  /// If location is not enabled, presents prompt dialog.
  Future<void> ensureLocationReady(BuildContext context) async {
    if (_promptingUser) return;
    await initialize();

    final hasPerm = await hasLocationPermission();
    final prefs = await SharedPreferences.getInstance();
    final askedBefore = prefs.getBool('location_prompted_once') ?? false;

    if (hasPerm) {
      // Silently fetch fresh GPS location
      fetchCurrentGpsLocation(context: null, showCityPickerIfOutside: false);
      return;
    }

    if (!askedBefore) {
      _promptingUser = true;
      await prefs.setBool('location_prompted_once', true);
      if (context.mounted) {
        await showLocationPromptSheet(context);
      }
      _promptingUser = false;
    }
  }

  /// Displays the location permission modal explaining twin cities exclusivity.
  Future<void> showLocationPromptSheet(BuildContext context) async {
    final isUrdu = Localizations.localeOf(context).languageCode == 'ur';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: const Color(0xFF0D9488).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_on,
                  color: Color(0xFF0D9488),
                  size: 38,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isUrdu ? 'اپنا مقام منتخب کریں' : 'Enable Real Location',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.info_outline, color: Color(0xFFD97706), size: 16),
                    const SizedBox(width: 6),
                    Text(
                      isUrdu
                          ? 'صرف راولپنڈی اور اسلام آباد کے لیے دستیاب ہے'
                          : 'Available for Rawalpindi & Islamabad only',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF92400E),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                isUrdu
                    ? 'مزدور لنک آپ کو راولپنڈی اور اسلام آباد میں قریبی مصدقہ ورکرز اور جابز سے جوڑتا ہے۔ درست فاصلے اور بروقت سروس کے لیے لوکیشن فعال کریں۔'
                    : 'MazdoorLink connects you with verified workers and jobs across Rawalpindi & Islamabad. Enable your device location for live proximity tracking.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Colors.black54, height: 1.4),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await fetchCurrentGpsLocation(context: context);
                  },
                  icon: const Icon(Icons.my_location, size: 20),
                  label: Text(
                    isUrdu ? 'موجودہ لوکیشن حاصل کریں (GPS)' : 'Use Current GPS Location',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0D9488),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    showAreaPickerDialog(context);
                  },
                  icon: const Icon(Icons.list_alt, size: 18, color: Color(0xFF0D9488)),
                  label: Text(
                    isUrdu ? 'شہر اور علاقہ خود منتخب کریں' : 'Select Islamabad / Rawalpindi Area',
                    style: const TextStyle(color: Color(0xFF0D9488), fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF0D9488)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Informs the user they are outside Rawalpindi / Islamabad and prompts area choice.
  Future<void> showOutsideServiceAreaDialog(BuildContext context, AppLocation detectedLoc) async {
    final isUrdu = Localizations.localeOf(context).languageCode == 'ur';

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isUrdu ? 'سروس کا دائرہ کار' : 'Service Zone Notice',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isUrdu
                  ? 'آپ کا موجودہ مقام (${detectedLoc.fullAddress.isNotEmpty ? detectedLoc.fullAddress : detectedLoc.city}) راولپنڈی اور اسلام آباد سے باہر ہے۔\n\nمزدور لنک فی الحال صرف جڑواں شہروں (راولپنڈی اور اسلام آباد) میں فعال ہے۔ جاری رکھنے کے لیے اپنا ورکنگ ایریا منتخب کریں۔'
                  : 'Your detected location (${detectedLoc.shortDisplayName}) is outside our active service zone.\n\nMazdoorLink is currently available specifically in Rawalpindi & Islamabad. Please choose your primary service hub to continue.',
              style: const TextStyle(fontSize: 13, height: 1.45, color: Colors.black87),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              showAreaPickerDialog(context);
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0D9488),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(isUrdu ? 'راولپنڈی / اسلام آباد علاقہ منتخب کریں' : 'Choose Operating Area'),
          ),
        ],
      ),
    );
  }

  /// Dialog or bottom sheet to pick a sector/area from Islamabad or Rawalpindi.
  Future<void> showAreaPickerDialog(BuildContext context) async {
    final isUrdu = Localizations.localeOf(context).languageCode == 'ur';
    String selectedCity = 'Islamabad';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final filteredAreas = supportedAreas.where((a) => a.city == selectedCity).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.72,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isUrdu ? 'شہر اور علاقہ منتخب کریں' : 'Select Service Area',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // City selector tabs: Islamabad vs Rawalpindi
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setSheetState(() => selectedCity = 'Islamabad'),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: selectedCity == 'Islamabad'
                                  ? const Color(0xFF0D9488)
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                isUrdu ? 'اسلام آباد' : 'Islamabad',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: selectedCity == 'Islamabad' ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () => setSheetState(() => selectedCity = 'Rawalpindi'),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: selectedCity == 'Rawalpindi'
                                  ? const Color(0xFF0D9488)
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                isUrdu ? 'راولپنڈی' : 'Rawalpindi',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: selectedCity == 'Rawalpindi' ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: ListView.separated(
                      itemCount: filteredAreas.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final a = filteredAreas[i];
                        final isCurrent = currentLocationNotifier.value.area == a.nameEn;

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          leading: CircleAvatar(
                            backgroundColor: isCurrent
                                ? const Color(0xFF0D9488)
                                : const Color(0xFF0D9488).withValues(alpha: 0.1),
                            child: Icon(
                              Icons.location_on,
                              color: isCurrent ? Colors.white : const Color(0xFF0D9488),
                              size: 18,
                            ),
                          ),
                          title: Text(
                            isUrdu ? a.nameUr : a.nameEn,
                            style: TextStyle(
                              fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                              color: isCurrent ? const Color(0xFF0D9488) : Colors.black87,
                            ),
                          ),
                          subtitle: Text('${a.city}, Pakistan', style: const TextStyle(fontSize: 12)),
                          trailing: isCurrent
                              ? const Icon(Icons.check_circle, color: Color(0xFF0D9488))
                              : const Icon(Icons.chevron_right, color: Colors.black26),
                          onTap: () async {
                            final chosenLoc = AppLocation(
                              latitude: a.latitude,
                              longitude: a.longitude,
                              city: a.city,
                              area: a.nameEn,
                              fullAddress: '${a.nameEn}, ${a.city}',
                              isInsideTwinCities: true,
                            );
                            await saveLocation(chosenLoc);
                            if (context.mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isUrdu
                                        ? 'مقام کامیابی سے ${a.nameUr}، ${a.city == "Islamabad" ? "اسلام آباد" : "راولپنڈی"} پر تبدیل ہو گیا'
                                        : 'Location updated to ${a.nameEn}, ${a.city}',
                                  ),
                                  duration: const Duration(seconds: 3),
                                  backgroundColor: const Color(0xFF0D9488),
                                ),
                              );
                            }
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Checks whether device location service is enabled AND location permission is granted.
  Future<bool> isLocationEnabledAndPermitted() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always || permission == LocationPermission.whileInUse;
  }

  /// Verifies location status for a worker attempting to toggle online.
  /// If location is not on, displays dialog and prevents going online.
  /// If location is on, updates live coordinates and returns true.
  Future<bool> verifyWorkerLocationForOnline(BuildContext context) async {
    final isUrdu = Localizations.localeOf(context).languageCode == 'ur';
    final hasPermission = await isLocationEnabledAndPermitted();

    if (!hasPermission) {
      if (!context.mounted) return false;

      final shouldEnable = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.location_off, color: Colors.red, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isUrdu ? 'لوکیشن آن ہونا لازمی ہے' : 'Location Required to Go Online',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Text(
            isUrdu
                ? 'آپ لوکیشن آن کیے بغیر آن لائن نہیں ہو سکتے۔ راولپنڈی اور اسلام آباد میں گاہکوں سے جابز حاصل کرنے کے لیے اپنی ڈیوائس لوکیشن آن کریں۔'
                : 'You cannot go online without enabling your location. MazdoorLink requires your active coordinates in Rawalpindi & Islamabad to match you with customers.',
            style: const TextStyle(fontSize: 13, height: 1.45, color: Colors.black87),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(isUrdu ? 'منسوخ' : 'Cancel'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.pop(ctx, true),
              icon: const Icon(Icons.my_location, size: 18),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0D9488),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              label: Text(isUrdu ? 'لوکیشن فعال کریں' : 'Turn On Location'),
            ),
          ],
        ),
      );

      if (shouldEnable != true) {
        return false;
      }

      // Try fetching GPS position now
      if (!context.mounted) return false;
      final loc = await fetchCurrentGpsLocation(context: context);
      return loc != null;
    }

    // Location is permitted and enabled - fetch fresh coordinates
    try {
      final loc = await fetchCurrentGpsLocation(context: context, showCityPickerIfOutside: true);
      return loc != null;
    } catch (_) {
      return true;
    }
  }
}
