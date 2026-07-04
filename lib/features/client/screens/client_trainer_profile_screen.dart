import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/services/client_service.dart';
import '../../../shared/widgets/custom_button.dart';

class ClientTrainerProfileScreen extends StatefulWidget {
  final int clientId;
  final int trainerId;

  const ClientTrainerProfileScreen({
    super.key,
    required this.clientId,
    required this.trainerId,
  });

  @override
  State<ClientTrainerProfileScreen> createState() =>
      _ClientTrainerProfileScreenState();
}

class _ClientTrainerProfileScreenState
    extends State<ClientTrainerProfileScreen> {
  final ClientService clientService = ClientService();

  Map<String, dynamic>? trainer;
  bool isLoading = true;
  bool isSaving = false;
  bool isLoadingSlots = false;

  DateTime selectedDate = DateTime.now();

  List<Map<String, dynamic>> availableSlots = [];
  Map<String, dynamic>? selectedSlot;

  @override
  void initState() {
    super.initState();
    fetchTrainer();
  }

  Future<void> fetchTrainer() async {
    try {
      final data = await clientService.getTrainerDetail(
        trainerId: widget.trainerId,
      );

      if (!mounted) return;

      setState(() {
        trainer = data;
      });

      await fetchAvailableSlots();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst("Exception: ", ""))),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchAvailableSlots() async {
    setState(() {
      isLoadingSlots = true;
      availableSlots = [];
      selectedSlot = null;
    });

    try {
      final data = await clientService.getAvailableSlots(
        trainerId: widget.trainerId,
        date: selectedDate.toIso8601String(),
      );

      if (!mounted) return;

      setState(() {
        availableSlots = data;
        selectedSlot = availableSlots.isNotEmpty ? availableSlots.first : null;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst("Exception: ", ""))),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        isLoadingSlots = false;
      });
    }
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (picked == null) return;

    setState(() {
      selectedDate = picked;
    });

    await fetchAvailableSlots();
  }

  Future<void> createAppointment() async {
    if (selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen uygun bir saat seçin")),
      );
      return;
    }

    setState(() => isSaving = true);

    try {
      await clientService.createAppointment(
        clientId: widget.clientId,
        trainerId: widget.trainerId,
        date: selectedDate.toIso8601String(),
        startTime: selectedSlot!["startTime"],
        endTime: selectedSlot!["endTime"],
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Randevu oluşturuldu")),
      );

      await fetchAvailableSlots();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst("Exception: ", ""))),
      );
    } finally {
      if (!mounted) return;

      setState(() => isSaving = false);
    }
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
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget buildWorkingHourItem(Map<String, dynamic> item) {
    final isAvailable = item["isAvailable"] == true;

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
              item["dayName"] ?? "-",
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            isAvailable
                ? "${item["startTime"] ?? "-"} - ${item["endTime"] ?? "-"}"
                : "İzinli",
            style: TextStyle(
              color: isAvailable ? AppColors.primary : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSlotSelector() {
    if (isLoadingSlots) {
      return const Center(child: CircularProgressIndicator());
    }

    if (availableSlots.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.inputFill,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: const Text(
          "Bu gün için uygun randevu saati bulunmuyor.",
          style: AppTextStyles.subtitle,
        ),
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: availableSlots.map((slot) {
        final selected =
            selectedSlot?["startTime"] == slot["startTime"] &&
                selectedSlot?["endTime"] == slot["endTime"];

        return ChoiceChip(
          label: Text("${slot["startTime"]} - ${slot["endTime"]}"),
          selected: selected,
          selectedColor: AppColors.primary,
          backgroundColor: AppColors.inputFill,
          side: const BorderSide(color: AppColors.border),
          labelStyle: TextStyle(
            color: selected ? AppColors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          onSelected: (_) {
            setState(() {
              selectedSlot = Map<String, dynamic>.from(slot);
            });
          },
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = trainer?["user"];
    final workingHours = trainer?["workingHours"] as List<dynamic>? ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: const Text(
          "Antrenör Profili",
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
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 38,
                    backgroundColor: Colors.white24,
                    child: Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 42,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    user?["fullName"] ?? "-",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    trainer?["specialty"] ?? "Fitness Antrenörü",
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            buildInfoCard(
              title: "Çalışma Saatleri",
              child: workingHours.isEmpty
                  ? const Text(
                "Çalışma saati bulunamadı.",
                style: AppTextStyles.subtitle,
              )
                  : Column(
                children: workingHours.map((item) {
                  return buildWorkingHourItem(
                    Map<String, dynamic>.from(item),
                  );
                }).toList(),
              ),
            ),

            buildInfoCard(
              title: "Randevu Al",
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Tarih", style: AppTextStyles.subtitle),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: pickDate,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.inputFill,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        "${selectedDate.day}.${selectedDate.month}.${selectedDate.year}",
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    "Uygun Saatler",
                    style: AppTextStyles.subtitle,
                  ),
                  const SizedBox(height: 10),

                  buildSlotSelector(),

                  const SizedBox(height: 22),

                  isSaving
                      ? const Center(child: CircularProgressIndicator())
                      : CustomButton(
                    text: "Randevu Oluştur",
                    onPressed: availableSlots.isEmpty
                        ? () {}
                        : createAppointment,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}