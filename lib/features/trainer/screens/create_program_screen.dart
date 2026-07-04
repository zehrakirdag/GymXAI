import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/services/program_service.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';

class CreateProgramScreen extends StatefulWidget {
  final Map<String, dynamic> clientProfile;
  final Map<String, dynamic>? existingProgram;

  const CreateProgramScreen({
    super.key,
    required this.clientProfile,
    this.existingProgram,
  });

  @override
  State<CreateProgramScreen> createState() => _CreateProgramScreenState();
}

class _CreateProgramScreenState extends State<CreateProgramScreen> {
  final ProgramService programService = ProgramService();

  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController focusController = TextEditingController();
  final TextEditingController exerciseNameController = TextEditingController();
  final TextEditingController setsController = TextEditingController();
  final TextEditingController repsController = TextEditingController();

  final List<String> weekDays = [
    "Pazartesi",
    "Salı",
    "Çarşamba",
    "Perşembe",
    "Cuma",
    "Cumartesi",
    "Pazar",
  ];

  String selectedDay = "Pazartesi";
  bool isLoading = false;

  final Map<String, String> focusByDay = {};
  final Map<String, List<Map<String, dynamic>>> exercisesByDay = {};

  bool get isEditMode => widget.existingProgram != null;

  @override
  void initState() {
    super.initState();

    for (final day in weekDays) {
      focusByDay[day] = "";
      exercisesByDay[day] = [];
    }

    if (isEditMode) {
      titleController.text = widget.existingProgram?["title"] ?? "Haftalık Program";
      descriptionController.text = widget.existingProgram?["description"] ?? "";

      final existingDays = widget.existingProgram?["days"] as List<dynamic>? ?? [];

      if (existingDays.isNotEmpty) {
        selectedDay = existingDays.first["dayName"] ?? "Pazartesi";

        for (final day in existingDays) {
          final dayName = day["dayName"] ?? "Pazartesi";
          focusByDay[dayName] = day["focus"] ?? "";

          final exercises = day["exercises"] as List<dynamic>? ?? [];

          exercisesByDay[dayName] = exercises.map<Map<String, dynamic>>((ex) {
            return {
              "name": ex["name"] ?? "",
              "sets": ex["sets"] ?? 0,
              "reps": ex["reps"] ?? 0,
              "description": ex["description"],
              "duration": ex["duration"],
              "status": ex["status"] ?? "PLANNED",
            };
          }).toList();
        }
      }
    } else {
      titleController.text = "Haftalık Program";
    }

    focusController.text = focusByDay[selectedDay] ?? "";

    focusController.addListener(() {
      focusByDay[selectedDay] = focusController.text;
    });
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    focusController.dispose();
    exerciseNameController.dispose();
    setsController.dispose();
    repsController.dispose();
    super.dispose();
  }

  void changeSelectedDay(String day) {
    setState(() {
      focusByDay[selectedDay] = focusController.text;
      selectedDay = day;
      focusController.text = focusByDay[selectedDay] ?? "";
    });
  }

  void addExercise() {
    if (exerciseNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Egzersiz adı gir")),
      );
      return;
    }

