import 'dart:io';

/// 写真のメタデータを管理するクラス
class PhotoMetadata {
  final String filePath;
  final String fileName;
  final DateTime? creationDate;
  final DateTime? modificationDate;
  final int? fileSize;
  final GPSLocation? location;
  final CameraInfo? cameraInfo;
  final String? mimeType;
  final Map<String, dynamic>? additionalProperties;

  PhotoMetadata({
    required this.filePath,
    required this.fileName,
    this.creationDate,
    this.modificationDate,
    this.fileSize,
    this.location,
    this.cameraInfo,
    this.mimeType,
    this.additionalProperties,
  });

  /// ファイルからPhotoMetadataを作成
  factory PhotoMetadata.fromFile(File file) {
    final stat = file.statSync();
    return PhotoMetadata(
      filePath: file.path,
      fileName: file.path.split('/').last,
      creationDate: stat.changed,
      modificationDate: stat.modified,
      fileSize: stat.size,
    );
  }

  /// JSONからPhotoMetadataを作成
  factory PhotoMetadata.fromJson(Map<String, dynamic> json) {
    return PhotoMetadata(
      filePath: json['filePath'] ?? '',
      fileName: json['fileName'] ?? '',
      creationDate: json['creationDate'] != null
          ? DateTime.parse(json['creationDate'])
          : null,
      modificationDate: json['modificationDate'] != null
          ? DateTime.parse(json['modificationDate'])
          : null,
      fileSize: json['fileSize'],
      location: json['location'] != null
          ? GPSLocation.fromJson(json['location'])
          : null,
      cameraInfo: json['cameraInfo'] != null
          ? CameraInfo.fromJson(json['cameraInfo'])
          : null,
      mimeType: json['mimeType'],
      additionalProperties: json['additionalProperties'],
    );
  }

  /// PhotoMetadataをJSONに変換
  Map<String, dynamic> toJson() {
    return {
      'filePath': filePath,
      'fileName': fileName,
      'creationDate': creationDate?.toIso8601String(),
      'modificationDate': modificationDate?.toIso8601String(),
      'fileSize': fileSize,
      'location': location?.toJson(),
      'cameraInfo': cameraInfo?.toJson(),
      'mimeType': mimeType,
      'additionalProperties': additionalProperties,
    };
  }

  /// ファイルサイズを人間が読みやすい形式で取得
  String get formattedFileSize {
    if (fileSize == null) return '不明';

    const units = ['B', 'KB', 'MB', 'GB'];
    int size = fileSize!;
    int unitIndex = 0;

    while (size >= 1024 && unitIndex < units.length - 1) {
      size ~/= 1024;
      unitIndex++;
    }

    return '$size ${units[unitIndex]}';
  }

  /// 撮影日を人間が読みやすい形式で取得
  String get formattedCreationDate {
    if (creationDate == null) return '不明';
    return '${creationDate!.year}年${creationDate!.month}月${creationDate!.day}日';
  }

  /// 位置情報があるかどうか
  bool get hasLocation => location != null;

  /// カメラ情報があるかどうか
  bool get hasCameraInfo => cameraInfo != null;
}

/// GPS位置情報を管理するクラス
class GPSLocation {
  final double latitude;
  final double longitude;
  final double? altitude;
  final double? accuracy;
  final String? address;

  GPSLocation({
    required this.latitude,
    required this.longitude,
    this.altitude,
    this.accuracy,
    this.address,
  });

  factory GPSLocation.fromJson(Map<String, dynamic> json) {
    return GPSLocation(
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
      altitude: json['altitude']?.toDouble(),
      accuracy: json['accuracy']?.toDouble(),
      address: json['address'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
      'accuracy': accuracy,
      'address': address,
    };
  }

  /// 緯度経度を文字列で取得
  String get coordinatesString =>
      '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
}

/// カメラ情報を管理するクラス
class CameraInfo {
  final String? make;
  final String? model;
  final String? software;
  final String? lensModel;
  final double? focalLength;
  final double? aperture;
  final int? iso;
  final String? shutterSpeed;
  final String? whiteBalance;
  final String? flash;

  CameraInfo({
    this.make,
    this.model,
    this.software,
    this.lensModel,
    this.focalLength,
    this.aperture,
    this.iso,
    this.shutterSpeed,
    this.whiteBalance,
    this.flash,
  });

  factory CameraInfo.fromJson(Map<String, dynamic> json) {
    return CameraInfo(
      make: json['make'],
      model: json['model'],
      software: json['software'],
      lensModel: json['lensModel'],
      focalLength: json['focalLength']?.toDouble(),
      aperture: json['aperture']?.toDouble(),
      iso: json['iso'],
      shutterSpeed: json['shutterSpeed'],
      whiteBalance: json['whiteBalance'],
      flash: json['flash'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'make': make,
      'model': model,
      'software': software,
      'lensModel': lensModel,
      'focalLength': focalLength,
      'aperture': aperture,
      'iso': iso,
      'shutterSpeed': shutterSpeed,
      'whiteBalance': whiteBalance,
      'flash': flash,
    };
  }

  /// カメラの基本情報を文字列で取得
  String get cameraString {
    if (make != null && model != null) {
      return '$make $model';
    } else if (make != null) {
      return make!;
    } else if (model != null) {
      return model!;
    }
    return '不明';
  }
}
