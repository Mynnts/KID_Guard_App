import 'package:flutter/material.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  int? _expandedIndex;

  // Colors
  static const _accentColor = Color(0xFF6B9080);

  final List<Map<String, String>> _faqs = [
    {
      'question': 'วิธีเชื่อมต่อกับเครื่องลูก?',
      'answer':
          '1. เปิดแอพบนเครื่องลูกแล้วเลือก "เด็ก"\n2. กรอก PIN 6 หลักจากหน้า Settings ของผู้ปกครอง\n3. เลือกโปรไฟล์เด็กหรือสร้างใหม่\n4. เปิดใช้งาน Child Mode',
    },
    {
      'question': 'ทำไมแอพที่ถูกบล็อกยังเปิดได้?',
      'answer':
          'ตรวจสอบว่า:\n• Accessibility Service เปิดอยู่\n• Child Mode เปิดใช้งานอยู่\n• แอพ Kid Guard ยังทำงานอยู่ในพื้นหลัง\n\nถ้ายังไม่ได้ผล ลอง Force Stop แอพ Kid Guard แล้วเปิดใหม่',
    },
    {
      'question': 'วิธีตั้งเวลาจำกัดการใช้งาน?',
      'answer':
          '1. ไปที่ Dashboard > Time Limit\n2. เลือกโปรไฟล์เด็ก\n3. ตั้งเวลาที่ต้องการ (ชั่วโมง:นาที)\n4. กด Save\n\nเมื่อถึงเวลาที่กำหนด หน้าจอเด็กจะถูกล็อค',
    },
    {
      'question': 'วิธีดูตำแหน่งของลูก?',
      'answer':
          '1. ไปที่ Dashboard > Location\n2. เลือกโปรไฟล์เด็ก\n3. ตำแหน่งจะแสดงบนแผนที่\n\nหมายเหตุ: ต้องเปิด Location Permission บนเครื่องเด็ก',
    },
    {
      'question': 'PIN หายทำอย่างไร?',
      'answer':
          '1. ไปที่ Settings > Connection\n2. กด "Regenerate" เพื่อสร้าง PIN ใหม่\n3. ใช้ PIN ใหม่ในการเชื่อมต่อ\n\nหมายเหตุ: เครื่องเด็กที่เชื่อมต่อแล้วไม่ต้องใส่ PIN ใหม่',
    },
    {
      'question': 'วิธีลบโปรไฟล์เด็ก?',
      'answer':
          '1. เปิดแอพบนเครื่องเด็ก\n2. เลือก "เชื่อมต่อกับผู้ปกครอง"\n3. กดค้างที่โปรไฟล์ที่ต้องการลบ\n4. ยืนยันการลบ',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: colorScheme.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: colorScheme.onBackground),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Help Center',
          style: TextStyle(
            color: colorScheme.onBackground,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_accentColor, _accentColor.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.help,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ศูนย์ช่วยเหลือ',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'คำถามที่พบบ่อยและวิธีใช้งาน',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Search (Visual only)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search,
                    color: colorScheme.onSurface.withOpacity(0.4),
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'ค้นหาคำถาม...',
                    style: TextStyle(
                      color: colorScheme.onSurface.withOpacity(0.4),
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // FAQ Section
            Text(
              'คำถามที่พบบ่อย',
              style: TextStyle(
                color: colorScheme.onBackground.withOpacity(0.6),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),

            // FAQ Cards
            ...List.generate(_faqs.length, (index) {
              final faq = _faqs[index];
              final isExpanded = _expandedIndex == index;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      setState(() {
                        _expandedIndex = isExpanded ? null : index;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: _accentColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      color: _accentColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  faq['question']!,
                                  style: TextStyle(
                                    color: colorScheme.onSurface,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              AnimatedRotation(
                                turns: isExpanded ? 0.5 : 0,
                                duration: const Duration(milliseconds: 200),
                                child: Icon(
                                  Icons.keyboard_arrow_down,
                                  color: colorScheme.onSurface.withOpacity(0.3),
                                ),
                              ),
                            ],
                          ),
                          AnimatedCrossFade(
                            firstChild: const SizedBox.shrink(),
                            secondChild: Padding(
                              padding: const EdgeInsets.only(top: 12, left: 40),
                              child: Text(
                                faq['answer']!,
                                style: TextStyle(
                                  color: colorScheme.onSurface.withOpacity(0.6),
                                  fontSize: 13,
                                  height: 1.6,
                                ),
                              ),
                            ),
                            crossFadeState: isExpanded
                                ? CrossFadeState.showSecond
                                : CrossFadeState.showFirst,
                            duration: const Duration(milliseconds: 200),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: 24),

            // Contact Support
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.support_agent,
                    color: colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ยังมีคำถามเพิ่มเติม?',
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'ติดต่อเราได้ที่ support@kidguard.app',
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontSize: 12,
                          ),
                        ),
                      ],
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
}
