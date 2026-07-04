import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/services/trainer_service.dart';
import '../../../data/services/notification_service.dart';
import '../../../data/services/session_service.dart';

import '../../auth/screens/login_screen.dart';
import '../../notifications/screens/notifications_screen.dart';

import 'my_clients_screen.dart';
import 'trainer_program_clients_screen.dart';
import 'trainer_measurement_clients_screen.dart';
import 'trainer_working_hours_screen.dart';
import 'trainer_gym_density_screen.dart';
import 'ai_program_requests_screen.dart';

class TrainerHomeScreen extends StatefulWidget {
  final int trainerUserId;
  final String trainerName;

  const TrainerHomeScreen({
    super.key,
    required this.trainerUserId,
    required this.trainerName,
  });

  @override
  State<TrainerHomeScreen> createState() => _TrainerHomeScreenState();
}

class _TrainerHomeScreenState extends State<TrainerHomeScreen> {
  final TrainerService trainerService = TrainerService();
  final NotificationService notificationService = NotificationService();

  bool isLoading = true;
  bool isUpdatingStatus = false;

  int unreadNotificationCount = 0;

  List<Map<String, dynamic>> appointments = [];

  @override
  void initState() {
    super.initState();
    fetchAppointments();
    fetchUnreadNotifications();
  }

