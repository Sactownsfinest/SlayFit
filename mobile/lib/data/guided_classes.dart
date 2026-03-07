import 'package:flutter/material.dart';

// ── Data Models ───────────────────────────────────────────────────────────────

class GuidedClassStep {
  final String name;
  final String description; // shown under the name
  final int durationSeconds;
  final String audioStart;  // played when step begins
  final String? audioCue;   // played at midpoint
  final String audioEnd;    // played at 10 seconds remaining
  final List<String> instructions; // bullet cues shown on screen

  const GuidedClassStep({
    required this.name,
    required this.description,
    required this.durationSeconds,
    required this.audioStart,
    this.audioCue,
    required this.audioEnd,
    required this.instructions,
  });
}

class GuidedClass {
  final String id;
  final String title;
  final String subtitle;
  final String category;
  final int totalMinutes;
  final String difficulty;
  final Color color;
  final IconData icon;
  final String audioIntro;  // played before first step
  final String audioOutro;  // played on completion
  final List<GuidedClassStep> steps;

  const GuidedClass({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.totalMinutes,
    required this.difficulty,
    required this.color,
    required this.icon,
    required this.audioIntro,
    required this.audioOutro,
    required this.steps,
  });

  int get totalSeconds =>
      steps.fold(0, (sum, s) => sum + s.durationSeconds);
}

// ── Audio file path helper ────────────────────────────────────────────────────

const _ms = 'audio/morning_stretch/';

// ── 10-Minute Morning Stretch Class ──────────────────────────────────────────

