import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/services/notification_service.dart';
import '../../../data/services/local_notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  final int userId;

  const NotificationsScreen({
    super.key,
    required this.userId,
  });

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService notificationService = NotificationService();

  bool isLoading = true;
  List<Map<String, dynamic>> notifications = [];

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    try {
      final data = await notificationService.getNotifications(
        userId: widget.userId,
      );

      final unreadNotifications = data.where((item) {
        return item["isRead"] != true;
      }).toList();

      for (final item in unreadNotifications) {
        await LocalNotificationService.showNotification(
          id: item["id"] ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
          title: item["title"] ?? "Yeni Bildirim",
          body: item["message"] ?? "",
        );
      }

      if (!mounted) return;

      setState(() {
        notifications = data;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }
  Future<void> markAllAsRead() async {
    try {
      await notificationService.markAllAsRead(userId: widget.userId);
      await fetchNotifications();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  Future<void> markAsRead(int notificationId) async {
    try {
      await notificationService.markAsRead(notificationId: notificationId);
      await fetchNotifications();
    } catch (_) {}
  }

  Color getNotificationColor(String? type, String? title) {
    final lowerTitle = (title ?? "").toLowerCase();

    if (type == "MOTIVATION") return Colors.purple;

    if (lowerTitle.contains("onay")) return Colors.green;
    if (lowerTitle.contains("iptal")) return Colors.red;
    if (lowerTitle.contains("talep")) return Colors.orange;

    return AppColors.primary;
  }

  IconData getNotificationIcon(String? type, String? title) {
    final lowerTitle = (title ?? "").toLowerCase();

    if (type == "MOTIVATION") return Icons.local_fire_department_rounded;

    if (lowerTitle.contains("onay")) {
      return Icons.check_circle_rounded;
    }

    if (lowerTitle.contains("iptal")) {
      return Icons.cancel_rounded;
    }

    if (lowerTitle.contains("talep")) {
      return Icons.pending_actions_rounded;
    }

    return Icons.notifications_rounded;
  }

  String getTypeLabel(String? type, String? title) {
    final lowerTitle = (title ?? "").toLowerCase();

    if (type == "MOTIVATION") return "Motivasyon";
    if (lowerTitle.contains("onay")) return "Onaylandı";
    if (lowerTitle.contains("iptal")) return "İptal";
    if (lowerTitle.contains("talep")) return "Talep";

    return "Bildirim";
  }

  String formatDate(dynamic value) {
    if (value == null) return "-";

    try {
      final date = DateTime.parse(value.toString()).toLocal();

      return "${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}  ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      return value.toString();
    }
  }

  Widget buildNotificationCard(Map<String, dynamic> notification) {
    final isRead = notification["isRead"] == true;
    final type = notification["type"]?.toString();
    final title = notification["title"]?.toString();

    final color = getNotificationColor(type, title);
    final icon = getNotificationIcon(type, title);
    final label = getTypeLabel(type, title);

    return InkWell(
      onTap: () {
        if (!isRead) {
          markAsRead(notification["id"]);
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isRead ? AppColors.white : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isRead ? AppColors.border : color.withOpacity(0.45),
            width: isRead ? 1 : 1.4,
          ),
          boxShadow: [
            if (!isRead)
              BoxShadow(
                color: color.withOpacity(0.10),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withOpacity(0.14),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: color,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (!isRead)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            "Yeni",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    notification["title"] ?? "Bildirim",
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notification["message"] ?? "",
                    style: AppTextStyles.subtitle,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    formatDate(notification["createdAt"]),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
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

  @override
  Widget build(BuildContext context) {
    final unreadCount = notifications.where((item) {
      return item["isRead"] != true;
    }).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: const Text(
          "Bildirimler",
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: markAllAsRead,
              child: const Text("Tümünü oku"),
            ),
        ],
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
          onRefresh: fetchNotifications,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: unreadCount > 0
                      ? AppColors.primary.withOpacity(0.08)
                      : AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: unreadCount > 0
                        ? AppColors.primary.withOpacity(0.35)
                        : AppColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: unreadCount > 0
                          ? AppColors.primary
                          : AppColors.inputFill,
                      child: Icon(
                        unreadCount > 0
                            ? Icons.notifications_active_rounded
                            : Icons.notifications_none_rounded,
                        color: unreadCount > 0
                            ? Colors.white
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        unreadCount == 0
                            ? "Yeni bildirimin yok."
                            : "$unreadCount yeni bildirimin var.",
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              if (notifications.isEmpty)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Text(
                    "Henüz bildirim bulunmuyor.",
                    style: AppTextStyles.subtitle,
                  ),
                )
              else
                ...notifications.map(buildNotificationCard),
            ],
          ),
        ),
      ),
    );
  }
}