import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/challenge_definitions.dart';

// ── Models ────────────────────────────────────────────────────────────────────

enum ChallengeType { calories, workouts, streak, goalHits }

extension ChallengeTypeX on ChallengeType {
  String get label {
    switch (this) {
      case ChallengeType.calories:
        return 'Most Calories Burned';
      case ChallengeType.workouts:
        return 'Most Workouts';
      case ChallengeType.streak:
        return 'Longest Streak';
      case ChallengeType.goalHits:
        return 'Calorie Goal Hits';
    }
  }

  String get emoji {
    switch (this) {
      case ChallengeType.calories:
        return '🔥';
      case ChallengeType.workouts:
        return '💪';
      case ChallengeType.streak:
        return '⚡';
      case ChallengeType.goalHits:
        return '🎯';
    }
  }

  String get unit {
    switch (this) {
      case ChallengeType.calories:
        return 'kcal';
      case ChallengeType.workouts:
        return 'workouts';
      case ChallengeType.streak:
        return 'days';
      case ChallengeType.goalHits:
        return 'days';
    }
  }

  static ChallengeType fromString(String s) {
    return ChallengeType.values.firstWhere((e) => e.name == s,
        orElse: () => ChallengeType.workouts);
  }
}

class ChallengeParticipant {
  final String userId;
  final String displayName;
  final double score;

  const ChallengeParticipant({
    required this.userId,
    required this.displayName,
    required this.score,
  });
}

class SlayChallenge {
  final String id;
  final String title;
  final ChallengeType type;
  final int durationDays;
  final DateTime startDate;
  final DateTime endDate;
  final String createdBy;
  final String creatorName;
  final String joinCode;
  final List<ChallengeParticipant> participants;

  const SlayChallenge({
    required this.id,
    required this.title,
    required this.type,
    required this.durationDays,
    required this.startDate,
    required this.endDate,
    required this.createdBy,
    required this.creatorName,
    required this.joinCode,
    required this.participants,
  });

  bool get isActive => DateTime.now().isBefore(endDate);

  int get daysLeft =>
      endDate.difference(DateTime.now()).inDays.clamp(0, durationDays);

  int myRank(String userId) {
    final sorted = [...participants]
      ..sort((a, b) => b.score.compareTo(a.score));
    return sorted.indexWhere((p) => p.userId == userId) + 1;
  }

  double myScore(String userId) {
    return participants
        .firstWhere((p) => p.userId == userId,
            orElse: () => const ChallengeParticipant(
                userId: '', displayName: '', score: 0))
        .score;
  }

  factory SlayChallenge.fromFirestore(
      String id, Map<String, dynamic> data) {
    final parts = <ChallengeParticipant>[];
    final rawParts = data['participants'] as Map<String, dynamic>? ?? {};
    rawParts.forEach((uid, val) {
      final v = val as Map<String, dynamic>;
      parts.add(ChallengeParticipant(
        userId: uid,
        displayName: v['name'] as String? ?? 'Unknown',
        score: (v['score'] as num? ?? 0).toDouble(),
      ));
    });
    return SlayChallenge(
      id: id,
      title: data['title'] as String? ?? '',
      type: ChallengeTypeX.fromString(data['type'] as String? ?? ''),
      durationDays: (data['durationDays'] as num? ?? 7).toInt(),
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      createdBy: data['createdBy'] as String? ?? '',
      creatorName: data['creatorName'] as String? ?? '',
      joinCode: data['joinCode'] as String? ?? '',
      participants: parts,
    );
  }
}

// ── Recipe Post ───────────────────────────────────────────────────────────────

class RecipePost {
  final String id;
  final String uid;
  final String displayName;
  final String photoBase64;
  final String caption;
  final List<String> likedBy;
  final int likeCount;
  final int commentCount;
  final DateTime createdAt;

  const RecipePost({
    required this.id,
    required this.uid,
    required this.displayName,
    required this.photoBase64,
    required this.caption,
    required this.likedBy,
    required this.likeCount,
    required this.commentCount,
    required this.createdAt,
  });

