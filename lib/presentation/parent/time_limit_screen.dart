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

    if (user == null)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Time Limits'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('children')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final childrenDocs = snapshot.data!.docs;
          if (childrenDocs.isEmpty) {
            return const Center(child: Text('No children added yet.'));
          }

          final children = childrenDocs
              .map(
                (doc) => ChildModel.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: children.length,
            itemBuilder: (context, index) {
              final child = children[index];
              return _buildChildTimeLimitCard(context, child, user.uid);
            },
          );
        },
      ),
    );
  }

  Widget _buildChildTimeLimitCard(
    BuildContext context,
    ChildModel child,
    String parentId,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: child.avatar != null
                      ? AssetImage(child.avatar!)
                      : null,
                  child: child.avatar == null
                      ? Text(child.name[0].toUpperCase())
                      : null,
                ),
                const SizedBox(width: 16),
                Text(
                  child.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Daily Limit',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getWhoRecommendation(child.age),
                      style: const TextStyle(fontSize: 12, color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _TimeLimitSlider(
              initialValue: child.dailyTimeLimit,
              onChanged: (newValue) {
                // Update Firestore
                FirebaseFirestore.instance
                    .collection('users')
                    .doc(parentId)
                    .collection('children')
                    .doc(child.id)
                    .update({'dailyTimeLimit': newValue});
              },
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () async {
                  // Unlock / Reset Time Logic
                  // We can reset screenTime to 0 or extend limit
                  // Let's reset screenTime to 0 for "Unlock" effect
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(parentId)
                      .collection('children')
                      .doc(child.id)
                      .update({'screenTime': 0});

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Screen time reset for today.'),
                    ),
                  );
                },
                icon: const Icon(Icons.lock_open),
                label: const Text('Reset Usage'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getWhoRecommendation(int age) {
    if (age < 1) {
      return 'WHO: No screen time recommended.';
    } else if (age < 2) {
      return 'WHO: No screen time recommended (video chat only).';
    } else if (age <= 4) {
      return 'WHO: Limit to less than 1 hour per day.';
    } else {
      return 'WHO: Consistent limits recommended (e.g., 2 hours).';
    }
  }
}

class _TimeLimitSlider extends StatefulWidget {
  final int initialValue;
  final Function(int) onChanged;

  const _TimeLimitSlider({required this.initialValue, required this.onChanged});

  @override
  State<_TimeLimitSlider> createState() => _TimeLimitSliderState();
}

class _TimeLimitSliderState extends State<_TimeLimitSlider> {
  late double _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.initialValue.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    // Convert seconds to minutes for display
    int minutes = (_currentValue / 60).round();
    String label = minutes == 0 ? 'Unlimited' : '${minutes}m';
    if (minutes >= 60) {
      int h = minutes ~/ 60;
      int m = minutes % 60;
      label = '${h}h ${m > 0 ? '${m}m' : ''}';
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            if (minutes > 0) const Icon(Icons.timer, color: Colors.blue),
          ],
        ),
        Slider(
          value: _currentValue,
          min: 0,
          max: 8 * 60 * 60, // 8 hours in seconds
          divisions: 48, // 10 minute intervals
          label: label,
          onChanged: (value) {
            setState(() {
              _currentValue = value;
            });
          },
          onChangeEnd: (value) {
            widget.onChanged(value.toInt());
          },
        ),
      ],
    );
  }
}
