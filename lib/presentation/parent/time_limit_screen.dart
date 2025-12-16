import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../logic/providers/auth_provider.dart';
import '../../data/models/child_model.dart';

class TimeLimitScreen extends StatelessWidget {
  const TimeLimitScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.userModel;
    final colorScheme = Theme.of(context).colorScheme;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: CustomScrollView(
        slivers: [
          // Modern App Bar
          SliverAppBar(
            expandedHeight: 100,
            floating: true,
            pinned: true,
            backgroundColor: colorScheme.background,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
              title: Text(
                'Time Limits',
                style: TextStyle(
                  color: colorScheme.onBackground,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.info_outline,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                ),
                onPressed: () => _showInfoDialog(context),
              ),
              const SizedBox(width: 8),
            ],
          ),

          // Children List
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .collection('children')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final childrenDocs = snapshot.data!.docs;
              if (childrenDocs.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.child_care,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No children added yet',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final children = childrenDocs
                  .map(
                    (doc) => ChildModel.fromMap(
                      doc.data() as Map<String, dynamic>,
                      doc.id,
                    ),
                  )
                  .toList();

              return SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    return TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: Duration(milliseconds: 400 + (index * 100)),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 30 * (1 - value)),
                            child: child,
                          ),
                        );
                      },
                      child: _ChildTimeLimitCard(
                        child: children[index],
                        parentId: user.uid,
                      ),
                    );
                  }, childCount: children.length),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              Icons.lightbulb_outline,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            const Text('WHO Guidelines'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Under 2 years', 'No screen time', Colors.red),
            _buildInfoRow('2-4 years', 'Less than 1 hour', Colors.orange),
            _buildInfoRow('5+ years', '1-2 hours recommended', Colors.green),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String age, String recommendation, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(age, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  recommendation,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChildTimeLimitCard extends StatefulWidget {
  final ChildModel child;
  final String parentId;

  const _ChildTimeLimitCard({required this.child, required this.parentId});

  @override
  State<_ChildTimeLimitCard> createState() => _ChildTimeLimitCardState();
}

class _ChildTimeLimitCardState extends State<_ChildTimeLimitCard> {
  late int _selectedLimit;
  final List<int> _presets = [
    30 * 60,
    60 * 60,
    2 * 60 * 60,
    3 * 60 * 60,
    4 * 60 * 60,
  ];
  final List<String> _presetLabels = ['30m', '1h', '2h', '3h', '4h'];

  @override
  void initState() {
    super.initState();
    _selectedLimit = widget.child.dailyTimeLimit;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final usedTime = widget.child.screenTime;
    final limitTime = _selectedLimit > 0 ? _selectedLimit : 1;
    final progress = _selectedLimit > 0
        ? (usedTime / limitTime).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [colorScheme.primary, colorScheme.tertiary],
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: colorScheme.surface,
                    backgroundImage: widget.child.avatar != null
                        ? AssetImage(widget.child.avatar!)
                        : null,
                    child: widget.child.avatar == null
                        ? Text(
                            widget.child.name[0].toUpperCase(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.child.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${widget.child.age} years old',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(progress),
              ],
            ),

            const SizedBox(height: 24),

            // Progress Ring
            SizedBox(
              height: 180,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Background circle
                  SizedBox(
                    width: 160,
                    height: 160,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: progress),
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return CustomPaint(
                          painter: _ProgressRingPainter(
                            progress: value,
                            backgroundColor: colorScheme.surfaceVariant,
                            progressColor: _getProgressColor(value),
                          ),
                        );
                      },
                    ),
                  ),
                  // Center text
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatDuration(_selectedLimit),
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      Text(
                        'Daily Limit',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      if (_selectedLimit > 0) ...[
                        const SizedBox(height: 8),
                        Text(
                          '${_formatDuration(usedTime)} used',
                          style: TextStyle(
                            color: _getProgressColor(progress),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Preset buttons
            Text(
              'Quick Set',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(_presets.length, (index) {
                final isSelected = _selectedLimit == _presets[index];
                return _PresetButton(
                  label: _presetLabels[index],
                  isSelected: isSelected,
                  onTap: () => _updateLimit(_presets[index]),
                );
              }),
            ),

            const SizedBox(height: 16),

            // Custom slider
            _buildCustomSlider(),

            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _updateLimit(0),
                    icon: const Icon(Icons.all_inclusive, size: 18),
                    label: const Text('Unlimited'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _resetUsage,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Reset'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(double progress) {
    Color color;
    String text;
    if (_selectedLimit == 0) {
      color = Colors.blue;
      text = 'Unlimited';
    } else if (progress >= 1) {
      color = Colors.red;
      text = 'Limit Reached';
    } else if (progress >= 0.8) {
      color = Colors.orange;
      text = 'Almost Done';
    } else {
      color = Colors.green;
      text = 'Good';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildCustomSlider() {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        activeTrackColor: Theme.of(context).colorScheme.primary,
        inactiveTrackColor: Colors.grey.shade200,
        thumbColor: Theme.of(context).colorScheme.primary,
        overlayColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
        trackHeight: 6,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
      ),
      child: Slider(
        value: _selectedLimit.toDouble(),
        min: 0,
        max: 8 * 60 * 60,
        divisions: 48,
        onChanged: (value) => setState(() => _selectedLimit = value.toInt()),
        onChangeEnd: (value) => _updateLimit(value.toInt()),
      ),
    );
  }

  Color _getProgressColor(double progress) {
    if (progress >= 1) return Colors.red;
    if (progress >= 0.8) return Colors.orange;
    if (progress >= 0.5) return Colors.amber;
    return Colors.green;
  }

  String _formatDuration(int seconds) {
    if (seconds == 0) return '∞';
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (hours > 0) {
      return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
    }
    return '${minutes}m';
  }

  void _updateLimit(int value) {
    setState(() => _selectedLimit = value);
    FirebaseFirestore.instance
        .collection('users')
        .doc(widget.parentId)
        .collection('children')
        .doc(widget.child.id)
        .update({'dailyTimeLimit': value});
  }

  void _resetUsage() async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.parentId)
        .collection('children')
        .doc(widget.child.id)
        .update({'screenTime': 0});

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Screen time reset for today'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }
}

class _PresetButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PresetButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [colorScheme.primary, colorScheme.tertiary],
                )
              : null,
          color: isSelected ? null : colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color progressColor;

  _ProgressRingPainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const strokeWidth = 12.0;

    // Background circle
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      rect,
      -math.pi / 2, // Start from top
      2 * math.pi * progress, // Sweep angle
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.progressColor != progressColor;
  }
}
