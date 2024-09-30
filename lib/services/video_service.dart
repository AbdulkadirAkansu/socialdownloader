import 'package:dio/dio.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:flutter/material.dart';
import 'package:socialdownloader/models/video_model.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:saver_gallery/saver_gallery.dart';
import 'package:permission_handler/permission_handler.dart';

class VideoService {
  static YoutubeExplode yt = YoutubeExplode();

  // Video detaylarını al
  static Future<VideoModel> getVideoDetails(String videoUrl) async {
    try {
      final videoId = parseVideoId(videoUrl); // Yeniden adlandırıldı
      if (videoId == null) throw Exception("Geçersiz Video URL'si");

      final video = await yt.videos.get(videoId);
      return VideoModel(
        title: video.title,
        videoUrl: videoUrl,
        savePath: '',
      );
    } on VideoUnavailableException catch (e) {
      print('Video erişilemiyor: ${e.message}');
      throw Exception('Bu video erişilemiyor. Video mevcut olmayabilir, gizlenmiş ya da kaldırılmış olabilir.');
    } catch (e) {
      print('Video detayları alınırken bir hata oluştu: $e');
      throw Exception('Video detayları alınırken bir hata oluştu: $e');
    }
  }

 static Future<void> downloadAndMerge(String videoUrl, String fileName, Function(double) onProgress) async {
  try {
    final videoId = parseVideoId(videoUrl);
    if (videoId == null) throw Exception("Geçersiz Video URL'si");

    final manifest = await yt.videos.streamsClient.getManifest(videoId);

    // Video ve ses stream'lerini al
    final videoStreamInfo = manifest.videoOnly.withHighestBitrate();
    final audioStreamInfo = manifest.audioOnly.withHighestBitrate();

    // Geçici indirme yolu
    final dir = await getTemporaryDirectory();
    final videoSavePath = '${dir.path}/$fileName-video.mp4';
    final audioSavePath = '${dir.path}/$fileName-audio.mp3';
    final outputSavePath = '${dir.path}/$fileName-merged.mp4';

    final dio = Dio();

    // Video ve ses dosyalarını indir
    await dio.download(videoStreamInfo.url.toString(), videoSavePath);
    await dio.download(audioStreamInfo.url.toString(), audioSavePath);

    print("Video ve ses indirildi. Şimdi birleştiriliyor...");

    // Video ve sesi FFmpeg ile birleştir
    await FFmpegKit.execute(
        "-i $videoSavePath -i $audioSavePath -c:v copy -c:a aac -strict experimental $outputSavePath");

    print("Birleştirme tamamlandı: $outputSavePath");

    // Birleştirilen dosyayı galeriye kaydet
    await SaverGallery.saveFile(
      file: outputSavePath,
      name: '$fileName-merged',
      androidExistNotSave: false,
      androidRelativePath: 'Movies/SocialDownloader',
    );

    print("Birleştirilmiş video başarıyla indirildi.");
  } catch (e) {
    print("Video ve ses birleştirme hatası: $e");
    throw Exception('Video ve ses birleştirme hatası: $e');
  }
}

  // Video ID'sini URL'den al
  static String? parseVideoId(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    if (uri.host.contains('youtube.com')) {
      return uri.queryParameters['v'];
    } else if (uri.host.contains('youtu.be')) {
      return uri.pathSegments.isNotEmpty ? uri.pathSegments[0] : null;
    }
    return null;
  }

  // Video indir
  static Future<void> downloadVideo(String videoUrl, String fileName) async {
    try {
      final videoId = parseVideoId(videoUrl); // Yeniden adlandırıldı
      final manifest = await yt.videos.streamsClient.getManifest(videoId!);
      final streamInfo = manifest.muxed.withHighestBitrate(); // En yüksek bitrate ile formatı alıyoruz
      final dir = await getTemporaryDirectory();
      final savePath = '${dir.path}/$fileName.mp4';
      final dio = Dio();

      print("Video indirilmeye başlandı: $savePath");

      await dio.download(
        streamInfo.url.toString(),
        savePath,
      );

      // Video başarıyla indirildikten sonra galeriye kaydet
      await SaverGallery.saveFile(
        file: savePath,
        name: fileName,
        androidExistNotSave: false,
        androidRelativePath: 'Movies/SocialDownloader',
      );
      print("Video başarıyla indirildi ve galeriye kaydedildi.");
    } catch (e) {
      print("Video indirme hatası: $e");
      throw Exception('Video indirme hatası: $e');
    }
  }

 // Video ve ses stream'lerini ayrı alarak birleştiriyoruz
  static Future<void> downloadAudioAndVideo(
      String videoUrl, String fileName, Function(double) onProgress) async {
    try {
      final videoId = parseVideoId(videoUrl);
      final manifest = await yt.videos.streamsClient.getManifest(videoId!);

      // En yüksek çözünürlükteki video ve ses stream'lerini alıyoruz
      final videoStreamInfo = manifest.videoOnly.withHighestBitrate();
      final audioStreamInfo = manifest.audioOnly.withHighestBitrate();

      // Geçici indirme yolu
      final dir = await getTemporaryDirectory();
      final videoSavePath = '${dir.path}/$fileName.mp4';
      final audioSavePath = '${dir.path}/$fileName.mp3';

      final dio = Dio();

      // Video ve ses dosyalarını indiriyoruz
      print("Video indirilmeye başlandı: $videoSavePath");
      await dio.download(videoStreamInfo.url.toString(), videoSavePath);
      await dio.download(audioStreamInfo.url.toString(), audioSavePath);

      // İndirme ilerlemesini takip etmek için progress fonksiyonu
      dio.download(
        videoStreamInfo.url.toString(),
        videoSavePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            onProgress(received / total);
          }
        },
      );

