import '../providers/workout_provider.dart';

// ── Workout Library ────────────────────────────────────────────────────────
// Pre-built plans organized by duration and type.
// IDs use prefix 'lib_' so they are never confused with user-created plans.

enum LibraryCategory { gettingStarted, cardio, strength, flexibility }

class LibraryPlan {
  final String id;
  final String name;
  final String description;
  final int durationMinutes;
  final LibraryCategory category;
  final String difficulty; // 'Beginner' | 'Intermediate' | 'Advanced'
  final String videoQuery; // YouTube search query for guided video
  final WorkoutPlan plan;

  const LibraryPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.durationMinutes,
    required this.category,
    required this.difficulty,
    required this.videoQuery,
    required this.plan,
  });
}

// Helper to build a LibraryPlan without boilerplate
LibraryPlan _plan({
  required String id,
  required String name,
  required String description,
  required int minutes,
  required LibraryCategory category,
  required String difficulty,
  required String videoQuery,
  required List<_Ex> exercises,
}) {
  return LibraryPlan(
    id: id,
    name: name,
    description: description,
    durationMinutes: minutes,
    category: category,
    difficulty: difficulty,
    videoQuery: videoQuery,
    plan: WorkoutPlan(
      id: 'lib_$id',
      name: name,
      exercises: exercises
          .map((e) => WorkoutExercise(
                id: 'lib_${id}_${e.name.replaceAll(' ', '_')}',
                name: e.name,
                sets: List.generate(
                  e.sets,
                  (_) => WorkoutSet(reps: e.reps),
                ),
              ))
          .toList(),
      createdAt: DateTime(2024, 1, 1),
    ),
  );
}

class _Ex {
  final String name;
  final int sets;
  final int reps;
  const _Ex(this.name, {required this.sets, required this.reps});
}

// ── 5-Minute Plans ─────────────────────────────────────────────────────────

final kLibrary5Min = <LibraryPlan>[
  _plan(
    id: '5_quickstart',
    name: 'Quick Start',
    description:
        'Perfect first workout. 5 simple moves to get your body moving with zero equipment.',
    minutes: 5,
    category: LibraryCategory.gettingStarted,
    difficulty: 'Beginner',
    videoQuery: '5 minute beginner workout no equipment full body',
    exercises: [
      const _Ex('Jumping Jacks', sets: 1, reps: 20),
      const _Ex('Bodyweight Squat', sets: 1, reps: 10),
      const _Ex('Push-Up (on knees ok)', sets: 1, reps: 8),
      const _Ex('Standing March', sets: 1, reps: 20),
      const _Ex('Arm Circles', sets: 1, reps: 15),
    ],
  ),
  _plan(
    id: '5_morning_wake_up',
    name: 'Morning Wake-Up',
    description:
        'Gentle moves to wake up your body and get blood flowing first thing in the morning.',
    minutes: 5,
    category: LibraryCategory.gettingStarted,
    difficulty: 'Beginner',
    videoQuery: '5 minute morning wake up stretch routine',
    exercises: [
      const _Ex('Neck Rolls', sets: 1, reps: 10),
      const _Ex('Shoulder Roll', sets: 1, reps: 10),
      const _Ex('Hip Circle', sets: 1, reps: 10),
      const _Ex('Knee Raise March', sets: 1, reps: 20),
      const _Ex('Standing Cat-Cow Stretch', sets: 1, reps: 10),
    ],
  ),
  _plan(
    id: '5_core_express',
    name: 'Core Express',
    description:
        'A quick ab circuit you can do anywhere. Great to tack on after any workout.',
    minutes: 5,
    category: LibraryCategory.strength,
    difficulty: 'Beginner',
    videoQuery: '5 minute ab workout beginners core',
    exercises: [
      const _Ex('Plank Hold', sets: 1, reps: 20),
      const _Ex('Crunch', sets: 1, reps: 15),
      const _Ex('Bicycle Crunch', sets: 1, reps: 20),
      const _Ex('Dead Bug', sets: 1, reps: 10),
      const _Ex('Glute Bridge', sets: 1, reps: 15),
    ],
  ),
  _plan(
    id: '5_desk_break',
    name: 'Desk Break',
    description:
        'No equipment, no sweat. Move your body after sitting all day.',
    minutes: 5,
    category: LibraryCategory.flexibility,
    difficulty: 'Beginner',
    videoQuery: '5 minute office desk stretch break sitting',
    exercises: [
      const _Ex('Seated Spinal Twist', sets: 1, reps: 5),
      const _Ex('Standing Hip Flexor Stretch', sets: 1, reps: 5),
      const _Ex('Calf Raises', sets: 1, reps: 15),
      const _Ex('Wall Chest Stretch', sets: 1, reps: 5),
      const _Ex('Standing Forward Fold', sets: 1, reps: 5),
    ],
  ),
];

