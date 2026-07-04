import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/services/trainer_service.dart';
import '../../../data/services/working_hours_service.dart';
import '../../../shared/widgets/custom_button.dart';

class AddSpecialLessonScreen extends StatefulWidget {
  final int workingHourId;
  final int trainerUserId;

  const AddSpecialLessonScreen({
    super.key,
    required this.workingHourId,
    required this.trainerUserId,
  });

  @override
  State<AddSpecialLessonScreen> createState() => _AddSpecialLessonScreenState();
}

class _AddSpecialLessonScreenState extends State<AddSpecialLessonScreen> {
  final WorkingHoursService workingHoursService = WorkingHoursService();
  final TrainerService trainerService = TrainerService();

  List<Map<String, dynamic>> clients = [];
  int? selectedClientId;

  final TextEditingController startController =
  TextEditingController(text: "10:00");
  final TextEditingController endController =
  TextEditingController(text: "11:00");

  bool isLoading = true;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    fetchClients();
  }

  Future<void> fetchClients() async {
    try {
      final data = await trainerService.getMyClients(
        trainerUserId: widget.trainerUserId,
      );

      if (!mounted) return;

      setState(() {
        clients = data;
        if (clients.isNotEmpty) {
          selectedClientId = clients.first["id"];
        }
      });
    } finally {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  Future<void> saveLesson() async {
    setState(() => isSaving = true);

    try {
      await workingHoursService.addSpecialLesson(
        workingHourId: widget.workingHourId,
        clientId: selectedClientId,
        startTime: startController.text.trim(),
        endTime: endController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Özel ders eklendi")),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (!mounted) return;
      setState(() => isSaving = false);
    }
  }

  InputDecoration inputDecoration(String hint) {
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

  @override
  void dispose() {
    startController.dispose();
    endController.dispose();
    super.dispose();
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
          "Özel Ders Ekle",
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text("Danışan", style: AppTextStyles.label),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: selectedClientId,
              decoration: inputDecoration("Danışan seç"),
              items: clients.map((clientProfile) {
                final user = clientProfile["user"];
                return DropdownMenuItem<int>(
                  value: clientProfile["id"],
                  child: Text(user?["fullName"] ?? "-"),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => selectedClientId = value);
              },
            ),
            const SizedBox(height: 18),
            const Text("Başlangıç Saati", style: AppTextStyles.label),
            const SizedBox(height: 8),
            TextField(
              controller: startController,
              decoration: inputDecoration("10:00"),
            ),
            const SizedBox(height: 18),
            const Text("Bitiş Saati", style: AppTextStyles.label),
            const SizedBox(height: 8),
            TextField(
              controller: endController,
              decoration: inputDecoration("11:00"),
            ),
            const SizedBox(height: 28),
            isSaving
                ? const Center(child: CircularProgressIndicator())
                : CustomButton(
              text: "Dersi Kaydet",
              onPressed: saveLesson,
            ),
          ],
        ),
      ),
    );
  }
}