const morningStretchClass = GuidedClass(
  id: 'morning_stretch_10',
  title: '10-Min Morning Stretch',
  subtitle: 'Wake up your body from head to toe',
  category: 'Stretch',
  totalMinutes: 10,
  difficulty: 'Beginner',
  color: Color(0xFF60A5FA),
  icon: Icons.self_improvement,
  audioIntro: '${_ms}ms_class_intro.mp3',
  audioOutro: '${_ms}ms_class_outro.mp3',
  steps: [
    GuidedClassStep(
      name: 'Deep Breathing',
      description: 'Center your mind and wake up your body',
      durationSeconds: 45,
      audioStart: '${_ms}ms_01_breath_start.mp3',
      audioCue: '${_ms}ms_01_breath_mid.mp3',
      audioEnd: '${_ms}ms_01_breath_end.mp3',
      instructions: [
        'Stand tall, feet hip-width apart',
        'Close your eyes',
        'Inhale slowly through your nose for 4 counts',
        'Exhale fully through your mouth for 4 counts',
      ],
    ),
    GuidedClassStep(
      name: 'Neck Rolls',
      description: 'Release tension in the neck and upper traps',
      durationSeconds: 45,
      audioStart: '${_ms}ms_02_neck_start.mp3',
      audioCue: '${_ms}ms_02_neck_mid.mp3',
      audioEnd: '${_ms}ms_02_neck_end.mp3',
      instructions: [
        'Drop your right ear toward your right shoulder',
        'Slowly roll your head forward, then to the left',
        'Keep movements slow and controlled',
        'Never force or rush through it',
      ],
    ),
    GuidedClassStep(
      name: 'Shoulder Rolls',
      description: 'Open up the shoulders and upper back',
      durationSeconds: 45,
      audioStart: '${_ms}ms_03_shoulder_start.mp3',
      audioCue: '${_ms}ms_03_shoulder_mid.mp3',
      audioEnd: '${_ms}ms_03_shoulder_end.mp3',
      instructions: [
        'Roll both shoulders up, back, and down',
        'Make big, exaggerated circles',
        'Squeeze your shoulder blades at the back',
        'Then reverse — forward, up, and back',
      ],
    ),
    GuidedClassStep(
      name: 'Standing Side Stretch',
      description: '30 seconds each side',
      durationSeconds: 60,
      audioStart: '${_ms}ms_04_side_start.mp3',
      audioCue: '${_ms}ms_04_side_mid.mp3',
      audioEnd: '${_ms}ms_04_side_end.mp3',
      instructions: [
        'Reach your right arm up, lean left',
        'Keep your hips square and feet planted',
        'Feel the stretch from hip to fingertips',
        'After 30 seconds, switch sides',
      ],
    ),
    GuidedClassStep(
      name: 'Standing Forward Fold',
      description: 'Hamstrings, lower back, and calves',
      durationSeconds: 60,
      audioStart: '${_ms}ms_05_fold_start.mp3',
      audioCue: '${_ms}ms_05_fold_mid.mp3',
      audioEnd: '${_ms}ms_05_fold_end.mp3',
      instructions: [
        'Hinge at your hips and fold forward',
        'Let your arms hang heavy toward the floor',
        'Bend your knees as much as you need',
        'Let your head hang completely — no tension',
      ],
    ),
    GuidedClassStep(
      name: 'Cat-Cow',
      description: 'Spinal mobility and core warm-up',
      durationSeconds: 60,
      audioStart: '${_ms}ms_06_catcow_start.mp3',
      audioCue: '${_ms}ms_06_catcow_mid.mp3',
      audioEnd: '${_ms}ms_06_catcow_end.mp3',
      instructions: [
        'Come to all fours — wrists under shoulders',
        'Inhale: drop belly, lift chest and tailbone (Cow)',
        'Exhale: round spine up to ceiling (Cat)',
        'Flow smoothly with your breath',
      ],
    ),
    GuidedClassStep(
      name: "Child's Pose",
      description: 'Full back and hip release',
      durationSeconds: 60,
      audioStart: '${_ms}ms_07_child_start.mp3',
      audioCue: '${_ms}ms_07_child_mid.mp3',
      audioEnd: '${_ms}ms_07_child_end.mp3',
      instructions: [
        'Sit hips back toward your heels',
        'Stretch arms long in front of you',
        'Rest your forehead on the mat',
        'Just breathe — this is your reset',
      ],
    ),
    GuidedClassStep(
      name: 'Thread the Needle',
      description: 'Upper back rotation — 30 sec each side',
      durationSeconds: 60,
      audioStart: '${_ms}ms_08_thread_start.mp3',
      audioCue: '${_ms}ms_08_thread_mid.mp3',
      audioEnd: '${_ms}ms_08_thread_end.mp3',
      instructions: [
        'From all fours, slide right arm under your body',
        'Palm faces up, right shoulder rests on mat',
        'Keep your hips level — do not rotate them',
        'Switch sides at the halfway point',
      ],
    ),
    GuidedClassStep(
      name: 'Seated Spinal Twist',
      description: 'Spine rotation — 30 sec each side',
      durationSeconds: 60,
      audioStart: '${_ms}ms_09_twist_start.mp3',
      audioCue: '${_ms}ms_09_twist_mid.mp3',
      audioEnd: '${_ms}ms_09_twist_end.mp3',
      instructions: [
        'Sit tall, cross right foot over left thigh',
        'Twist to the right, left elbow outside right knee',
        'Sit up tall on every inhale, twist deeper on exhale',
        'Switch sides at the halfway point',
      ],
    ),
    GuidedClassStep(
      name: 'Knee to Chest',
      description: 'Lower back and hip release — 30 sec each side',
      durationSeconds: 60,
      audioStart: '${_ms}ms_10_knee_start.mp3',
      audioCue: '${_ms}ms_10_knee_mid.mp3',
      audioEnd: '${_ms}ms_10_knee_end.mp3',
      instructions: [
        'Lie on your back, hug right knee to chest',
        'Keep left leg long and relaxed on the mat',
        'Gently rock side to side if that feels good',
        'Switch sides at the halfway point',
      ],
    ),
    GuidedClassStep(
      name: 'Savasana',
      description: 'Final relaxation — you earned this',
      durationSeconds: 75,
      audioStart: '${_ms}ms_11_final_start.mp3',
      audioCue: '${_ms}ms_11_final_mid.mp3',
      audioEnd: '${_ms}ms_11_final_end.mp3',
      instructions: [
        'Lie flat on your back, arms at sides, palms up',
        'Close your eyes and let everything go',
        'Scan your body — feel how different you feel',
        'Let your breath return to its natural rhythm',
      ],
    ),
  ],
);

// ── Class catalog ─────────────────────────────────────────────────────────────

const allGuidedClasses = [morningStretchClass];