// ── 10-Minute Plans ────────────────────────────────────────────────────────

final kLibrary10Min = <LibraryPlan>[
  _plan(
    id: '10_easy_full_body',
    name: 'Easy Full Body',
    description:
        'A gentle full-body circuit for complete beginners. Light effort, big confidence boost.',
    minutes: 10,
    category: LibraryCategory.gettingStarted,
    difficulty: 'Beginner',
    videoQuery: '10 minute easy full body workout complete beginners',
    exercises: [
      const _Ex('Marching in Place', sets: 2, reps: 20),
      const _Ex('Wall Push-Up', sets: 2, reps: 10),
      const _Ex('Chair Squat', sets: 2, reps: 10),
      const _Ex('Standing Side Bend', sets: 2, reps: 10),
      const _Ex('Calf Raise', sets: 2, reps: 15),
    ],
  ),
  _plan(
    id: '10_cardio_kickstart',
    name: 'Cardio Kickstart',
    description:
        'Low-impact cardio that raises your heart rate without pounding your joints.',
    minutes: 10,
    category: LibraryCategory.cardio,
    difficulty: 'Beginner',
    videoQuery: '10 minute low impact cardio workout no jumping beginners',
    exercises: [
      const _Ex('Step Touch', sets: 2, reps: 30),
      const _Ex('Modified Jumping Jack', sets: 2, reps: 20),
      const _Ex('Low-Impact High Knees', sets: 2, reps: 20),
      const _Ex('Side Step with Arm Swing', sets: 2, reps: 20),
      const _Ex('Standing Bicycle', sets: 2, reps: 20),
    ],
  ),
  _plan(
    id: '10_upper_body',
    name: 'Upper Body Basics',
    description:
        'Build arm, shoulder and back strength with just your bodyweight.',
    minutes: 10,
    category: LibraryCategory.strength,
    difficulty: 'Beginner',
    videoQuery: '10 minute upper body bodyweight workout no equipment',
    exercises: [
      const _Ex('Push-Up', sets: 3, reps: 8),
      const _Ex('Tricep Dip (using chair)', sets: 3, reps: 10),
      const _Ex('Superman Hold', sets: 3, reps: 8),
      const _Ex('Shoulder Tap', sets: 3, reps: 10),
      const _Ex('Wide Push-Up', sets: 2, reps: 8),
    ],
  ),
  _plan(
    id: '10_lower_body',
    name: 'Lower Body Basics',
    description:
        'Strengthen your legs and glutes with beginner-friendly bodyweight moves.',
    minutes: 10,
    category: LibraryCategory.strength,
    difficulty: 'Beginner',
    videoQuery: '10 minute leg glute workout beginners no equipment',
    exercises: [
      const _Ex('Bodyweight Squat', sets: 3, reps: 12),
      const _Ex('Reverse Lunge', sets: 3, reps: 10),
      const _Ex('Glute Bridge', sets: 3, reps: 15),
      const _Ex('Side-Lying Leg Raise', sets: 2, reps: 12),
      const _Ex('Wall Sit', sets: 2, reps: 20),
    ],
  ),
  _plan(
    id: '10_yoga_flow',
    name: '10-Min Yoga Flow',
    description:
        'Beginner-friendly yoga sequence to improve flexibility and calm your mind.',
    minutes: 10,
    category: LibraryCategory.flexibility,
    difficulty: 'Beginner',
    videoQuery: '10 minute yoga flow for beginners flexibility',
    exercises: [
      const _Ex('Child\'s Pose', sets: 1, reps: 5),
      const _Ex('Cat-Cow', sets: 1, reps: 10),
      const _Ex('Downward Dog', sets: 1, reps: 5),
      const _Ex('Low Lunge (each side)', sets: 1, reps: 5),
      const _Ex('Seated Forward Fold', sets: 1, reps: 5),
      const _Ex('Supine Twist (each side)', sets: 1, reps: 5),
    ],
  ),
];

// ── 30-Minute Plans ────────────────────────────────────────────────────────

