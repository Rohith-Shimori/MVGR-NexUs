import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Interactive tutorials screen with expandable sections
class TutorialsScreen extends StatelessWidget {
  const TutorialsScreen({super.key});

  static const _tutorials = [
    _Tutorial(
      icon: Icons.groups,
      title: 'Joining Clubs',
      color: AppColors.clubsColor,
      steps: [
        'Go to Explore → Clubs',
        'Browse or search for clubs',
        'Tap on a club to view details',
        'Tap "Join" to request membership',
        'Wait for admin approval (if required)',
      ],
    ),
    _Tutorial(
      icon: Icons.event,
      title: 'Finding Events',
      color: AppColors.eventsColor,
      steps: [
        'Go to Explore → Events',
        'Filter by category or date',
        'Tap an event for details',
        'RSVP to save your spot',
        'Add to calendar for reminders',
      ],
    ),
    _Tutorial(
      icon: Icons.forum,
      title: 'Using Academic Forum',
      color: AppColors.forumColor,
      steps: [
        'Go to Community → Forum',
        'Browse questions or post your own',
        'Use tags to categorize questions',
        'Upvote helpful answers',
        'Mark best answer if you asked',
      ],
    ),
    _Tutorial(
      icon: Icons.people,
      title: 'Finding Study Buddies',
      color: AppColors.studyBuddyColor,
      steps: [
        'Go to Tools → Study Buddy',
        'Create a study request',
        'Specify subject and preferences',
        'Get matched with compatible peers',
        'Connect and study together!',
      ],
    ),
    _Tutorial(
      icon: Icons.inventory,
      title: 'Using Resource Vault',
      color: AppColors.vaultColor,
      steps: [
        'Go to Tools → Vault',
        'Browse by subject or semester',
        'Download study materials',
        'Upload your own resources to help others',
        'Rate and review materials',
      ],
    ),
    _Tutorial(
      icon: Icons.radio,
      title: 'Campus Radio',
      color: AppColors.radioColor,
      steps: [
        'Go to Community → Radio',
        'Listen to live campus radio',
        'Request songs during sessions',
        'Send shoutouts to friends',
        'Vote on upcoming tracks',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('How To Use'),
        backgroundColor: AppColors.info,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _tutorials.length,
        itemBuilder: (context, index) {
          final tutorial = _tutorials[index];
          return _TutorialCard(tutorial: tutorial);
        },
      ),
    );
  }
}

class _Tutorial {
  final IconData icon;
  final String title;
  final Color color;
  final List<String> steps;

  const _Tutorial({
    required this.icon,
    required this.title,
    required this.color,
    required this.steps,
  });
}

class _TutorialCard extends StatefulWidget {
  final _Tutorial tutorial;

  const _TutorialCard({required this.tutorial});

  @override
  State<_TutorialCard> createState() => _TutorialCardState();
}

class _TutorialCardState extends State<_TutorialCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.tutorial;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: t.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(t.icon, color: t.color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      t.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Expandable steps
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Container(
              color: t.color.withValues(alpha: 0.05),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: t.steps.asMap().entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: t.color,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${entry.key + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            entry.value,
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).textTheme.bodyMedium?.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            crossFadeState: _expanded 
                ? CrossFadeState.showSecond 
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}
