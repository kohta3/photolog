import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import '../widgets/video_grid_item.dart';
import '../widgets/fullscreen_video_viewer.dart';
import '../widgets/banner_ad_widget.dart';
import '../services/permission_service.dart';

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
  final PermissionService _permissionService = PermissionService.instance;

  // 選択モード関連
  bool _isSelectionMode = false;
  Set<String> _selectedVideos = {};

  @override
  void initState() {
    super.initState();
    _permissionService.addListener(_onPermissionChanged);
    _checkPermissionAndLoadVideos();
  }

  @override
  void dispose() {
    _permissionService.removeListener(_onPermissionChanged);
    super.dispose();
  }

  void _onPermissionChanged() {
    if (_permissionService.hasPermission && mounted) {
      _loadVideos();
    }
  }

  Future<void> _checkPermissionAndLoadVideos() async {
    if (_permissionService.hasPermission) {
      _loadVideos();
    } else {
      setState(() {
        _isLoading = false;
        _error = '動画へのアクセス権限が必要です';
      });
    }
  }

  // 選択モードの制御
  void _toggleSelectionMode() {
    if (!mounted) return;

    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedVideos.clear();
      }
    });
  }

  void _toggleVideoSelection(String videoId) {
    if (!mounted) return;

    setState(() {
      if (_selectedVideos.contains(videoId)) {
        _selectedVideos.remove(videoId);
      } else {
        _selectedVideos.add(videoId);
      }
    });
  }

  // 一括削除機能
  Future<void> _deleteSelectedVideos() async {
    if (_selectedVideos.isEmpty) return;

    try {
      // Android 13以降では写真権限を確認
      PermissionStatus permissionStatus;
      try {
        permissionStatus = await Permission.photos.request();
      } catch (e) {
        // Android 12以前ではストレージ権限を使用
        permissionStatus = await Permission.storage.request();
      }

      if (!permissionStatus.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('動画へのアクセス権限が必要です')),
          );
        }
        return;
      }

      // 選択された動画を削除
      final selectedVideoIds = _selectedVideos.toList();
      final result = await PhotoManager.editor.deleteWithIds(selectedVideoIds);
      print('一括削除結果: $result');

      if (result.isNotEmpty) {
        setState(() {
          // 削除された動画をリストから除外
          _videos.removeWhere((video) => _selectedVideos.contains(video.id));
          _groupVideosByDate();
          _selectedVideos.clear();
          _isSelectionMode = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${result.length}本の動画を削除しました')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('削除に失敗しました')),
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
      // Android 13以降では写真権限を確認
      PermissionStatus permissionStatus;
      try {
        permissionStatus = await Permission.photos.request();
      } catch (e) {
        // Android 12以前ではストレージ権限を使用
        permissionStatus = await Permission.storage.request();
      }

      if (!permissionStatus.isGranted) {
        if (mounted) {
          print('動画へのアクセス権限が必要です');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('動画へのアクセス権限が必要です')),
          );
        }
        return;
      }

      // photo_managerを使用してアセットを削除
      final result = await PhotoManager.editor.deleteWithIds([video.id]);
      print('削除結果: $result');

      // 削除が成功した場合（resultが空でない、または削除されたIDが含まれている）
      if (result.isNotEmpty) {
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
        // 削除が失敗した場合でも、UIからは削除してユーザー体験を向上させる
        setState(() {
          _videos.remove(video);
          _groupVideosByDate();
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('動画を削除しました（一部のファイルは残っている可能性があります）')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        print('削除に失敗しました: $e');
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
        title: _isSelectionMode
            ? Text('${_selectedVideos.length}件選択中')
            : const Text('ムービー'),
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _toggleSelectionMode,
              )
            : null,
        actions: _isSelectionMode
            ? [
                if (_selectedVideos.isNotEmpty) ...[
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: _selectedVideos.isNotEmpty
                        ? _deleteSelectedVideos
                        : null,
                  ),
                ],
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.checklist),
                  onPressed: _toggleSelectionMode,
                ),
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
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadVideos,
              child: const Text('再試行'),
            ),
            if (_error!.contains('権限')) const SizedBox(height: 8),
            if (_error!.contains('権限'))
              ElevatedButton(
                onPressed: () async {
                  await _permissionService.checkPermission();
                },
                child: const Text('権限を再確認'),
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
                    onLongPress: () => _toggleSelectionMode(),
                    isSelectionMode: _isSelectionMode,
                    isSelected: _selectedVideos.contains(video.id),
                    onSelectionToggle: () => _toggleVideoSelection(video.id),
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
