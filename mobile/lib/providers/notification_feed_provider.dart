import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalNotif {
  final String id;
  final String title;
  final String body;
  final String type; // 'achievement' | 'meal_plan' | 'streak' | 'general'
  bool read;
  final DateTime createdAt;

  LocalNotif({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.read = false,
    required this.createdAt,
  });

  factory LocalNotif.fromJson(Map<String, dynamic> j) => LocalNotif(
        id: j['id'] as String,
        title: j['title'] as String,
        body: j['body'] as String? ?? '',
        type: j['type'] as String? ?? 'general',
        read: j['read'] as bool? ?? false,
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'type': type,
        'read': read,
        'createdAt': createdAt.toIso8601String(),
      };
}

class NotifFeedNotifier extends StateNotifier<List<LocalNotif>> {
  NotifFeedNotifier() : super([]) {
    _load();
  }

  static const _key = 'local_notif_feed_v1';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key) ?? '[]';
    try {
      final list = jsonDecode(raw) as List;
      if (mounted) {
        state = list
            .map((e) => LocalNotif.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _key, jsonEncode(state.map((n) => n.toJson()).toList()));
  }

  void add(String title, String body, String type) {
    final notif = LocalNotif(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
      type: type,
      createdAt: DateTime.now(),
    );
    state = [notif, ...state].take(50).toList();
    _persist();
  }

  void markAllRead() {
    if (state.any((n) => !n.read)) {
      for (final n in state) {
        n.read = true;
      }
      state = List.from(state);
      _persist();
    }
  }

  void remove(String id) {
    state = state.where((n) => n.id != id).toList();
    _persist();
  }

  int get unreadCount => state.where((n) => !n.read).length;
}

final notifFeedProvider =
    StateNotifierProvider<NotifFeedNotifier, List<LocalNotif>>((ref) {
  return NotifFeedNotifier();
});