  factory RecipePost.fromFirestore(String id, Map<String, dynamic> d) =>
      RecipePost(
        id: id,
        uid: d['uid'] as String? ?? '',
        displayName: d['displayName'] as String? ?? 'SlayFit User',
        photoBase64: d['photoBase64'] as String? ?? '',
        caption: d['caption'] as String? ?? '',
        likedBy: List<String>.from(d['likedBy'] as List? ?? []),
        likeCount: (d['likeCount'] as num? ?? 0).toInt(),
        commentCount: (d['commentCount'] as num? ?? 0).toInt(),
        createdAt: d['createdAt'] is Timestamp
            ? (d['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
      );
}

class RecipeComment {
  final String id;
  final String uid;
  final String displayName;
  final String text;
  final DateTime createdAt;

  const RecipeComment({
    required this.id,
    required this.uid,
    required this.displayName,
    required this.text,
    required this.createdAt,
  });

  factory RecipeComment.fromFirestore(String id, Map<String, dynamic> d) =>
      RecipeComment(
        id: id,
        uid: d['uid'] as String? ?? '',
        displayName: d['displayName'] as String? ?? 'SlayFit User',
        text: d['text'] as String? ?? '',
        createdAt: d['createdAt'] is Timestamp
            ? (d['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
      );
}

// ── App Notification ──────────────────────────────────────────────────────────

class AppNotification {
  final String id;
  final String type; // 'challenge_invite' | 'invite_accepted'
  final String fromUid;
  final String fromName;
  final String? challengeName;
  final String? joinCode;
  final String? definitionId;
  final bool read;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.fromUid,
    required this.fromName,
    this.challengeName,
    this.joinCode,
    this.definitionId,
    required this.read,
    required this.createdAt,
  });

  factory AppNotification.fromFirestore(String id, Map<String, dynamic> d) =>
      AppNotification(
        id: id,
        type: d['type'] as String? ?? '',
        fromUid: d['fromUid'] as String? ?? '',
        fromName: d['fromName'] as String? ?? 'Someone',
        challengeName: d['challengeName'] as String?,
        joinCode: d['joinCode'] as String?,
        definitionId: d['definitionId'] as String?,
        read: d['read'] as bool? ?? false,
        createdAt: d['createdAt'] is Timestamp
            ? (d['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
      );
}

// ─────────────────────────────────────────────────────────────────────────────

class ChatMsg {
  final String id;
  final String userId;
  final String displayName;
  final String text;
  final DateTime timestamp;

  const ChatMsg({
    required this.id,
    required this.userId,
    required this.displayName,
    required this.text,
    required this.timestamp,
  });
}

// ── Service ───────────────────────────────────────────────────────────────────

class FirebaseService {
  static final _auth = FirebaseAuth.instance;
  static final _db = FirebaseFirestore.instance;
  static final _rtdb = FirebaseDatabase.instance;

  static const _displayNameKey = 'community_display_name';

  // ── Auth ───────────────────────────────────────────────────────────────────

  static User? get currentUser => _auth.currentUser;
  static String? get uid => _auth.currentUser?.uid;

  static Future<void> ensureSignedIn() async {
    if (_auth.currentUser == null) {
      await _auth.signInAnonymously();
    }
  }

  static Future<String> getDisplayName() async {
    final prefs = await SharedPreferences.getInstance();
    final community = prefs.getString(_displayNameKey);
    if (community != null && community.isNotEmpty && community != 'SlayFit User') {
      return community;
    }
    // Fall back to the profile name set during onboarding
    final profileName = prefs.getString('user_name');
    if (profileName != null && profileName.isNotEmpty) {
      return profileName;
    }
    return 'SlayFit User';
  }

  static Future<void> setDisplayName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_displayNameKey, name);
    if (uid == null) return;
    // Update users collection so search returns the new name
    await registerUser(name);
    // Update all challenges this user is in
    final snap = await _db
        .collection('challenges')
        .where('participantIds', arrayContains: uid)
        .get();
    for (final doc in snap.docs) {
      await doc.reference.update({'participants.$uid.name': name});
    }
  }

  // ── Challenges ─────────────────────────────────────────────────────────────

  static String _fbKeyForDef(String definitionId) => 'challenge_fb_$definitionId';

  /// Creates a Firebase challenge for a catalog challenge definition the first
  /// time the user joins it.  Idempotent — subsequent calls return the stored ID.
  static Future<String?> createChallengeFromDefinition(ChallengeDefinition def) async {
    try {
      await ensureSignedIn();
      final prefs = await SharedPreferences.getInstance();
      final fbKey = _fbKeyForDef(def.id);
      final existing = prefs.getString(fbKey);
      if (existing != null) return existing;

      final name = await getDisplayName();
      final now = DateTime.now();
      final code = _randomCode();
      final ref = _db.collection('challenges').doc();
      await ref.set({
        'title': def.name,
        'type': ChallengeType.streak.name,
        'durationDays': def.durationDays,
        'startDate': Timestamp.fromDate(now),
        'endDate': Timestamp.fromDate(now.add(Duration(days: def.durationDays))),
        'createdBy': uid,
        'creatorName': name,
        'joinCode': code,
        'definitionId': def.id,
        'participantIds': [uid],
        'participants': {
          uid!: {'name': name, 'score': 0.0},
        },
      });
      await prefs.setString(fbKey, ref.id);
      return ref.id;
    } catch (_) {
      return null;
    }
  }

  /// Updates the user's score on the Firebase challenge tied to a catalog def.
  static Future<void> syncCatalogChallengeScore(String definitionId, double score) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final fbId = prefs.getString(_fbKeyForDef(definitionId));
      if (fbId == null || uid == null) return;
      await updateMyScore(fbId, score);
    } catch (_) {}
  }

