import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/services/trainer_service.dart';
import 'trainer_client_detail_screen.dart';

class MyClientsScreen extends StatefulWidget {
  final int trainerUserId;

  const MyClientsScreen({
    super.key,
    required this.trainerUserId,
  });

  @override
  State<MyClientsScreen> createState() => _MyClientsScreenState();
}

class _MyClientsScreenState extends State<MyClientsScreen> {
  final TrainerService trainerService = TrainerService();
  final TextEditingController searchController = TextEditingController();

  List<Map<String, dynamic>> clients = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchMyClients();
  }

  Future<void> fetchMyClients() async {
    setState(() {
      isLoading = true;
    });

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

  List<Map<String, dynamic>> get filteredClients {
    final query = searchController.text.trim().toLowerCase();

    if (query.isEmpty) return clients;

    return clients.where((clientProfile) {
      final user = clientProfile["user"];
      final fullName = (user?["fullName"] ?? "").toString().toLowerCase();
      final email = (user?["email"] ?? "").toString().toLowerCase();
      final phone = (user?["phone"] ?? "").toString().toLowerCase();

      return fullName.contains(query) ||
          email.contains(query) ||
          phone.contains(query);
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
        hintText: "Danışan ara...",
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

  Widget buildClientCard(Map<String, dynamic> clientProfile) {
    final user = clientProfile["user"];
    final measurements = clientProfile["measurements"] as List<dynamic>?;

    final latestMeasurement =
    measurements != null && measurements.isNotEmpty
        ? measurements.first
        : null;

    final weightText = latestMeasurement != null
        ? "${latestMeasurement["weight"]} kg"
        : "Ölçüm yok";

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TrainerClientDetailScreen(
                  clientProfile: clientProfile,
                ),
              ),
            );
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
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
                        user?["fullName"] ?? "-",
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Telefon: ${user?["phone"] ?? "-"}",
                        style: AppTextStyles.subtitle,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Son ölçüm: $weightText",
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
          ),
        ),
      ),
    );
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
          "Danışanlarım",
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
                    "Bu antrenöre atanmış danışan yok",
                    style: AppTextStyles.subtitle,
                  ),
                )
                    : RefreshIndicator(
                  onRefresh: fetchMyClients,
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