final kLibrary30Min = <LibraryPlan>[
  _plan(
    id: '30_beginner_full_body',
    name: 'Beginner Full Body',
    description:
        'Your first real strength workout. Covers every major muscle group with manageable sets.',
    minutes: 30,
    category: LibraryCategory.gettingStarted,
    difficulty: 'Beginner',
    videoQuery: '30 minute full body workout beginners no equipment home',
    exercises: [
      const _Ex('Jumping Jack Warm-Up', sets: 2, reps: 20),
      const _Ex('Bodyweight Squat', sets: 3, reps: 12),
      const _Ex('Push-Up', sets: 3, reps: 8),
      const _Ex('Reverse Lunge', sets: 3, reps: 10),
      const _Ex('Bent-Over Row (water bottles ok)', sets: 3, reps: 10),
      const _Ex('Plank Hold', sets: 3, reps: 20),
      const _Ex('Glute Bridge', sets: 3, reps: 15),
    ],
  ),
  _plan(
    id: '30_hiit',
    name: '30-Min HIIT',
    description:
        'High-intensity intervals that burn serious calories and improve cardiovascular fitness.',
    minutes: 30,
    category: LibraryCategory.cardio,
    difficulty: 'Intermediate',
    videoQuery: '30 minute HIIT workout fat burn no equipment',
    exercises: [
      const _Ex('Burpee', sets: 4, reps: 8),
      const _Ex('Jump Squat', sets: 4, reps: 12),
      const _Ex('Mountain Climber', sets: 4, reps: 20),
      const _Ex('High Knees', sets: 4, reps: 30),
      const _Ex('Push-Up', sets: 3, reps: 10),
      const _Ex('Plank to Downward Dog', sets: 3, reps: 10),
    ],
  ),
  _plan(
    id: '30_bodyweight_strength',
    name: 'Bodyweight Strength',
    description:
        'Build real muscle with zero equipment using progressive bodyweight exercises.',
    minutes: 30,
    category: LibraryCategory.strength,
    difficulty: 'Intermediate',
    videoQuery: '30 minute bodyweight strength training workout intermediate',
    exercises: [
      const _Ex('Push-Up', sets: 4, reps: 12),
      const _Ex('Bulgarian Split Squat', sets: 3, reps: 10),
      const _Ex('Pike Push-Up', sets: 3, reps: 8),
      const _Ex('Single-Leg Glute Bridge', sets: 3, reps: 12),
      const _Ex('Dip (chair)', sets: 3, reps: 10),
      const _Ex('Plank Shoulder Tap', sets: 3, reps: 16),
      const _Ex('Superman', sets: 3, reps: 12),
    ],
  ),
  _plan(
    id: '30_cardio_sculpt',
    name: 'Cardio + Sculpt',
    description:
        'Alternates cardio bursts with toning moves for the best of both worlds.',
    minutes: 30,
    category: LibraryCategory.cardio,
    difficulty: 'Beginner',
    videoQuery: '30 minute cardio sculpt toning workout beginners',
    exercises: [
      const _Ex('Step Touch (cardio)', sets: 2, reps: 30),
      const _Ex('Squat', sets: 3, reps: 12),
      const _Ex('March in Place (cardio)', sets: 2, reps: 40),
      const _Ex('Push-Up', sets: 3, reps: 8),
      const _Ex('Jumping Jack (cardio)', sets: 2, reps: 25),
      const _Ex('Glute Bridge', sets: 3, reps: 15),
      const _Ex('Low-Impact Skater', sets: 2, reps: 16),
    ],
  ),
  _plan(
    id: '30_stretch_recovery',
    name: 'Stretch & Recovery',
    description:
        'A full 30-minute deep stretch session to improve flexibility and ease soreness.',
    minutes: 30,
    category: LibraryCategory.flexibility,
    difficulty: 'Beginner',
    videoQuery: '30 minute full body stretch flexibility recovery',
    exercises: [
      const _Ex('Neck Stretch (each side)', sets: 1, reps: 5),
      const _Ex('Cross-Body Shoulder Stretch', sets: 1, reps: 5),
      const _Ex('Chest Opener', sets: 1, reps: 5),
      const _Ex('Standing Quad Stretch', sets: 1, reps: 5),
      const _Ex('Standing Hip Flexor Lunge', sets: 1, reps: 5),
      const _Ex('Seated Hamstring Stretch', sets: 1, reps: 5),
      const _Ex('Figure-Four Glute Stretch', sets: 1, reps: 5),
      const _Ex('Spinal Twist', sets: 1, reps: 5),
      const _Ex('Child\'s Pose', sets: 1, reps: 5),
    ],
  ),
];

// ── 60-Minute Plans ────────────────────────────────────────────────────────

