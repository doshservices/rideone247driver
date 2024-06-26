import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'geo_locator_service.dart';

class GoogleMapService {
  final GeoLocationService _geoLocationService = GeoLocationService();

  // Getter for camera position
  CameraPosition? cameraPosition;

  CameraUpdate get cameraUpdate {
    return CameraUpdate.newCameraPosition(cameraPosition!);
  }

  // LatLngBounds and bounds setter
  LatLngBounds? bounds;

  setBounds(LatLng southwest, LatLng northeast) =>
      bounds = LatLngBounds(southwest: southwest, northeast: northeast);

  // Getter for current location in LatLng
  Future<LatLng?> get currentLocationLatLng async {
    final position = await _geoLocationService.getCurrentPosition();
    if (position != null) {
      return LatLng(position.latitude, position.longitude);
    }
    return null;
  }

  CameraUpdate get latlngBoundsUpdate =>
      CameraUpdate.newLatLngBounds(bounds!, 90);

  // Static CameraPosition for a default location
  static CameraPosition googlePlex = const CameraPosition(
      target: LatLng(6.5244, 3.3792), zoom: 16.67);

  // Method to get CameraPosition based on user's current location
  Future<CameraPosition> getUserLocationCameraPosition() async {
    final currentLocation = await currentLocationLatLng;
    if (currentLocation != null) {
      return CameraPosition(target: currentLocation, zoom: 16.67);
    } else {
      // If current location is not available, return a default position
      return googlePlex;
    }
  }

  // Method to convert Position to LatLng
  LatLng convertPositionToLatLng(Position position) =>
      LatLng(position.latitude, position.longitude);

//getting camera position
//   CameraPosition? cameraPosition;
//
//   CameraUpdate get cameraUpdate {
//     return CameraUpdate.newCameraPosition(cameraPosition!);
//   }
//
//   /// returns camera position based on passed latitude and longitude
// // CameraPosition cameraPos(LatLng pos) => CameraPosition(target: pos, zoom: 18);
//
//   LatLngBounds? bounds;
//
//   setBounds(LatLng southwest, LatLng northeast) =>
//       bounds = LatLngBounds(southwest: southwest, northeast: northeast);
//
//   Future<LatLng?> get currentLocationLatLng async {
//     final position = await _geoLocationService.getCurrentPosition();
//     if (position != null) {
//       return LatLng(position.latitude, position.longitude);
//     }
//     return null;
//   }
//
//   CameraUpdate get latlngBoundsUpdate =>
//       CameraUpdate.newLatLngBounds(bounds!, 90);
//
//   static CameraPosition googlePlex =
//   const CameraPosition(target: LatLng(6.5244, 3.3792), zoom: 16.67);
//
//   convertPositionToLatLng(Position position) =>
//       LatLng(position.latitude, position.longitude);

  /// for circles
  final Set<Circle> _circles = <Circle>{};

  addCircle(Circle circles) => _circles.add(circles);

  clearCircles() => _circles.clear();

  Set<Circle> mainPageCircles(Position? pos) =>
      pos == null
          ? {}
          : {
        Circle(
            circleId: const CircleId('Current'),
            strokeColor: Colors.blue,
            strokeWidth: 2,
            radius: 150,
            center: convertPositionToLatLng(pos),
            fillColor: Colors.orange.withOpacity(0.1))
      };

  /// for markers
  BitmapDescriptor? movingMarkerIcon;
  Set<Marker> _markers = <Marker>{};
  Set<Marker> get markers => _markers;

  clearMarkers() => _markers.clear();

  setMarkers(Set<Marker> markers) => _markers = markers;

  addMarkers(Marker markers) => _markers.add(markers);

  removeGeofireMarkers() {
    _markers.removeWhere((m) => m.markerId.value.contains('driver'));
  }

  final Set<Marker> _tempMarkers = <Marker>{};

  Set<Marker> get tempMarkers => _tempMarkers;

  clearTempMarkers() => _tempMarkers.clear();

  addTempMarkers(Marker marker) => _tempMarkers.add(marker);

