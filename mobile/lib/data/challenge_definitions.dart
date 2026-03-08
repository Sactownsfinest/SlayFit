/// All challenge definitions for SlayFit.
/// These are the hard-coded catalog that users can join.

enum ChallengeCategory { daily, weekly, thirtyDay, lifestyle, social, signature }

enum MetricType { steps, calories, protein, water, workouts, foodLogs, manual }

class ChallengeRequirement {
  final MetricType metric;
  /// -1 means "use the user's personal goal"
  final double targetValue;
  final String label;

  const ChallengeRequirement({
    required this.metric,
    required this.targetValue,
    required this.label,
  });
}

class ChallengeDefinition {
  final String id;
  final String name;
  final String tagline;
  final String description;
  final ChallengeCategory category;
  final int durationDays; // 1 = daily, 7 = weekly, 30 = monthly
  final String badgeEmoji;
  final String badgeName;
  final List<ChallengeRequirement> requirements;

  const ChallengeDefinition({
    required this.id,
    required this.name,
    required this.tagline,
    required this.description,
    required this.category,
    required this.durationDays,
    required this.badgeEmoji,
    required this.badgeName,
    required this.requirements,
  });

  String get durationLabel {
    if (durationDays == 1) return 'Daily';
    if (durationDays == 7) return '7 Days';
    if (durationDays == 30) return '30 Days';
    return '$durationDays Days';
  }

  String get categoryLabel {
    switch (category) {
      case ChallengeCategory.daily: return 'Daily';
      case ChallengeCategory.weekly: return 'Weekly';
      case ChallengeCategory.thirtyDay: return '30-Day';
      case ChallengeCategory.lifestyle: return 'Lifestyle';
      case ChallengeCategory.social: return 'Community';
      case ChallengeCategory.signature: return 'Signature';
    }
  }
}

