class ComplaintItem {
  final String id;
  final String description;
  final String? imagePath;
  final String? videoPath;
  final String status;
  final DateTime createdAt;
  final String? title;
  final String? department;
  final String? mobileNumber;
  final String? priority;
  final String? category;
  final String? audioTranscription;

  const ComplaintItem({
    required this.id,
    required this.description,
    this.imagePath,
    this.videoPath,
    required this.status,
    required this.createdAt,
    this.title,
    this.department,
    this.mobileNumber,
    this.priority,
    this.category,
    this.audioTranscription,
  });

  // Helper getters for backward compatibility
  String get message => description;
  DateTime get timestamp => createdAt;
  bool get hasMedia => imagePath != null || videoPath != null;
  bool get isImage => imagePath != null;

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'imagePath': imagePath,
      'videoPath': videoPath,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'title': title,
      'department': department,
      'mobileNumber': mobileNumber,
      'priority': priority,
      'category': category,
      'audioTranscription': audioTranscription,
    };
  }

  factory ComplaintItem.fromJson(Map<String, dynamic> json) {
    return ComplaintItem(
      id: json['id'] ?? '',
      description: json['description'] ?? '',
      imagePath: json['imagePath'],
      videoPath: json['videoPath'],
      status: json['status'] ?? 'Pending',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      title: json['title'],
      department: json['department'],
      mobileNumber: json['mobileNumber'],
      priority: json['priority'],
      category: json['category'],
      audioTranscription: json['audioTranscription'],
    );
  }

  // Create a copy with updated fields
  ComplaintItem copyWith({
    String? id,
    String? description,
    String? imagePath,
    String? videoPath,
    String? status,
    DateTime? createdAt,
    String? title,
    String? department,
    String? mobileNumber,
    String? priority,
    String? category,
    String? audioTranscription,
  }) {
    return ComplaintItem(
      id: id ?? this.id,
      description: description ?? this.description,
      imagePath: imagePath ?? this.imagePath,
      videoPath: videoPath ?? this.videoPath,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      title: title ?? this.title,
      department: department ?? this.department,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      audioTranscription: audioTranscription ?? this.audioTranscription,
    );
  }

  @override
  String toString() {
    return 'ComplaintItem(id: $id, description: $description, status: $status, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ComplaintItem &&
        other.id == id &&
        other.description == description &&
        other.imagePath == imagePath &&
        other.videoPath == videoPath &&
        other.status == status &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      description,
      imagePath,
      videoPath,
      status,
      createdAt,
    );
  }
}
