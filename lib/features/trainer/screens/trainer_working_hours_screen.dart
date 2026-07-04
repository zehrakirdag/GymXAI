import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/services/working_hours_service.dart';
import 'edit_working_day_screen.dart';

class TrainerWorkingHoursScreen extends StatefulWidget {
  final int trainerUserId;

  const TrainerWorkingHoursScreen({
    super.key,
    required this.trainerUserId,
  });

  @override
  State<TrainerWorkingHoursScreen> createState() =>
      _TrainerWorkingHoursScreenState();
}

class _TrainerWorkingHoursScreenState extends State<TrainerWorkingHoursScreen> {
  final WorkingHoursService service = WorkingHoursService();

  List<Map<String, dynamic>> days = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetch();
  }

  Future<void> fetch() async {
    setState(() => isLoading = true);

    try {
      final data = await service.getWorkingHours(
        trainerUserId: widget.trainerUserId,
      );

      if (!mounted) return;

      setState(() {
        days = data;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  Widget buildDayCard(Map<String, dynamic> day) {
    final bool isAvailable = day["isAvailable"] ?? false;
    final lessons = day["specialLessons"] as List<dynamic>? ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EditWorkingDayScreen(
                  workingDay: day,
                  trainerUserId: widget.trainerUserId,
                ),
              ),
            );

            if (result == true) {
              await fetch();
            }
          },
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Icon(
                  isAvailable
                      ? Icons.check_circle_rounded
                      : Icons.pause_circle_rounded,
                  color: isAvailable ? AppColors.primary : AppColors.textSecondary,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        day["dayName"] ?? "-",
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isAvailable
                            ? "${day["startTime"] ?? "-"} - ${day["endTime"] ?? "-"}"
                            : "İzinli",
                        style: AppTextStyles.subtitle,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Özel ders: ${lessons.length}",
                        style: AppTextStyles.subtitle,
                      ),
                    ],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: const Text(
          "Çalışma Saatlerim",
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
            onRefresh: fetch,
            child: ListView(
              children: days.map(buildDayCard).toList(),
            ),
          ),
        ),
      ),
    );
  }
}