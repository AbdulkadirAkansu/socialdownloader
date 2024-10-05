import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socialdownloader/models/video_model.dart';
import 'package:socialdownloader/services/video_service.dart';
import 'package:socialdownloader/services/permission_service.dart';

class VideoNotifier extends StateNotifier<VideoModel?> {
  VideoNotifier() : super(null);

  Future<void> getVideoDetails(String videoUrl) async {
    print("Video detayları alınıyor: $videoUrl");
    state = null; // Önceki video detaylarını temizle
    final videoDetails = await VideoService.getVideoDetails(videoUrl);
    state = videoDetails;
    print("Video detayları alındı: ${videoDetails.title}");
  }

  Future<void> downloadAndSaveVideo() async {
    if (state == null) return;
    print("Video indiriliyor: ${state!.videoUrl}");
    await VideoService.downloadVideo(state!.videoUrl, state!.title);
  }

  Future<void> downloadVideo(String videoUrl, Function(double) onProgress) async {
    if (state == null) return;
    print("Video ve ses indirilmeye başlandı: $videoUrl");
    await VideoService.downloadAndMerge(videoUrl, state!.title, onProgress);
  }

  void clearVideoDetails() {
    print("Video detayları sıfırlanıyor.");
    state = null; // Video detaylarını sıfırla
  }


  void resetState() {
    print("Durum sıfırlanıyor.");
    PermissionService.resetPermissions();
    state = null; 
  }
}

final videoProvider = StateNotifierProvider<VideoNotifier, VideoModel?>((ref) {
  return VideoNotifier();
});
