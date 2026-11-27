import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final String name;
  final String pic; // Penanggung Jawab
  final DateTime date;
  final String location;
  final String description;
  final String? imageUrl;
  final String status; // "Aktif" / "Selesai" (status kegiatan)
  final String category; // "Akademik", "Organisasi", "Lomba", "Seminar"
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String createdBy;
  final bool isPublished;
  final List<int> reminderDaysBefore;

  // --- Field Admin Approval ---
  final String approvalStatus; // "pending", "approved", "rejected"
  final String? reviewedBy; // UID admin yang memeriksa
  final DateTime? reviewedAt; // Waktu pemeriksaan
  final String? rejectionReason; // Alasan penolakan

  EventModel({
    required this.id,
    required this.name,
    required this.pic,
    required this.date,
    required this.location,
    required this.description,
    this.imageUrl,
    required this.status,
    required this.category,
    required this.createdAt,
    this.updatedAt,
    this.createdBy = '',
    this.isPublished = true,
    this.reminderDaysBefore = const [1],
    this.approvalStatus = 'approved',
    this.reviewedBy,
    this.reviewedAt,
    this.rejectionReason,
  });

  static const supportedReminderDays = [7, 3, 1, 0];

  /// Approval status constants
  static const String statusPending = 'pending';
  static const String statusApproved = 'approved';
  static const String statusRejected = 'rejected';

  bool get isPending => approvalStatus == statusPending;
  bool get isApproved => approvalStatus == statusApproved;
  bool get isRejected => approvalStatus == statusRejected;

  static List<int> _parseReminderDays(dynamic value) {
    if (value is! List) return [1];
    return value
        .whereType<num>()
        .map((day) => day.toInt())
        .where(supportedReminderDays.contains)
        .toSet()
        .toList();
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'id': id,
      'name': name,
      'pic': pic,
      'date': Timestamp.fromDate(date),
      'location': location,
      'description': description,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'status': status,
      'category': category,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'isPublished': isPublished,
      'reminderDaysBefore': reminderDaysBefore,
      'approvalStatus': approvalStatus,
    };
    if (updatedAt != null) {
      map['updatedAt'] = Timestamp.fromDate(updatedAt!);
    }
    if (reviewedBy != null) {
      map['reviewedBy'] = reviewedBy;
    }
    if (reviewedAt != null) {
      map['reviewedAt'] = Timestamp.fromDate(reviewedAt!);
    }
    if (rejectionReason != null) {
      map['rejectionReason'] = rejectionReason;
    }
    return map;
  }

  // Convert to Map for local storage (JSON-safe, no Timestamp)
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'id': id,
      'name': name,
      'pic': pic,
      'date': date.toIso8601String(),
      'location': location,
      'description': description,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'status': status,
      'category': category,
      'createdAt': createdAt.toIso8601String(),
      'createdBy': createdBy,
      'isPublished': isPublished,
      'reminderDaysBefore': reminderDaysBefore,
      'approvalStatus': approvalStatus,
    };
    if (updatedAt != null) {
      json['updatedAt'] = updatedAt!.toIso8601String();
    }
    if (reviewedBy != null) {
      json['reviewedBy'] = reviewedBy;
    }
    if (reviewedAt != null) {
      json['reviewedAt'] = reviewedAt!.toIso8601String();
    }
    if (rejectionReason != null) {
      json['rejectionReason'] = rejectionReason;
    }
    return json;
  }

  // Create EventModel from Firestore Document Snapshot
  factory EventModel.fromFirestore(Map<String, dynamic> map, String docId) {
    DateTime parseDate(dynamic d) {
      if (d is Timestamp) return d.toDate();
      if (d is String) return DateTime.tryParse(d) ?? DateTime.now();
      return DateTime.now();
    }

    return EventModel(
      id: docId,
      name: map['name'] ?? '',
      pic: map['pic'] ?? '',
      date: parseDate(map['date']),
      location: map['location'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'] is String ? map['imageUrl'] as String : null,
      status: map['status'] ?? 'Aktif',
      category: map['category'] ?? 'Organisasi',
      createdAt: parseDate(map['createdAt']),
      updatedAt: map['updatedAt'] == null ? null : parseDate(map['updatedAt']),
      createdBy: map['createdBy'] is String ? map['createdBy'] as String : '',
      isPublished: map['isPublished'] is bool
          ? map['isPublished'] as bool
          : true,
      reminderDaysBefore: _parseReminderDays(map['reminderDaysBefore']),
      // Backward compatible: event lama tanpa approvalStatus dianggap approved
      approvalStatus: map['approvalStatus'] ?? 'approved',
      reviewedBy: map['reviewedBy'] as String?,
      reviewedAt: map['reviewedAt'] == null
          ? null
          : parseDate(map['reviewedAt']),
      rejectionReason: map['rejectionReason'] as String?,
    );
  }

  factory EventModel.fromMap(Map<String, dynamic> map, String docId) =>
      EventModel.fromFirestore(map, docId);

  // Create EventModel from JSON Map (Shared Preferences)
  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      pic: json['pic'] ?? '',
      date: json['date'] != null
          ? DateTime.parse(json['date'])
          : DateTime.now(),
      location: json['location'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'] is String ? json['imageUrl'] as String : null,
      status: json['status'] ?? 'Aktif',
      category: json['category'] ?? 'Organisasi',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      createdBy: json['createdBy'] is String ? json['createdBy'] as String : '',
      isPublished: json['isPublished'] is bool
          ? json['isPublished'] as bool
          : true,
      reminderDaysBefore: _parseReminderDays(json['reminderDaysBefore']),
      approvalStatus: json['approvalStatus'] ?? 'approved',
      reviewedBy: json['reviewedBy'] as String?,
      reviewedAt: json['reviewedAt'] != null
          ? DateTime.parse(json['reviewedAt'])
          : null,
      rejectionReason: json['rejectionReason'] as String?,
    );
  }

  // CopyWith helper to modify models easily
  EventModel copyWith({
    String? id,
    String? name,
    String? pic,
    DateTime? date,
    String? location,
    String? description,
    String? imageUrl,
    bool clearImageUrl = false,
    String? status,
    String? category,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    bool? isPublished,
    List<int>? reminderDaysBefore,
    String? approvalStatus,
    String? reviewedBy,
    DateTime? reviewedAt,
    String? rejectionReason,
  }) {
    return EventModel(
      id: id ?? this.id,
      name: name ?? this.name,
      pic: pic ?? this.pic,
      date: date ?? this.date,
      location: location ?? this.location,
      description: description ?? this.description,
      imageUrl: clearImageUrl ? null : imageUrl ?? this.imageUrl,
      status: status ?? this.status,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      isPublished: isPublished ?? this.isPublished,
      reminderDaysBefore: reminderDaysBefore ?? this.reminderDaysBefore,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }
}
