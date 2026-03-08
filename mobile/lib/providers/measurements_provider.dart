import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Model ────────────────────────────────────────────────────────────────────

class BodyMeasurement {
  final String id;
  final DateTime date;
  final double? waistCm;
  final double? hipsCm;
  final double? chestCm;
  final double? armsCm;
  final double? thighsCm;
  final double? bodyFatPercent;
  final String? notes;

  const BodyMeasurement({
    required this.id,
    required this.date,
    this.waistCm,
    this.hipsCm,
    this.chestCm,
    this.armsCm,
    this.thighsCm,
    this.bodyFatPercent,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'waistCm': waistCm,
        'hipsCm': hipsCm,
        'chestCm': chestCm,
        'armsCm': armsCm,
        'thighsCm': thighsCm,
        'bodyFatPercent': bodyFatPercent,
        'notes': notes,
      };

  factory BodyMeasurement.fromJson(Map<String, dynamic> j) => BodyMeasurement(
        id: j['id'] as String,
        date: DateTime.parse(j['date'] as String),
        waistCm: (j['waistCm'] as num?)?.toDouble(),
        hipsCm: (j['hipsCm'] as num?)?.toDouble(),
        chestCm: (j['chestCm'] as num?)?.toDouble(),
        armsCm: (j['armsCm'] as num?)?.toDouble(),
        thighsCm: (j['thighsCm'] as num?)?.toDouble(),
        bodyFatPercent: (j['bodyFatPercent'] as num?)?.toDouble(),
        notes: j['notes'] as String?,
      );
}

// ── State ────────────────────────────────────────────────────────────────────

class MeasurementsState {
  final List<BodyMeasurement> entries;

  const MeasurementsState({this.entries = const []});

  BodyMeasurement? get latest =>
      entries.isEmpty ? null : entries.first;

  MeasurementsState copyWith({List<BodyMeasurement>? entries}) =>
      MeasurementsState(entries: entries ?? this.entries);
}

// ── Notifier ─────────────────────────────────────────────────────────────────

class MeasurementsNotifier extends StateNotifier<MeasurementsState> {
  MeasurementsNotifier() : super(const MeasurementsState()) {
    _load();
  }

  static const _key = 'body_measurements_v1';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return;
    final list = (jsonDecode(raw) as List)
        .map((e) => BodyMeasurement.fromJson(e as Map<String, dynamic>))
        .toList();
    state = state.copyWith(entries: list);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _key, jsonEncode(state.entries.map((e) => e.toJson()).toList()));
  }

  Future<void> addMeasurement(BodyMeasurement m) async {
    state = state.copyWith(entries: [m, ...state.entries]);
    await _save();
  }

  Future<void> deleteMeasurement(String id) async {
    state = state.copyWith(
        entries: state.entries.where((e) => e.id != id).toList());
    await _save();
  }
}

// ── Provider ─────────────────────────────────────────────────────────────────

final measurementsProvider =
    StateNotifierProvider<MeasurementsNotifier, MeasurementsState>(
        (ref) => MeasurementsNotifier());
