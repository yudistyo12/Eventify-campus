import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import 'database_helper.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream of user auth state
  Stream<User?> get firebaseUserStream => _firebaseAuth.authStateChanges();
  bool get hasCurrentUser => _firebaseAuth.currentUser != null;
  String? get currentUid => _firebaseAuth.currentUser?.uid;

  // Login (User Biasa)
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final UserCredential credential = await _firebaseAuth
        .signInWithEmailAndPassword(email: email, password: password);

    final firebaseUser = credential.user;
    if (firebaseUser == null) {
      throw Exception("User tidak ditemukan");
    }

    return _loadVerifiedUser(firebaseUser);
  }

  // Cek apakah user saat ini adalah admin
  Future<bool> isCurrentUserAdmin() async {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) return false;

    final userDoc = await _firestore
        .collection('users')
        .doc(currentUser.uid)
        .get();
    return userDoc.exists && userDoc.data()?['role'] == 'admin';
  }

  // Register
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    required String nim,
    required String major,
  }) async {
    final UserCredential credential = await _firebaseAuth
        .createUserWithEmailAndPassword(email: email, password: password);

    if (credential.user == null) {
      throw Exception("Gagal melakukan registrasi");
    }

    final user = UserModel(
      uid: credential.user!.uid,
      name: name,
      email: email,
      nim: nim,
      major: major,
      role: 'user', // User baru selalu role 'user'
    );

    // Save user profile to Firestore
    await _firestore.collection('users').doc(user.uid).set(user.toMap());

    // Also cache user locally
    await DatabaseHelper.saveLocalUser(user.toMap());

    return user;
  }

  // Get Current Authenticated User Profile
  Future<UserModel?> getCurrentUser() async {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) return null;

    return _loadVerifiedUser(currentUser);
  }

  Future<UserModel> _loadVerifiedUser(User firebaseUser) async {
    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();
      final userData = userDoc.data();
      if (!userDoc.exists || userData == null) {
        throw StateError('Profil akun tidak ditemukan di Firestore.');
      }

      final user = UserModel.fromMap(userData, firebaseUser.uid);
      await DatabaseHelper.saveLocalUser(user.toMap());
      return user;
    } catch (error, stackTrace) {
      if (_firebaseAuth.currentUser?.uid == firebaseUser.uid) {
        await _firebaseAuth.signOut();
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  // Sign Out
  Future<void> logout() async {
    await _firebaseAuth.signOut();
    await DatabaseHelper.clearLocalData();
  }
}
