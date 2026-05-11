import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scam_detector/core/theme/app_colors.dart';
import 'package:scam_detector/core/widgets/index.dart';
import 'package:scam_detector/features/sms/presentation/providers/scam_detection_provider.dart';


class DetectionHistoryScreen extends StatefulWidget {
  const DetectionHistoryScreen({super.key});

  @override
  State<DetectionHistoryScreen> createState() => _DetectionHistoryScreenState();
}

class _DetectionHistoryScreenState extends State<DetectionHistoryScreen> {
  String _selectedFilter = 'All';

  final List<String> _filters = [
    'All',
    'SMS',
    'WhatsApp',
    'Messenger',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text(
          'Detection History',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Consumer<ScamDetectionProvider>(
        builder: (context, provider, _) {
          final allMessages = provider.messages;
          
          final filteredMessages = allMessages.where((message) {
            if (_selectedFilter == 'All') return true;
            
            final type = message.appName.toLowerCase();
            final filterType = _selectedFilter.toLowerCase();
            
            if (filterType == 'sms') {
               return type == 'sms' || type == 'messages';
            }
            return type == filterType;
          }).toList();

          return Column(
            children: [
              _buildFilterRow(),
              Expanded(
                child: filteredMessages.isEmpty
                    ? const Center(
                        child: EmptyStateWidget(
                          title: 'No detections found',
                          subtitle: 'There are no messages matching the selected filter.',
                          icon: Icons.history_rounded,
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        itemCount: filteredMessages.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final detection = filteredMessages[index];
                          return DetectionCard(
                            message: detection,
                            onDismiss: () =>
                                provider.removeDetection(detection.id),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterRow() {
    return Container(
      height: 56,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = filter == _selectedFilter;
          
          return FilterChip(
            label: Text(
              filter,
              style: TextStyle(
                color: isSelected ? AppColors.surfaceDark : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            selected: isSelected,
            onSelected: (selected) {
              if (selected) {
                setState(() => _selectedFilter = filter);
              }
            },
            backgroundColor: AppColors.surfaceDark,
            selectedColor: AppColors.primaryNeonGreen,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isSelected ? AppColors.primaryNeonGreen : AppColors.border,
              ),
            ),
            showCheckmark: false,
          );
        },
      ),
    );
  }
}
