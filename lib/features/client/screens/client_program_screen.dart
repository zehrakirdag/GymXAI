import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'client_day_program_screen.dart';

class ClientProgramScreen extends StatefulWidget {
  final int clientId;
  final List<dynamic> programs;

  const ClientProgramScreen({
    super.key,
    required this.clientId,
    required this.programs,
  });

  @override
  State<ClientProgramScreen> createState() => _ClientProgramScreenState();
}

class _ClientProgramScreenState extends State<ClientProgramScreen> {
  late List<Map<String, dynamic>> days;

  @override
  void initState() {
    super.initState();

    if (widget.programs.isNotEmpty) {
      final program = widget.programs.first;
      days = (program["days"] as List<dynamic>? ?? [])
          .map((day) => Map<String, dynamic>.from(day))
          .toList();
    } else {
      days = [];
    }
  }

  int getSetCount(Map<String, dynamic> exercise) {
    return int.tryParse((exercise["sets"] ?? 0).toString()) ?? 0;
  }

  bool isSetCompleted({
    required Map<String, dynamic> exercise,
    required int setNumber,
  }) {
    final completions = exercise["setCompletions"] as List<dynamic>? ?? [];

    return completions.any(
          (completion) =>
      completion["clientId"] == widget.clientId &&
          completion["setNumber"] == setNumber &&
          completion["isCompleted"] == true,
    );
  }

  int getTotalSetCount(Map<String, dynamic> day) {
    final exercises = day["exercises"] as List<dynamic>? ?? [];
    int total = 0;

    for (final exercise in exercises) {
      total += getSetCount(Map<String, dynamic>.from(exercise));
    }

    return total;
  }

  int getCompletedSetCount(Map<String, dynamic> day) {
    final exercises = day["exercises"] as List<dynamic>? ?? [];
    int completed = 0;

    for (final exerciseData in exercises) {
      final exercise = Map<String, dynamic>.from(exerciseData);
      final sets = getSetCount(exercise);

      for (int setNumber = 1; setNumber <= sets; setNumber++) {
        if (isSetCompleted(
          exercise: exercise,
          setNumber: setNumber,
        )) {
          completed++;
        }
      }
    }

    return completed;
  }

  double getDayProgress(Map<String, dynamic> day) {
    final totalSets = getTotalSetCount(day);
    if (totalSets == 0) return 0;

    return getCompletedSetCount(day) / totalSets;
  }

  Widget buildProgressBar(double value) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: LinearProgressIndicator(
        value: value,
        minHeight: 9,
        backgroundColor: AppColors.inputFill,
        valueColor: const AlwaysStoppedAnimation(AppColors.primary),
      ),
    );
  }

  Widget buildEmptyState() {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.border),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.fitness_center_rounded,
              color: AppColors.primary,
              size: 42,
            ),
            SizedBox(height: 16),
            Text(
              "Henüz program oluşturulmamış",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Antrenörün program oluşturduğunda burada görüntülenecek.",
              textAlign: TextAlign.center,
              style: AppTextStyles.subtitle,
            ),
          ],
        ),
      ),
    );
  }

  Widget buildWeeklyProgressCard() {
    int totalSets = 0;
    int completedSets = 0;

    for (final day in days) {
      totalSets += getTotalSetCount(day);
      completedSets += getCompletedSetCount(day);
    }

    final weeklyPercent = totalSets == 0 ? 0.0 : completedSets / totalSets;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Haftalık İlerleme",
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "%${(weeklyPercent * 100).round()} tamamlandı • "
                "$completedSets / $totalSets set",
            style: AppTextStyles.subtitle,
          ),
          const SizedBox(height: 12),
          buildProgressBar(weeklyPercent),
        ],
      ),
    );
  }

  Widget buildTodayCard(Map<String, dynamic> day) {
    final progress = getDayProgress(day);
    final completedSets = getCompletedSetCount(day);
    final totalSets = getTotalSetCount(day);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Bugünün Programı",
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "${day["dayName"] ?? "-"} • ${day["focus"] ?? "-"}",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "%${(progress * 100).round()} tamamlandı • "
                "$completedSets / $totalSets set",
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 9,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDayCard(Map<String, dynamic> day) {
    final progress = getDayProgress(day);
    final completedSets = getCompletedSetCount(day);
    final totalSets = getTotalSetCount(day);
    final isDone = totalSets > 0 && completedSets == totalSets;

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
                builder: (_) => ClientDayProgramScreen(
                  clientId: widget.clientId,
                  day: day,
                ),
              ),
            );

            if (result == true) {
              setState(() {});
            }
          },
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isDone
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: isDone
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "${day["dayName"] ?? "-"} • ${day["focus"] ?? "-"}",
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 17,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  "%${(progress * 100).round()} tamamlandı • "
                      "$completedSets / $totalSets set",
                  style: AppTextStyles.subtitle,
                ),
                const SizedBox(height: 10),
                buildProgressBar(progress),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.programs.isEmpty || days.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          iconTheme: const IconThemeData(color: AppColors.textPrimary),
          title: const Text(
            "Antrenman Programım",
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: buildEmptyState(),
        ),
      );
    }

    final program = widget.programs.first;
    final firstDay = days.first;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: const Text(
          "Antrenman Programım",
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              program["title"] ?? "Haftalık Program",
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              program["description"] ??
                  "Antrenörün tarafından oluşturulan program.",
              style: AppTextStyles.subtitle,
            ),
            const SizedBox(height: 20),
            buildWeeklyProgressCard(),
            const SizedBox(height: 16),
            buildTodayCard(firstDay),
            const SizedBox(height: 22),
            const Text(
              "Haftalık Program",
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 14),
            ...days.map((day) {
              return buildDayCard(day);
            }),
          ],
        ),
      ),
    );
  }
}