const List<ChallengeDefinition> kAllChallenges = [
  // ── DAILY ─────────────────────────────────────────────────────────────────
  ChallengeDefinition(
    id: 'step_slayer',
    name: 'Step Slayer',
    tagline: 'Every step counts.',
    description: 'Hit 8,000 steps today. Walk, run, pace the kitchen — just move that body.',
    category: ChallengeCategory.daily,
    durationDays: 1,
    badgeEmoji: '👟',
    badgeName: 'Step Slayer',
    requirements: [
      ChallengeRequirement(metric: MetricType.steps, targetValue: 8000, label: '8,000 steps'),
    ],
  ),
  ChallengeDefinition(
    id: 'hydration_hero',
    name: 'Hydration Hero',
    tagline: 'Drink up. Glow up.',
    description: 'Log 2,000ml of water today. Hydration is the foundation of every slay.',
    category: ChallengeCategory.daily,
    durationDays: 1,
    badgeEmoji: '💧',
    badgeName: 'Hydration Hero',
    requirements: [
      ChallengeRequirement(metric: MetricType.water, targetValue: 2000, label: '2,000ml of water'),
    ],
  ),
  ChallengeDefinition(
    id: 'protein_priority',
    name: 'Protein Priority',
    tagline: 'Feed the muscle.',
    description: 'Hit your daily protein goal. Protein builds the body you\'re working for.',
    category: ChallengeCategory.daily,
    durationDays: 1,
    badgeEmoji: '🥩',
    badgeName: 'Protein Priority',
    requirements: [
      ChallengeRequirement(metric: MetricType.protein, targetValue: -1, label: 'Hit protein goal'),
    ],
  ),
  ChallengeDefinition(
    id: 'stay_in_green',
    name: 'Stay in the Green',
    tagline: 'Hit the target, no excuses.',
    description: 'Eat within your calorie target today — not under, not over. Precision is power.',
    category: ChallengeCategory.daily,
    durationDays: 1,
    badgeEmoji: '🎯',
    badgeName: 'In the Green',
    requirements: [
      ChallengeRequirement(metric: MetricType.calories, targetValue: -1, label: 'Hit calorie target'),
    ],
  ),
  ChallengeDefinition(
    id: 'twenty_min_move',
    name: '20-Minute Move',
    tagline: 'Twenty minutes. No negotiating.',
    description: 'Complete any workout of 20 minutes or more today. Consistency beats perfection.',
    category: ChallengeCategory.daily,
    durationDays: 1,
    badgeEmoji: '⏱️',
    badgeName: '20-Minute Mover',
    requirements: [
      ChallengeRequirement(metric: MetricType.workouts, targetValue: 1, label: 'Complete a workout'),
    ],
  ),
  ChallengeDefinition(
    id: 'clean_plate',
    name: 'Clean Plate',
    tagline: 'Log it all. Every bite.',
    description: 'Log at least 3 meals today — breakfast, lunch, and dinner. Awareness is the first step to transformation.',
    category: ChallengeCategory.daily,
    durationDays: 1,
    badgeEmoji: '📋',
    badgeName: 'Clean Plate',
    requirements: [
      ChallengeRequirement(metric: MetricType.foodLogs, targetValue: 3, label: 'Log 3 meals'),
    ],
  ),
  // ── WEEKLY ────────────────────────────────────────────────────────────────
  ChallengeDefinition(
    id: 'move_5_days',
    name: 'Move 5 Days',
    tagline: 'Consistency is the cheat code.',
    description: 'Complete at least one workout on 5 different days this week. Show up — that\'s the whole job.',
    category: ChallengeCategory.weekly,
    durationDays: 7,
    badgeEmoji: '🔥',
    badgeName: 'Move 5 Days',
    requirements: [
      ChallengeRequirement(metric: MetricType.workouts, targetValue: 5, label: '5 workout days'),
    ],
  ),
  ChallengeDefinition(
    id: 'forty_k_steps',
    name: '40,000 Steps',
    tagline: 'Walk the distance.',
    description: '40,000 total steps across 7 days. That\'s under 6k a day — absolutely achievable.',
    category: ChallengeCategory.weekly,
    durationDays: 7,
    badgeEmoji: '🚶',
    badgeName: '40K Walker',
    requirements: [
      ChallengeRequirement(metric: MetricType.steps, targetValue: 40000, label: '40,000 total steps'),
    ],
  ),
  ChallengeDefinition(
    id: 'log_food_all_week',
    name: 'Log Food All Week',
    tagline: 'Accountability is the move.',
    description: 'Log at least one meal every single day for 7 days straight. Awareness breeds discipline.',
    category: ChallengeCategory.weekly,
    durationDays: 7,
    badgeEmoji: '📊',
    badgeName: 'Food Logger',
    requirements: [
      ChallengeRequirement(metric: MetricType.foodLogs, targetValue: 7, label: 'Log food 7 days'),
    ],
  ),
  ChallengeDefinition(
    id: 'hit_tdee_week',
    name: 'Hit TDEE 4-6 Days',
    tagline: 'Precision nutrition.',
    description: 'Hit your calorie target on at least 4 out of 7 days this week. Sustainable results come from consistency.',
    category: ChallengeCategory.weekly,
    durationDays: 7,
    badgeEmoji: '⚡',
    badgeName: 'TDEE Precision',
    requirements: [
      ChallengeRequirement(metric: MetricType.calories, targetValue: 4, label: 'Hit calorie goal 4+ days'),
    ],
  ),
  ChallengeDefinition(
    id: 'strength_3x',
    name: '3 Strength Workouts',
    tagline: 'Build that base.',
    description: 'Complete 3 strength-based workouts this week. Muscle is your metabolism\'s best friend.',
    category: ChallengeCategory.weekly,
    durationDays: 7,
    badgeEmoji: '🏋️',
    badgeName: 'Strength Builder',
    requirements: [
      ChallengeRequirement(metric: MetricType.workouts, targetValue: 3, label: '3 strength workouts'),
    ],
  ),
  // ── SIGNATURE ─────────────────────────────────────────────────────────────
  ChallengeDefinition(
    id: 'dont_play_with_me',
    name: "Don't Play With Me",
    tagline: "7 days. All goals. No excuses.",
    description: 'Hit your calorie target, protein goal, AND 2,000ml of water — every single day for 7 days. This is what separation looks like.',
    category: ChallengeCategory.signature,
    durationDays: 7,
    badgeEmoji: '👑',
    badgeName: "Don't Play With Me",
    requirements: [
      ChallengeRequirement(metric: MetricType.calories, targetValue: -1, label: 'Hit calorie goal'),
      ChallengeRequirement(metric: MetricType.protein, targetValue: -1, label: 'Hit protein goal'),
      ChallengeRequirement(metric: MetricType.water, targetValue: 2000, label: 'Drink 2,000ml'),
    ],
  ),
  ChallengeDefinition(
    id: 'no_excuses_execution',
    name: 'No Excuses, Just Execution',
    tagline: 'Talk less. Move more.',
    description: 'Complete 5 workouts this week. No modifications, no skips, no stories. Just work.',
    category: ChallengeCategory.signature,
    durationDays: 7,
    badgeEmoji: '💪',
    badgeName: 'No Excuses',
    requirements: [
      ChallengeRequirement(metric: MetricType.workouts, targetValue: 5, label: '5 workouts this week'),
    ],
  ),
  ChallengeDefinition(
    id: 'slayfit_savage',
    name: 'Slayfit Savage Week',
    tagline: 'Elite level. Not for everyone.',
    description: 'Work out every day AND hit your calorie target AND drink 2L of water — for 7 consecutive days. Savage is earned.',
    category: ChallengeCategory.signature,
    durationDays: 7,
    badgeEmoji: '🦁',
    badgeName: 'Slayfit Savage',
    requirements: [
      ChallengeRequirement(metric: MetricType.workouts, targetValue: 7, label: 'Work out every day'),
      ChallengeRequirement(metric: MetricType.water, targetValue: 2000, label: 'Drink 2,000ml'),
      ChallengeRequirement(metric: MetricType.calories, targetValue: -1, label: 'Hit calorie goal'),
    ],
  ),
  // ── COMMUNITY ─────────────────────────────────────────────────────────────
  ChallengeDefinition(
    id: 'weekend_warrior',
    name: 'Weekend Warrior',
    tagline: 'The weekend is not a rest day.',
    description: 'Complete a workout on both Saturday AND Sunday. Most people rest — you separate yourself.',
    category: ChallengeCategory.social,
    durationDays: 7,
    badgeEmoji: '⚡',
    badgeName: 'Weekend Warrior',
    requirements: [
      ChallengeRequirement(metric: MetricType.workouts, targetValue: 2, label: 'Workout Sat + Sun'),
    ],
  ),
  ChallengeDefinition(
    id: 'squad_steps',
    name: 'Squad Steps',
    tagline: 'Move together. Win together.',
    description: 'Hit 10,000 steps every day for 5 days this week. Post your count in Community chat and keep each other accountable.',
    category: ChallengeCategory.social,
    durationDays: 7,
    badgeEmoji: '👥',
    badgeName: 'Squad Stepper',
    requirements: [
      ChallengeRequirement(metric: MetricType.steps, targetValue: 50000, label: '50,000 steps (5 days × 10k)'),
    ],
  ),
  ChallengeDefinition(
    id: 'accountability_partner',
    name: 'Accountability Partner',
    tagline: 'Better together.',
    description: 'Log food AND complete a workout every day for 5 days. Share your wins in the Community feed. Accountability changes everything.',
    category: ChallengeCategory.social,
    durationDays: 7,
    badgeEmoji: '🤝',
    badgeName: 'Accountability Partner',
    requirements: [
      ChallengeRequirement(metric: MetricType.workouts, targetValue: 5, label: 'Work out 5 days'),
      ChallengeRequirement(metric: MetricType.foodLogs, targetValue: 5, label: 'Log food 5 days'),
    ],
  ),
  // ── 30-DAY ────────────────────────────────────────────────────────────────
  ChallengeDefinition(
    id: 'thirty_day_shred',
    name: '30-Day Shred',
    tagline: 'One month. Transformed.',
    description: 'Complete at least one workout every single day for 30 days. By day 30, you won\'t recognize yourself.',
    category: ChallengeCategory.thirtyDay,
    durationDays: 30,
    badgeEmoji: '🏆',
    badgeName: '30-Day Finisher',
    requirements: [
      ChallengeRequirement(metric: MetricType.workouts, targetValue: 30, label: 'Work out 30 days'),
    ],
  ),
  ChallengeDefinition(
    id: 'glute_builder',
    name: 'Glute Builder Month',
    tagline: 'Build what you want to see.',
    description: 'Complete a lower-body workout 4 days per week for 30 days. 16+ sessions. The results will speak for themselves.',
    category: ChallengeCategory.thirtyDay,
    durationDays: 30,
    badgeEmoji: '🍑',
    badgeName: 'Glute Builder',
    requirements: [
      ChallengeRequirement(metric: MetricType.workouts, targetValue: 16, label: '16 lower-body workouts'),
    ],
  ),
  ChallengeDefinition(
    id: 'walk_100_miles',
    name: 'Walk 100 Miles',
    tagline: 'Mile by mile.',
    description: '100 miles in 30 days — about 3.3 miles (7,000 steps) a day. You can do this while living your normal life.',
    category: ChallengeCategory.thirtyDay,
    durationDays: 30,
    badgeEmoji: '🗺️',
    badgeName: '100-Mile Club',
    requirements: [
      ChallengeRequirement(metric: MetricType.steps, targetValue: 528000, label: '~528,000 steps (100 miles)'),
    ],
  ),
  ChallengeDefinition(
    id: 'core_rebuild',
    name: 'Core Rebuild',
    tagline: 'Strong core. Strong life.',
    description: 'Do a core-focused workout or 10 minutes of core work every day for 30 days. Your posture, your back, your everything will improve.',
    category: ChallengeCategory.thirtyDay,
    durationDays: 30,
    badgeEmoji: '🎖️',
    badgeName: 'Core Rebuilt',
    requirements: [
      ChallengeRequirement(metric: MetricType.workouts, targetValue: 30, label: 'Core workout 30 days'),
    ],
  ),
  // ── LIFESTYLE ─────────────────────────────────────────────────────────────
  ChallengeDefinition(
    id: 'no_sugar_week',
    name: 'No Sugar Week',
    tagline: 'Break the cycle.',
    description: 'Commit to no added sugar for 7 days. Log your meals to keep yourself honest. Your energy levels will change.',
    category: ChallengeCategory.lifestyle,
    durationDays: 7,
    badgeEmoji: '🚫',
    badgeName: 'Sugar-Free',
    requirements: [
      ChallengeRequirement(metric: MetricType.manual, targetValue: 7, label: 'Check in daily: no added sugar'),
    ],
  ),
  ChallengeDefinition(
    id: 'no_doordash_week',
    name: 'No DoorDash Week',
    tagline: 'Cook your way to a better body.',
    description: 'Skip delivery apps for 7 days. Cook at home, control your macros, save money. Three wins.',
    category: ChallengeCategory.lifestyle,
    durationDays: 7,
    badgeEmoji: '🍳',
    badgeName: 'Home Cook',
    requirements: [
      ChallengeRequirement(metric: MetricType.manual, targetValue: 7, label: 'Check in daily: cooked at home'),
    ],
  ),
  ChallengeDefinition(
    id: 'cook_3_meals',
    name: 'Cook 3 Meals',
    tagline: 'Your kitchen is your gym.',
    description: 'Cook 3 home-cooked meals today and log them all. Meal prep is self-care.',
    category: ChallengeCategory.lifestyle,
    durationDays: 1,
    badgeEmoji: '👨‍🍳',
    badgeName: 'Home Chef',
    requirements: [
      ChallengeRequirement(metric: MetricType.manual, targetValue: 1, label: 'Cook and log 3 meals'),
    ],
  ),
  ChallengeDefinition(
    id: 'no_soda_week',
    name: 'No Soda Week',
    tagline: 'Liquid calories are the enemy.',
    description: 'No soda, no sugary drinks for 7 days. Water and black coffee only. Watch your body change.',
    category: ChallengeCategory.lifestyle,
    durationDays: 7,
    badgeEmoji: '💦',
    badgeName: 'Soda-Free',
    requirements: [
      ChallengeRequirement(metric: MetricType.manual, targetValue: 7, label: 'Check in daily: no soda'),
    ],
  ),
];
