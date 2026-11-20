import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/event_service.dart';
import '../services/notification_service.dart';
import '../services/database_helper.dart';

class AppState extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final EventService _eventService = EventService();
  final NotificationService _notificationService = NotificationService();

  bool _isLoading = false;
  bool _notificationsEnabled = true;
  UserModel? _currentUser;
  List<EventModel> _events = [];
  String _searchQuery = '';
  String _selectedCategory = 'Semua';

  // Subscriptions
  StreamSubscription<List<EventModel>>? _eventsSubscription;

  // Getters
  bool get isLoading => _isLoading;
  bool get notificationsEnabled => _notificationsEnabled;
  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  List<EventModel> get events => _events;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  bool canManageEvent(EventModel event) =>
      _currentUser != null &&
      event.createdBy.isNotEmpty &&
      event.createdBy == _currentUser!.uid;

  // Filtered event list based on search and category tab
  List<EventModel> get filteredEvents {
    return _events.where((event) {
      final matchesSearch =
          event.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          event.pic.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          event.location.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesCategory =
          _selectedCategory == 'Semua' ||
          event.category.toLowerCase() == _selectedCategory.toLowerCase();

      return matchesSearch && matchesCategory;
    }).toList();
  }

  // Get statistics
  int get totalEventsCount => _events.length;
  int get activeEventsCount => _events.where((e) => e.status == 'Aktif').length;
  int get completedEventsCount =>
      _events.where((e) => e.status == 'Selesai').length;

  AppState() {
    _initializeState();
  }

  // Initial load
  Future<void> _initializeState() async {
    _isLoading = true;
    notifyListeners();

    // Load notification preference
    _notificationsEnabled = await DatabaseHelper.isNotificationEnabled();

    // Try to auto-login cached user
    await refreshCurrentUser();

    // Load events
    await loadEventsData();

    _isLoading = false;
    notifyListeners();
  }

  // Refresh User State
  Future<void> refreshCurrentUser() async {
    _currentUser = await _authService.getCurrentUser();
    notifyListeners();
  }

  // Load events from Firestore (real-time stream)
  Future<void> loadEventsData() async {
    // Cancel active stream subscription if any
    await _eventsSubscription?.cancel();

    // Load real-time stream from Cloud Firestore
    _eventsSubscription = _eventService.getEventsStream().listen(
      (fetchedEvents) {
        _events = fetchedEvents;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Error loading events: $error');
      },
    );
  }

  // Search & Filter actions
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void selectCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  // --- NOTIFICATION ACTIONS ---

  Future<void> toggleNotifications(bool enabled) async {
    _notificationsEnabled = enabled;
    await DatabaseHelper.setNotificationEnabled(enabled);

    if (!enabled) {
      // Cancel all pending notifications
      await _notificationService.cancelAll();
    } else {
      // Reschedule reminders for all active events
      for (final event in _events.where((e) => e.status == 'Aktif')) {
        await _notificationService.scheduleEventReminders(event);
        await _notificationService.scheduleEventReminderHourBefore(event);
      }
    }

    notifyListeners();
  }

  // --- AUTH ACTIONS ---

  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentUser = await _authService.login(email: email, password: password);
      // Reload events to sync
      await loadEventsData();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String nim,
    required String major,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentUser = await _authService.register(
        name: name,
        email: email,
        password: password,
        nim: nim,
        major: major,
      );
      // Reload events
      await loadEventsData();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> logout() async {
    Object? cleanupError;
    StackTrace? cleanupStackTrace;
    try {
      await _authService.logout();
    } catch (error, stackTrace) {
      if (_authService.hasCurrentUser) rethrow;
      cleanupError = error;
      cleanupStackTrace = stackTrace;
    }

    if (!_authService.hasCurrentUser) {
      _currentUser = null;
      final subscription = _eventsSubscription;
      _eventsSubscription = null;
      _events = [];
      _searchQuery = '';
      _selectedCategory = 'Semua';
      _notificationsEnabled = true;
      notifyListeners();

      try {
        await subscription?.cancel();
      } catch (error, stackTrace) {
        cleanupError ??= error;
        cleanupStackTrace ??= stackTrace;
      }

      try {
        await loadEventsData();
      } catch (error, stackTrace) {
        cleanupError ??= error;
        cleanupStackTrace ??= stackTrace;
      }

      try {
        await _notificationService.cancelAll();
      } catch (error, stackTrace) {
        cleanupError ??= error;
        cleanupStackTrace ??= stackTrace;
      }
    }

    if (cleanupError != null) {
      Error.throwWithStackTrace(cleanupError, cleanupStackTrace!);
    }
  }

  // --- CRUD ACTIONS ---

  Future<bool> addEvent({
    required String name,
    required String pic,
    required DateTime date,
    required String location,
    required String description,
    required String status,
    required String category,
    required List<int> reminderDaysBefore,
  }) async {
    final uid = _authService.currentUid;
    if (uid == null) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'unauthenticated',
        message: 'Silakan login untuk menambahkan event.',
      );
    }

    final newEvent = EventModel(
      id: FirebaseFirestore.instance.collection('events').doc().id,
      name: name,
      pic: pic,
      date: date,
      location: location,
      description: description,
      status: status,
      category: category,
      createdAt: DateTime.now(),
      createdBy: uid,
      isPublished: false, // Belum dipublikasikan, menunggu persetujuan admin
      reminderDaysBefore: reminderDaysBefore,
      approvalStatus: EventModel.statusPending, // Status awal: pending
    );

    await _eventService.addEvent(newEvent);

    var notificationFailed = false;
    if (_notificationsEnabled) {
      try {
        await _notificationService.showEventCreatedNotification(newEvent);
      } catch (error, stackTrace) {
        debugPrint(
          'Event was saved, but its creation notification failed: $error',
        );
        debugPrintStack(stackTrace: stackTrace);
        notificationFailed = true;
      }

      if (newEvent.isApproved && newEvent.isPublished && status == 'Aktif') {
        try {
          await _notificationService.scheduleEventReminders(newEvent);
        } catch (error, stackTrace) {
          debugPrint('Event was saved, but deadline reminders failed: $error');
          debugPrintStack(stackTrace: stackTrace);
          notificationFailed = true;
        }
        try {
          await _notificationService.scheduleEventReminderHourBefore(newEvent);
        } catch (error, stackTrace) {
          debugPrint(
            'Event was saved, but its one-hour reminder failed: $error',
          );
          debugPrintStack(stackTrace: stackTrace);
          notificationFailed = true;
        }
      }
    }
    return notificationFailed;
  }

  Future<bool> updateEvent({
    required String id,
    required String name,
    required String pic,
    required DateTime date,
    required String location,
    required String description,
    required String status,
    required String category,
    required DateTime createdAt,
    required List<int> reminderDaysBefore,
  }) async {
    final cachedEvent = _events.cast<EventModel?>().firstWhere(
      (event) => event?.id == id,
      orElse: () => null,
    );
    final existingEvent = cachedEvent ?? await _eventService.getEventById(id);
    if (existingEvent == null || !canManageEvent(existingEvent)) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
        message: 'Hanya pemilik event yang dapat mengubahnya.',
      );
    }

    final updatedEvent = EventModel(
      id: id,
      name: name,
      pic: pic,
      date: date,
      location: location,
      description: description,
      status: status,
      category: category,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      createdBy: existingEvent.createdBy,
      isPublished: false,
      reminderDaysBefore: reminderDaysBefore,
      approvalStatus: EventModel.statusPending,
      reviewedBy: existingEvent.reviewedBy,
      reviewedAt: existingEvent.reviewedAt,
      rejectionReason: existingEvent.rejectionReason,
    );

    await _eventService.updateEvent(updatedEvent);

    var notificationFailed = false;
    if (_notificationsEnabled) {
      try {
        await _notificationService.cancelEventReminders(id);
      } catch (error, stackTrace) {
        debugPrint(
          'Event was updated, but old reminders could not be canceled: $error',
        );
        debugPrintStack(stackTrace: stackTrace);
        notificationFailed = true;
      }

      try {
        await _notificationService.showEventUpdatedNotification(updatedEvent);
      } catch (error, stackTrace) {
        debugPrint(
          'Event was updated, but its update notification failed: $error',
        );
        debugPrintStack(stackTrace: stackTrace);
        notificationFailed = true;
      }

      if (updatedEvent.isApproved &&
          updatedEvent.isPublished &&
          status == 'Aktif') {
        try {
          await _notificationService.scheduleEventReminders(updatedEvent);
        } catch (error, stackTrace) {
          debugPrint(
            'Event was updated, but deadline reminders failed: $error',
          );
          debugPrintStack(stackTrace: stackTrace);
          notificationFailed = true;
        }
        try {
          await _notificationService.scheduleEventReminderHourBefore(
            updatedEvent,
          );
        } catch (error, stackTrace) {
          debugPrint(
            'Event was updated, but its one-hour reminder failed: $error',
          );
          debugPrintStack(stackTrace: stackTrace);
          notificationFailed = true;
        }
      }
    }
    return notificationFailed;
  }

  Future<void> deleteEvent(String id) async {
    // Find event name before deletion for notification
    final eventName = _events
        .firstWhere(
          (e) => e.id == id,
          orElse: () => EventModel(
            id: '',
            name: 'Event',
            pic: '',
            date: DateTime.now(),
            location: '',
            description: '',
            status: '',
            category: '',
            createdAt: DateTime.now(),
          ),
        )
        .name;

    final event = _events.cast<EventModel?>().firstWhere(
      (item) => item?.id == id,
      orElse: () => null,
    );
    if (event == null || !canManageEvent(event)) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
        message: 'Hanya pemilik event yang dapat menghapusnya.',
      );
    }

    await _eventService.deleteEvent(id);

    // Send notification & cancel reminders
    await _notificationService.cancelEventReminders(id);
    if (_notificationsEnabled) {
      await _notificationService.showEventDeletedNotification(eventName);
    }
  }

  @override
  void dispose() {
    _eventsSubscription?.cancel();
    super.dispose();
  }
}
