import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
static Future<bool> requestStoragePermission() async {
    try {
      // Android 11 ve üstü için MANAGE_EXTERNAL_STORAGE izni kontrolü
      if (await Permission.manageExternalStorage.request().isGranted) {
        return true;
      }
      
      // Android 10 ve altı için STORAGE izni kontrolü
      if (await Permission.storage.request().isGranted) {
        return true;
      }

      return false;
    } catch (e) {
      print("İzin kontrolü sırasında hata: $e");
      return false;
    }
  }

   static Future<void> showPermissionRationale(BuildContext context) async {
    try {
      if (await Permission.manageExternalStorage.isPermanentlyDenied) {
        print("İzin kalıcı olarak reddedilmiş. Ayarlara yönlendiriliyor...");
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Depolama İzni Gerekli"),
              content: const Text("Bu işlem için depolama izni verilmelidir. Lütfen ayarlardan izin verin."),
              actions: <Widget>[
                TextButton(
                  child: const Text("Ayarları Aç"),
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await openAppSettings();
                  },
                ),
                TextButton(
                  child: const Text("Kapat"),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      print("Ayarları açma sırasında hata: $e");
    }
  }
}