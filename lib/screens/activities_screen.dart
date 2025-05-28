import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/activity_model.dart';
import '../styles/app_text_styles.dart';

class ActivitiesScreen extends StatefulWidget {
  const ActivitiesScreen({super.key});

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Activity>> _activities = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      final startDate = DateTime(_focusedDay.year, _focusedDay.month, 1);
      final endDate = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);

      print('Loading activities for month: ${startDate.toString()} to ${endDate.toString()}');

      final snapshot = await _firestore
          .collection('activities')
          .where('userId', isEqualTo: userId)
          .get();

      print('Found ${snapshot.docs.length} activities in total');

      final activities = <DateTime, List<Activity>>{};
      for (final doc in snapshot.docs) {
        //print('Processing document: ${doc.id}');
        //print('Document data: ${doc.data()}');
        
        final data = doc.data();
        final dateStr = data['date'] as String;
        final activityDate = DateTime.parse(dateStr);
        //print('Activity date: $activityDate');

        // 只保留当月的活动
        if (activityDate.year == _focusedDay.year && 
            activityDate.month == _focusedDay.month) {
          final activity = Activity.fromMap({
            ...data,
            'id': doc.id,
          });
          
          final date = DateTime(
            activity.date.year,
            activity.date.month,
            activity.date.day,
          );
          
          activities[date] = [...(activities[date] ?? []), activity];
          print('Added activity for date: $date');
        }
      }

      //print('Final activities map: $activities');

      if (mounted) {
        setState(() {
          _activities = activities;
        });
      }
    } catch (e, stackTrace) {
      print('Error loading activities: $e');
      print('Stack trace: $stackTrace');
    }
  }

  Future<void> _showAddActivityDialog([DateTime? date]) async {
    date ??= _selectedDay ?? DateTime.now();
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Activity', style: AppTextStyles.titleLarge),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  labelStyle: AppTextStyles.bodyMedium,
                ),
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  labelStyle: AppTextStyles.bodyMedium,
                ),
                style: AppTextStyles.bodyMedium,
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: AppTextStyles.bodyMedium),
          ),
          FilledButton(
            onPressed: () async {
              if (titleController.text.isEmpty) return;
              
              final userId = _auth.currentUser?.uid;
              if (userId == null) return;

              try {
                print('Adding activity for date: ${date.toString()}');
                final docRef = await _firestore.collection('activities').add({
                  'userId': userId,
                  'title': titleController.text.trim(),
                  'description': descriptionController.text.trim(),
                  'date': date!.toIso8601String(),
                  'createdAt': DateTime.now().toIso8601String(),
                });
                
                print('Activity added with ID: ${docRef.id}');

                if (mounted) {
                  Navigator.pop(context);
                  await _loadActivities();  // 等待加载完成
                }
              } catch (e, stackTrace) {
                print('Error adding activity: $e');
                print('Stack trace: $stackTrace');
              }
            },
            child: Text('Save', style: AppTextStyles.button.copyWith(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _showActivityDetails(Activity activity) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(activity.title, style: AppTextStyles.titleLarge),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (activity.description?.isNotEmpty == true) ...[
              Text(
                'Description:',
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                activity.description!,
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 16),
            ],
            Text(
              'Date:',
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${activity.date.year}-${activity.date.month}-${activity.date.day}',
              style: AppTextStyles.bodyMedium,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: AppTextStyles.bodyMedium),
          ),
          TextButton(
            onPressed: () => _showEditActivityDialog(activity),
            child: Text('Edit', style: AppTextStyles.bodyMedium),
          ),
          TextButton(
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Delete Activity', style: AppTextStyles.titleLarge),
                  content: Text(
                    'Are you sure you want to delete this activity?',
                    style: AppTextStyles.bodyMedium,
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text('Cancel', style: AppTextStyles.bodyMedium),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: Text('Delete', style: AppTextStyles.bodyMedium),
                    ),
                  ],
                ),
              );

              if (confirmed == true && mounted) {
                await _firestore.collection('activities').doc(activity.id).delete();
                if (mounted) {
                  Navigator.pop(context);
                  _loadActivities();
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Delete', style: AppTextStyles.bodyMedium),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditActivityDialog(Activity activity) async {
    final titleController = TextEditingController(text: activity.title);
    final descriptionController = TextEditingController(text: activity.description ?? '');
    DateTime selectedDate = activity.date;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Activity', style: AppTextStyles.titleLarge),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  labelStyle: AppTextStyles.bodyMedium,
                ),
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  labelStyle: AppTextStyles.bodyMedium,
                ),
                style: AppTextStyles.bodyMedium,
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text(
                  'Date: ${selectedDate.year}-${selectedDate.month}-${selectedDate.day}',
                  style: AppTextStyles.bodyMedium,
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (date != null) {
                    selectedDate = date;
                    (context as Element).markNeedsBuild();
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: AppTextStyles.bodyMedium),
          ),
          FilledButton(
            onPressed: () async {
              if (titleController.text.isEmpty) return;
              
              final userId = _auth.currentUser?.uid;
              if (userId == null) return;

              try {
                print('Updating activity: ${activity.id}');
                await _firestore.collection('activities').doc(activity.id).update({
                  'title': titleController.text.trim(),
                  'description': descriptionController.text.trim(),
                  'date': selectedDate.toIso8601String(),
                });
                
                print('Activity updated successfully');

                if (mounted) {
                  Navigator.pop(context); // Close edit dialog
                  Navigator.pop(context); // Close details dialog
                  await _loadActivities();
                }
              } catch (e, stackTrace) {
                print('Error updating activity: $e');
                print('Stack trace: $stackTrace');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating activity: $e')),
                  );
                }
              }
            },
            child: Text('Save', style: AppTextStyles.button.copyWith(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedDayActivities = _selectedDay == null
        ? []
        : _activities[DateTime(
            _selectedDay!.year,
            _selectedDay!.month,
            _selectedDay!.day,
          )] ??
            [];

    //print('Selected day: $_selectedDay');
    //print('Activities for selected day: $selectedDayActivities');

    return Column(
      children: [
        TableCalendar(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            print('Day selected: $selectedDay');
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          onPageChanged: (focusedDay) {
            print('Page changed to: $focusedDay');
            _focusedDay = focusedDay;
            _loadActivities();
          },
          eventLoader: (day) {
            final events = _activities[DateTime(
              day.year,
              day.month,
              day.day,
            )] ??
                [];
            //print('Events for $day: ${events.length}');
            return events;
          },
          calendarStyle: CalendarStyle(
            markersMaxCount: 1,
            markerDecoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Activities',
                      style: AppTextStyles.titleLarge.copyWith(fontSize: 20),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => _showAddActivityDialog(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: selectedDayActivities.isEmpty
                    ? Center(
                        child: Text(
                          'No activities for this day',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: selectedDayActivities.length,
                        itemBuilder: (context, index) {
                          final activity = selectedDayActivities[index];
                          return ListTile(
                            title: Text(
                              activity.title,
                              style: AppTextStyles.bodyLarge,
                            ),
                            subtitle: activity.description?.isNotEmpty == true
                                ? Text(
                                    activity.description!,
                                    style: AppTextStyles.bodyMedium,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  )
                                : null,
                            onTap: () => _showActivityDetails(activity),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
} 