final kLibrary60Min = <LibraryPlan>[
  _plan(
    id: '60_complete_strength',
    name: 'Complete Strength',
    description:
        'A full hour of strength training hitting every muscle group. Classic gym workout.',
    minutes: 60,
    category: LibraryCategory.strength,
    difficulty: 'Intermediate',
    videoQuery: '60 minute full body strength training workout',
    exercises: [
      const _Ex('Warm-Up: Jumping Jacks', sets: 2, reps: 25),
      const _Ex('Squat', sets: 4, reps: 12),
      const _Ex('Romanian Deadlift', sets: 4, reps: 10),
      const _Ex('Bench Press / Push-Up', sets: 4, reps: 10),
      const _Ex('Bent-Over Row', sets: 4, reps: 10),
      const _Ex('Overhead Press', sets: 3, reps: 10),
      const _Ex('Bicep Curl', sets: 3, reps: 12),
      const _Ex('Tricep Extension', sets: 3, reps: 12),
      const _Ex('Plank', sets: 3, reps: 30),
      const _Ex('Cool-Down: Full Body Stretch', sets: 1, reps: 5),
    ],
  ),
  _plan(
    id: '60_endurance_builder',
    name: 'Endurance Builder',
    description:
        'Mixed cardio and bodyweight circuit designed to build stamina over 60 minutes.',
    minutes: 60,
    category: LibraryCategory.cardio,
    difficulty: 'Intermediate',
    videoQuery: '60 minute cardio endurance workout home no equipment',
    exercises: [
      const _Ex('Jog in Place Warm-Up', sets: 1, reps: 60),
      const _Ex('Jumping Jack', sets: 4, reps: 30),
      const _Ex('Burpee', sets: 4, reps: 10),
      const _Ex('Mountain Climber', sets: 4, reps: 30),
      const _Ex('High Knees', sets: 4, reps: 40),
      const _Ex('Speed Squat', sets: 4, reps: 20),
      const _Ex('Push-Up', sets: 4, reps: 12),
      const _Ex('Jump Lunge', sets: 3, reps: 12),
      const _Ex('Plank Hold', sets: 3, reps: 45),
      const _Ex('Cool-Down Walk', sets: 1, reps: 5),
    ],
  ),
  _plan(
    id: '60_full_body_challenge',
    name: 'Full Body Challenge',
    description:
        'An intermediate challenge that pushes you through push, pull, legs, and core with supersets.',
    minutes: 60,
    category: LibraryCategory.strength,
    difficulty: 'Intermediate',
    videoQuery: '60 minute full body challenge workout intermediate no equipment',
    exercises: [
      const _Ex('Dynamic Warm-Up', sets: 2, reps: 10),
      const _Ex('Squat + Overhead Press Combo', sets: 4, reps: 10),
      const _Ex('Push-Up + Row Superset', sets: 4, reps: 10),
      const _Ex('Reverse Lunge + Curl', sets: 3, reps: 10),
      const _Ex('Hip Thrust', sets: 4, reps: 15),
      const _Ex('Plank to Push-Up', sets: 3, reps: 10),
      const _Ex('Lateral Lunge', sets: 3, reps: 12),
      const _Ex('V-Up', sets: 3, reps: 12),
      const _Ex('Superman Pulses', sets: 3, reps: 15),
      const _Ex('Full Body Stretch Cool-Down', sets: 1, reps: 5),
    ],
  ),
  _plan(
    id: '60_yoga_power',
    name: 'Power Yoga Flow',
    description:
        'A 60-minute dynamic yoga session that builds strength and flexibility simultaneously.',
    minutes: 60,
    category: LibraryCategory.flexibility,
    difficulty: 'Intermediate',
    videoQuery: '60 minute power yoga flow intermediate strength flexibility',
    exercises: [
      const _Ex('Sun Salutation A (×5)', sets: 5, reps: 1),
      const _Ex('Sun Salutation B (×3)', sets: 3, reps: 1),
      const _Ex('Warrior I (each side)', sets: 3, reps: 5),
      const _Ex('Warrior II (each side)', sets: 3, reps: 5),
      const _Ex('Triangle Pose (each side)', sets: 2, reps: 5),
      const _Ex('Chair Pose', sets: 3, reps: 5),
      const _Ex('Boat Pose', sets: 3, reps: 5),
      const _Ex('Bridge Pose', sets: 3, reps: 5),
      const _Ex('Pigeon Pose (each side)', sets: 1, reps: 5),
      const _Ex('Corpse Pose (Savasana)', sets: 1, reps: 1),
    ],
  ),
];

// ── Unified access ─────────────────────────────────────────────────────────

final kAllLibraryPlans = [
  ...kLibrary5Min,
  ...kLibrary10Min,
  ...kLibrary30Min,
  ...kLibrary60Min,
];

List<LibraryPlan> libraryByDuration(int minutes) =>
    kAllLibraryPlans.where((p) => p.durationMinutes == minutes).toList();

List<LibraryPlan> libraryByCategory(LibraryCategory cat) =>
    kAllLibraryPlans.where((p) => p.category == cat).toList();
