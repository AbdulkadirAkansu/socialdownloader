import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class VideoPlayerWidget extends StatelessWidget {
  final String videoUrl;

  VideoPlayerWidget(this.videoUrl);

  @override
  Widget build(BuildContext context) {
    final videoId = YoutubePlayer.convertUrlToId(videoUrl);
    YoutubePlayerController _controller = YoutubePlayerController(
      initialVideoId: videoId!,
      flags: YoutubePlayerFlags(autoPlay: false, mute: false),
    );

    return YoutubePlayer(controller: _controller);
  }
}
