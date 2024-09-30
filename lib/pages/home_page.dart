import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socialdownloader/models/video_model.dart';
import 'package:socialdownloader/providers/video_provider.dart';
import 'package:socialdownloader/services/video_service.dart';
import 'package:socialdownloader/widgets/video_player_widget.dart';

class HomePage extends ConsumerStatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final TextEditingController _urlController = TextEditingController();
  double _downloadProgress = 0;
  bool _isDownloading = false;
  String _downloadStatus = '';

  @override
  Widget build(BuildContext context) {
    final videoState = ref.watch(videoProvider);
    final videoNotifier = ref.read(videoProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text('YouTube Video İndirici'),
      ),
      resizeToAvoidBottomInset: true, // Klavye çıkınca düzeni bozmamak için
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildUrlTextField(videoNotifier),
            SizedBox(height: 20),
            if (videoState != null) _buildVideoContent(videoState, context),
            SizedBox(height: 20),
            _buildDownloadProgress(),
          ],
        ),
      ),
    );
  }

  // TextField sıfırlama ve yeni video detaylarını alma
  Widget _buildUrlTextField(VideoNotifier videoNotifier) {
    return TextField(
      controller: _urlController,
      decoration: InputDecoration(
        labelText: 'YouTube Video URL',
        border: OutlineInputBorder(),
      ),
      onSubmitted: (value) {
        videoNotifier.getVideoDetails(_urlController.text); // Yeni video bilgilerini al
        setState(() {
          _downloadProgress = 0; // İlerlemeyi sıfırla
          _downloadStatus = ''; // İndirme durumunu sıfırla
        });
      },
    );
  }

  // Video içeriği ve format seçim butonu
  Widget _buildVideoContent(VideoModel video, BuildContext context) {
    return Column(
      children: [
        VideoPlayerWidget(video.videoUrl),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: () async {
            await VideoService.showFormatSelectionDialog(
              context, 
              video.videoUrl, 
              (progress) {
                setState(() {
                  _isDownloading = true;
                  _downloadProgress = progress;
                });
              }
            );
          },
          child: Text('Format ve Kalite Seç ve İndir'),
        ),
      ],
    );
  }

  // İndirme işlemi sırasında ilerleme göstergesi
  Widget _buildDownloadProgress() {
    return Column(
      children: [
        if (_isDownloading)
          Column(
            children: [
              LinearProgressIndicator(value: _downloadProgress),
              SizedBox(height: 10),
              Text('İndirme ilerlemesi: %${(_downloadProgress * 100).toStringAsFixed(0)}'),
            ],
          ),
        if (_downloadProgress == 1) Text('İndirme tamamlandı!'),
      ],
    );
  }
}
