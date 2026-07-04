import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../client/screens/client_analytics_screen.dart';
import 'add_measurement_screen.dart';
import 'client_weekly_program_screen.dart';
import 'create_program_screen.dart';

class TrainerClientDetailScreen extends StatelessWidget {
  final Map<String, dynamic> clientProfile;

  const TrainerClientDetailScreen({
    super.key,
    required this.clientProfile,
  });

  int? calculateAge(dynamic birthDateValue) {
    if (birthDateValue == null) return null;

    final birthDate = DateTime.tryParse(birthDateValue.toString());
    if (birthDate == null) return null;

    final now = DateTime.now();
    int age = now.year - birthDate.year;

    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }

    return age;
  }

  @override
  Widget build(BuildContext context) {
    final user = clientProfile["user"];
    final measurements = clientProfile["measurements"] as List<dynamic>?;

    final latestMeasurement =
    measurements != null && measurements.isNotEmpty ? measurements.first : null;

    final String clientName = user?["fullName"] ?? "-";
    final String phone = user?["phone"] ?? "-";
    final String gender = clientProfile["gender"] ?? "-";

    final int? age = calculateAge(clientProfile["birthDate"]);
    final goal = clientProfile["goal"] ?? "-";
    final activityLevel = clientProfile["activityLevel"] ?? "-";
    final height = clientProfile["height"] ?? "-";
    final startWeight = clientProfile["startWeight"] ?? "-";
    final targetWeight = clientProfile["targetWeight"] ?? "-";
    final healthNotes = clientProfile["healthNotes"] ?? "Belirtilmemiş";
    final injuryNotes = clientProfile["injuryNotes"] ?? "Belirtilmemiş";

    final int clientId = clientProfile["id"];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: Text(
          clientName,
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
            Row(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.inputFill,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: AppColors.primary,
                    size: 34,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        clientName,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text("Telefon: $phone", style: AppTextStyles.subtitle),
                      const SizedBox(height: 4),
                      Text("Cinsiyet: $gender", style: AppTextStyles.subtitle),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            _infoCard(
              title: "Danışan Profili",
              children: [
                Text("Yaş: ${age ?? "-"}", style: AppTextStyles.subtitle),
                const SizedBox(height: 6),
                Text("Hedef: $goal", style: AppTextStyles.subtitle),
                const SizedBox(height: 6),
                Text("Aktivite Seviyesi: $activityLevel",
                    style: AppTextStyles.subtitle),
                const SizedBox(height: 6),
                Text("Boy: $height cm", style: AppTextStyles.subtitle),
                const SizedBox(height: 6),
                Text("Başlangıç Kilo: $startWeight kg",
                    style: AppTextStyles.subtitle),
                const SizedBox(height: 6),
                Text("Hedef Kilo: $targetWeight kg",
                    style: AppTextStyles.subtitle),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.inputFill,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    "Sağlık Bilgisi:\n$healthNotes",
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.inputFill,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    "Sakatlık Bilgisi:\n$injuryNotes",
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: _tabButton(
                    text: "Program",
                    icon: Icons.fitness_center_rounded,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ClientWeeklyProgramScreen(
                            clientProfile: clientProfile,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _tabButton(
                    text: "Analiz",
                    icon: Icons.analytics_rounded,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ClientAnalyticsScreen(
                            clientId: clientId,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _tabButton(
                    text: "Ölçüm",
                    icon: Icons.monitor_weight_rounded,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddMeasurementScreen(
                            clientProfile: clientProfile,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            _infoCard(
              title: "Son Ölçüm",
              children: [
                Text(
                  latestMeasurement != null
                      ? "Kilo: ${latestMeasurement["weight"]} kg"
                      : "Henüz ölçüm bulunmuyor.",
                  style: AppTextStyles.subtitle,
                ),
              ],
            ),

            const SizedBox(height: 24),

            CustomButton(
              text: "Haftalık Programı Gör",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ClientWeeklyProgramScreen(
                      clientProfile: clientProfile,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CreateProgramScreen(
                        clientProfile: clientProfile,
                      ),
                    ),
                  );

                  if (result == true && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Program oluşturuldu"),
                      ),
                    );
                  }
                },
                child: const Text(
                  "Program Oluştur",
                  style: AppTextStyles.link,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabButton({
    required String text,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          height: 58,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.primary, size: 21),
              const SizedBox(height: 4),
              Text(
                text,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoCard({
    required String title,
    required List<Widget> children,
  }) {
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
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}