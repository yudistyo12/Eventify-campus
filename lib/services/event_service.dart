import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/event_model.dart';

class EventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // =============================================
  // PUBLIC QUERIES (Pengunjung & User)
  // =============================================

  /// Stream event yang sudah disetujui dan dipublikasikan (untuk pengunjung)
  Stream<List<EventModel>> getEventsStream() {
    return _firestore
        .collection('events')
        .where('approvalStatus', isEqualTo: EventModel.statusApproved)
        .where('isPublished', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final events = snapshot.docs
              .map((doc) => EventModel.fromFirestore(doc.data(), doc.id))
              .toList();
          events.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return events;
        });
  }

  /// Fetch events sekali (yang sudah published)
  Future<List<EventModel>> getEventsOnce() async {
    final snapshot = await _firestore
        .collection('events')
        .where('approvalStatus', isEqualTo: EventModel.statusApproved)
        .where('isPublished', isEqualTo: true)
        .get();
    final events = snapshot.docs
        .map((doc) => EventModel.fromFirestore(doc.data(), doc.id))
        .toList();
    events.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return events;
  }

  /// Fetch a single event so owners can edit submissions outside the public feed.
  Future<EventModel?> getEventById(String eventId) async {
    final snapshot = await _firestore.collection('events').doc(eventId).get();
    final data = snapshot.data();
    if (data == null) return null;
    return EventModel.fromFirestore(data, snapshot.id);
  }

  /// Stream event milik user tertentu (untuk melihat status pengajuan)
  Stream<List<EventModel>> getUserEventsStream(String uid) {
    return _firestore
        .collection('events')
        .where('createdBy', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
          final events = snapshot.docs
              .map((doc) => EventModel.fromFirestore(doc.data(), doc.id))
              .toList();
          events.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return events;
        });
  }

  // =============================================
  // ADMIN QUERIES
  // =============================================

  /// Stream seluruh event (untuk dashboard admin)
  Stream<List<EventModel>> getAllEventsStream() {
    return _firestore.collection('events').snapshots().map((snapshot) {
      final events = snapshot.docs
          .map((doc) => EventModel.fromFirestore(doc.data(), doc.id))
          .toList();
      events.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return events;
    });
  }

  /// Stream event pending (menunggu persetujuan admin)
  Stream<List<EventModel>> getPendingEventsStream() {
    return _firestore
        .collection('events')
        .where('approvalStatus', isEqualTo: EventModel.statusPending)
        .snapshots()
        .map((snapshot) {
          final events = snapshot.docs
              .map((doc) => EventModel.fromFirestore(doc.data(), doc.id))
              .toList();
          events.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return events;
        });
  }

  /// Stream event yang sudah disetujui admin
  Stream<List<EventModel>> getApprovedEventsStream() {
    return _firestore
        .collection('events')
        .where('approvalStatus', isEqualTo: EventModel.statusApproved)
        .snapshots()
        .map((snapshot) {
          final events = snapshot.docs
              .map((doc) => EventModel.fromFirestore(doc.data(), doc.id))
              .toList();
          events.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return events;
        });
  }

  /// Stream event yang ditolak admin
  Stream<List<EventModel>> getRejectedEventsStream() {
    return _firestore
        .collection('events')
        .where('approvalStatus', isEqualTo: EventModel.statusRejected)
        .snapshots()
        .map((snapshot) {
          final events = snapshot.docs
              .map((doc) => EventModel.fromFirestore(doc.data(), doc.id))
              .toList();
          events.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return events;
        });
  }

  // =============================================
  // ADMIN ACTIONS
  // =============================================

  /// Setujui event — ubah status menjadi approved dan publikasikan
  Future<void> approveEvent({
    required String eventId,
    required String adminUid,
  }) async {
    await _firestore.collection('events').doc(eventId).update({
      'approvalStatus': EventModel.statusApproved,
      'isPublished': true,
      'reviewedBy': adminUid,
      'reviewedAt': Timestamp.fromDate(DateTime.now()),
      'rejectionReason': FieldValue.delete(),
    });
  }

  /// Tolak event — ubah status menjadi rejected dengan alasan
  Future<void> rejectEvent({
    required String eventId,
    required String adminUid,
    required String reason,
  }) async {
    await _firestore.collection('events').doc(eventId).update({
      'approvalStatus': EventModel.statusRejected,
      'isPublished': false,
      'reviewedBy': adminUid,
      'reviewedAt': Timestamp.fromDate(DateTime.now()),
      'rejectionReason': reason,
    });
  }

  /// Nonaktifkan event yang sudah dipublikasikan
  Future<void> deactivateEvent({
    required String eventId,
    required String adminUid,
  }) async {
    await _firestore.collection('events').doc(eventId).update({
      'isPublished': false,
      'reviewedBy': adminUid,
      'reviewedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Aktifkan kembali event yang telah dinonaktifkan
  Future<void> reactivateEvent({
    required String eventId,
    required String adminUid,
  }) async {
    await _firestore.collection('events').doc(eventId).update({
      'isPublished': true,
      'reviewedBy': adminUid,
      'reviewedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // =============================================
  // CRUD OPERATIONS (User)
  // =============================================

  /// CREATE: Add new Event (status pending, belum dipublikasikan)
  Future<void> addEvent(EventModel event) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'unauthenticated',
        message: 'Login diperlukan untuk membuat event.',
      );
    }
    if (event.createdBy != uid) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
        message: 'Identitas pemilik event tidak valid.',
      );
    }
    await _firestore.collection('events').doc(event.id).set(event.toMap());
  }

  /// UPDATE: Edit existing Event
  Future<void> updateEvent(EventModel event) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'unauthenticated',
        message: 'Login diperlukan untuk mengubah event.',
      );
    }
    final eventRef = _firestore.collection('events').doc(event.id);
    final snapshot = await eventRef.get();
    final data = snapshot.data();
    if (data == null ||
        data['createdBy'] != uid ||
        event.createdBy != data['createdBy']) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
        message: 'Hanya pemilik event yang dapat mengubahnya.',
      );
    }
    await _firestore.collection('events').doc(event.id).update(event.toMap());
  }

  /// DELETE: Delete existing Event
  Future<void> deleteEvent(String id) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'unauthenticated',
        message: 'Login diperlukan untuk menghapus event.',
      );
    }
    final eventRef = _firestore.collection('events').doc(id);
    final snapshot = await eventRef.get();
    if (!snapshot.exists || snapshot.data()?['createdBy'] != uid) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
        message: 'Hanya pemilik event yang dapat menghapusnya.',
      );
    }
    await eventRef.delete();
  }
}
