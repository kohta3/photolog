import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';

class PhotoGridItem extends StatefulWidget {
  final AssetEntity photo;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback? onLongPress;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback? onSelectionToggle;

  const PhotoGridItem({
    super.key,
    required this.photo,
    required this.onTap,
    required this.onDelete,
    this.onLongPress,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onSelectionToggle,
  });

  @override
  State<PhotoGridItem> createState() => _PhotoGridItemState();
}

class _PhotoGridItemState extends State<PhotoGridItem> {
  bool _isFavorite = false;
  Uint8List? _cachedThumbnail;

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
    _loadThumbnail();
  }

  @override
  void didUpdateWidget(PhotoGridItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 写真が変更された場合のみサムネイルを再読み込み
    if (oldWidget.photo.id != widget.photo.id) {
      _loadThumbnail();
    }
  }

  Future<void> _loadThumbnail() async {
    if (_cachedThumbnail != null) return;

    try {
      final thumbnail = await widget.photo.thumbnailDataWithSize(
        const ThumbnailSize(300, 300),
      );
      if (mounted) {
        setState(() {
          _cachedThumbnail = thumbnail;
        });
      }
    } catch (e) {
      print('サムネイルの読み込みに失敗: $e');
    }
  }

  Future<void> _checkFavoriteStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final favoriteIds = prefs.getStringList('favorite_photos') ?? [];
    setState(() {
      _isFavorite = favoriteIds.contains(widget.photo.id);
    });
  }

  Future<void> _toggleFavorite() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoriteIds = prefs.getStringList('favorite_photos') ?? [];

      if (_isFavorite) {
        favoriteIds.remove(widget.photo.id);
      } else {
        favoriteIds.add(widget.photo.id);
      }

      await prefs.setStringList('favorite_photos', favoriteIds);

      setState(() {
        _isFavorite = !_isFavorite;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isFavorite ? 'お気に入りに追加しました' : 'お気に入りから削除しました'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作に失敗しました: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.isSelectionMode ? widget.onSelectionToggle : widget.onTap,
      onLongPress: widget.isSelectionMode
          ? null
          : (widget.onLongPress ?? () => _showDeleteDialog(context)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // キャッシュされたサムネイルを使用
              if (_cachedThumbnail != null)
                Image.memory(
                  _cachedThumbnail!,
                  fit: BoxFit.cover,
                )
              else
                Container(
                  color: Colors.grey[300],
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              if (widget.photo.type == AssetType.video)
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              // 選択モードのチェックボックス（アニメーション付き）
              AnimatedPositioned(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                top: widget.isSelectionMode ? 6 : -30,
                left: 6,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: widget.isSelectionMode ? 1.0 : 0.0,
                  child: GestureDetector(
                    onTap: widget.onSelectionToggle,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: widget.isSelected
                            ? Colors.blue
                            : Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: widget.isSelected
                              ? Colors.blue
                              : Colors.grey.shade400,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: AnimatedScale(
                        duration: const Duration(milliseconds: 150),
                        scale: widget.isSelected ? 1.0 : 0.8,
                        child: widget.isSelected
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 16,
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
              ),
              // お気に入りアイコン（アニメーション付き）
              AnimatedPositioned(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                top: !widget.isSelectionMode ? 4 : -30,
                right: 4,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: !widget.isSelectionMode ? 1.0 : 0.0,
                  child: GestureDetector(
                    onTap: _toggleFavorite,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: _isFavorite ? Colors.red : Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('写真を削除'),
        content: const Text('この写真を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onDelete();
            },
            child: const Text('削除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
