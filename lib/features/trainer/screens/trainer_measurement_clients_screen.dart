import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/services/trainer_service.dart';
import 'add_measurement_screen.dart';

class TrainerMeasurementClientsScreen extends StatefulWidget {
  final int trainerUserId;

  const TrainerMeasurementClientsScreen({
    super.key,
    required this.trainerUserId,
  });

  @override
  State<TrainerMeasurementClientsScreen> createState() =>
      _TrainerMeasurementClientsScreenState();
}

class _TrainerMeasurementClientsScreenState
    extends State<TrainerMeasurementClientsScreen> {
  final TrainerService trainerService = TrainerService();
  final TextEditingController searchController = TextEditingController();

  List<Map<String, dynamic>> clients = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchClients();
  }

  Future<void> fetchClients() async {
    setState(() => isLoading = true);

    try {
      final data = await trainerService.getMyClients(
        trainerUserId: widget.trainerUserId,
      );

      if (!mounted) return;

      setState(() {
        clients = data;
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

  List<Map<String, dynamic>> get filteredClients {
    final query = searchController.text.trim().toLowerCase();

    if (query.isEmpty) return clients;

    return clients.where((clientProfile) {
      final user = clientProfile["user"];
      final name = (user?["fullName"] ?? "").toString().toLowerCase();
      final phone = (user?["phone"] ?? "").toString().toLowerCase();
      final goal = (clientProfile["goal"] ?? "").toString().toLowerCase();

      return name.contains(query) ||
          phone.contains(query) ||
          goal.contains(query);
    }).toList();
  }

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

  Widget buildSearchField() {
    return TextField(
      controller: searchController,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: "Danışan ara...",
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.inputFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
      ),
    );
  }

  Widget buildSmallInfoChip({
    required IconData icon,
    required String text,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 8, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildWarningBox({
    required String title,
    required String value,
    required IconData icon,
  }) {
    if (value.trim().isEmpty || value == "-") {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 19),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  height: 1.35,
                ),
                children: [
                  TextSpan(
                    text: "$title: ",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildClientCard(Map<String, dynamic> clientProfile) {
    final user = clientProfile["user"];
    final name = user?["fullName"] ?? "-";
    final phone = user?["phone"] ?? "-";

    final age = calculateAge(clientProfile["birthDate"]);
    final goal = clientProfile["goal"] ?? "-";
    final activityLevel = clientProfile["activityLevel"] ?? "-";
    final height = clientProfile["height"];
    final startWeight = clientProfile["startWeight"];
    final targetWeight = clientProfile["targetWeight"];
    final healthNotes = clientProfile["healthNotes"] ?? "";
    final injuryNotes = clientProfile["injuryNotes"] ?? "";

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
                builder: (_) => AddMeasurementScreen(
                  clientProfile: clientProfile,
                ),
              ),
            );

            if (result == true) {
              await fetchClients();
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
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.inputFill,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Icon(
                        Icons.monitor_weight_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text("Telefon: $phone", style: AppTextStyles.subtitle),
                          const SizedBox(height: 4),
                          const Text(
                            "Ölçüm ekle / görüntüle",
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

                const SizedBox(height: 14),

                Wrap(
                  children: [
                    buildSmallInfoChip(
                      icon: Icons.cake_rounded,
                      text: age == null ? "Yaş: -" : "Yaş: $age",
                    ),
                    buildSmallInfoChip(
                      icon: Icons.flag_rounded,
                      text: "Hedef: $goal",
                    ),
                    buildSmallInfoChip(
                      icon: Icons.fitness_center_rounded,
                      text: "Seviye: $activityLevel",
                    ),
                    buildSmallInfoChip(
                      icon: Icons.height_rounded,
                      text: height == null ? "Boy: -" : "Boy: $height cm",
                    ),
                    buildSmallInfoChip(
                      icon: Icons.monitor_weight_rounded,
                      text: startWeight == null
                          ? "Başlangıç: -"
                          : "Başlangıç: $startWeight kg",
                    ),
                    buildSmallInfoChip(
                      icon: Icons.track_changes_rounded,
                      text: targetWeight == null
                          ? "Hedef kilo: -"
                          : "Hedef kilo: $targetWeight kg",
                    ),
                  ],
                ),

                buildWarningBox(
                  title: "Sağlık",
                  value: healthNotes.toString(),
                  icon: Icons.health_and_safety_rounded,
                ),

                buildWarningBox(
                  title: "Sakatlık",
                  value: injuryNotes.toString(),
                  icon: Icons.warning_amber_rounded,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final list = filteredClients;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: const Text(
          "Ölçüm",
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            children: [
              buildSearchField(),
              const SizedBox(height: 16),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : list.isEmpty
                    ? const Center(
                  child: Text(
                    "Ölçüm eklenecek danışan bulunamadı",
                    style: AppTextStyles.subtitle,
                  ),
                )
                    : RefreshIndicator(
                  onRefresh: fetchClients,
                  child: ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      return buildClientCard(list[index]);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}