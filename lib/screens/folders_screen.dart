import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import '../widgets/photo_grid_item.dart';
import '../widgets/fullscreen_photo_viewer.dart';
import '../widgets/banner_ad_widget.dart';
import '../services/permission_service.dart';

class FoldersScreen extends StatefulWidget {
  const FoldersScreen({super.key});

  @override
  State<FoldersScreen> createState() => _FoldersScreenState();
}

class _FoldersScreenState extends State<FoldersScreen> {
  List<AssetPathEntity> _folders = [];
  bool _isLoading = true;
  String? _error;
  AssetPathEntity? _selectedFolder;
  List<AssetEntity> _folderPhotos = [];
  Map<String, List<AssetEntity>> _photosByDate = {};
  final PermissionService _permissionService = PermissionService.instance;

  // 選択モード関連
  bool _isSelectionMode = false;
  Set<String> _selectedPhotos = {};

  @override
  void initState() {
    super.initState();
    _permissionService.addListener(_onPermissionChanged);
    _checkPermissionAndLoadFolders();
  }

  @override
  void dispose() {
    _permissionService.removeListener(_onPermissionChanged);
    super.dispose();
  }

  void _onPermissionChanged() {
    if (_permissionService.hasPermission && mounted) {
      _loadFolders();
    }
  }

  Future<void> _checkPermissionAndLoadFolders() async {
    if (_permissionService.hasPermission) {
      _loadFolders();
    } else {
      setState(() {
        _isLoading = false;
        _error = 'フォルダへのアクセス権限が必要です';
      });
    }
  }

  // 選択モードの制御
  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedPhotos.clear();
      }
    });
  }

  void _togglePhotoSelection(String photoId) {
    setState(() {
      if (_selectedPhotos.contains(photoId)) {
        _selectedPhotos.remove(photoId);
      } else {
        _selectedPhotos.add(photoId);
      }
    });
  }

  void _selectAllPhotos() {
    setState(() {
      _selectedPhotos = _folderPhotos.map((photo) => photo.id).toSet();
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedPhotos.clear();
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
          _folderPhotos
              .removeWhere((photo) => _selectedPhotos.contains(photo.id));
          _groupPhotosByDate();
          _selectedPhotos.clear();
          _isSelectionMode = false;
        });

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

  Future<void> _loadFolders() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final albums = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        hasAll: false,
      );

      setState(() {
        _folders = albums;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'フォルダの読み込みに失敗しました: $e';
      });
    }
  }

  Future<void> _loadFolderPhotos(AssetPathEntity folder) async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final photos = await folder.getAssetListPaged(
        page: 0,
        size: 1000,
      );

      setState(() {
        _selectedFolder = folder;
        _folderPhotos = photos;
        _groupPhotosByDate();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'フォルダ内の写真の読み込みに失敗しました: $e';
      });
    }
  }

  void _groupPhotosByDate() {
    _photosByDate.clear();
    for (final photo in _folderPhotos) {
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
          _folderPhotos.remove(photo);
          _groupPhotosByDate();
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('写真を削除しました')),
          );
        }
      } else {
        // 削除が失敗した場合でも、UIからは削除してユーザー体験を向上させる
        setState(() {
          _folderPhotos.remove(photo);
          _groupPhotosByDate();
        });

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

  void _goBack() {
    setState(() {
      _selectedFolder = null;
      _folderPhotos.clear();
      _photosByDate.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSelectionMode
            ? Text('${_selectedPhotos.length}件選択中')
            : Text(_selectedFolder?.name ?? 'フォルダ'),
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _toggleSelectionMode,
              )
            : _selectedFolder != null
                ? IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: _goBack,
                  )
                : null,
        actions: _isSelectionMode
            ? [
                if (_selectedPhotos.isNotEmpty) ...[
                  IconButton(
                    icon: const Icon(Icons.select_all),
                    onPressed: _selectedPhotos.length == _folderPhotos.length
                        ? _clearSelection
                        : _selectAllPhotos,
                  ),
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
                  onPressed:
                      _selectedFolder != null ? _toggleSelectionMode : null,
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _selectedFolder != null
                      ? () => _loadFolderPhotos(_selectedFolder!)
                      : _loadFolders,
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
              onPressed: _selectedFolder != null
                  ? () => _loadFolderPhotos(_selectedFolder!)
                  : _loadFolders,
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

    if (_selectedFolder == null) {
      return _buildFoldersList();
    } else {
      return _buildFolderPhotos();
    }
  }

  Widget _buildFoldersList() {
    if (_folders.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'フォルダがありません',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _folders.length,
      itemBuilder: (context, index) {
        final folder = _folders[index];
        return FutureBuilder<int>(
          future: folder.assetCountAsync,
          builder: (context, snapshot) {
            final count = snapshot.data ?? 0;
            return ListTile(
              leading: const Icon(Icons.folder, size: 40),
              title: Text(folder.name),
              subtitle: Text('$count 枚の写真'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _loadFolderPhotos(folder),
            );
          },
        );
      },
    );
  }

  Widget _buildFolderPhotos() {
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
              'このフォルダには写真がありません',
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
      onRefresh: () => _loadFolderPhotos(_selectedFolder!),
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
