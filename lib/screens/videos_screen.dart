import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import '../widgets/video_grid_item.dart';
import '../widgets/fullscreen_video_viewer.dart';
import '../widgets/banner_ad_widget.dart';

class VideosScreen extends StatefulWidget {
  const VideosScreen({super.key});

  @override
  State<VideosScreen> createState() => _VideosScreenState();
}

class _VideosScreenState extends State<VideosScreen> {
  List<AssetEntity> _videos = [];
  Map<String, List<AssetEntity>> _videosByDate = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final albums = await PhotoManager.getAssetPathList(
        type: RequestType.video,
        hasAll: true,
      );

      if (albums.isNotEmpty) {
        final recentAlbum = albums.first;
        final videos = await recentAlbum.getAssetListPaged(
          page: 0,
          size: 1000,
        );

        setState(() {
          _videos = videos;
          _groupVideosByDate();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _error = '動画が見つかりません';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = '動画の読み込みに失敗しました: $e';
      });
    }
  }

  void _groupVideosByDate() {
    _videosByDate.clear();
    for (final video in _videos) {
      final date = DateFormat('yyyy年MM月dd日').format(video.createDateTime);
      _videosByDate.putIfAbsent(date, () => []).add(video);
    }
  }

  void _deleteVideo(AssetEntity video) async {
    try {
      // 権限の確認
      final permission = await Permission.storage.request();

      if (!permission.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ストレージへのアクセス権限が必要です')),
          );
        }
        return;
      }

      // ファイルの削除を試行
      final file = await video.originFile;
      if (file != null && await file.exists()) {
        await file.delete();

        setState(() {
          _videos.remove(video);
          _groupVideosByDate();
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('動画を削除しました')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('動画の削除に失敗しました')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('削除に失敗しました: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ムービー'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadVideos,
          ),
        ],
      ),
      body: Column(
        children: [
          const BannerAdWidget(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadVideos,
              child: const Text('再試行'),
            ),
          ],
        ),
      );
    }

    if (_videosByDate.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.video_library_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              '動画がありません',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadVideos,
      child: ListView.builder(
        itemCount: _videosByDate.length,
        itemBuilder: (context, index) {
          final date = _videosByDate.keys.elementAt(index);
          final videos = _videosByDate[date]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  date,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 2,
                  mainAxisSpacing: 2,
                  childAspectRatio: 1,
                ),
                itemCount: videos.length,
                itemBuilder: (context, index) {
                  final video = videos[index];
                  return VideoGridItem(
                    video: video,
                    onTap: () => _showFullscreenVideo(videos, index),
                    onDelete: () => _deleteVideo(video),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }

  void _showFullscreenVideo(List<AssetEntity> videos, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullscreenVideoViewer(
          videos: videos,
          initialIndex: initialIndex,
          onDelete: (video) {
            _deleteVideo(video);
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }
}