      print("Video başarıyla indirildi: $videoSavePath");
      print("Ses başarıyla indirildi: $audioSavePath");

      // Galeriye kaydediyoruz
      await SaverGallery.saveFile(
        file: videoSavePath,
        name: '$fileName - Video',
        androidExistNotSave: false,
        androidRelativePath: 'Movies/SocialDownloader',
      );

      await SaverGallery.saveFile(
        file: audioSavePath,
        name: '$fileName - Audio',
        androidExistNotSave: false,
        androidRelativePath: 'Music/SocialDownloader',
      );

      print("Video ve ses başarıyla indirildi.");
    } catch (e) {
      print("Video ve ses indirme hatası: $e");
      throw Exception('Video ve ses indirme hatası: $e');
    }
  }

 // Format ve kalite seçimi
static Future<void> showFormatSelectionDialog(
    BuildContext context, String videoUrl, Function(double) onProgress) async {
  final videoId = parseVideoId(videoUrl);
  if (videoId == null) {
    return;
  }

  try {
    final manifest = await yt.videos.streamsClient.getManifest(videoId);
    final videoOnlyStreams = manifest.videoOnly.where((stream) => stream.container.name == 'mp4'); // Sadece MP4 formatı
    final audioOnlyStreams = manifest.audioOnly.where((stream) => stream.container.name == 'mp4'); // Sadece MP4 formatı

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Format ve Kalite Seçin'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                Text('Ses ve Video Birleşik (MP4 tercih edilir):'),
                ...videoOnlyStreams.map((stream) {
                  return ListTile(
                    title: Text('${stream.videoQualityLabel} - ${stream.container.name}'),
                    onTap: () {
                      Navigator.pop(context);
                      _downloadSelectedVideoAndAudio(
                        context,
                        stream.url.toString(),
                        audioOnlyStreams.first.url.toString(),
                        stream.container.name,
                        onProgress
                      );
                    },
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  } catch (e) {
    print('Kalite seçeneklerini alma hatası: $e');
    throw Exception('Kalite seçenekleri alınamadı: $e');
  }
}


  // Video ve sesin ayrı ayrı indirildiği birleştirme fonksiyonu
 static Future<void> _downloadSelectedVideoAndAudio(
    BuildContext context, String videoUrl, String audioUrl, String fileType, Function(double) onProgress) async {
  final dir = await getTemporaryDirectory();
  final videoSavePath = '${dir.path}/video_download.$fileType';
  final audioSavePath = '${dir.path}/audio_download.mp3';
  final outputSavePath = '${dir.path}/video_audio_merged.mp4';
  final dio = Dio();

  // Video ve ses dosyalarını indir
  await dio.download(
    videoUrl,
    videoSavePath,
    onReceiveProgress: (received, total) {
      if (total != -1) {
        onProgress(received / total);
      }
    },
  );
  await dio.download(audioUrl, audioSavePath);

  // Video ve ses birleştirilir
  await FFmpegKit.execute(
      "-i $videoSavePath -i $audioSavePath -c:v copy -c:a aac -strict experimental $outputSavePath");

  // Birleştirilmiş dosya galeriye kaydedilir
  await SaverGallery.saveFile(
    file: outputSavePath,
    name: 'video_audio_merged',
    androidExistNotSave: false,
    androidRelativePath: 'Movies/SocialDownloader',
  );

  print("Video ve ses başarıyla birleştirildi ve kaydedildi.");
}


  // Video indirme işlemi ile progress (yüzde) callback'i
  static Future<String> downloadVideoWithProgress( // Yeniden adlandırıldı
      String videoUrl, String fileName, Function(double) onProgress) async {
    try {
      final dio = Dio();

      dio.options.connectTimeout = const Duration(seconds: 10);
      dio.options.receiveTimeout = const Duration(seconds: 60);

      // İndirme yolu
      final externalDir = await getTemporaryDirectory();
      final savePath = '${externalDir.path}/$fileName';

      // İndirme işlemi başlatılıyor
      await dio.download(
        videoUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            onProgress(received / total);
          }
        },
      );

      print("Video başarıyla indirildi: $savePath");

      // Galeriye kaydetme işlemi
      await SaverGallery.saveFile(
        file: savePath,
        name: fileName,
        androidExistNotSave: false,
        androidRelativePath: 'Movies/SocialDownloader',
      );

      return savePath;
    } on DioError catch (e) {
      if (e.type == DioErrorType.connectionTimeout) {
        print("Bağlantı zaman aşımına uğradı");
      } else if (e.type == DioErrorType.receiveTimeout) {
        print("Veri alımı zaman aşımına uğradı");
      } else if (e.error is SocketException) {
        print("İnternet bağlantısı kesildi: ${e.error}");
      } else {
        print("İndirme hatası: $e");
      }
      throw Exception('Video indirme hatası: $e');
    }
  }
}
