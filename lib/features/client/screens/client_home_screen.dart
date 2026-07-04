import 'package:flutter/material.dart';
import 'client_qr_scan_screen.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/services/client_service.dart';
import '../../../data/services/notification_service.dart';
import '../../../data/services/ai_service.dart';
import '../../../data/services/gym_density_service.dart';
import '../../../data/services/session_service.dart';

import '../../auth/screens/login_screen.dart';
import '../../notifications/screens/notifications_screen.dart';

import 'client_program_screen.dart';
import 'client_trainers_screen.dart';
import 'client_analytics_screen.dart';

class ClientHomeScreen extends StatefulWidget {
  final int clientUserId;
  final String clientName;

  const ClientHomeScreen({
    super.key,
    required this.clientUserId,
    required this.clientName,
  });

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  final ClientService clientService = ClientService();
  final NotificationService notificationService = NotificationService();
  final AIService aiService = AIService();
  final GymDensityService gymDensityService = GymDensityService();

  bool isLoading = true;
  Map<String, dynamic>? profile;
  Map<String, dynamic>? gymDensity;
  int unreadNotificationCount = 0;

  @override
  void initState() {
    super.initState();
    fetchProfile();
    fetchUnreadNotifications();
    fetchGymDensity();
  }

  Future<void> fetchProfile() async {
    try {
      final data = await clientService.getProfile(
        clientUserId: widget.clientUserId,
      );

      if (!mounted) return;

      setState(() {
        profile = data;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
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
        userId: widget.clientUserId,
      );

      if (!mounted) return;

      setState(() {
        unreadNotificationCount = data.where((item) {
          return item["isRead"] != true;
        }).length;
      });
    } catch (_) {}
  }

  Future<void> fetchGymDensity() async {
    try {
      final data = await gymDensityService.getStatus();

      if (!mounted) return;

      setState(() {
        gymDensity = data;
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

  Future<void> requestAIProgram() async {
    try {
      final clientId = profile?["id"];

      if (clientId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Danışan bilgisi bulunamadı")),
        );
        return;
      }

      await aiService.requestAIProgram(clientId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text(
            "AI program önerisi oluşturuldu ve antrenörüne gönderildi.",
          ),
        ),
      );

      fetchUnreadNotifications();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst("Exception: ", "")),
        ),
      );
    }
  }

