import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import '../widgets/photo_grid_item.dart';
import '../widgets/fullscreen_photo_viewer.dart';
import '../widgets/banner_ad_widget.dart';

class PhotosScreen extends StatefulWidget {
  const PhotosScreen({super.key});

  @override
  State<PhotosScreen> createState() => _PhotosScreenState();
}

class _PhotosScreenState extends State<PhotosScreen> {
  List<AssetEntity> _photos = [];
  Map<String, List<AssetEntity>> _photosByDate = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final albums = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        hasAll: true,
      );

      if (albums.isNotEmpty) {
        final recentAlbum = albums.first;
        final photos = await recentAlbum.getAssetListPaged(
          page: 0,
          size: 1000,
        );

        setState(() {
          _photos = photos;
          _groupPhotosByDate();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _error = '写真が見つかりません';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = '写真の読み込みに失敗しました: $e';
      });
    }
  }

  void _groupPhotosByDate() {
    _photosByDate.clear();
    for (final photo in _photos) {
      final date = DateFormat('yyyy年MM月dd日').format(photo.createDateTime);
      _photosByDate.putIfAbsent(date, () => []).add(photo);
    }
  }

  void _deletePhoto(AssetEntity photo) async {
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
      final file = await photo.originFile;
      if (file != null && await file.exists()) {
        await file.delete();

        setState(() {
          _photos.remove(photo);
          _groupPhotosByDate();
        });

        // お気に入りからも削除
        final prefs = await SharedPreferences.getInstance();
        final favoriteIds = prefs.getStringList('favorite_photos') ?? [];
        favoriteIds.remove(photo.id);
        await prefs.setStringList('favorite_photos', favoriteIds);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('写真を削除しました')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('写真の削除に失敗しました')),
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
        title: const Text('フォト'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPhotos,
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
              onPressed: _loadPhotos,
              child: const Text('再試行'),
            ),
          ],
        ),
      );
    }

    if (_photosByDate.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              '写真がありません',
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
      onRefresh: _loadPhotos,
      child: ListView.builder(
        itemCount: _photosByDate.length,
        itemBuilder: (context, index) {
          final date = _photosByDate.keys.elementAt(index);
          final photos = _photosByDate[date]!;

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
                itemCount: photos.length,
                itemBuilder: (context, index) {
                  final photo = photos[index];
                  return PhotoGridItem(
                    photo: photo,
                    onTap: () => _showFullscreenPhoto(photos, index),
                    onDelete: () => _deletePhoto(photo),
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

  void _showFullscreenPhoto(List<AssetEntity> photos, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullscreenPhotoViewer(
          photos: photos,
          initialIndex: initialIndex,
          onDelete: (photo) {
            _deletePhoto(photo);
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }
}
