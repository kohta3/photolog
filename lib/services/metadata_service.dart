import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/photo_metadata.dart';

/// 写真のメタデータを管理するサービスクラス
class MetadataService {
  static const String _metadataKey = 'photo_metadata';
  static MetadataService? _instance;

  MetadataService._();

  static MetadataService get instance {
    _instance ??= MetadataService._();
    return _instance!;
  }

  /// 写真のメタデータを取得
  Future<PhotoMetadata?> getMetadata(String filePath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final metadataJson = prefs.getString('${_metadataKey}_$filePath');

      if (metadataJson != null) {
        final metadataMap = jsonDecode(metadataJson);
        return PhotoMetadata.fromJson(metadataMap);
      }

      // キャッシュされていない場合は、ファイルから基本情報を取得
      final file = File(filePath);
      if (await file.exists()) {
        final metadata = PhotoMetadata.fromFile(file);
        await saveMetadata(metadata);
        return metadata;
      }

      return null;
    } catch (e) {
      print('メタデータの取得に失敗しました: $e');
      return null;
    }
  }

  /// 写真のメタデータを保存
  Future<void> saveMetadata(PhotoMetadata metadata) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final metadataJson = jsonEncode(metadata.toJson());
      await prefs.setString(
          '${_metadataKey}_${metadata.filePath}', metadataJson);
    } catch (e) {
      print('メタデータの保存に失敗しました: $e');
    }
  }

  /// 複数の写真のメタデータを一括取得
  Future<List<PhotoMetadata>> getMultipleMetadata(
      List<String> filePaths) async {
    final List<PhotoMetadata> metadataList = [];

    for (final filePath in filePaths) {
      final metadata = await getMetadata(filePath);
      if (metadata != null) {
        metadataList.add(metadata);
      }
    }

    return metadataList;
  }

  /// メタデータを削除
  Future<void> deleteMetadata(String filePath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('${_metadataKey}_$filePath');
    } catch (e) {
      print('メタデータの削除に失敗しました: $e');
    }
  }

  /// 全てのメタデータを取得
  Future<List<PhotoMetadata>> getAllMetadata() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final metadataKeys = keys.where((key) => key.startsWith(_metadataKey));

      final List<PhotoMetadata> metadataList = [];

      for (final key in metadataKeys) {
        final metadataJson = prefs.getString(key);
        if (metadataJson != null) {
          final metadataMap = jsonDecode(metadataJson);
          metadataList.add(PhotoMetadata.fromJson(metadataMap));
        }
      }

      return metadataList;
    } catch (e) {
      print('全メタデータの取得に失敗しました: $e');
      return [];
    }
  }

  /// 位置情報がある写真のメタデータを取得
  Future<List<PhotoMetadata>> getMetadataWithLocation() async {
    final allMetadata = await getAllMetadata();
    return allMetadata.where((metadata) => metadata.hasLocation).toList();
  }

  /// 特定の日付範囲のメタデータを取得
  Future<List<PhotoMetadata>> getMetadataByDateRange(
      DateTime startDate, DateTime endDate) async {
    final allMetadata = await getAllMetadata();
    return allMetadata.where((metadata) {
      if (metadata.creationDate == null) return false;
      return metadata.creationDate!.isAfter(startDate) &&
          metadata.creationDate!.isBefore(endDate);
    }).toList();
  }

  /// メタデータをファイルにエクスポート
  Future<String> exportMetadataToFile() async {
    try {
      final allMetadata = await getAllMetadata();
      final metadataJson =
          jsonEncode(allMetadata.map((m) => m.toJson()).toList());

      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/photo_metadata_export.json');
      await file.writeAsString(metadataJson);

      return file.path;
    } catch (e) {
      print('メタデータのエクスポートに失敗しました: $e');
      rethrow;
    }
  }

  /// ファイルからメタデータをインポート
  Future<void> importMetadataFromFile(String filePath) async {
    try {
      final file = File(filePath);
      final metadataJson = await file.readAsString();
      final List<dynamic> metadataList = jsonDecode(metadataJson);

      for (final metadataMap in metadataList) {
        final metadata = PhotoMetadata.fromJson(metadataMap);
        await saveMetadata(metadata);
      }
    } catch (e) {
      print('メタデータのインポートに失敗しました: $e');
      rethrow;
    }
  }

  /// メタデータの統計情報を取得
  Future<Map<String, dynamic>> getMetadataStatistics() async {
    final allMetadata = await getAllMetadata();

    int totalPhotos = allMetadata.length;
    int photosWithLocation = allMetadata.where((m) => m.hasLocation).length;
    int photosWithCameraInfo = allMetadata.where((m) => m.hasCameraInfo).length;

    int totalFileSize = allMetadata
        .where((m) => m.fileSize != null)
        .fold(0, (sum, m) => sum + m.fileSize!);

    return {
      'totalPhotos': totalPhotos,
      'photosWithLocation': photosWithLocation,
      'photosWithCameraInfo': photosWithCameraInfo,
      'totalFileSize': totalFileSize,
      'averageFileSize': totalPhotos > 0 ? totalFileSize ~/ totalPhotos : 0,
    };
  }
}
