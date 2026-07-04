import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/services/gym_density_service.dart';

class TrainerGymDensityScreen extends StatefulWidget {
  const TrainerGymDensityScreen({super.key});

  @override
  State<TrainerGymDensityScreen> createState() =>
      _TrainerGymDensityScreenState();
}

class _TrainerGymDensityScreenState extends State<TrainerGymDensityScreen> {
  final GymDensityService gymDensityService = GymDensityService();

  bool isLoading = true;
  Map<String, dynamic>? density;

  @override
  void initState() {
    super.initState();
    fetchDensity();
  }

  Future<void> fetchDensity() async {
    try {
      final data = await gymDensityService.getStatus();

      if (!mounted) return;

      setState(() {
        density = data;
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
            e.toString().replaceFirst("Exception: ", ""),
          ),
        ),
      );
    }
  }

  Widget buildProgressBar(double value) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: LinearProgressIndicator(
        value: value,
        minHeight: 12,
        backgroundColor: AppColors.inputFill,
        valueColor: const AlwaysStoppedAnimation(AppColors.primary),
      ),
    );
  }

  Widget buildInfoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppTextStyles.subtitle),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final capacity = density?["capacity"] ?? 100;
    final currentCount = density?["currentCount"] ?? 0;
    final densityPercent = density?["densityPercent"] ?? 0;
    final femaleCount = density?["femaleCount"] ?? 0;
    final maleCount = density?["maleCount"] ?? 0;
    final femalePercent = density?["femalePercent"] ?? 0;
    final malePercent = density?["malePercent"] ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Salon Yoğunluğu"),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
          onRefresh: fetchDensity,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Anlık Salon Yoğunluğu",
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "%$densityPercent",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 38,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        value: (densityPercent / 100).toDouble(),
                        minHeight: 12,
                        backgroundColor: Colors.white24,
                        valueColor:
                        const AlwaysStoppedAnimation(Colors.white),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      "İçeride: $currentCount / $capacity kişi",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
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
                      "Cinsiyet Dağılımı",
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 18),
                    buildInfoRow(
                      "Kadın",
                      "$femaleCount kişi • %$femalePercent",
                    ),
                    buildProgressBar((femalePercent / 100).toDouble()),
                    const SizedBox(height: 18),
                    buildInfoRow(
                      "Erkek",
                      "$maleCount kişi • %$malePercent",
                    ),
                    buildProgressBar((malePercent / 100).toDouble()),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Text(
                  "Bu ekran QR giriş/çıkış kayıtlarına göre gerçek zamanlı salon yoğunluğunu gösterir.",
                  style: AppTextStyles.subtitle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}