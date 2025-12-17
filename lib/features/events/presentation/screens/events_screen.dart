import 'package:flutter/material.dart' hide TimeOfDay;
import 'package:flutter/material.dart' as material show TimeOfDay;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/services/event_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../shared/widgets/animated_gradient_background.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../domain/entities/event.dart';

/// Events screen for managing countdowns and special dates
class EventsScreen extends ConsumerStatefulWidget {
  const EventsScreen({super.key});

  @override
  ConsumerState<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends ConsumerState<EventsScreen> {
  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(eventsStreamProvider);

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: eventsAsync.when(
                  data: (events) => events.isEmpty
                      ? _buildEmptyState()
                      : _buildEventsList(events),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        shape: const CircleBorder(),
        onPressed: () => _showAddEventDialog(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: AppColors.white),
      ).animate().scale(delay: 300.ms, curve: Curves.elasticOut),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          Text(
            'Events & Countdowns',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.white),
              ),
              child: const Icon(Icons.event, size: 60, color: AppColors.white),
            ).animate().scale(curve: Curves.elasticOut),
            const SizedBox(height: 24),
            Text(
              'No Events Yet',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Add birthdays, anniversaries, and other special dates to count down together!',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.grayDark),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventsList(List<Event> events) {
    // Separate events into upcoming and past
    final upcoming = events.where((e) => e.daysUntil >= 0).toList()
      ..sort((a, b) => a.daysUntil.compareTo(b.daysUntil));
    final past = events
        .where((e) => e.daysUntil < 0 && !e.isRecurring)
        .toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      children: [
        if (upcoming.isNotEmpty) ...[
          Text(
            'Upcoming',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: AppColors.grayDark),
          ),
          const SizedBox(height: 12),
          ...upcoming.asMap().entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildEventCard(entry.value, entry.key),
            ),
          ),
        ],
        if (past.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            'Past Events',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: AppColors.grayDark),
          ),
          const SizedBox(height: 12),
          ...past.map(
            (event) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildPastEventCard(event),
            ),
          ),
        ],
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildEventCard(Event event, int index) {
    final isToday = event.daysUntil == 0;
    final isTomorrow = event.daysUntil == 1;

    return GlassCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Countdown circle
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isToday
                      ? AppGradients.primary
                      : AppGradients.twilight,
                  boxShadow: [
                    BoxShadow(
                      color: (isToday ? AppColors.primary : AppColors.accent)
                          .withValues(alpha: 0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isToday ? '🎉' : event.daysUntil.toString(),
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      if (!isToday)
                        Text(
                          'days',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppColors.white.withValues(alpha: 0.8),
                              ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (event.isRecurring)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Icon(
                              Icons.repeat,
                              size: 16,
                              color: AppColors.accent,
                            ),
                          ),
                        Expanded(
                          child: Text(
                            event.title,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isToday
                          ? 'Today! 🎊'
                          : isTomorrow
                          ? 'Tomorrow!'
                          : DateFormat(
                              'MMMM d, yyyy',
                            ).format(event.nextOccurrence),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isToday ? AppColors.primary : AppColors.grayDark,
                        fontWeight: isToday
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    if (event.description != null &&
                        event.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        event.description!,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: AppColors.gray),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _showEventOptions(event),
                icon: const Icon(Icons.more_vert, color: AppColors.gray),
              ),
            ],
          ),
        )
        .animate(delay: Duration(milliseconds: 100 * index))
        .fadeIn()
        .slideX(begin: 0.1, end: 0);
  }

  Widget _buildPastEventCard(Event event) {
    return Opacity(
      opacity: 0.6,
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.event_busy, color: AppColors.gray),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                event.title,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.grayDark),
              ),
            ),
            Text(
              DateFormat('MMM d').format(event.eventDate),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.gray),
            ),
            IconButton(
              onPressed: () => _deleteEvent(event),
              icon: const Icon(
                Icons.delete_outline,
                color: AppColors.gray,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEventOptions(Event event) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.grayLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              event.title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.edit, color: AppColors.primary),
              title: const Text('Edit Event'),
              onTap: () {
                Navigator.pop(context);
                _showEditEventDialog(event);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: AppColors.error),
              title: const Text(
                'Delete Event',
                style: TextStyle(color: AppColors.error),
              ),
              onTap: () {
                Navigator.pop(context);
                _deleteEvent(event);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showAddEventDialog(BuildContext context) {
    _showEventDialog(context, null);
  }

  void _showEditEventDialog(Event event) {
    _showEventDialog(context, event);
  }

  void _showEventDialog(BuildContext context, Event? event) {
    final isEditing = event != null;
    final titleController = TextEditingController(text: event?.title ?? '');
    final descriptionController = TextEditingController(
      text: event?.description ?? '',
    );
    DateTime selectedDate =
        event?.eventDate ?? DateTime.now().add(const Duration(days: 7));
    bool isRecurring = event?.isRecurring ?? false;
    RecurringType recurringType = event?.recurringType ?? RecurringType.yearly;
    material.TimeOfDay notificationTime = event?.notificationTime != null
        ? material.TimeOfDay(
            hour: event!.notificationTime!.hour,
            minute: event.notificationTime!.minute,
          )
        : const material.TimeOfDay(hour: 9, minute: 0);
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Edit Event' : 'New Event'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Event Name',
                    hintText: "e.g., Partner's Birthday",
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    hintText: 'Add a note...',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.calendar_today,
                    color: AppColors.primary,
                  ),
                  title: const Text('Date'),
                  subtitle: Text(
                    DateFormat('MMMM d, yyyy').format(selectedDate),
                  ),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: dialogContext,
                      initialDate: selectedDate,
                      firstDate: DateTime.now().subtract(
                        const Duration(days: 365 * 10),
                      ),
                      lastDate: DateTime.now().add(
                        const Duration(days: 365 * 10),
                      ),
                    );
                    if (date != null) {
                      setDialogState(() => selectedDate = date);
                    }
                  },
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Repeats Yearly'),
                  subtitle: const Text('For birthdays & anniversaries'),
                  value: isRecurring,
                  onChanged: (value) {
                    setDialogState(() {
                      isRecurring = value;
                      if (value) recurringType = RecurringType.yearly;
                    });
                  },
                  activeColor: AppColors.primary,
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.notifications,
                    color: AppColors.accent,
                  ),
                  title: const Text('Reminder Time'),
                  subtitle: Text(notificationTime.format(dialogContext)),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: dialogContext,
                      initialTime: notificationTime,
                    );
                    if (time != null) {
                      setDialogState(() => notificationTime = time);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (titleController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter an event name'),
                          ),
                        );
                        return;
                      }

                      setDialogState(() => isLoading = true);

                      try {
                        final eventService = ref.read(eventServiceProvider);

                        final eventTimeOfDay = TimeOfDay(
                          hour: notificationTime.hour,
                          minute: notificationTime.minute,
                        );

                        if (isEditing) {
                          await eventService.updateEvent(
                            event.copyWith(
                              title: titleController.text.trim(),
                              description:
                                  descriptionController.text.trim().isEmpty
                                  ? null
                                  : descriptionController.text.trim(),
                              eventDate: selectedDate,
                              isRecurring: isRecurring,
                              recurringType: isRecurring
                                  ? recurringType
                                  : RecurringType.none,
                              notificationTime: eventTimeOfDay,
                            ),
                          );
                        } else {
                          await eventService.createEvent(
                            title: titleController.text.trim(),
                            description:
                                descriptionController.text.trim().isEmpty
                                ? null
                                : descriptionController.text.trim(),
                            eventDate: selectedDate,
                            isRecurring: isRecurring,
                            recurringType: isRecurring
                                ? recurringType
                                : RecurringType.none,
                            notificationTime: eventTimeOfDay,
                          );
                        }

                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                        }
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isEditing
                                    ? 'Event updated!'
                                    : 'Event created! 🎉',
                              ),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      } finally {
                        if (dialogContext.mounted) {
                          setDialogState(() => isLoading = false);
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
                      ),
                    )
                  : Text(isEditing ? 'Save' : 'Create'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteEvent(Event event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event?'),
        content: Text('Are you sure you want to delete "${event.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final eventService = ref.read(eventServiceProvider);
        await eventService.deleteEvent(event.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Event deleted'),
              backgroundColor: AppColors.grayDark,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }
}
