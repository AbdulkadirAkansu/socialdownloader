import 'package:dio/dio.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:flutter/material.dart';
import 'package:socialdownloader/models/video_model.dart';
import 'package:socialdownloader/services/permission_service.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:saver_gallery/saver_gallery.dart';
import 'package:permission_handler/permission_handler.dart';

class VideoService {
  static YoutubeExplode yt = YoutubeExplode();


  static Future<VideoModel> getVideoDetails(String videoUrl) async {
    try {
      final videoId = parseVideoId(videoUrl);
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
    if (videoId == null) throw Exception("Invalid video URL");

    final manifest = await yt.videos.streamsClient.getManifest(videoId);

    final videoStreamInfo = manifest.videoOnly.withHighestBitrate();
    final audioStreamInfo = manifest.audioOnly.withHighestBitrate();

    final dir = await getTemporaryDirectory();
    final videoSavePath = '${dir.path}/$fileName-video.mp4';
    final audioSavePath = '${dir.path}/$fileName-audio.mp3';
    final outputSavePath = '${dir.path}/$fileName-merged.mp4';

    final dio = Dio();

    await dio.download(
      videoStreamInfo.url.toString(),
      videoSavePath,
      onReceiveProgress: (received, total) {
        if (total != -1) {
          double progress = received / total;
          onProgress(progress);  
        }
      },
    );

    await dio.download(audioStreamInfo.url.toString(), audioSavePath);

    print("Merging video and audio...");

    await FFmpegKit.execute(
        "-i $videoSavePath -i $audioSavePath -c:v copy -c:a aac -strict experimental $outputSavePath");

    print("Merge completed: $outputSavePath");

    await SaverGallery.saveFile(
      file: outputSavePath,
      name: '$fileName-merged',
      androidExistNotSave: false,
      androidRelativePath: 'Movies/SocialDownloader',
    );

    print("Merged video saved successfully.");
    onProgress(1.0);  
  } catch (e) {
    print("Error during video and audio merging: $e");
    throw Exception('Error during merging: $e');
  }
}

  // Video indir
static Future<void> downloadVideo(String videoUrl, String fileName) async {
  bool hasPermission = await PermissionService.requestAllPermissions();

  if (!hasPermission) {
    print("Gerekli izinler verilmedi.");
    return; 
  }

  try {
    final videoId = parseVideoId(videoUrl);
    final manifest = await yt.videos.streamsClient.getManifest(videoId!);
    final streamInfo = manifest.muxed.withHighestBitrate();
    final dir = await getTemporaryDirectory();
    final savePath = '${dir.path}/$fileName.mp4';
    final dio = Dio();

    print("Video indirilmeye başlandı: $savePath");

    await dio.download(
      streamInfo.url.toString(),
      savePath,
    );

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


  static Future<void> downloadAudioAndVideo(
      String videoUrl, String fileName, Function(double) onProgress) async {
    try {
      final videoId = parseVideoId(videoUrl);
      final manifest = await yt.videos.streamsClient.getManifest(videoId!);

      final videoStreamInfo = manifest.videoOnly.withHighestBitrate();
      final audioStreamInfo = manifest.audioOnly.withHighestBitrate();

      // Geçici indirme yolu
      final dir = await getTemporaryDirectory();
      final videoSavePath = '${dir.path}/$fileName.mp4';
      final audioSavePath = '${dir.path}/$fileName.mp3';

      final dio = Dio();

      print("Video indirilmeye başlandı: $videoSavePath");
      await dio.download(videoStreamInfo.url.toString(), videoSavePath);
      await dio.download(audioStreamInfo.url.toString(), audioSavePath);

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


static Future<void> showFormatSelectionDialog(
    BuildContext context, String videoUrl, Function(double) onProgress) async {
  final videoId = VideoService.parseVideoId(videoUrl);
  if (videoId == null) {
    print("Video ID not found.");
    return;
  }

  try {


    final manifest = await yt.videos.streamsClient.getManifest(videoId);
    print("Manifest received: ${manifest.videoOnly}");
    final videoOnlyStreams = manifest.videoOnly

        .where((stream) => stream.container.name == 'mp4')
        .toList();
    if (videoOnlyStreams.isEmpty) {
      print("No suitable video streams found.");
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Select Format and Quality',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              Expanded(
                child: ListView(
                  children: videoOnlyStreams.map((stream) {
                    return ListTile(
                      title: Text(
                        '${stream.videoQualityLabel} - ${stream.container.name}',
                        style: TextStyle(color: Colors.black),
                      ),
                      onTap: () async {
                        Navigator.pop(context); 
                        print("Selected format: ${stream.videoQualityLabel}");

                        String fileName = 'downloaded_video_${stream.videoQualityLabel}';
                        await VideoService.downloadAndMerge(
                          videoUrl,
                          fileName,
                          onProgress,
                        );
                        onProgress(1.0);
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  } catch (e) {
    print("Error fetching quality options: $e");
  }
}


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

static Future<void> _downloadSelectedVideoAndAudio(
    BuildContext context, String videoUrl, String audioUrl, String fileType, Function(double) onProgress) async {
  final dir = await getTemporaryDirectory();
  final videoSavePath = '${dir.path}/video_download.$fileType';
  final audioSavePath = '${dir.path}/audio_download.mp3';
  final outputSavePath = '${dir.path}/video_audio_merged.mp4';
  final dio = Dio();

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

  await FFmpegKit.execute(
      "-i $videoSavePath -i $audioSavePath -c:v copy -c:a aac -strict experimental $outputSavePath");

  await SaverGallery.saveFile(
    file: outputSavePath,
    name: 'video_audio_merged',
    androidExistNotSave: false,
    androidRelativePath: 'Movies/SocialDownloader',
  );

  print("Video ve ses başarıyla birleştirildi ve kaydedildi.");
}

  static Future<String> downloadVideoWithProgress( 
      String videoUrl, String fileName, Function(double) onProgress) async {
    try {
      final dio = Dio();

      dio.options.connectTimeout = const Duration(seconds: 10);
      dio.options.receiveTimeout = const Duration(seconds: 60);

      // İndirme yolu
      final externalDir = await getTemporaryDirectory();
      final savePath = '${externalDir.path}/$fileName';

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