    setState(() {
      exercisesByDay[selectedDay]!.add({
        "name": exerciseNameController.text.trim(),
        "sets": int.tryParse(setsController.text.trim()) ?? 0,
        "reps": int.tryParse(repsController.text.trim()) ?? 0,
        "status": "PLANNED",
      });

      exerciseNameController.clear();
      setsController.clear();
      repsController.clear();
    });
  }

  List<Map<String, dynamic>> buildDaysPayload() {
    focusByDay[selectedDay] = focusController.text;

    return weekDays
        .where((day) {
      final focus = focusByDay[day]?.trim() ?? "";
      final exercises = exercisesByDay[day] ?? [];
      return focus.isNotEmpty || exercises.isNotEmpty;
    })
        .map((day) {
      return {
        "dayName": day,
        "focus": focusByDay[day]?.trim(),
        "exercises": exercisesByDay[day] ?? [],
      };
    })
        .toList();
  }

  Future<void> saveProgram() async {
    final daysPayload = buildDaysPayload();

    if (titleController.text.trim().isEmpty || daysPayload.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Başlık ve en az 1 gün içeriği zorunlu"),
        ),
      );
      return;
    }

    final hasExercise = daysPayload.any((day) {
      final exercises = day["exercises"] as List<dynamic>? ?? [];
      return exercises.isNotEmpty;
    });

    if (!hasExercise) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("En az 1 egzersiz eklemelisin"),
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      if (isEditMode) {
        await programService.updateProgram(
          programId: widget.existingProgram!["id"],
          title: titleController.text.trim(),
          description: descriptionController.text.trim(),
          days: daysPayload,
        );
      } else {
        await programService.createProgram(
          clientProfileId: widget.clientProfile["id"],
          title: titleController.text.trim(),
          description: descriptionController.text.trim(),
          days: daysPayload,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditMode ? "Program güncellendi" : "Program oluşturuldu"),
        ),
      );

      Navigator.pop(context, true);
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

  Widget buildDaySelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: weekDays.map((day) {
        final isSelected = selectedDay == day;

        return ChoiceChip(
          label: Text(day),
          selected: isSelected,
          onSelected: (_) => changeSelectedDay(day),
          selectedColor: AppColors.primary,
          labelStyle: TextStyle(
            color: isSelected ? AppColors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        );
      }).toList(),
    );
  }

  Widget buildExerciseList() {
    final exercises = exercisesByDay[selectedDay] ?? [];

    if (exercises.isEmpty) {
      return const Text(
        "Bu güne henüz egzersiz eklenmedi.",
        style: AppTextStyles.subtitle,
      );
    }

    return Column(
      children: exercises.asMap().entries.map((entry) {
        final index = entry.key;
        final exercise = entry.value;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  "${exercise["name"]} • ${exercise["sets"]} set x ${exercise["reps"]} tekrar",
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    exercisesByDay[selectedDay]!.removeAt(index);
                  });
                },
                icon: const Icon(Icons.delete_outline, color: Colors.red),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.clientProfile["user"];
    final clientName = user?["fullName"] ?? "-";

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: Text(
          isEditMode ? "Program Güncelle" : "Program Oluştur",
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text("Danışan: $clientName", style: AppTextStyles.subtitle),
            const SizedBox(height: 20),

            CustomTextField(
              label: "Program Başlığı",
              hintText: "Örn: Haftalık Program",
              controller: titleController,
            ),
            const SizedBox(height: 18),

            CustomTextField(
              label: "Açıklama",
              hintText: "Program açıklaması",
              controller: descriptionController,
            ),
            const SizedBox(height: 18),

            const Text("Haftanın Günleri", style: AppTextStyles.label),
            const SizedBox(height: 10),
            buildDaySelector(),
            const SizedBox(height: 18),

            CustomTextField(
              label: "Gün Odak Alanı",
              hintText: "Örn: Bacak, Kardiyo, Üst Vücut",
              controller: focusController,
            ),
            const SizedBox(height: 24),

            const Text(
              "Egzersiz Ekle",
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),

            CustomTextField(
              label: "Egzersiz Adı",
              hintText: "Örn: Squat",
              controller: exerciseNameController,
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    label: "Set",
                    hintText: "4",
                    controller: setsController,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomTextField(
                    label: "Tekrar",
                    hintText: "10",
                    controller: repsController,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            OutlinedButton(
              onPressed: addExercise,
              child: Text("+ $selectedDay gününe egzersiz ekle"),
            ),

            const SizedBox(height: 20),
            buildExerciseList(),

            const SizedBox(height: 28),

            isLoading
                ? const Center(child: CircularProgressIndicator())
                : CustomButton(
              text: isEditMode ? "Programı Güncelle" : "Programı Kaydet",
              onPressed: saveProgram,
            ),
          ],
        ),
      ),
    );
  }
}