  Marker createMarker({
    // required BitmapDescriptor icon,
    required String id,
    required LatLng position,
    String? iconPath,
    required ImageConfiguration imageConfiguration,
    double? rotation,
    String? infoTitle,
    String? snippet,
  }) {
    BitmapDescriptor bitMapIcon = BitmapDescriptor.defaultMarker;
    BitmapDescriptor.fromAssetImage(
        imageConfiguration, 'assets/svgs/check.svg')
        .then((icon) {
      bitMapIcon = icon;
    });

    return Marker(
      markerId: MarkerId('driver$id'),
      position: position,
      icon: bitMapIcon,
      rotation: rotation ?? 0.0,
      infoWindow: infoTitle != null
          ? InfoWindow(title: infoTitle, snippet: snippet)
          : InfoWindow.noText,
    );
  }

  /// driver marker
  updateDriverLocationMarker() async {
    Position position = await _geoLocationService.getCurrentPosition();
    LatLng driverLatLng = LatLng(position.latitude, position.longitude);

    BitmapDescriptor customIcon =
    await BitmapDescriptor
        .fromAssetImage(
      const ImageConfiguration(size: Size(5, 5)),
      'assets/images/driver_car.png', // Ensure this path matches your project structure
    );

    Marker driverMarker = Marker(
      markerId: const MarkerId('driver_location'),
      position: driverLatLng,
      icon: customIcon,
    );

    _markers = {driverMarker};
  }
  ///

  ///for polylines
  LatLng convertDoubleToLatLng(double latitude, double longitude) =>
      LatLng(latitude, longitude);

  static final List<LatLng> _polylineCoordinates = [];
  List<LatLng> get polylineCoordinates => _polylineCoordinates;

  clearPolyLineCoordinate() => _polylineCoordinates.clear();

  clearPolyLines() => _polyLines.clear();
  static final Set<Polyline> _polyLines = <Polyline>{};
  Set<Polyline> get polyLines => _polyLines;

    setPolyLine(List<LatLng> polylineCoordinates) {
      Polyline polyline = Polyline(
        polylineId: const PolylineId('polyid'),
        color: Colors.orange,
        points: polylineCoordinates,
        jointType: JointType.round,
        width: 4,
        startCap: Cap.customCapFromBitmap(
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed)),
        endCap: Cap.customCapFromBitmap(
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue)),
        // startCap: Cap.roundCap,
        // endCap: Cap.roundCap,
        geodesic: true,
      );

      _polyLines.add(polyline);
    }

    addPolyLine(Polyline poly) => polyLines.add(poly);

    fitPolyLineToMap({required List pickup, required List destination}) {
      double pickupLongitude = pickup[1];
      double pickupLatitude = pickup[0];
      double destinationLongitude = destination[1];
      double destinationLatitude = destination[0];

      LatLng pickupLatLng = LatLng(pickupLatitude, pickupLongitude);
      LatLng destinationLatLng =
      LatLng(destinationLatitude, destinationLongitude);

      if (pickupLatitude > destinationLatitude &&
          pickupLongitude > destinationLongitude) {
        bounds = LatLngBounds(
          southwest: LatLng(pickupLatitude, destinationLongitude),
          northeast: LatLng(destinationLatitude, pickupLongitude),
        );
      } else if (pickupLongitude > destinationLongitude) {
        bounds = LatLngBounds(
          southwest: LatLng(pickupLatitude, destinationLongitude),
          northeast: LatLng(destinationLatitude, pickupLongitude),
        );
      } else if (pickupLatitude > destinationLatitude) {
        bounds = LatLngBounds(
          southwest: LatLng(destinationLatitude, pickupLongitude),
          northeast: LatLng(pickupLatitude, destinationLongitude),
        );
      } else {
        bounds =
            LatLngBounds(southwest: pickupLatLng, northeast: destinationLatLng);
      }
    }

    ///polylines service
    List<PointLatLng> results = [];
    decodePolylines(String encodedPoints) {
      PolylinePoints lines = PolylinePoints();
      results = lines.decodePolyline(encodedPoints);
      return results;
    }
  }

