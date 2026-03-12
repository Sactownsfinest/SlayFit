import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main.dart';
import '../providers/challenges_provider.dart';
import '../providers/notification_feed_provider.dart';
import '../services/firebase_service.dart';

// ── Bell button — drop into any AppBar actions list ───────────────────────────

class AppBellIcon extends ConsumerWidget {
  const AppBellIcon({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localUnread =
        ref.watch(notifFeedProvider).where((n) => !n.read).length;

    return StreamBuilder<List<AppNotification>>(
      stream: FirebaseService.myNotificationsStream(),
      builder: (_, snap) {
        final fbUnread = (snap.data ?? []).where((n) => !n.read).length;
        final total = localUnread + fbUnread;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined,
                  color: kTextSecondary),
              onPressed: () {
                ref.read(notifFeedProvider.notifier).markAllRead();
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: kSurfaceDark,
                  shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (_) => const NotificationPanelSheet(),
                );
              },
            ),
            if (total > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                      color: Colors.redAccent, shape: BoxShape.circle),
                  child: Center(
                    child: Text(
                      '$total',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ── Unified notification panel (Firebase + local) ─────────────────────────────

class NotificationPanelSheet extends ConsumerWidget {
  const NotificationPanelSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localNotifs = ref.watch(notifFeedProvider);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      builder: (_, controller) => Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
                color: const Color(0xFF2A3550),
                borderRadius: BorderRadius.circular(2)),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Icon(Icons.notifications_outlined,
                    color: kNeonYellow, size: 20),
                SizedBox(width: 8),
                Text('Notifications',
                    style: TextStyle(
                        color: kTextPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<AppNotification>>(
              stream: FirebaseService.myNotificationsStream(),
              builder: (context, snap) {
                final fbNotifs = snap.data ?? [];
                if (snap.connectionState == ConnectionState.waiting &&
                    fbNotifs.isEmpty &&
                    localNotifs.isEmpty) {
                  return const Center(
                      child:
                          CircularProgressIndicator(color: kNeonYellow));
                }
                if (fbNotifs.isEmpty && localNotifs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.notifications_none,
                            color: kTextSecondary, size: 48),
                        SizedBox(height: 16),
                        Text('No notifications yet',
                            style: TextStyle(
                                color: kTextPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        Text(
                            'Challenges, achievements, and\nupdates will appear here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: kTextSecondary)),
                      ],
                    ),
                  );
                }
                return ListView(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  children: [
                    ...fbNotifs.map((n) => _FbNotifCard(notif: n)),
                    ...localNotifs.map((n) => _LocalNotifCard(notif: n)),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Firebase notification card (challenge invites / accepts) ──────────────────

class _FbNotifCard extends ConsumerWidget {
  final AppNotification notif;
  const _FbNotifCard({required this.notif});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isInvite = notif.type == 'challenge_invite';
    final color =
        isInvite ? const Color(0xFF007AFF) : const Color(0xFF34C759);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: notif.read ? kCardDark : color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: notif.read
                ? const Color(0xFF2A3550)
                : color.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                    isInvite
                        ? Icons.emoji_events_outlined
                        : Icons.check_circle_outline,
                    color: color,
                    size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isInvite
                        ? '${notif.fromName} invited you to a challenge'
                        : '${notif.fromName} accepted your challenge invite',
                    style: TextStyle(
                        color: kTextPrimary,
                        fontWeight: notif.read
                            ? FontWeight.normal
                            : FontWeight.bold,
                        fontSize: 13),
                  ),
                ),
                if (!notif.read)
                  Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                          color: color, shape: BoxShape.circle)),
              ],
            ),
            if (notif.challengeName != null) ...[
              const SizedBox(height: 4),
              Text('"${notif.challengeName}"',
                  style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ],
            const SizedBox(height: 10),
            if (isInvite)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (notif.definitionId != null) {
                          ref
                              .read(challengesProvider.notifier)
                              .joinChallenge(notif.definitionId!);
                        }
                        await FirebaseService.acceptChallengeInvite(notif);
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(
                            content:
                                Text('Joined "${notif.challengeName}"! 🏆'),
                            backgroundColor: kNeonYellow,
                            behavior: SnackBarBehavior.floating,
                          ));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kNeonYellow,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Accept',
                          style:
                              TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        FirebaseService.deleteNotification(notif.id);
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kTextSecondary,
                        side: const BorderSide(color: Color(0xFF2A3550)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Decline'),
                    ),
                  ),
                ],
              )
            else
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () =>
                      FirebaseService.markNotificationRead(notif.id),
                  child: const Text('Dismiss',
                      style:
                          TextStyle(color: kTextSecondary, fontSize: 12)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Local (in-app) notification card ─────────────────────────────────────────

class _LocalNotifCard extends ConsumerWidget {
  final LocalNotif notif;
  const _LocalNotifCard({required this.notif});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _colorForType(notif.type);
    final icon = _iconForType(notif.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: kCardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A3550)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(notif.title,
                      style: const TextStyle(
                          color: kTextPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                  if (notif.body.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(notif.body,
                        style: const TextStyle(
                            color: kTextSecondary, fontSize: 12)),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: kTextSecondary, size: 16),
              onPressed: () =>
                  ref.read(notifFeedProvider.notifier).remove(notif.id),
            ),
          ],
        ),
      ),
    );
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'achievement':
        return kNeonYellow;
      case 'meal_plan':
        return Colors.greenAccent;
      case 'streak':
        return Colors.orangeAccent;
      default:
        return Colors.cyanAccent;
    }
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'achievement':
        return Icons.emoji_events;
      case 'meal_plan':
        return Icons.restaurant_menu;
      case 'streak':
        return Icons.local_fire_department;
      default:
        return Icons.notifications;
    }
  }
}
