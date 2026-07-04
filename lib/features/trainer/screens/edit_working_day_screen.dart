import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/services/working_hours_service.dart';
import '../../../shared/widgets/custom_button.dart';
import 'add_special_lesson_screen.dart';

class EditWorkingDayScreen extends StatefulWidget {
  final Map<String, dynamic> workingDay;
  final int trainerUserId;

  const EditWorkingDayScreen({
    super.key,
    required this.workingDay,
    required this.trainerUserId,
  });

  @override
  State<EditWorkingDayScreen> createState() => _EditWorkingDayScreenState();
}

class _EditWorkingDayScreenState extends State<EditWorkingDayScreen> {
  final WorkingHoursService service = WorkingHoursService();

  late bool isAvailable;
  late TextEditingController startController;
  late TextEditingController endController;
  late TextEditingController noteController;

  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    isAvailable = widget.workingDay["isAvailable"] ?? false;
    startController = TextEditingController(
      text: widget.workingDay["startTime"] ?? "09:00",
    );
    endController = TextEditingController(
      text: widget.workingDay["endTime"] ?? "18:00",
    );
    noteController = TextEditingController(
      text: widget.workingDay["note"] ?? "",
    );
  }

  @override
  void dispose() {
    startController.dispose();
    endController.dispose();
    noteController.dispose();
    super.dispose();
  }

  Future<void> saveDay() async {
    setState(() => isLoading = true);

    try {
      await service.updateWorkingHour(
        id: widget.workingDay["id"],
        isAvailable: isAvailable,
        startTime: startController.text.trim(),
        endTime: endController.text.trim(),
        note: noteController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Çalışma günü güncellendi")),
      );

      Navigator.pop(context, true);
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

  Widget buildStatusOption(String text, bool value) {
    final selected = isAvailable == value;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => isAvailable = value);
        },
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: selected ? AppColors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildLessonCard(Map<String, dynamic> lesson) {
    final client = lesson["client"];
    final user = client?["user"];
    final clientName = user?["fullName"] ?? "Danışan seçilmedi";

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              "${lesson["startTime"]} - ${lesson["endTime"]} • $clientName",
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () async {
              await service.deleteSpecialLesson(lesson["id"]);
              if (!mounted) return;
              Navigator.pop(context, true);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lessons = widget.workingDay["specialLessons"] as List<dynamic>? ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: Text(
          widget.workingDay["dayName"] ?? "Gün Detayı",
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
            const Text("Çalışma Durumu", style: AppTextStyles.label),
            const SizedBox(height: 12),
            Row(
              children: [
                buildStatusOption("Salonda", true),
                const SizedBox(width: 12),
                buildStatusOption("İzinli", false),
              ],
            ),
            const SizedBox(height: 20),

            if (isAvailable) ...[
              const Text("Başlangıç Saati", style: AppTextStyles.label),
              const SizedBox(height: 8),
              TextField(
                controller: startController,
                decoration: _inputDecoration("09:00"),
              ),
              const SizedBox(height: 16),
              const Text("Bitiş Saati", style: AppTextStyles.label),
              const SizedBox(height: 8),
              TextField(
                controller: endController,
                decoration: _inputDecoration("18:00"),
              ),
              const SizedBox(height: 24),
            ],

            const Text("Özel Dersler", style: AppTextStyles.label),
            const SizedBox(height: 12),
            if (lessons.isEmpty)
              const Text("Bu güne özel ders eklenmedi.", style: AppTextStyles.subtitle)
            else
              ...lessons.map((lesson) => buildLessonCard(lesson)),

            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: isAvailable
                  ? () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddSpecialLessonScreen(
                      workingHourId: widget.workingDay["id"],
                      trainerUserId: widget.trainerUserId,
                    ),
                  ),
                );

                if (result == true) {
                  Navigator.pop(context, true);
                }
              }
                  : null,
              child: const Text("+ Özel Ders Ekle"),
            ),

            const SizedBox(height: 24),
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : CustomButton(
              text: "Kaydet",
              onPressed: saveDay,
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppColors.inputFill,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
    );
  }
}