  /// Returns the join code for the Firebase challenge tied to a catalog def, or null.
  static Future<String?> getCatalogChallengeCode(String definitionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final fbId = prefs.getString(_fbKeyForDef(definitionId));
      if (fbId == null) return null;
      final doc = await _db.collection('challenges').doc(fbId).get();
      return doc.data()?['joinCode'] as String?;
    } catch (_) {
      return null;
    }
  }

  static String _randomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rnd = Random.secure();
    return List.generate(6, (_) => chars[rnd.nextInt(chars.length)]).join();
  }

  static Future<SlayChallenge> createChallenge({
    required String title,
    required ChallengeType type,
    required int durationDays,
  }) async {
    await ensureSignedIn();
    final name = await getDisplayName();
    final now = DateTime.now();
    final code = _randomCode();
    final ref = _db.collection('challenges').doc();
    final data = {
      'title': title,
      'type': type.name,
      'durationDays': durationDays,
      'startDate': Timestamp.fromDate(now),
      'endDate': Timestamp.fromDate(now.add(Duration(days: durationDays))),
      'createdBy': uid,
      'creatorName': name,
      'joinCode': code,
      'participantIds': [uid],
      'participants': {
        uid!: {'name': name, 'score': 0.0},
      },
    };
    await ref.set(data);
    return SlayChallenge(
      id: ref.id,
      title: title,
      type: type,
      durationDays: durationDays,
      startDate: now,
      endDate: now.add(Duration(days: durationDays)),
      createdBy: uid!,
      creatorName: name,
      joinCode: code,
      participants: [
        ChallengeParticipant(userId: uid!, displayName: name, score: 0),
      ],
    );
  }

  static Future<SlayChallenge?> joinChallenge(String code) async {
    await ensureSignedIn();
    final name = await getDisplayName();
    final snap = await _db
        .collection('challenges')
        .where('joinCode', isEqualTo: code.toUpperCase())
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    final doc = snap.docs.first;
    await doc.reference.update({
      'participantIds': FieldValue.arrayUnion([uid]),
      'participants.$uid': {'name': name, 'score': 0.0},
    });
    final updated = await doc.reference.get();
    return SlayChallenge.fromFirestore(
        doc.id, updated.data() as Map<String, dynamic>);
  }

  static Stream<List<SlayChallenge>> myChallengesStream() {
    // Switch the Firestore query whenever the Firebase Auth user changes
    // (e.g. anonymous → Google). Without this, a UID captured at startup
    // becomes stale and the query returns nothing after re-auth.
    StreamSubscription? innerSub;
    StreamSubscription? authSub;
    late StreamController<List<SlayChallenge>> controller;
    controller = StreamController<List<SlayChallenge>>(
      onCancel: () {
        innerSub?.cancel();
        authSub?.cancel();
      },
    );
    authSub = _auth.authStateChanges().listen((user) {
      innerSub?.cancel();
      if (user == null) {
        controller.add([]);
        return;
      }
      innerSub = _db
          .collection('challenges')
          .where('participantIds', arrayContains: user.uid)
          .snapshots()
          .map((snap) => snap.docs
              .map((d) => SlayChallenge.fromFirestore(d.id, d.data()))
              .where((c) => c.isActive)
              .toList())
          .listen(controller.add, onError: controller.addError);
    });
    return controller.stream;
  }

  static Future<void> updateMyScore(
      String challengeId, double score) async {
    if (uid == null) return;
    await _db.collection('challenges').doc(challengeId).update({
      'participants.$uid.score': score,
    });
  }

  static Future<void> leaveChallenge(String challengeId) async {
    if (uid == null) return;
    await _db.collection('challenges').doc(challengeId).update({
      'participantIds': FieldValue.arrayRemove([uid]),
      'participants.$uid': FieldValue.delete(),
    });
  }

  // ── Community Chat ─────────────────────────────────────────────────────────

  static Stream<List<ChatMsg>> chatStream() {
    return _rtdb
        .ref('chat')
        .orderByChild('ts')
        .limitToLast(100)
        .onValue
        .map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return <ChatMsg>[];
      final msgs = data.entries
          .map((e) {
            final v = e.value as Map<dynamic, dynamic>;
            return ChatMsg(
              id: e.key as String,
              userId: v['userId'] as String? ?? '',
              displayName: v['name'] as String? ?? 'Anonymous',
              text: v['text'] as String? ?? '',
              timestamp: DateTime.fromMillisecondsSinceEpoch(
                  (v['ts'] as int? ?? 0)),
            );
          })
          .toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return msgs;
    });
  }

  static Future<void> sendChatMessage(String text) async {
    await ensureSignedIn();
    final name = await getDisplayName();
    await _rtdb.ref('chat').push().set({
      'userId': uid,
      'name': name,
      'text': text,
      'ts': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // ── User Registry (for in-app search & invites) ────────────────────────────

  /// Register/update this user in the global users collection so others can
  /// search for them by display name.
  static Future<void> registerUser(String displayName) async {
    if (uid == null) return;
    await _db.collection('users').doc(uid).set({
      'displayName': displayName,
      'uid': uid,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Search registered users by display name (case-insensitive, excludes self).
  static Future<List<Map<String, String>>> searchUsers(String query) async {
    final q = query.trim().toLowerCase();
    final snap = await _db.collection('users').limit(50).get();
    return snap.docs
        .where((d) => d.id != uid)
        .where((d) {
          if (q.isEmpty) return true;
          final name = (d.data()['displayName'] as String? ?? '').toLowerCase();
          return name.contains(q);
        })
        .map((d) => {
              'uid': d.data()['uid'] as String? ?? d.id,
              'displayName': d.data()['displayName'] as String? ?? 'Unknown',
            })
        .toList();
  }

  // ── Notifications ──────────────────────────────────────────────────────────

  static DocumentReference _myNotifRef(String notifId) =>
      _db.collection('users').doc(uid).collection('notifications').doc(notifId);

  static Stream<List<AppNotification>> myNotificationsStream() {
    if (uid == null) return Stream.value([]);
    return _db
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(30)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => AppNotification.fromFirestore(d.id, d.data()))
            .toList());
  }

  static Future<void> markNotificationRead(String notifId) async {
    if (uid == null) return;
    await _myNotifRef(notifId).update({'read': true});
  }

  static Future<void> deleteNotification(String notifId) async {
    if (uid == null) return;
    await _myNotifRef(notifId).delete();
  }

  /// Send a challenge invite to a specific user.
  static Future<void> sendChallengeInviteToUser({
    required String toUid,
    required String challengeName,
    required String joinCode,
  }) async {
    if (uid == null) return;
    final name = await getDisplayName();
    await _db
        .collection('users')
        .doc(toUid)
        .collection('notifications')
        .add({
      'type': 'challenge_invite',
      'fromUid': uid,
      'fromName': name,
      'challengeName': challengeName,
      'joinCode': joinCode,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Send a catalog challenge invite directly to a user by UID.
  /// Creates the Firebase challenge doc if not yet created, then sends notification.
  static Future<void> sendCatalogChallengeInvite({
    required String toUid,
    required ChallengeDefinition def,
  }) async {
    if (uid == null) return;
    final fbId = await createChallengeFromDefinition(def);
    final code = fbId != null ? await getCatalogChallengeCode(def.id) : null;
    final myName = await getDisplayName();
    await _db
        .collection('users')
        .doc(toUid)
        .collection('notifications')
        .add({
      'type': 'challenge_invite',
      'fromUid': uid,
      'fromName': myName,
      'challengeName': def.name,
      'definitionId': def.id,
      'joinCode': code,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Returns all registered users except self (for invite list).
  static Future<List<Map<String, String>>> getAllUsers() async {
    final snap = await _db
        .collection('users')
        .orderBy('displayName')
        .limit(50)
        .get();
    return snap.docs
        .where((d) => d.id != uid)
        .map((d) => {
              'uid': d.data()['uid'] as String? ?? d.id,
              'displayName': d.data()['displayName'] as String? ?? 'Unknown',
            })
        .toList();
  }

  // ── Catalog Challenge Accountability ───────────────────────────────────────

  /// Write this user's check-in progress for a catalog challenge so others can see it.
  static Future<void> updateCatalogCheckin(
      String challengeId, List<String> completedDates) async {
    if (uid == null) { debugPrint('CHECKIN: uid is null, skipping'); return; }
    try {
      final name = await getDisplayName();
      debugPrint('CHECKIN: writing $challengeId for $uid ($name)');
      await _db
          .collection('catalog_checkins')
          .doc(challengeId)
          .collection('users')
          .doc(uid)
          .set({
        'uid': uid,
        'displayName': name,
        'completedDates': completedDates,
        'lastCheckIn': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
      debugPrint('CHECKIN: write success');
    } catch (e) { debugPrint('CHECKIN ERROR: $e'); }
  }

  /// Stream all participants' progress for a catalog challenge.
  static Stream<List<Map<String, dynamic>>> catalogCheckinStream(
      String challengeId) {
    return _db
        .collection('catalog_checkins')
        .doc(challengeId)
        .collection('users')
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  // ── Recipe Posts ────────────────────────────────────────────────────────────

  /// Post a recipe photo to the community feed.
  /// [photoBase64] is a base64-encoded JPEG string.
  static Future<String?> postRecipe({
    required String photoBase64,
    required String caption,
  }) async {
    try {
      await ensureSignedIn();
      final name = await getDisplayName();
      final ref = _db.collection('recipe_posts').doc();
      await ref.set({
        'uid': uid,
        'displayName': name,
        'photoBase64': photoBase64,
        'caption': caption,
        'likedBy': <String>[],
        'likeCount': 0,
        'commentCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return ref.id;
    } catch (_) {
      return null;
    }
  }

  static Stream<List<RecipePost>> recipesStream() {
    return _db
        .collection('recipe_posts')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => RecipePost.fromFirestore(d.id, d.data()))
            .toList());
  }

  static Future<void> toggleRecipeLike(String postId) async {
    if (uid == null) return;
    final ref = _db.collection('recipe_posts').doc(postId);
    final doc = await ref.get();
    final data = doc.data();
    if (data == null) return;
    final likedBy = List<String>.from(data['likedBy'] as List? ?? []);
    if (likedBy.contains(uid)) {
      await ref.update({
        'likedBy': FieldValue.arrayRemove([uid]),
        'likeCount': FieldValue.increment(-1),
      });
    } else {
      await ref.update({
        'likedBy': FieldValue.arrayUnion([uid]),
        'likeCount': FieldValue.increment(1),
      });
    }
  }

  static Stream<List<RecipeComment>> recipeCommentsStream(String postId) {
    return _db
        .collection('recipe_posts')
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => RecipeComment.fromFirestore(d.id, d.data()))
            .toList());
  }

  static Future<void> addRecipeComment(String postId, String text) async {
    if (uid == null) return;
    final name = await getDisplayName();
    final batch = _db.batch();
    final commentRef = _db
        .collection('recipe_posts')
        .doc(postId)
        .collection('comments')
        .doc();
    batch.set(commentRef, {
      'uid': uid,
      'displayName': name,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.update(_db.collection('recipe_posts').doc(postId), {
      'commentCount': FieldValue.increment(1),
    });
    await batch.commit();
  }

  /// Accept a challenge invite — joins the challenge and notifies the sender.
  static Future<void> acceptChallengeInvite(AppNotification notif) async {
    if (uid == null) return;
    // Join the challenge by code
    if (notif.joinCode != null) {
      await joinChallenge(notif.joinCode!);
    }
    // Mark as read
    await markNotificationRead(notif.id);
    // Notify the sender
    final myName = await getDisplayName();
    await _db
        .collection('users')
        .doc(notif.fromUid)
        .collection('notifications')
        .add({
      'type': 'invite_accepted',
      'fromUid': uid,
      'fromName': myName,
      'challengeName': notif.challengeName,
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
