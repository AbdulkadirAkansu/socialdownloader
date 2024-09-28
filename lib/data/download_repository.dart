import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'package:socialdownloader/core/utils/permission_service.dart';

class DownloadRepository {
  final Dio _dio = Dio();

Future<void> downloadVideo(BuildContext context, String mediaUrl) async {
  try {
    debugPrint("Depolama izni kontrol ediliyor...");
    
    bool permissionGranted = await PermissionService.requestStoragePermission();
    if (!permissionGranted) {
      throw FileSystemException('Depolama izni verilmedi.');
    }

    debugPrint("Depolama izni verildi. Video indiriliyor...");

    Response response = await _dio.get(
      mediaUrl,
      options: Options(responseType: ResponseType.bytes),
    );

    debugPrint("Video indirildi. Dosya kaydediliyor...");

    Directory directory = Directory('/storage/emulated/0/Download');
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    String fileName = 'downloaded_video_${DateTime.now().millisecondsSinceEpoch}.mp4';
    String filePath = '${directory.path}/$fileName';

    File file = File(filePath);
    await file.writeAsBytes(response.data);
    debugPrint("Video başarıyla kaydedildi: $filePath");

    await _triggerMediaScanner(filePath); // Medya tarayıcıyı tetikle

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Video başarıyla indirildi: $filePath')),
    );
  } catch (e) {
    debugPrint("Hata: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('İndirme sırasında hata oluştu: ${e.toString()}')),
    );
  }
}


  Future<void> _triggerMediaScanner(String filePath) async {
    const platform = MethodChannel('com.example.socialdownloader/mediaScanner');
    try {
      await platform.invokeMethod('scanMedia', {'filePath': filePath});
      debugPrint('Medya tarayıcı başarıyla tetiklendi: $filePath');
    } catch (e) {
      debugPrint('Medya tarayıcı tetikleme hatası: $e');
    }
  }
}
