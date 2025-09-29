import 'package:flutter/material.dart';
import '../models/photo_metadata.dart';
import '../services/metadata_service.dart';
import '../widgets/metadata_display_widget.dart';

class MetadataScreen extends StatefulWidget {
  const MetadataScreen({super.key});

  @override
  State<MetadataScreen> createState() => _MetadataScreenState();
}

class _MetadataScreenState extends State<MetadataScreen> {
  List<PhotoMetadata> _allMetadata = [];
  List<PhotoMetadata> _filteredMetadata = [];
  Map<String, dynamic> _statistics = {};
  bool _isLoading = true;
  String? _error;
  String? _searchQuery;
  bool _hasLocation = false;
  bool _hasCameraInfo = false;

  @override
  void initState() {
    super.initState();
    _loadMetadata();
  }

  Future<void> _loadMetadata() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final metadata = await MetadataService.instance.getAllMetadata();
      final statistics = await MetadataService.instance.getMetadataStatistics();

      setState(() {
        _allMetadata = metadata;
        _filteredMetadata = metadata;
        _statistics = statistics;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'メタデータの読み込みに失敗しました: $e';
      });
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredMetadata = _allMetadata.where((metadata) {
        // 検索クエリでフィルタリング
        if (_searchQuery != null && _searchQuery!.isNotEmpty) {
          if (!metadata.fileName
                  .toLowerCase()
                  .contains(_searchQuery!.toLowerCase()) &&
              !metadata.filePath
                  .toLowerCase()
                  .contains(_searchQuery!.toLowerCase())) {
            return false;
          }
        }

        // 位置情報でフィルタリング
        if (_hasLocation && !metadata.hasLocation) {
          return false;
        }

        // カメラ情報でフィルタリング
        if (_hasCameraInfo && !metadata.hasCameraInfo) {
          return false;
        }

        return true;
      }).toList();
    });
  }

  void _onFilterChanged(
      String? searchQuery, bool? hasLocation, bool? hasCameraInfo) {
    setState(() {
      _searchQuery = searchQuery;
      _hasLocation = hasLocation ?? false;
      _hasCameraInfo = hasCameraInfo ?? false;
    });
    _applyFilters();
  }

  void _exportMetadata() async {
    try {
      final filePath = await MetadataService.instance.exportMetadataToFile();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('メタデータをエクスポートしました: $filePath')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エクスポートに失敗しました: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('写真の詳細情報'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMetadata,
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportMetadata,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_statistics.isNotEmpty)
            MetadataStatisticsWidget(statistics: _statistics),
          MetadataFilterWidget(onFilterChanged: _onFilterChanged),
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
              onPressed: _loadMetadata,
              child: const Text('再試行'),
            ),
          ],
        ),
      );
    }

    if (_filteredMetadata.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.info_outline,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'メタデータが見つかりません',
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
      onRefresh: _loadMetadata,
      child: ListView.builder(
        itemCount: _filteredMetadata.length,
        itemBuilder: (context, index) {
          final metadata = _filteredMetadata[index];
          return MetadataDisplayWidget(
            metadata: metadata,
            isExpanded: false,
            onToggleExpanded: () {
              setState(() {
                // 展開状態を管理するロジックを追加
              });
            },
          );
        },
      ),
    );
  }
}
