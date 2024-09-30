import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socialdownloader/models/video_model.dart';
import 'package:socialdownloader/services/video_service.dart';

class VideoNotifier extends StateNotifier<VideoModel?> {
  VideoNotifier() : super(null);

  Future<void> getVideoDetails(String videoUrl) async {
    final videoDetails = await VideoService.getVideoDetails(videoUrl);
    state = videoDetails;
  }

  Future<void> downloadAndSaveVideo() async {
    if (state == null) return;
    await VideoService.downloadVideo(state!.videoUrl, state!.title);
  }
}

final videoProvider = StateNotifierProvider<VideoNotifier, VideoModel?>((ref) {
  return VideoNotifier();
});
