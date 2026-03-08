import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Syncs SharedPreferences data to Firestore so user data survives reinstalls.
/// Structure: users/{uid}/prefs/{key} → {v: "json string"}
class CloudSyncService {
  static String? _userId;

  static String? get userId => _userId;

  /// Derives a stable user ID from email (for email-only users).
  static String emailToUid(String email) {
    return sha256.convert(utf8.encode(email.toLowerCase().trim())).toString();
  }

  /// Called on app startup to restore the saved user ID so uploads work.
  static Future<void> loadUserId() async {
    final firebaseUid = FirebaseAuth.instance.currentUser?.uid;
    if (firebaseUid != null) {
      _userId = firebaseUid;
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('cloud_user_id');
  }

  /// Set up user ID for a new or returning user.
  static Future<void> initUser(String email) async {
    final firebaseUid = FirebaseAuth.instance.currentUser?.uid;
    _userId = firebaseUid ?? emailToUid(email);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cloud_user_id', _userId!);
  }

  /// Fire-and-forget: upload a single key to Firestore.
  static void upload(String key, String value) {
    if (_userId == null) return;
    FirebaseFirestore.instance
        .collection('users')
        .doc(_userId)
        .collection('prefs')
        .doc(_docId(key))
        .set({'v': value, 't': FieldValue.serverTimestamp()}).catchError((_) {});
  }

  /// Restore all Firestore data to SharedPreferences (called on login).
  /// Returns true if any data was found.
  static Future<bool> restore(String uid) async {
    _userId = uid;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('prefs')
          .get();
      if (snapshot.docs.isEmpty) return false;
      final prefs = await SharedPreferences.getInstance();
      for (final doc in snapshot.docs) {
        final value = doc.data()['v'];
        if (value is String) {
          final key = _fromDocId(doc.id);
          // Deserialize type-tagged values back to their original types
          if (value.startsWith('bool:')) {
            await prefs.setBool(key, value == 'bool:true');
          } else if (value.startsWith('int:')) {
            final n = int.tryParse(value.substring(4));
            if (n != null) await prefs.setInt(key, n);
          } else if (value.startsWith('double:')) {
            final d = double.tryParse(value.substring(7));
            if (d != null) await prefs.setDouble(key, d);
          } else {
            await prefs.setString(key, value);
          }
        }
      }
      await prefs.setString('cloud_user_id', uid);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Upload ALL current SharedPreferences keys to Firestore (full backup).
  /// Serializes bool/int/double with type tags so they restore correctly.
  static Future<void> uploadAll() async {
    if (_userId == null) return;
    final prefs = await SharedPreferences.getInstance();
    final all = prefs.getKeys();
    final batch = FirebaseFirestore.instance.batch();
    final colRef = FirebaseFirestore.instance
        .collection('users')
        .doc(_userId)
        .collection('prefs');
    for (final key in all) {
      String? value = prefs.getString(key);
      if (value == null) {
        final b = prefs.getBool(key);
        if (b != null) {
          value = 'bool:$b';
        } else {
          final i = prefs.getInt(key);
          if (i != null) {
            value = 'int:$i';
          } else {
            final d = prefs.getDouble(key);
            if (d != null) value = 'double:$d';
          }
        }
      }
      if (value != null) {
        batch.set(colRef.doc(_docId(key)),
            {'v': value, 't': FieldValue.serverTimestamp()});
      }
    }
    try {
      await batch.commit();
    } catch (_) {}
  }

  /// Upload a non-string value (bool/int/double) with type tag.
  static void uploadValue(String key, dynamic value) {
    String encoded;
    if (value is bool) {
      encoded = 'bool:$value';
    } else if (value is int) {
      encoded = 'int:$value';
    } else if (value is double) {
      encoded = 'double:$value';
    } else {
      encoded = value.toString();
    }
    upload(key, encoded);
  }

  // Firestore doc IDs can't contain '/' — replace with safe char
  static String _docId(String key) => key.replaceAll('/', '_fs_');
  static String _fromDocId(String id) => id.replaceAll('_fs_', '/');
}
