import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/services/user_service.dart';
import '../../../shared/widgets/custom_button.dart';
import 'add_trainer_screen.dart';
import 'edit_trainer_screen.dart';

class TrainerManagementScreen extends StatefulWidget {
  const TrainerManagementScreen({super.key});

  @override
  State<TrainerManagementScreen> createState() => _TrainerManagementScreenState();
}

class _TrainerManagementScreenState extends State<TrainerManagementScreen> {
  final TextEditingController searchController = TextEditingController();
  final UserService userService = UserService();

  List<Map<String, dynamic>> trainers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchTrainers();
  }

  Future<void> fetchTrainers() async {
    setState(() {
      isLoading = true;
    });

    try {
      final fetchedTrainers = await userService.getTrainers();

      if (!mounted) return;

      setState(() {
        trainers = fetchedTrainers;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    } finally {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get filteredTrainers {
    final query = searchController.text.trim().toLowerCase();

    if (query.isEmpty) return trainers;

    return trainers.where((trainer) {
      final name = (trainer["fullName"] ?? "").toString().toLowerCase();
      final email = (trainer["email"] ?? "").toString().toLowerCase();
      final phone = (trainer["phone"] ?? "").toString().toLowerCase();
      final trainerProfile = trainer["trainerProfile"];
      final specialty = trainerProfile != null
          ? (trainerProfile["specialty"] ?? "").toString().toLowerCase()
          : "";

      return name.contains(query) ||
          email.contains(query) ||
          phone.contains(query) ||
          specialty.contains(query);
    }).toList();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Widget buildSearchField() {
    return TextField(
      controller: searchController,
      onChanged: (_) {
        setState(() {});
      },
      decoration: InputDecoration(
        hintText: "Antrenör Ara...",
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        prefixIcon: const Icon(
          Icons.search,
          color: AppColors.textSecondary,
        ),
        filled: true,
        fillColor: AppColors.inputFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
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

  Widget buildStatusChip(bool isAvailable) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isAvailable ? AppColors.primary : AppColors.inputFill,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isAvailable ? AppColors.primary : AppColors.border,
        ),
      ),
      child: Text(
        isAvailable ? "Salonda" : "İzinli",
        style: TextStyle(
          color: isAvailable ? AppColors.white : AppColors.textPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget buildTrainerCard(Map<String, dynamic> trainer) {
    final trainerProfile = trainer["trainerProfile"];
    final specialty = trainerProfile != null
        ? (trainerProfile["specialty"] ?? "-")
        : "-";
    final isAvailable = trainerProfile != null
        ? (trainerProfile["isAvailable"] ?? true)
        : true;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Uzmanlık: $specialty",
                  style: AppTextStyles.subtitle,
                ),
                const SizedBox(height: 10),
                buildStatusChip(isAvailable),
              ],
            ),
          ),
          TextButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditTrainerScreen(trainer: trainer),
                ),
              );

              if (result == true) {
                await fetchTrainers();
              }
            },
            child: const Text(
              "Düzenle →",
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = filteredTrainers;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: const Text(
          "Antrenör Yönetimi",
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
              CustomButton(
                text: "+ Antrenör Ekle",
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AddTrainerScreen(),
                    ),
                  );
                  await fetchTrainers();
                },
              ),
              const SizedBox(height: 18),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : list.isEmpty
                    ? const Center(
                  child: Text(
                    "Antrenör bulunamadı",
                    style: AppTextStyles.subtitle,
                  ),
                )
                    : RefreshIndicator(
                  onRefresh: fetchTrainers,
                  child: ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      return buildTrainerCard(list[index]);
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