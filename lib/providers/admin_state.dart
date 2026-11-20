import 'dart:async';
import 'package:flutter/material.dart';
import '../models/event_model.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/event_service.dart';

/// Provider untuk state management admin dashboard
class AdminState extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final EventService _eventService = EventService();

  bool _isLoading = false;
  bool _isAdminLoggedIn = false;
  UserModel? _adminUser;
  List<EventModel> _allEvents = [];
  List<EventModel> _pendingEvents = [];
  List<EventModel> _approvedEvents = [];
  List<EventModel> _rejectedEvents = [];

  // Subscriptions
  StreamSubscription<List<EventModel>>? _allEventsSubscription;
  StreamSubscription<List<EventModel>>? _pendingSubscription;
  StreamSubscription<List<EventModel>>? _approvedSubscription;
  StreamSubscription<List<EventModel>>? _rejectedSubscription;

  // Getters
  bool get isLoading => _isLoading;
  bool get isAdminLoggedIn => _isAdminLoggedIn;
  UserModel? get adminUser => _adminUser;
  List<EventModel> get allEvents => _allEvents;
  List<EventModel> get pendingEvents => _pendingEvents;
  List<EventModel> get approvedEvents => _approvedEvents;
  List<EventModel> get rejectedEvents => _rejectedEvents;

  // Statistik
  int get totalEventsCount => _allEvents.length;
  int get pendingEventsCount => _pendingEvents.length;
  int get approvedEventsCount => _approvedEvents.length;
  int get rejectedEventsCount => _rejectedEvents.length;

  // =============================================
  // AUTH ACTIONS
  // =============================================

  /// Login sebagai admin
  Future<void> adminLogin(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      _adminUser = await _authService.adminLogin(
        email: email,
        password: password,
      );
      _isAdminLoggedIn = true;

      // Mulai listen semua stream event
      _startListeningEvents();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Logout admin
  Future<void> adminLogout() async {
    await _stopListeningEvents();
    await _authService.logout();

    _isAdminLoggedIn = false;
    _adminUser = null;
    _allEvents = [];
    _pendingEvents = [];
    _approvedEvents = [];
    _rejectedEvents = [];
    notifyListeners();
  }

  // =============================================
  // EVENT STREAMS
  // =============================================

  void _startListeningEvents() {
    // Stream semua event
    _allEventsSubscription = _eventService.getAllEventsStream().listen(
      (events) {
        _allEvents = events;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Error loading all events: $error');
      },
    );

    // Stream event pending
    _pendingSubscription = _eventService.getPendingEventsStream().listen(
      (events) {
        _pendingEvents = events;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Error loading pending events: $error');
      },
    );

    // Stream event approved
    _approvedSubscription = _eventService.getApprovedEventsStream().listen(
      (events) {
        _approvedEvents = events;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Error loading approved events: $error');
      },
    );

    // Stream event rejected
    _rejectedSubscription = _eventService.getRejectedEventsStream().listen(
      (events) {
        _rejectedEvents = events;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Error loading rejected events: $error');
      },
    );
  }

  Future<void> _stopListeningEvents() async {
    await _allEventsSubscription?.cancel();
    await _pendingSubscription?.cancel();
    await _approvedSubscription?.cancel();
    await _rejectedSubscription?.cancel();
    _allEventsSubscription = null;
    _pendingSubscription = null;
    _approvedSubscription = null;
    _rejectedSubscription = null;
  }

  // =============================================
  // ADMIN EVENT ACTIONS
  // =============================================

  /// Setujui event
  Future<void> approveEvent(String eventId) async {
    if (_adminUser == null) throw Exception('Admin belum login');

    _isLoading = true;
    notifyListeners();

    try {
      await _eventService.approveEvent(
        eventId: eventId,
        adminUid: _adminUser!.uid,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Tolak event dengan alasan
  Future<void> rejectEvent(String eventId, String reason) async {
    if (_adminUser == null) throw Exception('Admin belum login');

    _isLoading = true;
    notifyListeners();

    try {
      await _eventService.rejectEvent(
        eventId: eventId,
        adminUid: _adminUser!.uid,
        reason: reason,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Nonaktifkan event yang sudah dipublikasikan
  Future<void> deactivateEvent(String eventId) async {
    if (_adminUser == null) throw Exception('Admin belum login');

    _isLoading = true;
    notifyListeners();

    try {
      await _eventService.deactivateEvent(
        eventId: eventId,
        adminUid: _adminUser!.uid,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Aktifkan kembali event
  Future<void> reactivateEvent(String eventId) async {
    if (_adminUser == null) throw Exception('Admin belum login');

    _isLoading = true;
    notifyListeners();

    try {
      await _eventService.reactivateEvent(
        eventId: eventId,
        adminUid: _adminUser!.uid,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _stopListeningEvents();
    super.dispose();
  }
}
