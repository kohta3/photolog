import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'dart:typed_data';

class VideoGridItem extends StatefulWidget {
  final AssetEntity video;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback? onLongPress;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback? onSelectionToggle;

  const VideoGridItem({
    super.key,
    required this.video,
    required this.onTap,
    required this.onDelete,
    this.onLongPress,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onSelectionToggle,
  });

  @override
  State<VideoGridItem> createState() => _VideoGridItemState();
}

class _VideoGridItemState extends State<VideoGridItem> {
  Uint8List? _cachedThumbnail;

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  @override
  void didUpdateWidget(VideoGridItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 動画が変更された場合のみサムネイルを再読み込み
    if (oldWidget.video.id != widget.video.id) {
      _loadThumbnail();
    }
  }

  Future<void> _loadThumbnail() async {
    if (_cachedThumbnail != null) return;

    try {
      final thumbnail = await widget.video.thumbnailDataWithSize(
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
              // 動画の再生アイコン
              const Center(
                child: Icon(
                  Icons.play_circle_filled,
                  color: Colors.white,
                  size: 48,
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
              // 動画の長さ表示
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: FutureBuilder<int>(
                    future: Future.value(widget.video.duration),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data != null) {
                        final durationSeconds = snapshot.data!;
                        final minutes = durationSeconds ~/ 60;
                        final seconds = durationSeconds % 60;
                        return Text(
                          '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
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
        title: const Text('動画を削除'),
        content: const Text('この動画を削除しますか？'),
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
