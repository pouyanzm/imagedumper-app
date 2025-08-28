class ImageModel {
  final String filename;
  final String url;
  final int size;
  final String uploadedAt;

  ImageModel({
    required this.filename,
    required this.url,
    required this.size,
    required this.uploadedAt,
  });

  /// Create ImageModel from JSON
  factory ImageModel.fromJson(Map<String, dynamic> json) {
    return ImageModel(
      filename: json['filename'] ?? '',
      url: json['url'] != null && json['url'].isNotEmpty
          ? 'http://192.168.0.3:3000${json['url']}'
          : '',
      size: json['size'] ?? 0,
      uploadedAt: json['uploadedAt'] ?? '',
    );
  }

  /// Convert ImageModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'filename': filename,
      'url': url,
      'size': size,
      'uploadedAt': uploadedAt,
    };
  }

  @override
  String toString() {
    return 'ImageModel(filename: $filename, url: $url, size: $size, uploadedAt: $uploadedAt)';
  }
}
