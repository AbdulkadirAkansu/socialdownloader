import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:socialdownloader/data/download_repository.dart';

class DownloaderPage extends StatefulWidget {
  @override
  _DownloaderPageState createState() => _DownloaderPageState();
}

class _DownloaderPageState extends State<DownloaderPage> {
  final TextEditingController _urlController = TextEditingController();
  YoutubePlayerController? _youtubePlayerController;
  bool _isVideoLoaded = false;
  final DownloadRepository _downloadRepository = DownloadRepository();

  Future<void> _initializeYouTubePlayer(String videoUrl) async {
    final videoId = YoutubePlayer.convertUrlToId(videoUrl);
    if (videoId != null) {
      _youtubePlayerController = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: false,
          mute: false,
        ),
      );
      setState(() {
        _isVideoLoaded = true;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Geçersiz YouTube URL\'si')),
      );
    }
  }

  Future<void> _downloadVideoToStorage() async {
    if (_youtubePlayerController != null && _urlController.text.isNotEmpty) {
      await _downloadRepository.downloadVideo(context, _urlController.text);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen geçerli bir YouTube URL\'si girin.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('YouTube Video Downloader')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(labelText: 'YouTube Video URL'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _initializeYouTubePlayer(_urlController.text),
              child: const Text('Videoyu Oynat'),
            ),
            const SizedBox(height: 20),
            _isVideoLoaded && _youtubePlayerController != null
                ? Column(
                    children: [
                      YoutubePlayer(controller: _youtubePlayerController!),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _downloadVideoToStorage,
                        child: const Text('Videoyu İndir'),
                      ),
                    ],
                  )
                : const Text("Geçerli bir video URL'si girin"),
          ],
        ),
      ),
    );
  }
}
