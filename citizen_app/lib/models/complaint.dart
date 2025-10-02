enum ComplaintStatus {
  submitted,
  forwarded,
  acknowledged,
  inProgress,
  resolved,
  rejected,
}

enum ComplaintPriority {
  low,
  medium,
  high,
}

class Complaint {
  final String complaintId;
  final int userId;
  final int? deptId;
  final int? assignedWorkerId;
  final String title;
  final String description;
  final String? issueType;
  final String? imageUrl;
  final double locationLat;
  final double locationLng;
  final String? city;
  final String? zone;
  final String priority;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Complaint({
    required this.complaintId,
    required this.userId,
    this.deptId,
    this.assignedWorkerId,
    required this.title,
    required this.description,
    this.issueType,
    this.imageUrl,
    required this.locationLat,
    required this.locationLng,
    this.city,
    this.zone,
    required this.priority,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Complaint.fromJson(Map<String, dynamic> json) {
    return Complaint(
      complaintId: json['complaint_id'] ?? '',
      userId: json['user_id'] ?? 0,
      deptId: json['dept_id'],
      assignedWorkerId: json['assigned_worker_id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      issueType: json['issue_type'],
      imageUrl: json['image_url'],
      locationLat: (json['location_lat'] ?? 0.0).toDouble(),
      locationLng: (json['location_lng'] ?? 0.0).toDouble(),
      city: json['city'],
      zone: json['zone'],
      priority: json['priority'] ?? 'medium',
      status: json['status'] ?? 'submitted',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'complaint_id': complaintId,
      'user_id': userId,
      'dept_id': deptId,
      'assigned_worker_id': assignedWorkerId,
      'title': title,
      'description': description,
      'issue_type': issueType,
      'image_url': imageUrl,
      'location_lat': locationLat,
      'location_lng': locationLng,
      'city': city,
      'zone': zone,
      'priority': priority,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ComplaintStatus get complaintStatus {
    switch (status.toLowerCase()) {
      case 'submitted':
        return ComplaintStatus.submitted;
      case 'forwarded':
        return ComplaintStatus.forwarded;
      case 'acknowledged':
        return ComplaintStatus.acknowledged;
      case 'in_progress':
        return ComplaintStatus.inProgress;
      case 'resolved':
        return ComplaintStatus.resolved;
      case 'rejected':
        return ComplaintStatus.rejected;
      default:
        return ComplaintStatus.submitted;
    }
  }

  ComplaintPriority get complaintPriority {
    switch (priority.toLowerCase()) {
      case 'low':
        return ComplaintPriority.low;
      case 'medium':
        return ComplaintPriority.medium;
      case 'high':
        return ComplaintPriority.high;
      default:
        return ComplaintPriority.medium;
    }
  }

  String get statusDisplayName {
    switch (complaintStatus) {
      case ComplaintStatus.submitted:
        return 'Submitted';
      case ComplaintStatus.forwarded:
        return 'Forwarded';
      case ComplaintStatus.acknowledged:
        return 'Acknowledged';
      case ComplaintStatus.inProgress:
        return 'In Progress';
      case ComplaintStatus.resolved:
        return 'Resolved';
      case ComplaintStatus.rejected:
        return 'Rejected';
    }
  }

  String get priorityDisplayName {
    switch (complaintPriority) {
      case ComplaintPriority.low:
        return 'Low';
      case ComplaintPriority.medium:
        return 'Medium';
      case ComplaintPriority.high:
        return 'High';
    }
  }

  Complaint copyWith({
    String? complaintId,
    int? userId,
    int? deptId,
    int? assignedWorkerId,
    String? title,
    String? description,
    String? issueType,
    String? imageUrl,
    double? locationLat,
    double? locationLng,
    String? city,
    String? zone,
    String? priority,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Complaint(
      complaintId: complaintId ?? this.complaintId,
      userId: userId ?? this.userId,
      deptId: deptId ?? this.deptId,
      assignedWorkerId: assignedWorkerId ?? this.assignedWorkerId,
      title: title ?? this.title,
      description: description ?? this.description,
      issueType: issueType ?? this.issueType,
      imageUrl: imageUrl ?? this.imageUrl,
      locationLat: locationLat ?? this.locationLat,
      locationLng: locationLng ?? this.locationLng,
      city: city ?? this.city,
      zone: zone ?? this.zone,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper methods
  bool get isResolved => complaintStatus == ComplaintStatus.resolved;
  bool get isActive => complaintStatus == ComplaintStatus.submitted || 
                      complaintStatus == ComplaintStatus.forwarded ||
                      complaintStatus == ComplaintStatus.acknowledged ||
                      complaintStatus == ComplaintStatus.inProgress;
  bool get isAssigned => assignedWorkerId != null;
  
  String get statusColor {
    switch (complaintStatus) {
      case ComplaintStatus.submitted:
        return '#FFA500'; // Orange
      case ComplaintStatus.forwarded:
        return '#17A2B8'; // Cyan
      case ComplaintStatus.acknowledged:
        return '#007BFF'; // Blue
      case ComplaintStatus.inProgress:
        return '#6F42C1'; // Purple
      case ComplaintStatus.resolved:
        return '#28A745'; // Green
      case ComplaintStatus.rejected:
        return '#DC3545'; // Red
    }
  }

  String get priorityColor {
    switch (complaintPriority) {
      case ComplaintPriority.low:
        return '#28A745'; // Green
      case ComplaintPriority.medium:
        return '#FFC107'; // Yellow
      case ComplaintPriority.high:
        return '#DC3545'; // Red
    }
  }

  String get formattedCreatedAt {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  @override
  String toString() {
    return 'Complaint(complaintId: $complaintId, title: $title, status: $status, priority: $priority)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Complaint && other.complaintId == complaintId;
  }

  @override
  int get hashCode => complaintId.hashCode;
}
