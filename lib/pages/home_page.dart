import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socialdownloader/providers/video_provider.dart';
import 'package:socialdownloader/widgets/video_player_widget.dart';
import 'package:socialdownloader/models/video_model.dart';
import 'package:socialdownloader/services/video_service.dart';
import 'package:socialdownloader/services/permission_service.dart';

class HomePage extends ConsumerStatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final TextEditingController _urlController = TextEditingController();
  double _downloadProgress = 0;
  bool _isDownloading = false;
  String _downloadStatus = '';
  String _videoUrl = '';

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final videoNotifier = ref.read(videoProvider.notifier);
    final videoState = ref.watch(videoProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: _buildBody(context, videoState, videoNotifier),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.red,
      title: Text(
        'YouTube Video Downloader',
        style: TextStyle(color: Colors.white),
      ),
      centerTitle: true,
    );
  }

  Widget _buildBody(BuildContext context, VideoModel? videoState, VideoNotifier videoNotifier) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildUrlTextField(videoNotifier),
              SizedBox(height: 20),
              if (videoState != null) _buildVideoContent(videoState, context),
              SizedBox(height: 20),
              _buildDownloadProgress(),
              if (_downloadProgress == 1) _buildRestartText(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUrlTextField(VideoNotifier videoNotifier) {
    return TextField(
      controller: _urlController,
      decoration: InputDecoration(
        labelText: 'Enter YouTube Video URL',
        labelStyle: TextStyle(color: Colors.red),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.red),
        ),
      ),
      onSubmitted: (value) async {
        videoNotifier.clearVideoDetails();
        PermissionService.resetPermissions();

        bool hasPermission = await PermissionService.requestAllPermissions();
        if (!hasPermission) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Required permissions not granted.')),
          );
          return;
        }

        videoNotifier.getVideoDetails(_urlController.text);
        if (mounted) {
          setState(() {
            _downloadProgress = 0;
            _downloadStatus = '';
            _isDownloading = false;
          });
        }
      },
    );
  }

  Widget _buildVideoContent(VideoModel video, BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16.0),
          child: VideoPlayerWidget(video.videoUrl),
        ),
        SizedBox(height: 20),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.red,
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () async {
            bool hasPermission = await PermissionService.requestAllPermissions();
            if (!hasPermission) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Required permissions not granted.')),
              );
              return;
            }

            await VideoService.showFormatSelectionDialog(
              context,
              video.videoUrl,
              (progress) {
                if (mounted) {
                  setState(() {
                    _isDownloading = progress < 1.0;
                    _downloadProgress = progress;
                    if (progress == 1.0) {
                      _downloadStatus = 'Download completed!';
                    }
                  });
                }
              },
            );
          },
          child: Text('Select Format and Download'),
        ),
      ],
    );
  }

  Widget _buildDownloadProgress() {
    return Column(
      children: [
        if (_isDownloading)
          Column(
            children: [
              LinearProgressIndicator(
                value: _downloadProgress,
                backgroundColor: Colors.grey[300],
                color: Colors.red,
              ),
              SizedBox(height: 10),
              Text(
                'Download progress: ${(_downloadProgress * 100).toStringAsFixed(0)}%',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        if (_downloadProgress == 1) Text(_downloadStatus),
      ],
    );
  }

  Widget _buildRestartText(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _restartApp(context);  
      },
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          'Click here to download again',
          style: TextStyle(
            color: Colors.blue,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }

  void _restartApp(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => HomePage()),
      (Route<dynamic> route) => false,
    );
  }
}
