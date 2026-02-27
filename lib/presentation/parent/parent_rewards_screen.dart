import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../data/models/child_model.dart';
import '../../data/models/reward_model.dart';
import '../../logic/providers/auth_provider.dart';
import '../../logic/providers/rewards_provider.dart';
import 'package:kidguard/l10n/app_localizations.dart';
import '../../core/utils/responsive_helper.dart';

// Emoji grid ที่เหมาะกับเด็ก — แบ่งเป็นหมวด
const List<String> _availableEmojis = [
  // อาหาร/ขนม
  '🍦', '🍕', '🍩', '🍫', '🎂', '🍪', '🧁', '🍰',
  // ความบันเทิง
  '🎮', '🎬', '🎵', '🎨', '🎪', '🎭', '🎠', '🎡',
  // กิจกรรม
  '🏊', '🚴', '🏕️', '🏞️', '⛱️', '🌊', '🎯', '🏆',
  // ของเล่น/ของขวัญ
  '🧸', '🎁', '🎈', '🪀', '🎲', '🧩', '🪁', '🤖',
  // อื่นๆ
  '⭐', '💎', '👑', '🌟', '🦄', '🐱', '🐶', '🌈',
];

class ParentRewardsScreen extends StatefulWidget {
  final ChildModel child;

  const ParentRewardsScreen({super.key, required this.child});

  @override
  State<ParentRewardsScreen> createState() => _ParentRewardsScreenState();
}

class _ParentRewardsScreenState extends State<ParentRewardsScreen> {
  // Helper method to get localized quick reasons
  List<Map<String, dynamic>> _getQuickReasons(BuildContext context) {
    return [
      {
        'emoji': '📚',
        'label': AppLocalizations.of(context)!.homework,
        'points': 10,
      },
      {
        'emoji': '🧹',
        'label': AppLocalizations.of(context)!.chores,
        'points': 15,
      },
      {
        'emoji': '🌟',
        'label': AppLocalizations.of(context)!.goodBehavior,
        'points': 20,
      },
      {
        'emoji': '🏃',
        'label': AppLocalizations.of(context)!.exercise,
        'points': 10,
      },
    ];
  }

