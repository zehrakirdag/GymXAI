import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/services/program_service.dart';
import '../../../shared/widgets/custom_button.dart';
import 'create_program_screen.dart';

class ClientWeeklyProgramScreen extends StatefulWidget {
  final Map<String, dynamic> clientProfile;

  const ClientWeeklyProgramScreen({
    super.key,
    required this.clientProfile,
  });

  @override
  State<ClientWeeklyProgramScreen> createState() =>
      _ClientWeeklyProgramScreenState();
}

class _ClientWeeklyProgramScreenState extends State<ClientWeeklyProgramScreen> {
  final ProgramService programService = ProgramService();

  List<Map<String, dynamic>> programs = [];
  bool isLoading = true;
  int selectedDayIndex = 0;

  @override
  void initState() {
    super.initState();
    fetchPrograms();
  }

  Future<void> fetchPrograms() async {
    setState(() => isLoading = true);

    try {
      final data = await programService.getClientPrograms(
        clientProfileId: widget.clientProfile["id"],
      );

      if (!mounted) return;

      setState(() {
        programs = data;
        selectedDayIndex = 0;
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
      setState(() => isLoading = false);
    }
  }

  Future<void> openCreateScreen({Map<String, dynamic>? existingProgram}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateProgramScreen(
          clientProfile: widget.clientProfile,
          existingProgram: existingProgram,
        ),
      ),
    );

    if (result == true) {
      await fetchPrograms();
    }
  }

  Widget buildEmptyState(String clientName) {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.fitness_center,
              size: 42,
              color: AppColors.primary,
            ),
            const SizedBox(height: 16),
            const Text(
              "Henüz program yok",
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "$clientName için program oluşturulmamış.",
              style: AppTextStyles.subtitle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            CustomButton(
              text: "Program Oluştur",
              onPressed: () => openCreateScreen(),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildDaySelector(List<dynamic> days) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final day = days[index];
          final isSelected = selectedDayIndex == index;

          return ChoiceChip(
            label: Text(day["dayName"] ?? "-"),
            selected: isSelected,
            onSelected: (_) {
              setState(() {
                selectedDayIndex = index;
              });
            },
            selectedColor: AppColors.primary,
            backgroundColor: AppColors.white,
            labelStyle: TextStyle(
              color: isSelected ? AppColors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            side: const BorderSide(color: AppColors.border),
          );
        },
      ),
    );
  }

  Widget buildSelectedDayDetail(Map<String, dynamic> day) {
    final exercises = day["exercises"] as List<dynamic>? ?? [];

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
          Text(
            "${day["dayName"] ?? "-"} • ${day["focus"] ?? "Odak yok"}",
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "${exercises.length} egzersiz",
            style: AppTextStyles.subtitle,
          ),
          const SizedBox(height: 14),

          if (exercises.isEmpty)
            const Text(
              "Bu güne egzersiz eklenmemiş.",
              style: AppTextStyles.subtitle,
            )
          else
            ...exercises.asMap().entries.map((entry) {
              final index = entry.key;
              final ex = entry.value;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.inputFill,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 13,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        "${index + 1}",
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ex["name"] ?? "-",
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${ex["sets"] ?? "-"} set x ${ex["reps"] ?? "-"} tekrar",
                            style: AppTextStyles.subtitle,
                          ),
                          if (ex["description"] != null &&
                              ex["description"].toString().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                ex["description"],
                                style: AppTextStyles.subtitle,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget buildProgram(Map<String, dynamic> program) {
    final days = program["days"] as List<dynamic>? ?? [];

    if (days.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            program["title"] ?? "Haftalık Program",
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "Bu programa henüz gün eklenmemiş.",
            style: AppTextStyles.subtitle,
          ),
          const SizedBox(height: 20),
          CustomButton(
            text: "Programı Güncelle",
            onPressed: () => openCreateScreen(existingProgram: program),
          ),
        ],
      );
    }

    if (selectedDayIndex >= days.length) {
      selectedDayIndex = 0;
    }

    final selectedDay = days[selectedDayIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          program["title"] ?? "Haftalık Program",
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          program["description"] ?? "Açıklama yok",
          style: AppTextStyles.subtitle,
        ),
        const SizedBox(height: 18),

        buildDaySelector(days),

        const SizedBox(height: 18),

        buildSelectedDayDetail(selectedDay),

        const SizedBox(height: 20),

        CustomButton(
          text: "Programı Güncelle",
          onPressed: () => openCreateScreen(existingProgram: program),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.clientProfile["user"];
    final String clientName = user?["fullName"] ?? "-";

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: const Text(
          "Haftalık Program",
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : programs.isEmpty
              ? buildEmptyState(clientName)
              : RefreshIndicator(
            onRefresh: fetchPrograms,
            child: ListView(
              children: [
                Text(
                  "Danışan: $clientName",
                  style: AppTextStyles.subtitle,
                ),
                const SizedBox(height: 20),
                buildProgram(programs.first),
              ],
            ),
          ),
        ),
      ),
    );
  }
}