  Future<void> fetchAppointments() async {
    try {
      final data = await trainerService.getTodayAppointments(
        trainerUserId: widget.trainerUserId,
      );

      if (!mounted) return;

      setState(() {
        appointments = data;
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

  Future<void> fetchUnreadNotifications() async {
    try {
      final data = await notificationService.getNotifications(
        userId: widget.trainerUserId,
      );

      if (!mounted) return;

      setState(() {
        unreadNotificationCount = data.where((item) {
          return item["isRead"] != true;
        }).length;
      });
    } catch (_) {}
  }

  Future<void> logout() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Çıkış Yap"),
        content: const Text("Oturumu kapatmak istediğine emin misin?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Vazgeç"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Çıkış Yap"),
          ),
        ],
      ),
    );

    if (result != true) return;

    await SessionService.logout();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
          (route) => false,
    );
  }

  Future<void> openAIProgramRequests() async {
    try {
      final trainerProfileId = await trainerService.getTrainerProfileId(
        trainerUserId: widget.trainerUserId,
      );

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AIProgramRequestsScreen(
            trainerProfileId: trainerProfileId,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst("Exception: ", "")),
        ),
      );
    }
  }

  Future<void> updateAppointmentStatus({
    required int appointmentId,
    required String status,
    String? cancelReason,
  }) async {
    setState(() {
      isUpdatingStatus = true;
    });

    try {
      await trainerService.updateAppointmentStatus(
        appointmentId: appointmentId,
        status: status,
        cancelReason: cancelReason,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == "APPROVED"
                ? "Randevu onaylandı"
                : "Randevu iptal edildi",
          ),
        ),
      );

      await fetchAppointments();
      await fetchUnreadNotifications();
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
        isUpdatingStatus = false;
      });
    }
  }

  Future<void> showCancelReasonDialog({
    required int appointmentId,
  }) async {
    final reasonController = TextEditingController();

    final reason = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Randevu İptal Sebebi"),
          content: TextField(
            controller: reasonController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: "İptal sebebini yazın...",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Vazgeç"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, reasonController.text.trim());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text("İptal Et"),
            ),
          ],
        );
      },
    );

    if (reason == null) return;

    await updateAppointmentStatus(
      appointmentId: appointmentId,
      status: "CANCELLED",
      cancelReason: reason.isEmpty ? "Sebep belirtilmedi" : reason,
    );
  }

  String getStatusText(Map<String, dynamic> appointment) {
    final isPast = appointment["isPast"] == true;
    final status = appointment["status"];

    if (isPast && status == "PENDING") {
      return "Süresi geçti";
    }

    if (status == "PENDING") return "Bekliyor";
    if (status == "APPROVED") return "Onaylandı";
    if (status == "CANCELLED") return "İptal";

    return status?.toString() ?? "-";
  }

  Color getStatusColor(Map<String, dynamic> appointment) {
    final isPast = appointment["isPast"] == true;
    final status = appointment["status"];

    if (isPast && status == "PENDING") {
      return AppColors.textSecondary;
    }

    if (status == "APPROVED") return Colors.green;
    if (status == "CANCELLED") return Colors.red;
    return AppColors.primary;
  }

  bool canApproveOrCancel(Map<String, dynamic> appointment) {
    final isPast = appointment["isPast"] == true;
    final status = appointment["status"];

    return (status == "PENDING" || status == "APPROVED") && !isPast;
  }

  Widget buildMenuCard({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    int badgeCount = 0,
  }) {
    return Expanded(
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            height: 105,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      icon,
                      color: AppColors.primary,
                      size: 30,
                    ),
                    if (badgeCount > 0)
                      Positioned(
                        right: -8,
                        top: -8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Text(
                            badgeCount > 9 ? "9+" : badgeCount.toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                const Icon(
                  Icons.touch_app_rounded,
                  color: AppColors.textSecondary,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildTodayCard() {
    final count = appointments.where((appointment) {
      return appointment["status"] != "CANCELLED";
    }).length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Bugün",
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Özel Ders: $count / 3",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "Bugünkü gerçek randevularını buradan takip edebilirsin.",
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget buildLessonItem(Map<String, dynamic> appointment) {
    final client = appointment["client"];
    final user = client?["user"];

    final startTime = appointment["startTime"] ?? "-";
    final endTime = appointment["endTime"] ?? "-";
    final clientName = user?["fullName"] ?? "Danışan";
    final appointmentId = appointment["id"];

    final status = appointment["status"];
    final statusText = getStatusText(appointment);
    final statusColor = getStatusColor(appointment);
    final canAct = canApproveOrCancel(appointment);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                "$startTime - $endTime",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  clientName,
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (appointment["cancelReason"] != null &&
              appointment["cancelReason"].toString().isNotEmpty) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "İptal sebebi: ${appointment["cancelReason"]}",
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
          ],
          if (canAct) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isUpdatingStatus
                        ? null
                        : () {
                      showCancelReasonDialog(
                        appointmentId: appointmentId,
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      status == "APPROVED" ? "Dersi İptal Et" : "İptal Et",
                    ),
                  ),
                ),
                if (status == "PENDING") ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isUpdatingStatus
                          ? null
                          : () {
                        updateAppointmentStatus(
                          appointmentId: appointmentId,
                          status: "APPROVED",
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text("Onayla"),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget buildEmptyLessons() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: const Text(
        "Bugün için randevu bulunmuyor.",
        style: AppTextStyles.subtitle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          "Antrenör Paneli",
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: logout,
            icon: const Icon(
              Icons.logout_rounded,
              color: Colors.red,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await fetchAppointments();
            await fetchUnreadNotifications();
          },
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ListView(
              children: [
                Text(
                  "Hoş geldin, ${widget.trainerName} 👋",
                  style: AppTextStyles.subtitle,
                ),
                const SizedBox(height: 20),
                isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : buildTodayCard(),
                const SizedBox(height: 20),
                Row(
                  children: [
                    buildMenuCard(
                      title: "Danışanlarım",
                      icon: Icons.people_alt_rounded,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MyClientsScreen(
                              trainerUserId: widget.trainerUserId,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    buildMenuCard(
                      title: "Program",
                      icon: Icons.fitness_center_rounded,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TrainerProgramClientsScreen(
                              trainerUserId: widget.trainerUserId,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    buildMenuCard(
                      title: "Ölçüm",
                      icon: Icons.monitor_weight_rounded,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TrainerMeasurementClientsScreen(
                              trainerUserId: widget.trainerUserId,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    buildMenuCard(
                      title: "Bildirim",
                      icon: Icons.notifications_rounded,
                      badgeCount: unreadNotificationCount,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => NotificationsScreen(
                              userId: widget.trainerUserId,
                            ),
                          ),
                        ).then((_) {
                          fetchUnreadNotifications();
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    buildMenuCard(
                      title: "AI Talepleri",
                      icon: Icons.smart_toy_rounded,
                      onTap: openAIProgramRequests,
                    ),
                    const SizedBox(width: 12),
                    buildMenuCard(
                      title: "Çalışma Saatleri",
                      icon: Icons.schedule_rounded,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TrainerWorkingHoursScreen(
                              trainerUserId: widget.trainerUserId,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    buildMenuCard(
                      title: "Salon Yoğunluğu",
                      icon: Icons.groups_rounded,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TrainerGymDensityScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    const Expanded(child: SizedBox()),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  "Bugünün Ders Programı",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                if (isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (appointments.isEmpty)
                  buildEmptyLessons()
                else
                  ...appointments.map((appointment) {
                    return buildLessonItem(appointment);
                  }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}