import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    return prefs.getString(_displayNameKey) ?? 'SlayFit User';
  }

  static Future<void> setDisplayName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_displayNameKey, name);
    // Update all challenges this user is in
    if (uid == null) return;
    final snap = await _db
        .collection('challenges')
        .where('participantIds', arrayContains: uid)
        .get();
    for (final doc in snap.docs) {
      await doc.reference
          .update({'participants.$uid.name': name});
    }
  }

  // ── Challenges ─────────────────────────────────────────────────────────────

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
    if (uid == null) return Stream.value([]);
    return _db
        .collection('challenges')
        .where('participantIds', arrayContains: uid)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => SlayChallenge.fromFirestore(
                d.id, d.data()))
            .where((c) => c.isActive)
            .toList());
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
}
