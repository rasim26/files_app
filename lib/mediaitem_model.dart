class MediaItem {
  String id;
  String fileBase64;
  String description;
  String status;
  String recoveryStatus;
  String fileName;
  String fileExtension;
  String? createdAt;
  String? deletedAt;
  String? recoveredAt;

  MediaItem({
    required this.id,
    required this.fileBase64,
    required this.description,
    required this.status,
    required this.recoveryStatus,
    required this.fileName,
    required this.fileExtension,
    this.createdAt,
    this.deletedAt,
    this.recoveredAt,
  });

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "fileBase64": fileBase64,
      "description": description,
      "status": status,
      "recoveryStatus": recoveryStatus,
      "fileName": fileName,
      "fileExtension": fileExtension,
      "createdAt": createdAt,
      "deletedAt": deletedAt,
      "recoveredAt": recoveredAt,
    };
  }
}