  Widget buildQuickAccessButton({
    required String text,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      width: double.infinity,
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    text,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildInfoCard({
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget buildProgressBar(double value) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: LinearProgressIndicator(
        value: value,
        minHeight: 10,
        backgroundColor: AppColors.inputFill,
        valueColor: const AlwaysStoppedAnimation(AppColors.primary),
      ),
    );
  }

  Map<String, dynamic> calculateProgress(List<dynamic> programs, int? clientId) {
    if (programs.isEmpty || clientId == null) {
      return {"completed": 0, "total": 0, "percent": 0.0};
    }

    final program = programs.first;
    final days = program["days"] as List<dynamic>? ?? [];

    int totalSets = 0;
    int completedSets = 0;

    for (final day in days) {
      final exercises = day["exercises"] as List<dynamic>? ?? [];

      for (final exercise in exercises) {
        final int setCount =
            int.tryParse((exercise["sets"] ?? 0).toString()) ?? 0;

        final setCompletions =
            exercise["setCompletions"] as List<dynamic>? ?? [];

        for (int setNumber = 1; setNumber <= setCount; setNumber++) {
          totalSets++;

          final isCompleted = setCompletions.any(
                (completion) =>
            completion["clientId"] == clientId &&
                completion["setNumber"] == setNumber &&
                completion["isCompleted"] == true,
          );

          if (isCompleted) completedSets++;
        }
      }
    }

    final percent = totalSets == 0 ? 0.0 : completedSets / totalSets;

    return {
      "completed": completedSets,
      "total": totalSets,
      "percent": percent,
    };
  }

  void openClientProgramScreen({
    required BuildContext context,
    required List<dynamic> programs,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClientProgramScreen(
          clientId: profile?["id"],
          programs: programs,
        ),
      ),
    ).then((_) {
      fetchProfile();
    });
  }

  void openAnalyticsScreen() {
    final clientId = profile?["id"];

    if (clientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Danışan bilgisi bulunamadı")),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClientAnalyticsScreen(clientId: clientId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final measurements = profile?["measurements"] as List<dynamic>? ?? [];
    final programs = profile?["programs"] as List<dynamic>? ?? [];

    final clientId = profile?["id"];
    final progress = calculateProgress(programs, clientId);
    final completedSets = progress["completed"];
    final totalSets = progress["total"];
    final progressPercent = progress["percent"];

    final latestMeasurement =
    measurements.isNotEmpty ? measurements.first : null;

    final trainer = profile?["trainer"];
    final trainerUser = trainer?["user"];

    final densityPercent = gymDensity?["densityPercent"] ?? 0;
    final femalePercent = gymDensity?["femalePercent"] ?? 0;
    final malePercent = gymDensity?["malePercent"] ?? 0;
    final currentCount = gymDensity?["currentCount"] ?? 0;
    final capacity = gymDensity?["capacity"] ?? 100;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => NotificationsScreen(
                    userId: widget.clientUserId,
                  ),
                ),
              ).then((_) {
                fetchUnreadNotifications();
              });
            },
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(
                  Icons.notifications_rounded,
                  color: AppColors.textPrimary,
                ),
                if (unreadNotificationCount > 0)
                  Positioned(
                    right: -6,
                    top: -6,
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
                        unreadNotificationCount > 9
                            ? "9+"
                            : unreadNotificationCount.toString(),
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
          ),
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
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
          onRefresh: () async {
            await fetchProfile();
            await fetchUnreadNotifications();
            await fetchGymDensity();
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            children: [
              Text(
                "Hoş geldin ${widget.clientName}!",
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              buildInfoCard(
                title: "Salon Yoğunluğu",
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "%$densityPercent",
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    buildProgressBar((densityPercent / 100).toDouble()),
                    const SizedBox(height: 10),
                    Text(
                      "Kadın: %$femalePercent   •   Erkek: %$malePercent",
                      style: AppTextStyles.subtitle,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "İçeride: $currentCount / $capacity kişi",
                      style: AppTextStyles.subtitle,
                    ),
                  ],
                ),
              ),
              buildInfoCard(
                title: "Antrenörüm",
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.inputFill,
                      child: Icon(Icons.person, color: AppColors.primary),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            trainerUser?["fullName"] ?? "Henüz atanmadı",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            trainer?["specialty"] ?? "-",
                            style: AppTextStyles.subtitle,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              buildInfoCard(
                title: "Bugünkü İlerlemen",
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      totalSets == 0
                          ? "Henüz program yok"
                          : "%${(progressPercent * 100).round()} tamamlandı • $completedSets / $totalSets set",
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    buildProgressBar(progressPercent),
                  ],
                ),
              ),
              buildInfoCard(
                title: "Ölçümlerim",
                child: latestMeasurement == null
                    ? const Text(
                  "Henüz ölçüm bulunamadı.",
                  style: AppTextStyles.subtitle,
                )
                    : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Kilo"),
                        Text(
                          "${latestMeasurement["weight"] ?? "-"} kg",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Yağ Oranı"),
                        Text(
                          "${latestMeasurement["bodyFat"] ?? "-"}%",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Bel"),
                        Text(
                          "${latestMeasurement["waist"] ?? "-"} cm",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Hızlı Erişim",
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 16),
              buildQuickAccessButton(
                text: "Kişiye Özel Antrenman Programım",
                onTap: () {
                  openClientProgramScreen(
                    context: context,
                    programs: programs,
                  );
                },
              ),
              buildQuickAccessButton(
                text: "Antrenmanı Tamamla / İşaretle",
                onTap: () {
                  openClientProgramScreen(
                    context: context,
                    programs: programs,
                  );
                },
              ),
              buildQuickAccessButton(
                text: "Haftalık & Aylık Analizler",
                onTap: openAnalyticsScreen,
              ),
              buildQuickAccessButton(
                text: "🤖 AI Program Önerisi İste",
                onTap: requestAIProgram,
              ),
              buildQuickAccessButton(
                text: "Antrenörler ve Çalışma Saatleri",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ClientTrainersScreen(
                        clientId: profile?["id"],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 30),
              Center(
                child: InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ClientQrScanScreen(
                          clientUserId: widget.clientUserId,
                        ),
                      ),
                    );

                    if (result == true) {
                      await fetchGymDensity();
                    }
                  },
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Icon(
                      Icons.qr_code_scanner_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}