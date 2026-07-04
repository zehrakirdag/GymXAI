import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/services/user_service.dart';

class AssignTrainerScreen extends StatefulWidget {
  final Map<String, dynamic> client;

  const AssignTrainerScreen({
    super.key,
    required this.client,
  });

  @override
  State<AssignTrainerScreen> createState() => _AssignTrainerScreenState();
}

class _AssignTrainerScreenState extends State<AssignTrainerScreen> {
  final UserService userService = UserService();

  List<Map<String, dynamic>> trainers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchTrainers();
  }

  Future<void> fetchTrainers() async {
    try {
      final data = await userService.getTrainers();

      if (!mounted) return;

      setState(() {
        trainers = data;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    }
  }

  Future<void> assignTrainer(int trainerProfileId) async {
    try {
      await userService.assignTrainer(
        clientId: widget.client["id"],
        trainerId: trainerProfileId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Antrenör atandı"),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    }
  }

  Widget buildTrainerCard(Map<String, dynamic> trainer) {
    final profile = trainer["trainerProfile"];
    final int? trainerProfileId = profile != null ? profile["id"] as int? : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              Icons.person,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trainer["fullName"] ?? "",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  profile?["specialty"] ?? "-",
                  style: AppTextStyles.subtitle,
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: trainerProfileId == null
                ? null
                : () => assignTrainer(trainerProfileId),
            child: const Text("Seç"),
          ),
        ],
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
          "Antrenör Ata",
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Danışan: ${widget.client["fullName"]}",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: trainers.isEmpty
                  ? const Center(
                child: Text(
                  "Antrenör bulunamadı",
                  style: AppTextStyles.subtitle,
                ),
              )
                  : ListView.builder(
                itemCount: trainers.length,
                itemBuilder: (context, index) {
                  return buildTrainerCard(trainers[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}