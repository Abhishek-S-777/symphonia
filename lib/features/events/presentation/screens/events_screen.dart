import 'package:flutter/material.dart' hide TimeOfDay;
import 'package:flutter/material.dart' as material show TimeOfDay;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app.dart';
import '../../../../core/services/event_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../shared/widgets/animated_gradient_background.dart';
import '../../../../shared/widgets/app_snackbar.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../domain/entities/event.dart';

/// Events screen for managing countdowns and special dates
class EventsScreen extends ConsumerStatefulWidget {
  const EventsScreen({super.key});

  @override
  ConsumerState<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends ConsumerState<EventsScreen> {
  final rootContext = rootNavigatorKey.currentContext;

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

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _showEventSummary(event),
      child:
          GlassCard(
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
                            ? AppGradients.primary.withOpacity(0.7)
                            : AppGradients.aurora.withOpacity(0.7),
                        boxShadow: [
                          BoxShadow(
                            color:
                                (isToday ? AppColors.primary : AppColors.accent)
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
                                    ?.copyWith(color: AppColors.white),
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
                                    color: AppColors.success,
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
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: isToday
                                      ? AppColors.primary
                                      : AppColors.grayDark,
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
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.gray),
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
              .slideX(begin: 0.1, end: 0),
    );
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
    if (rootContext == null) return;
    showModalBottomSheet(
      context: rootContext!,
      useRootNavigator: true,
      enableDrag: false,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    event.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: AppColors.gray),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.visibility, color: AppColors.accent),
              title: const Text('View Details'),
              onTap: () {
                Navigator.pop(context);
                _showEventSummary(event);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blueAccent),
              title: const Text('Edit Event'),
              onTap: () {
                Navigator.pop(context);
                _showEditEventDialog(event);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: AppColors.error),
              title: const Text('Delete Event'),
              onTap: () {
                Navigator.pop(context);
                _deleteEvent(event);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showAddEventDialog(BuildContext context) {
    _showEventBottomSheet(context, null);
  }

  void _showEditEventDialog(Event event) {
    _showEventBottomSheet(context, event);
  }

  void _showEventBottomSheet(BuildContext context, Event? event) {
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
    bool isPickerOpen = false;

    // Use root navigator context to show over navigation bar
    if (rootContext == null) return;

    showModalBottomSheet(
      context: rootContext!,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          return Visibility(
            visible: !isPickerOpen,
            maintainState: true,
            maintainAnimation: true,
            maintainSize: false,
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 24,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isEditing ? 'Edit Event' : 'New Event',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          icon: const Icon(Icons.close, color: AppColors.gray),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1),

                  // Scrollable content
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Event Name
                          TextField(
                            controller: titleController,
                            maxLength: 50,
                            decoration: InputDecoration(
                              labelText: 'Event Name',
                              labelStyle: const TextStyle(
                                color: AppColors.white,
                              ),
                              hintText: "e.g., Partner's Birthday",
                              prefixIcon: const Icon(
                                Icons.event,
                                color: AppColors.primary,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.gray,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.white,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Description
                          TextField(
                            controller: descriptionController,
                            maxLength: 100,
                            decoration: InputDecoration(
                              labelText: 'Description (optional)',
                              labelStyle: const TextStyle(
                                color: AppColors.white,
                              ),
                              hintText: 'Add a note...',
                              prefixIcon: const Icon(
                                Icons.notes,
                                color: AppColors.gray,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.gray,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppColors.white,
                                  width: 2,
                                ),
                              ),
                            ),
                            maxLines: 2,
                          ),
                          const SizedBox(height: 12),

                          // Date picker
                          _buildPickerTile(
                            icon: Icons.calendar_today,
                            iconColor: AppColors.primary,
                            title: 'Date',
                            subtitle: DateFormat(
                              'MMMM d, yyyy',
                            ).format(selectedDate),
                            onTap: () async {
                              setSheetState(() => isPickerOpen = true);

                              final date = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime.now().subtract(
                                  const Duration(days: 365 * 10),
                                ),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 365 * 10),
                                ),
                              );

                              setSheetState(() {
                                isPickerOpen = false;
                                if (date != null) selectedDate = date;
                              });
                            },
                          ),
                          const SizedBox(height: 16),

                          // Notification time picker
                          _buildPickerTile(
                            icon: Icons.notifications,
                            iconColor: AppColors.accent,
                            title: 'Reminder Time',
                            subtitle: notificationTime.format(context),
                            onTap: () async {
                              setSheetState(() => isPickerOpen = true);

                              final time = await showTimePicker(
                                context: context,
                                initialTime: notificationTime,
                              );

                              setSheetState(() {
                                isPickerOpen = false;
                                if (time != null) notificationTime = time;
                              });
                            },
                          ),

                          const SizedBox(height: 12),

                          // Recurring toggle
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.repeat,
                                  color: AppColors.success,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text('Repeats Yearly'),
                                  subtitle: const Text(
                                    'For birthdays & anniversaries',
                                  ),
                                  value: isRecurring,
                                  onChanged: (value) {
                                    setSheetState(() {
                                      isRecurring = value;
                                      if (value) {
                                        recurringType = RecurringType.yearly;
                                      }
                                    });
                                  },
                                  activeThumbColor: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                  // Action buttons
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(sheetContext),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: const BorderSide(color: AppColors.gray),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: isLoading
                                ? null
                                : () async {
                                    if (titleController.text.trim().isEmpty) {
                                      AppSnackbar.showWarning(
                                        context,
                                        'Please enter an event name',
                                      );
                                      return;
                                    }

                                    setSheetState(() => isLoading = true);

                                    try {
                                      final eventService = ref.read(
                                        eventServiceProvider,
                                      );

                                      final eventTimeOfDay = TimeOfDay(
                                        hour: notificationTime.hour,
                                        minute: notificationTime.minute,
                                      );

                                      if (isEditing) {
                                        await eventService.updateEvent(
                                          event.copyWith(
                                            title: titleController.text.trim(),
                                            description:
                                                descriptionController.text
                                                    .trim()
                                                    .isEmpty
                                                ? null
                                                : descriptionController.text
                                                      .trim(),
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
                                              descriptionController.text
                                                  .trim()
                                                  .isEmpty
                                              ? null
                                              : descriptionController.text
                                                    .trim(),
                                          eventDate: selectedDate,
                                          isRecurring: isRecurring,
                                          recurringType: isRecurring
                                              ? recurringType
                                              : RecurringType.none,
                                          notificationTime: eventTimeOfDay,
                                        );
                                      }

                                      if (sheetContext.mounted) {
                                        Navigator.pop(sheetContext);
                                      }
                                      if (mounted) {
                                        AppSnackbar.showSuccess(
                                          context,
                                          isEditing
                                              ? 'Event updated! ✨'
                                              : 'Event created! 🎉',
                                        );
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        AppSnackbar.showError(
                                          context,
                                          'Error creating event: $e',
                                        );
                                      }
                                    } finally {
                                      if (sheetContext.mounted) {
                                        setSheetState(() => isLoading = false);
                                      }
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
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
                                : Text(
                                    isEditing ? 'Save Changes' : 'Create Event',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Bottom padding for safe area
                  SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPickerTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 14, color: AppColors.gray),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.gray),
        ],
      ),
    );
  }

  /// Show event summary in a read-only bottom sheet
  void _showEventSummary(Event event) {
    if (rootContext == null) return;

    showModalBottomSheet(
      context: rootContext!,
      isDismissible: true,
      enableDrag: false,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (sheetContext) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title with countdown badge
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
              child: Row(
                children: [
                  // Countdown badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: event.daysUntil == 0
                          ? AppGradients.primary
                          : AppGradients.aurora,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      event.daysUntil == 0
                          ? '🎉 Today!'
                          : event.daysUntil == 1
                          ? '1 day'
                          : '${event.daysUntil} days to go',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    icon: const Icon(Icons.close, color: AppColors.gray),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Scrollable content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Event Name (read-only display)
                    _buildSummaryField(
                      icon: Icons.event,
                      iconColor: AppColors.primary,
                      label: 'Event Name',
                      value: event.title,
                    ),
                    const SizedBox(height: 16),

                    // Description (if exists)
                    if (event.description != null &&
                        event.description!.isNotEmpty) ...[
                      _buildSummaryField(
                        icon: Icons.notes,
                        iconColor: AppColors.gray,
                        label: 'Description',
                        value: event.description!,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Date
                    _buildSummaryField(
                      icon: Icons.calendar_today,
                      iconColor: AppColors.primary,
                      label: 'Date',
                      value: DateFormat('MMMM d, yyyy').format(event.eventDate),
                    ),
                    const SizedBox(height: 16),

                    // Notification time
                    _buildSummaryField(
                      icon: Icons.notifications,
                      iconColor: AppColors.accent,
                      label: 'Reminder Time',
                      value: event.notificationTime != null
                          ? material.TimeOfDay(
                              hour: event.notificationTime!.hour,
                              minute: event.notificationTime!.minute,
                            ).format(context)
                          : '9:00 AM',
                    ),

                    const SizedBox(height: 16),

                    // Recurring status
                    _buildSummaryField(
                      icon: event.isRecurring ? Icons.repeat : Icons.repeat_one,
                      iconColor: event.isRecurring
                          ? AppColors.success
                          : AppColors.gray,
                      label: 'Repeats',
                      value: event.isRecurring
                          ? 'Every year (${event.recurringType.name})'
                          : 'Does not repeat',
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Action buttons
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        _showEditEventDialog(event);
                      },
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Edit'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Colors.blueAccent),
                        foregroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        _deleteEvent(event);
                      },
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Delete'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AppColors.error),
                        foregroundColor: AppColors.error,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom padding for safe area
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// Build a read-only summary field (similar to picker tile but without tap)
  Widget _buildSummaryField({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 14, color: AppColors.gray),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
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
          AppSnackbar.showInfo(context, 'Event deleted');
        }
      } catch (e) {
        if (mounted) {
          AppSnackbar.showError(context, 'Error deleting event: $e');
        }
      }
    }
  }
}
