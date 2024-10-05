import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static bool _permissionsGranted = false; 
  static bool isRequestingPermissions = false; 

  static Future<bool> requestAllPermissions() async {
    if (_permissionsGranted) {
      print("İzinler zaten verildi, tekrar izin istenmiyor.");
      return true;
    }

    if (isRequestingPermissions) {
      print("Zaten bir izin isteği devam ediyor.");
      return false;
    }

    isRequestingPermissions = true; 

    try {
      if (Platform.isAndroid) {
        if (await _isAndroid13OrAbove()) {
          Map<Permission, PermissionStatus> statuses = await [
            Permission.photos,
            Permission.videos,
            Permission.audio,
          ].request();

          for (var entry in statuses.entries) {
            final permission = entry.key;
            final status = entry.value;

            if (status.isGranted) {
              print("İzin verildi: $permission");
            } else if (status.isDenied) {
              print("İzin reddedildi: $permission");
              isRequestingPermissions = false;
              return false;
            } else if (status.isPermanentlyDenied) {
              print("İzin kalıcı olarak reddedildi: $permission");
              await _showPermissionDialog(); 
              isRequestingPermissions = false;
              return false;
            }
          }
        } 
        else if (await _isAndroid11Or12()) {
          if (await Permission.manageExternalStorage.isDenied) {
            bool manageExternalStorageGranted = await _requestManageExternalStoragePermission();
            if (!manageExternalStorageGranted) {
              isRequestingPermissions = false;
              return false;
            }
          }
        } 
        else {
          Map<Permission, PermissionStatus> statuses = await [
            Permission.storage,
          ].request();

          for (var entry in statuses.entries) {
            final permission = entry.key;
            final status = entry.value;

            if (status.isGranted) {
              print("İzin verildi: $permission");
            } else if (status.isDenied) {
              print("İzin reddedildi: $permission");
              isRequestingPermissions = false;
              return false;
            } else if (status.isPermanentlyDenied) {
              print("İzin kalıcı olarak reddedildi: $permission");
              await _showPermissionDialog(); 
              isRequestingPermissions = false;
              return false;
            }
          }
        }
      }

      _permissionsGranted = true; 
      isRequestingPermissions = false;
      return true;
    } catch (e) {
      print("İzin isteği sırasında bir hata oluştu: $e");
      isRequestingPermissions = false;
      return false;
    }
  }

  static Future<bool> _isAndroid13OrAbove() async {
    return Platform.version.contains('13') || Platform.version.contains('14');
  }

  static Future<bool> _isAndroid11Or12() async {
    return Platform.version.contains('11') || Platform.version.contains('12');
  }

  static Future<bool> _requestManageExternalStoragePermission() async {
    if (await Permission.manageExternalStorage.isGranted) {
      return true;
    } else {
      return await openAppSettings(); 
    }
  }

  static Future<void> _showPermissionDialog() async {
    await openAppSettings(); 
  }
  
  static void resetPermissions() {
    _permissionsGranted = false;
    print("İzinler sıfırlandı.");
  }
}
