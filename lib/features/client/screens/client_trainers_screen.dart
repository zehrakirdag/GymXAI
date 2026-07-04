import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/services/client_service.dart';
import 'client_trainer_profile_screen.dart';

class ClientTrainersScreen extends StatefulWidget {
  final int clientId;

  const ClientTrainersScreen({
    super.key,
    required this.clientId,
  });

  @override
  State<ClientTrainersScreen> createState() => _ClientTrainersScreenState();
}

class _ClientTrainersScreenState extends State<ClientTrainersScreen> {
  final ClientService clientService = ClientService();

  bool isLoading = true;
  List<Map<String, dynamic>> trainers = [];

  @override
  void initState() {
    super.initState();
    fetchTrainers();
  }

  Future<void> fetchTrainers() async {
    try {
      final data = await clientService.getTrainers();

      if (!mounted) return;

      setState(() {
        trainers = data;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst("Exception: ", ""),
          ),
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  Color getStatusColor(String status) {
    if (status == "Uygun") return Colors.green;
    if (status == "Ders Veriyor") return Colors.orange;
    if (status == "Dolu") return Colors.red;
    if (status == "Bugün Aktif") return AppColors.primary;
    return AppColors.textSecondary;
  }

  IconData getStatusIcon(String status) {
    if (status == "Uygun") return Icons.check_circle_rounded;
    if (status == "Ders Veriyor") return Icons.fitness_center_rounded;
    if (status == "Dolu") return Icons.event_busy_rounded;
    if (status == "Bugün Aktif") return Icons.schedule_rounded;
    return Icons.do_not_disturb_on_rounded;
  }

  Widget buildStatusBadge(String status) {
    final color = getStatusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            getStatusIcon(status),
            size: 15,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildLessonCapacity({
    required int count,
    required int max,
  }) {
    return Row(
      children: List.generate(max, (index) {
        final isFilled = index < count;

        return Expanded(
          child: Container(
            height: 8,
            margin: EdgeInsets.only(right: index == max - 1 ? 0 : 6),
            decoration: BoxDecoration(
              color: isFilled ? AppColors.primary : AppColors.inputFill,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        );
      }),
    );
  }

  Widget buildInfoItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: AppColors.primary,
              size: 20,
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTrainerCard(Map<String, dynamic> trainer) {
    final user = trainer["user"];

    final String name = user?["fullName"] ?? "-";
    final String specialty = trainer["specialty"] ?? "Fitness Antrenörü";

    final String status = trainer["statusLabel"] ?? "Çalışmıyor";
    final bool availableNow = trainer["availableNow"] == true;

    final String? workingStart = trainer["workingStart"];
    final String? workingEnd = trainer["workingEnd"];

    final int todayAppointmentsCount =
        int.tryParse((trainer["todayAppointmentsCount"] ?? 0).toString()) ?? 0;

    final int maxDailyAppointments =
        int.tryParse((trainer["maxDailyAppointments"] ?? 3).toString()) ?? 3;

    final int remainingAppointments =
        int.tryParse((trainer["remainingAppointments"] ?? 0).toString()) ?? 0;

    final String workingText = workingStart != null && workingEnd != null
        ? "$workingStart - $workingEnd"
        : "Bugün çalışmıyor";

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ClientTrainerProfileScreen(
                  clientId: widget.clientId,
                  trainerId: trainer["id"],
                ),
              ),
            ).then((_) => fetchTrainers());
          },
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.035),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 62,
                          height: 62,
                          decoration: BoxDecoration(
                            color: AppColors.inputFill,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.person_rounded,
                            color: AppColors.primary,
                            size: 36,
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: availableNow
                                  ? Colors.green
                                  : AppColors.textSecondary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.white,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            specialty,
                            style: AppTextStyles.subtitle,
                          ),
                        ],
                      ),
                    ),
                    buildStatusBadge(status),
                  ],
                ),

                const SizedBox(height: 18),

                Row(
                  children: [
                    buildInfoItem(
                      icon: Icons.access_time_rounded,
                      title: "Çalışma",
                      value: workingText,
                    ),
                    const SizedBox(width: 10),
                    buildInfoItem(
                      icon: Icons.event_available_rounded,
                      title: "Kalan",
                      value: "$remainingAppointments ders",
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Özel Ders Doluluğu",
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      "$todayAppointmentsCount / $maxDailyAppointments",
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                buildLessonCapacity(
                  count: todayAppointmentsCount,
                  max: maxDailyAppointments,
                ),

                const SizedBox(height: 14),

                Row(
                  children: [
                    Icon(
                      status == "Dolu"
                          ? Icons.warning_amber_rounded
                          : Icons.info_outline_rounded,
                      color: getStatusColor(status),
                      size: 18,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        status == "Dolu"
                            ? "Bugünkü özel ders kontenjanı doldu."
                            : status == "Çalışmıyor"
                            ? "Bugün çalışma saati bulunmuyor."
                            : status == "Ders Veriyor"
                            ? "Antrenör şu anda özel derste."
                            : "Randevu detaylarını görmek için karta dokun.",
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.fitness_center_rounded,
            color: Colors.white,
            size: 30,
          ),
          SizedBox(height: 14),
          Text(
            "Antrenörler ve Çalışma Saatleri",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 21,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Bugünkü çalışma durumlarını, özel ders doluluklarını ve uygunluklarını buradan takip edebilirsin.",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13.5,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildEmptyState() {
    return const Center(
      child: Text(
        "Antrenör bulunamadı",
        style: TextStyle(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
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
        iconTheme: const IconThemeData(
          color: AppColors.textPrimary,
        ),
        title: const Text(
          "Antrenörler",
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(
          child: CircularProgressIndicator(),
        )
            : trainers.isEmpty
            ? buildEmptyState()
            : RefreshIndicator(
          onRefresh: fetchTrainers,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            children: [
              buildHeader(),
              ...trainers.map(buildTrainerCard),
            ],
          ),
        ),
      ),
    );
  }
}