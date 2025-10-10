import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import '../widgets/photo_grid_item.dart';
import '../widgets/fullscreen_photo_viewer.dart';
import '../widgets/banner_ad_widget.dart';
import '../services/permission_service.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<AssetEntity> _favoritePhotos = [];
  Map<String, List<AssetEntity>> _photosByDate = {};
  bool _isLoading = true;
  String? _error;
  final PermissionService _permissionService = PermissionService.instance;

  // 選択モード関連
  bool _isSelectionMode = false;
  Set<String> _selectedPhotos = {};

  @override
  void initState() {
    super.initState();
    _permissionService.addListener(_onPermissionChanged);
    _checkPermissionAndLoadFavorites();
  }

  @override
  void dispose() {
    _permissionService.removeListener(_onPermissionChanged);
    super.dispose();
  }

  void _onPermissionChanged() {
    if (_permissionService.hasPermission && mounted) {
      _loadFavorites();
    }
  }

  Future<void> _checkPermissionAndLoadFavorites() async {
    if (_permissionService.hasPermission) {
      _loadFavorites();
    } else {
      setState(() {
        _isLoading = false;
        _error = 'お気に入りへのアクセス権限が必要です';
      });
    }
  }

  // 選択モードの制御
  void _toggleSelectionMode() {
    if (!mounted) return;

    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedPhotos.clear();
      }
    });
  }

  void _togglePhotoSelection(String photoId) {
    if (!mounted) return;

    setState(() {
      if (_selectedPhotos.contains(photoId)) {
        _selectedPhotos.remove(photoId);
      } else {
        _selectedPhotos.add(photoId);
      }
    });
  }

  // 一括削除機能
  Future<void> _deleteSelectedPhotos() async {
    if (_selectedPhotos.isEmpty) return;

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
            const SnackBar(content: Text('写真へのアクセス権限が必要です')),
          );
        }
        return;
      }

      // 選択された写真を削除
      final selectedPhotoIds = _selectedPhotos.toList();
      final result = await PhotoManager.editor.deleteWithIds(selectedPhotoIds);
      print('一括削除結果: $result');

      if (result.isNotEmpty) {
        setState(() {
          // 削除された写真をリストから除外
          _favoritePhotos
              .removeWhere((photo) => _selectedPhotos.contains(photo.id));
          _groupPhotosByDate();
          _selectedPhotos.clear();
          _isSelectionMode = false;
        });

        // お気に入りからも削除
        final prefs = await SharedPreferences.getInstance();
        final favoriteIds = prefs.getStringList('favorite_photos') ?? [];
        for (final photoId in selectedPhotoIds) {
          favoriteIds.remove(photoId);
        }
        await prefs.setStringList('favorite_photos', favoriteIds);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${result.length}枚の写真を削除しました')),
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

  Future<void> _loadFavorites() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final prefs = await SharedPreferences.getInstance();
      final favoriteIds = prefs.getStringList('favorite_photos') ?? [];

      if (favoriteIds.isEmpty) {
        setState(() {
          _favoritePhotos = [];
          _photosByDate = {};
          _isLoading = false;
        });
        return;
      }

      final albums = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        hasAll: true,
      );

      if (albums.isNotEmpty) {
        final recentAlbum = albums.first;
        final allPhotos = await recentAlbum.getAssetListPaged(
          page: 0,
          size: 1000,
        );

        final favoritePhotos = allPhotos.where((photo) {
          return favoriteIds.contains(photo.id);
        }).toList();

        setState(() {
          _favoritePhotos = favoritePhotos;
          _groupPhotosByDate();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _error = 'お気に入り写真の読み込みに失敗しました';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'お気に入り写真の読み込みに失敗しました: $e';
      });
    }
  }

  void _groupPhotosByDate() {
    _photosByDate.clear();
    for (final photo in _favoritePhotos) {
      final date = DateFormat('yyyy年MM月dd日').format(photo.createDateTime);
      _photosByDate.putIfAbsent(date, () => []).add(photo);
    }
  }

  void _deletePhoto(AssetEntity photo) async {
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
          print('写真へのアクセス権限が必要です');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('写真へのアクセス権限が必要です')),
          );
        }
        return;
      }

      // photo_managerを使用してアセットを削除
      final result = await PhotoManager.editor.deleteWithIds([photo.id]);
      print('削除結果: $result');

      // 削除が成功した場合（resultが空でない、または削除されたIDが含まれている）
      if (result.isNotEmpty) {
        setState(() {
          _favoritePhotos.remove(photo);
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
        // 削除が失敗した場合でも、UIからは削除してユーザー体験を向上させる
        setState(() {
          _favoritePhotos.remove(photo);
          _groupPhotosByDate();
        });

        // お気に入りからも削除
        final prefs = await SharedPreferences.getInstance();
        final favoriteIds = prefs.getStringList('favorite_photos') ?? [];
        favoriteIds.remove(photo.id);
        await prefs.setStringList('favorite_photos', favoriteIds);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('写真を削除しました（一部のファイルは残っている可能性があります）')),
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
            ? Text('${_selectedPhotos.length}件選択中')
            : const Text('お気に入り'),
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _toggleSelectionMode,
              )
            : null,
        actions: _isSelectionMode
            ? [
                if (_selectedPhotos.isNotEmpty) ...[
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: _selectedPhotos.isNotEmpty
                        ? _deleteSelectedPhotos
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
                  onPressed: _loadFavorites,
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
              onPressed: _loadFavorites,
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

    if (_photosByDate.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'お気に入り写真がありません',
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
      onRefresh: _loadFavorites,
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
                    onLongPress: () => _toggleSelectionMode(),
                    isSelectionMode: _isSelectionMode,
                    isSelected: _selectedPhotos.contains(photo.id),
                    onSelectionToggle: () => _togglePhotoSelection(photo.id),
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
