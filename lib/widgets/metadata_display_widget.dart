import 'package:flutter/material.dart';
import '../models/photo_metadata.dart';
import '../constants/app_colors.dart';

/// 写真のメタデータを表示するウィジェット
class MetadataDisplayWidget extends StatelessWidget {
  final PhotoMetadata metadata;
  final bool isExpanded;
  final VoidCallback? onToggleExpanded;

  const MetadataDisplayWidget({
    Key? key,
    required this.metadata,
    this.isExpanded = false,
    this.onToggleExpanded,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ヘッダー部分
          ListTile(
            leading:
                const Icon(Icons.info_outline, color: AppColors.primaryColor),
            title: const Text('写真の詳細情報'),
            trailing: onToggleExpanded != null
                ? IconButton(
                    icon: Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                    ),
                    onPressed: onToggleExpanded,
                  )
                : null,
          ),

          if (isExpanded) ...[
            const Divider(),
            _buildBasicInfo(),
            if (metadata.hasLocation) _buildLocationInfo(),
            if (metadata.hasCameraInfo) _buildCameraInfo(),
            _buildFileInfo(),
          ],
        ],
      ),
    );
  }

  /// 基本情報を表示
  Widget _buildBasicInfo() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '基本情報',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          _buildInfoRow('ファイル名', metadata.fileName),
          _buildInfoRow('撮影日', metadata.formattedCreationDate),
          if (metadata.modificationDate != null)
            _buildInfoRow(
              '更新日',
              '${metadata.modificationDate!.year}年${metadata.modificationDate!.month}月${metadata.modificationDate!.day}日',
            ),
        ],
      ),
    );
  }

  /// 位置情報を表示
  Widget _buildLocationInfo() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '位置情報',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          _buildInfoRow('緯度', metadata.location!.latitude.toStringAsFixed(6)),
          _buildInfoRow('経度', metadata.location!.longitude.toStringAsFixed(6)),
          if (metadata.location!.altitude != null)
            _buildInfoRow(
                '標高', '${metadata.location!.altitude!.toStringAsFixed(1)}m'),
          if (metadata.location!.accuracy != null)
            _buildInfoRow(
                '精度', '±${metadata.location!.accuracy!.toStringAsFixed(1)}m'),
          if (metadata.location!.address != null)
            _buildInfoRow('住所', metadata.location!.address!),
        ],
      ),
    );
  }

  /// カメラ情報を表示
  Widget _buildCameraInfo() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'カメラ情報',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          if (metadata.cameraInfo!.make != null ||
              metadata.cameraInfo!.model != null)
            _buildInfoRow('カメラ', metadata.cameraInfo!.cameraString),
          if (metadata.cameraInfo!.lensModel != null)
            _buildInfoRow('レンズ', metadata.cameraInfo!.lensModel!),
          if (metadata.cameraInfo!.focalLength != null)
            _buildInfoRow('焦点距離',
                '${metadata.cameraInfo!.focalLength!.toStringAsFixed(1)}mm'),
          if (metadata.cameraInfo!.aperture != null)
            _buildInfoRow(
                '絞り', 'f/${metadata.cameraInfo!.aperture!.toStringAsFixed(1)}'),
          if (metadata.cameraInfo!.iso != null)
            _buildInfoRow('ISO', metadata.cameraInfo!.iso.toString()),
          if (metadata.cameraInfo!.shutterSpeed != null)
            _buildInfoRow('シャッター速度', metadata.cameraInfo!.shutterSpeed!),
          if (metadata.cameraInfo!.whiteBalance != null)
            _buildInfoRow('ホワイトバランス', metadata.cameraInfo!.whiteBalance!),
          if (metadata.cameraInfo!.flash != null)
            _buildInfoRow('フラッシュ', metadata.cameraInfo!.flash!),
        ],
      ),
    );
  }

  /// ファイル情報を表示
  Widget _buildFileInfo() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ファイル情報',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          _buildInfoRow('ファイルサイズ', metadata.formattedFileSize),
          _buildInfoRow('ファイルパス', metadata.filePath),
          if (metadata.mimeType != null)
            _buildInfoRow('MIMEタイプ', metadata.mimeType!),
        ],
      ),
    );
  }

  /// 情報行を構築
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

/// メタデータの統計情報を表示するウィジェット
class MetadataStatisticsWidget extends StatelessWidget {
  final Map<String, dynamic> statistics;

  const MetadataStatisticsWidget({
    Key? key,
    required this.statistics,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '統計情報',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            _buildStatRow(
              '総写真数',
              '${statistics['totalPhotos']}枚',
              Icons.photo_library,
            ),
            _buildStatRow(
              '位置情報付き',
              '${statistics['photosWithLocation']}枚',
              Icons.location_on,
            ),
            _buildStatRow(
              'カメラ情報付き',
              '${statistics['photosWithCameraInfo']}枚',
              Icons.camera_alt,
            ),
            _buildStatRow(
              '総ファイルサイズ',
              _formatFileSize(statistics['totalFileSize']),
              Icons.storage,
            ),
            _buildStatRow(
              '平均ファイルサイズ',
              _formatFileSize(statistics['averageFileSize']),
              Icons.analytics,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  String _formatFileSize(int bytes) {
    const units = ['B', 'KB', 'MB', 'GB'];
    int size = bytes;
    int unitIndex = 0;

    while (size >= 1024 && unitIndex < units.length - 1) {
      size ~/= 1024;
      unitIndex++;
    }

    return '$size ${units[unitIndex]}';
  }
}

/// メタデータの検索・フィルタリング用ウィジェット
class MetadataFilterWidget extends StatefulWidget {
  final Function(String? searchQuery, bool? hasLocation, bool? hasCameraInfo)
      onFilterChanged;

  const MetadataFilterWidget({
    Key? key,
    required this.onFilterChanged,
  }) : super(key: key);

  @override
  State<MetadataFilterWidget> createState() => _MetadataFilterWidgetState();
}

class _MetadataFilterWidgetState extends State<MetadataFilterWidget> {
  final TextEditingController _searchController = TextEditingController();
  bool _hasLocation = false;
  bool _hasCameraInfo = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onFilterChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onFilterChanged() {
    widget.onFilterChanged(
      _searchController.text.isEmpty ? null : _searchController.text,
      _hasLocation,
      _hasCameraInfo,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'フィルター',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryColor,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'ファイル名で検索...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: CheckboxListTile(
                    title: const Text('位置情報あり'),
                    value: _hasLocation,
                    onChanged: (value) {
                      setState(() {
                        _hasLocation = value ?? false;
                      });
                      _onFilterChanged();
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                Expanded(
                  child: CheckboxListTile(
                    title: const Text('カメラ情報あり'),
                    value: _hasCameraInfo,
                    onChanged: (value) {
                      setState(() {
                        _hasCameraInfo = value ?? false;
                      });
                      _onFilterChanged();
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
