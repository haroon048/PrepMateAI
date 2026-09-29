import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_typography.dart';
import '../../services/firestore_service.dart';
import '../../services/pdf_service.dart';
import '../../utils/app_page_route.dart';
import '../../utils/date_formatter.dart';
import 'history_detail_screen.dart';

class HistoryListScreen extends StatelessWidget {
  const HistoryListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Interview History')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirestoreService().watchInterviews(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const _StatusView(
              icon: Icons.cloud_off_outlined,
              title: 'History is unavailable',
              message: 'Please check your connection and Firestore rules.',
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final sessions = snapshot.data!.docs;
          if (sessions.isEmpty) {
            return const _StatusView(
              icon: Icons.history_toggle_off,
              title: 'No completed interviews yet',
              message: 'Your AI feedback will appear here after a session.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: sessions.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final document = sessions[index];
              final data = document.data();
              final score = (data['overallScore'] as num? ?? 0).toInt();
              final timestamp = data['completedAt'] as Timestamp?;
              final role = data['role'] as String? ?? 'Mock Interview';
              final level = data['experienceLevel'] as String? ?? '';
              final scoreColor = score >= 75
                  ? AppColors.success
                  : score >= 50
                  ? AppColors.warning
                  : AppColors.error;

              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: scoreColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$score%',
                      style: TextStyle(
                        color: scoreColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  title: Text(role, style: AppTypography.titleLarge),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '$level • ${DateFormatter.short(timestamp?.toDate())}',
                      style: AppTypography.caption,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.file_download_outlined,
                          color: AppColors.primary,
                        ),
                        onPressed: () {
                          final feedback =
                              data['overallFeedback'] as String? ??
                              'No feedback recorded.';

                          PdfService.downloadPdf(
                            role: role,
                            experienceLevel: level,
                            score: score,
                            feedback: feedback,
                          );
                        },
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  onTap: () => Navigator.push(
                    context,
                    AppPageRoute(
                      builder: (_) =>
                          HistoryDetailScreen(session: data, title: role),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _StatusView extends StatelessWidget {
  const _StatusView({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: AppColors.textLight),
            const SizedBox(height: 16),
            Text(title, style: AppTypography.titleLarge),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTypography.subHeading,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
