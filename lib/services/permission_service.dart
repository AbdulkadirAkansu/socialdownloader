import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  // Tüm gerekli izinleri ister ve döner
  static Future<bool> requestAllPermissions() async {
    print("İzinler istenmeye başlıyor...");
    try {
      if (await _isAndroid13OrAbove()) {
        print("Android 13 veya üzeri cihaz tespit edildi.");
        return await _requestMediaPermissions();
      }

      if (await _isAndroid11Or12()) {
        print("Android 11 veya 12 tespit edildi.");
        return await _requestManageExternalStoragePermission();
      }

      print("Android 10 veya daha altı bir cihaz tespit edildi.");
      return await _requestStoragePermissions();
    } catch (e) {
      print("İzin kontrolü sırasında hata: $e");
      return false;
    }
  }

  // Android 13 ve üzeri için medya erişim izinlerini talep eder
  static Future<bool> _requestMediaPermissions() async {
    print("Android 13 için medya izinleri isteniyor...");
    Map<Permission, PermissionStatus> statuses = await [
      Permission.photos,
      Permission.videos,
      Permission.audio,
    ].request();

    print("Medya izinleri durumu: ${statuses.toString()}");

    if (statuses[Permission.photos]!.isGranted &&
        statuses[Permission.videos]!.isGranted &&
        statuses[Permission.audio]!.isGranted) {
      print("Android 13 medya izinleri verildi.");
      return true;
    } else if (statuses.values.any((status) => status.isPermanentlyDenied)) {
      print("Medya izinleri kalıcı olarak reddedildi.");
      _showPermissionDialog();
      return false;
    }

    print("Android 13 medya izinleri reddedildi.");
    return false;
  }

  // Android 11 ve 12 için MANAGE_EXTERNAL_STORAGE iznini talep eder
  static Future<bool> _requestManageExternalStoragePermission() async {
    print("Android 11/12 için MANAGE_EXTERNAL_STORAGE izni isteniyor...");
    if (await Permission.manageExternalStorage.request().isGranted) {
      print("MANAGE_EXTERNAL_STORAGE izni verildi.");
      return true;
    } else if (await Permission.manageExternalStorage.isPermanentlyDenied) {
      print("MANAGE_EXTERNAL_STORAGE izni kalıcı olarak reddedildi.");
      _showPermissionDialog();
      return false;
    }

    print("MANAGE_EXTERNAL_STORAGE izni reddedildi.");
    return false;
  }

  // Android 10 ve altı için depolama iznini talep eder
  static Future<bool> _requestStoragePermissions() async {
    print("Android 10 veya altı için depolama izni isteniyor...");
    var status = await Permission.storage.request();

    print("Depolama izni durumu: ${status.toString()}");

    if (status.isGranted) {
      print("Depolama izni verildi.");
      return true;
    } else if (status.isPermanentlyDenied) {
      print("Depolama izni kalıcı olarak reddedildi.");
      _showPermissionDialog();
      return false;
    }

    print("Depolama izni reddedildi.");
    return false;
  }

  // Android 13 ve üzeri sürümler için kontrol
  static Future<bool> _isAndroid13OrAbove() async {
    // Android 13 üzeri medya izinleri varsa true döndür
    return (await Permission.photos.isGranted ||
        await Permission.videos.isGranted ||
        await Permission.audio.isGranted);
  }

  // Android 11 ve 12 sürümleri için kontrol
  static Future<bool> _isAndroid11Or12() async {
    // Android 11 ve 12 için MANAGE_EXTERNAL_STORAGE izni varsa true döndür
    return await Permission.manageExternalStorage.isGranted;
  }

  // Kullanıcıya ayarlara yönlendiren bir diyalog gösterir
  static void _showPermissionDialog() {
    print("İzinler ayarlar sayfasından açılmalı.");
    openAppSettings();
  }
}