  // Default rewards (hardcoded) — ยังคงเก็บไว้เป็นรางวัลแนะนำ
  List<Map<String, dynamic>> _getDefaultRewards(BuildContext context) {
    return [
      {
        'emoji': '🍦',
        'name': AppLocalizations.of(context)!.iceCream,
        'cost': 50,
        'isCustom': false,
      },
      {
        'emoji': '🎮',
        'name': AppLocalizations.of(context)!.gameTime,
        'cost': 100,
        'isCustom': false,
      },
      {
        'emoji': '🎬',
        'name': AppLocalizations.of(context)!.movie,
        'cost': 150,
        'isCustom': false,
      },
      {
        'emoji': '🧸',
        'name': AppLocalizations.of(context)!.newToy,
        'cost': 300,
        'isCustom': false,
      },
      {
        'emoji': '🌙',
        'name': AppLocalizations.of(context)!.stayUp,
        'cost': 80,
        'isCustom': false,
      },
      {
        'emoji': '🏞️',
        'name': AppLocalizations.of(context)!.parkTrip,
        'cost': 200,
        'isCustom': false,
      },
    ];
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final rewardsProvider = context.read<RewardsProvider>();
      rewardsProvider.initializePoints(widget.child.points);

      final authProvider = context.read<AuthProvider>();
      final user = authProvider.userModel;
      if (user != null) {
        rewardsProvider.fetchHistory(user.uid, widget.child.id);
        rewardsProvider.fetchCustomRewards(user.uid);
      }
    });
  }

  Future<void> _addPoints(int amount, String reason) async {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.userModel;
    if (user == null) return;

    final rewardsProvider = context.read<RewardsProvider>();
    final success = await rewardsProvider.addPoints(
      userId: user.uid,
      childId: widget.child.id,
      amount: amount,
      reason: reason,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.pointsEarned(amount, reason),
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  Future<void> _redeemReward(Map<String, dynamic> reward) async {
    final rewardsProvider = context.read<RewardsProvider>();

    if (rewardsProvider.currentPoints < reward['cost']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(
              context,
            )!.needMorePoints(reward['cost'] - rewardsProvider.currentPoints),
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Text(reward['emoji'], style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                AppLocalizations.of(context)!.redeemConfirm(reward['name']),
              ),
            ),
          ],
        ),
        content: Text(AppLocalizations.of(context)!.redeemCost(reward['cost'])),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B9080),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(AppLocalizations.of(context)!.redeemNow),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final authProvider = context.read<AuthProvider>();
      final user = authProvider.userModel;
      if (user == null) return;

      final redeemReason = AppLocalizations.of(
        context,
      )!.redeemed(reward['name']);
      final success = await rewardsProvider.redeemReward(
        userId: user.uid,
        childId: widget.child.id,
        cost: reward['cost'],
        rewardName: redeemReason,
      );

      if (success && mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(reward['emoji'], style: const TextStyle(fontSize: 64)),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)!.success,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(
                    context,
                  )!.earnedReward(widget.child.name, reward['name']),
                ),
              ],
            ),
            actions: [
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(AppLocalizations.of(context)!.close),
                ),
              ),
            ],
          ),
        );
      }
    }
  }

  // ==================== Custom Reward Bottom Sheet ====================

  void _showAddRewardSheet({RewardModel? existingReward}) {
    final nameController = TextEditingController(
      text: existingReward?.name ?? '',
    );
    final costController = TextEditingController(
      text: existingReward != null ? existingReward.cost.toString() : '',
    );
    String selectedEmoji = existingReward?.emoji ?? '⭐';
    final isEditing = existingReward != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final r = ResponsiveHelper.of(context);
            final l10n = AppLocalizations.of(context)!;

            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF6FBF4),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(r.radius(28)),
                ),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    r.wp(24),
                    r.hp(12),
                    r.wp(24),
                    r.hp(24),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle bar
                      Center(
                        child: Container(
                          width: r.wp(40),
                          height: r.hp(4),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(r.radius(4)),
                          ),
                        ),
                      ),
                      SizedBox(height: r.hp(20)),

                      // Title
                      Text(
                        isEditing ? l10n.editReward : l10n.addReward,
                        style: TextStyle(
                          fontSize: r.sp(22),
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                      SizedBox(height: r.hp(24)),

                      // Selected emoji preview
                      Center(
                        child: Container(
                          width: r.wp(80),
                          height: r.wp(80),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6B9080).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(r.radius(20)),
                            border: Border.all(
                              color: const Color(0xFF6B9080).withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              selectedEmoji,
                              style: TextStyle(fontSize: r.sp(40)),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: r.hp(20)),

                      // Emoji picker label
                      Text(
                        l10n.selectIcon,
                        style: TextStyle(
                          fontSize: r.sp(14),
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                      SizedBox(height: r.hp(8)),

                      // Emoji grid
                      Container(
                        height: r.hp(160),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(r.radius(16)),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: GridView.builder(
                          padding: EdgeInsets.all(r.wp(8)),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 8,
                                mainAxisSpacing: r.hp(4),
                                crossAxisSpacing: r.wp(4),
                              ),
                          itemCount: _availableEmojis.length,
                          itemBuilder: (context, index) {
                            final emoji = _availableEmojis[index];
                            final isSelected = emoji == selectedEmoji;
                            return GestureDetector(
                              onTap: () {
                                setSheetState(() {
                                  selectedEmoji = emoji;
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(
                                          0xFF6B9080,
                                        ).withOpacity(0.15)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(
                                    r.radius(10),
                                  ),
                                  border: isSelected
                                      ? Border.all(
                                          color: const Color(0xFF6B9080),
                                          width: 2,
                                        )
                                      : null,
                                ),
                                child: Center(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      emoji,
                                      style: TextStyle(fontSize: r.sp(20)),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      SizedBox(height: r.hp(20)),

                      // Reward name field
                      Text(
                        l10n.rewardName,
                        style: TextStyle(
                          fontSize: r.sp(14),
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                      SizedBox(height: r.hp(8)),
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          hintText: l10n.rewardName,
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(r.radius(14)),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(r.radius(14)),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(r.radius(14)),
                            borderSide: const BorderSide(
                              color: Color(0xFF6B9080),
                              width: 2,
                            ),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: r.wp(16),
                            vertical: r.hp(14),
                          ),
                        ),
                      ),
                      SizedBox(height: r.hp(16)),

                      // Cost field
                      Text(
                        l10n.rewardCost,
                        style: TextStyle(
                          fontSize: r.sp(14),
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                      SizedBox(height: r.hp(8)),
                      TextField(
                        controller: costController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: '50',
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon: Icon(
                            Icons.star_rounded,
                            color: Colors.amber,
                            size: r.iconSize(22),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(r.radius(14)),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(r.radius(14)),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(r.radius(14)),
                            borderSide: const BorderSide(
                              color: Color(0xFF6B9080),
                              width: 2,
                            ),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: r.wp(16),
                            vertical: r.hp(14),
                          ),
                        ),
                      ),
                      SizedBox(height: r.hp(28)),

                      // Save button
                      SizedBox(
                        width: double.infinity,
                        height: r.hp(52),
                        child: ElevatedButton(
                          onPressed: () => _saveReward(
                            nameController.text.trim(),
                            costController.text.trim(),
                            selectedEmoji,
                            existingReward,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6B9080),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(r.radius(16)),
                            ),
                          ),
                          child: Text(
                            l10n.save,
                            style: TextStyle(
                              fontSize: r.sp(16),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: r.hp(8)),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _saveReward(
    String name,
    String costText,
    String emoji,
    RewardModel? existingReward,
  ) async {
    final l10n = AppLocalizations.of(context)!;

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.enterRewardName),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final cost = int.tryParse(costText);
    if (cost == null || cost <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.enterValidCost),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final user = authProvider.userModel;
    if (user == null) return;

    final rewardsProvider = context.read<RewardsProvider>();
    bool success;

    if (existingReward != null) {
      success = await rewardsProvider.updateCustomReward(
        userId: user.uid,
        rewardId: existingReward.id,
        name: name,
        emoji: emoji,
        cost: cost,
      );
    } else {
      success = await rewardsProvider.addCustomReward(
        userId: user.uid,
        name: name,
        emoji: emoji,
        cost: cost,
      );
    }

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            existingReward != null ? l10n.rewardUpdated : l10n.rewardAdded,
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  Future<void> _deleteReward(RewardModel reward) async {
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Text(reward.emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 10),
            Expanded(child: Text(l10n.deleteRewardConfirm)),
          ],
        ),
        content: Text(reward.name),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[400],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(l10n.deleteReward),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final authProvider = context.read<AuthProvider>();
      final user = authProvider.userModel;
      if (user == null) return;

      final rewardsProvider = context.read<RewardsProvider>();
      final success = await rewardsProvider.deleteCustomReward(
        userId: user.uid,
        rewardId: reward.id,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.rewardDeleted),
            backgroundColor: Colors.grey[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  void _showRewardOptions(RewardModel reward) {
    final l10n = AppLocalizations.of(context)!;
    final r = ResponsiveHelper.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(r.radius(20)),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: r.hp(8)),
              Container(
                width: r.wp(40),
                height: r.hp(4),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(r.radius(4)),
                ),
              ),
              SizedBox(height: r.hp(16)),
              Text(
                '${reward.emoji} ${reward.name}',
                style: TextStyle(
                  fontSize: r.sp(18),
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: r.hp(16)),
              ListTile(
                leading: const Icon(
                  Icons.edit_rounded,
                  color: Color(0xFF6B9080),
                ),
                title: Text(l10n.editReward),
                onTap: () {
                  Navigator.pop(context);
                  _showAddRewardSheet(existingReward: reward);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete_rounded, color: Colors.red[400]),
                title: Text(
                  l10n.deleteReward,
                  style: TextStyle(color: Colors.red[400]),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _deleteReward(reward);
                },
              ),
              SizedBox(height: r.hp(8)),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== Build ====================

  @override
  Widget build(BuildContext context) {
    final r = ResponsiveHelper.of(context);
    final rewardsProvider = context.watch<RewardsProvider>();
    final currentPoints = rewardsProvider.currentPoints;

    return Scaffold(
      backgroundColor: const Color(0xFFF6FBF4),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // App Bar with Points
              SliverAppBar(
                expandedHeight: r.hp(220),
                floating: false,
                pinned: true,
                backgroundColor: const Color(0xFF6B9080),
                leading: IconButton(
                  icon: Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: r.iconSize(24),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF6B9080), Color(0xFF84A98C)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: SafeArea(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return Padding(
                            padding: EdgeInsets.symmetric(horizontal: r.wp(16)),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.center,
                              child: SizedBox(
                                width: constraints.maxWidth - r.wp(32),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(height: r.hp(16)),
                                    // Child Avatar
                                    CircleAvatar(
                                      radius: r.wp(30),
                                      backgroundColor: Colors.white.withOpacity(
                                        0.2,
                                      ),
                                      backgroundImage:
                                          widget.child.avatar != null
                                          ? AssetImage(widget.child.avatar!)
                                          : null,
                                      child: widget.child.avatar == null
                                          ? Text(
                                              widget.child.name[0],
                                              style: TextStyle(
                                                fontSize: r.sp(24),
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            )
                                          : null,
                                    ),
                                    SizedBox(height: r.hp(8)),
                                    Text(
                                      widget.child.name,
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: r.sp(15),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                    SizedBox(height: r.hp(4)),
                                    // Points Display
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.star_rounded,
                                          color: Colors.amber,
                                          size: r.iconSize(28),
                                        ),
                                        SizedBox(width: r.wp(6)),
                                        TweenAnimationBuilder<int>(
                                          tween: IntTween(
                                            begin: 0,
                                            end: currentPoints,
                                          ),
                                          duration: const Duration(
                                            milliseconds: 600,
                                          ),
                                          builder: (context, value, child) {
                                            return Text(
                                              '$value',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: r.sp(42),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            );
                                          },
                                        ),
                                        SizedBox(width: r.wp(4)),
                                        Text(
                                          AppLocalizations.of(context)!.points,
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: r.sp(16),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: r.hp(8)),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),

              // Quick Add Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    r.wp(20),
                    r.hp(24),
                    r.wp(20),
                    r.hp(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.quickAdd,
                        style: TextStyle(
                          fontSize: r.sp(18),
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                      SizedBox(height: r.hp(12)),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final cardWidth = (constraints.maxWidth - 36) / 4;
                          return IntrinsicHeight(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: _getQuickReasons(context).map((item) {
                                return GestureDetector(
                                  onTap: () =>
                                      _addPoints(item['points'], item['label']),
                                  child: Container(
                                    width: cardWidth.clamp(70.0, 90.0),
                                    padding: EdgeInsets.symmetric(
                                      vertical: r.hp(10),
                                      horizontal: r.wp(6),
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(
                                        r.radius(16),
                                      ),
                                      border: Border.all(
                                        color: Colors.grey.shade200,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.03),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            item['emoji'],
                                            style: TextStyle(
                                              fontSize: r.sp(22),
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: r.hp(3)),
                                        Text(
                                          '+${item['points']}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF10B981),
                                            fontSize: r.sp(13),
                                          ),
                                        ),
                                        SizedBox(height: r.hp(2)),
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            item['label'],
                                            style: TextStyle(
                                              fontSize: r.sp(10),
                                              color: Colors.grey[600],
                                            ),
                                            maxLines: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Default Rewards Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    r.wp(20),
                    r.hp(8),
                    r.wp(20),
                    r.hp(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.defaultRewards,
                        style: TextStyle(
                          fontSize: r.sp(18),
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                      SizedBox(height: r.hp(8)),
                      SizedBox(
                        height: r.hp(140),
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          clipBehavior: Clip.none,
                          itemCount: _getDefaultRewards(context).length,
                          separatorBuilder: (_, __) =>
                              SizedBox(width: r.wp(12)),
                          itemBuilder: (context, index) {
                            final reward = _getDefaultRewards(context)[index];
                            return _buildRewardCard(
                              r,
                              reward,
                              currentPoints,
                              isCustom: false,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Custom "My Rewards" Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    r.wp(20),
                    r.hp(8),
                    r.wp(20),
                    r.hp(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.myRewards,
                            style: TextStyle(
                              fontSize: r.sp(18),
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1F2937),
                            ),
                          ),
                          // Add reward button
                          GestureDetector(
                            onTap: () => _showAddRewardSheet(),
                            child: Container(
                              padding: EdgeInsets.all(r.wp(8)),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6B9080),
                                borderRadius: BorderRadius.circular(
                                  r.radius(12),
                                ),
                              ),
                              child: Icon(
                                Icons.add_rounded,
                                color: Colors.white,
                                size: r.iconSize(20),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: r.hp(8)),
                      if (rewardsProvider.customRewards.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(r.wp(24)),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(r.radius(16)),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.card_giftcard_rounded,
                                size: r.iconSize(40),
                                color: Colors.grey[300],
                              ),
                              SizedBox(height: r.hp(12)),
                              Text(
                                AppLocalizations.of(context)!.noRewardsYet,
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: r.sp(14),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      else
                        SizedBox(
                          height: r.hp(140),
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            clipBehavior: Clip.none,
                            itemCount: rewardsProvider.customRewards.length,
                            separatorBuilder: (_, __) =>
                                SizedBox(width: r.wp(12)),
                            itemBuilder: (context, index) {
                              final reward =
                                  rewardsProvider.customRewards[index];
                              final rewardMap = {
                                'emoji': reward.emoji,
                                'name': reward.name,
                                'cost': reward.cost,
                                'isCustom': true,
                                'model': reward,
                              };
                              return _buildRewardCard(
                                r,
                                rewardMap,
                                currentPoints,
                                isCustom: true,
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Calendar Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    r.wp(20),
                    r.hp(8),
                    r.wp(20),
                    r.hp(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.pointHistory,
                        style: TextStyle(
                          fontSize: r.sp(18),
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                      SizedBox(height: r.hp(12)),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(r.radius(20)),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: TableCalendar(
                          firstDay: DateTime.utc(2024, 1, 1),
                          lastDay: DateTime.utc(2030, 12, 31),
                          focusedDay: rewardsProvider.focusedDay,
                          calendarFormat: CalendarFormat.week,
                          selectedDayPredicate: (day) =>
                              isSameDay(rewardsProvider.selectedDay, day),
                          onDaySelected: (selectedDay, focusedDay) {
                            rewardsProvider.selectDay(selectedDay, focusedDay);
                          },
                          eventLoader: rewardsProvider.getEventsForDay,
                          calendarStyle: CalendarStyle(
                            selectedDecoration: const BoxDecoration(
                              color: Color(0xFF6B9080),
                              shape: BoxShape.circle,
                            ),
                            todayDecoration: BoxDecoration(
                              color: const Color(0xFF6B9080).withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            markerDecoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                            markerSize: r.wp(6),
                            markersMaxCount: 1,
                          ),
                          headerStyle: HeaderStyle(
                            formatButtonVisible: false,
                            titleCentered: true,
                            leftChevronIcon: Icon(
                              Icons.chevron_left,
                              size: r.iconSize(20),
                            ),
                            rightChevronIcon: Icon(
                              Icons.chevron_right,
                              size: r.iconSize(20),
                            ),
                          ),
                          daysOfWeekHeight: r.hp(32),
                          rowHeight: r.hp(48),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Activity List
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: r.wp(20)),
                  child: _buildActivityList(),
                ),
              ),

              SliverToBoxAdapter(child: SizedBox(height: r.hp(32))),
            ],
          ),

          // Loading Overlay
          if (rewardsProvider.isLoading)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFF6B9080)),
              ),
            ),
        ],
      ),
    );
  }

  // ==================== Reward Card Builder ====================

  Widget _buildRewardCard(
    ResponsiveHelper r,
    Map<String, dynamic> reward,
    int currentPoints, {
    required bool isCustom,
  }) {
    final canAfford = currentPoints >= (reward['cost'] as int);

    return GestureDetector(
      onTap: () => _redeemReward(reward),
      onLongPress: isCustom
          ? () => _showRewardOptions(reward['model'] as RewardModel)
          : null,
      child: Container(
        width: r.wp(100),
        padding: EdgeInsets.symmetric(horizontal: r.wp(8), vertical: r.hp(8)),
        decoration: BoxDecoration(
          color: canAfford ? Colors.white : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(r.radius(16)),
          border: Border.all(
            color: canAfford
                ? isCustom
                      ? const Color(0xFF6B9080).withOpacity(0.5)
                      : const Color(0xFF6B9080).withOpacity(0.3)
                : Colors.grey.shade200,
          ),
          boxShadow: isCustom
              ? [
                  BoxShadow(
                    color: const Color(0xFF6B9080).withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  reward['emoji'],
                  style: TextStyle(
                    fontSize: r.sp(28),
                    color: canAfford ? null : Colors.grey,
                  ),
                ),
              ),
            ),
            SizedBox(height: r.hp(4)),
            Text(
              reward['name'],
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: r.sp(11),
                color: canAfford ? Colors.black87 : Colors.grey,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: r.hp(3)),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: r.wp(8),
                vertical: r.hp(2),
              ),
              decoration: BoxDecoration(
                color: canAfford
                    ? const Color(0xFF6B9080).withOpacity(0.1)
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(r.radius(8)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.star_rounded,
                    size: r.iconSize(12),
                    color: canAfford ? const Color(0xFF6B9080) : Colors.grey,
                  ),
                  SizedBox(width: r.wp(2)),
                  Text(
                    '${reward['cost']}',
                    style: TextStyle(
                      fontSize: r.sp(11),
                      fontWeight: FontWeight.bold,
                      color: canAfford ? const Color(0xFF6B9080) : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityList() {
    final rewardsProvider = context.watch<RewardsProvider>();
    final events = rewardsProvider.selectedDay != null
        ? rewardsProvider.getEventsForDay(rewardsProvider.selectedDay!)
        : [];
    final r = ResponsiveHelper.of(context);

    if (events.isEmpty) {
      return Container(
        padding: EdgeInsets.all(r.wp(24)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(r.radius(16)),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(
              Icons.event_note_rounded,
              size: r.iconSize(40),
              color: Colors.grey[300],
            ),
            SizedBox(height: r.hp(12)),
            Text(
              AppLocalizations.of(context)!.noActivity,
              style: TextStyle(color: Colors.grey[500], fontSize: r.sp(14)),
            ),
          ],
        ),
      );
    }

    return Column(
      children: events.map((event) {
        final isEarn = event['type'] == 'earn';
        return Container(
          margin: EdgeInsets.only(bottom: r.hp(8)),
          padding: EdgeInsets.all(r.wp(14)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(r.radius(14)),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(r.wp(10)),
                decoration: BoxDecoration(
                  color: isEarn
                      ? const Color(0xFF10B981).withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(r.radius(12)),
                ),
                child: Icon(
                  isEarn ? Icons.add_rounded : Icons.remove_rounded,
                  color: isEarn ? const Color(0xFF10B981) : Colors.orange,
                  size: r.iconSize(20),
                ),
              ),
              SizedBox(width: r.wp(14)),
              Expanded(
                child: Text(
                  event['reason'] ?? '',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: r.sp(14),
                  ),
                ),
              ),
              Text(
                '${isEarn ? '+' : '-'}${event['amount']}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: r.sp(16),
                  color: isEarn ? const Color(0xFF10B981) : Colors.orange,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
