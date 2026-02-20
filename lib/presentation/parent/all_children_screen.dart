import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logic/providers/auth_provider.dart';
import '../../data/models/child_model.dart';
import 'child_setup_screen.dart';
import '../../core/utils/responsive_helper.dart';

class AllChildrenScreen extends StatelessWidget {
  const AllChildrenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.userModel;
    final colorScheme = Theme.of(context).colorScheme;
    final r = ResponsiveHelper.of(context);

    if (user == null)
      return const Scaffold(body: Center(child: Text('User not found')));

    return Scaffold(
      backgroundColor: const Color(0xFFF6FBF4),
      appBar: AppBar(
        title: Text('My Children', style: TextStyle(fontSize: r.sp(18))),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ChildSetupScreen()),
          );
        },
        label: Text('Add Child', style: TextStyle(fontSize: r.sp(14))),
        icon: Icon(Icons.add, size: r.iconSize(20)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('children')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_off_outlined,
                    size: r.iconSize(64),
                    color: Colors.grey.shade300,
                  ),
                  SizedBox(height: r.hp(16)),
                  Text(
                    'No children profiles yet',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: r.sp(16),
                    ),
                  ),
                  SizedBox(height: r.hp(16)),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ChildSetupScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: r.wp(24),
                        vertical: r.hp(12),
                      ),
                    ),
                    child: Text(
                      'Add your first child',
                      style: TextStyle(fontSize: r.sp(14)),
                    ),
                  ),
                ],
              ),
            );
          }

          final children = snapshot.data!.docs
              .map(
                (doc) => ChildModel.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ),
              )
              .toList();

          return ListView.separated(
            padding: EdgeInsets.all(r.wp(20)),
            itemCount: children.length,
            separatorBuilder: (_, __) => SizedBox(height: r.hp(16)),
            itemBuilder: (context, index) {
              final child = children[index];
              return _buildChildCard(context, child, colorScheme);
            },
          );
        },
      ),
    );
  }

  Widget _buildChildCard(
    BuildContext context,
    ChildModel child,
    ColorScheme colorScheme,
  ) {
    final r = ResponsiveHelper.of(context);
    return Container(
      padding: EdgeInsets.all(r.wp(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(r.radius(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: r.wp(60),
            height: r.wp(60),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.5),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: child.avatar != null
                ? ClipOval(child: Image.asset(child.avatar!, fit: BoxFit.cover))
                : Icon(
                    Icons.person,
                    color: colorScheme.primary,
                    size: r.iconSize(30),
                  ),
          ),
          SizedBox(width: r.wp(16)),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  child.name,
                  style: TextStyle(
                    fontSize: r.sp(18),
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                SizedBox(height: r.hp(4)),
                Text(
                  '${child.age} years old • ${child.dailyTimeLimit == 0 ? "No Limit" : "${(child.dailyTimeLimit / 3600).toStringAsFixed(1)}h limit"}',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: r.sp(14),
                  ),
                ),
              ],
            ),
          ),
          // Edit Button
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChildSetupScreen(child: child),
                ),
              );
            },
            icon: Container(
              padding: EdgeInsets.all(r.wp(8)),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(r.radius(12)),
              ),
              child: Icon(Icons.edit_rounded, size: r.iconSize(20)),
            ),
          ),
        ],
      ),
    );
  }
}
