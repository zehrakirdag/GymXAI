import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/services/user_service.dart';
import '../../../shared/widgets/custom_button.dart';
import 'add_client_screen.dart';
import 'edit_client_screen.dart';
import 'assign_trainer_screen.dart';

class ClientManagementScreen extends StatefulWidget {
  const ClientManagementScreen({super.key});

  @override
  State<ClientManagementScreen> createState() => _ClientManagementScreenState();
}

class _ClientManagementScreenState extends State<ClientManagementScreen> {
  final TextEditingController searchController = TextEditingController();
  final UserService userService = UserService();

  List<Map<String, dynamic>> clients = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchClients();
  }

  Future<void> fetchClients() async {
    setState(() {
      isLoading = true;
    });

    try {
      final fetchedClients = await userService.getClients();

      if (!mounted) return;

      setState(() {
        clients = fetchedClients;
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

    return clients.where((client) {
      final fullName = (client["fullName"] ?? "").toString().toLowerCase();
      final email = (client["email"] ?? "").toString().toLowerCase();
      final phone = (client["phone"] ?? "").toString().toLowerCase();

      final clientProfile = client["clientProfile"];
      String trainerName = "";
      if (clientProfile != null &&
          clientProfile["trainer"] != null &&
          clientProfile["trainer"]["user"] != null) {
        trainerName =
            (clientProfile["trainer"]["user"]["fullName"] ?? "")
                .toString()
                .toLowerCase();
      }

      return fullName.contains(query) ||
          email.contains(query) ||
          phone.contains(query) ||
          trainerName.contains(query);
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
        hintText: "Danışan Ara...",
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

  Widget buildClientCard(Map<String, dynamic> client) {
    final clientProfile = client["clientProfile"];

    String trainerName = "Atanmadı";
    bool hasTrainer = false;

    if (clientProfile != null &&
        clientProfile["trainer"] != null &&
        clientProfile["trainer"]["user"] != null) {
      trainerName = clientProfile["trainer"]["user"]["fullName"] ?? "Atanmadı";
      hasTrainer = true;
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
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
            client["fullName"] ?? "",
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Antrenör: $trainerName",
            style: AppTextStyles.subtitle,
          ),
          const SizedBox(height: 6),
          Text(
            "E-mail: ${client["email"] ?? "-"}",
            style: AppTextStyles.subtitle,
          ),
          const SizedBox(height: 6),
          Text(
            "Telefon: ${client["phone"] ?? "-"}",
            style: AppTextStyles.subtitle,
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (!hasTrainer)
                TextButton(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AssignTrainerScreen(client: client),
                      ),
                    );

                    if (result == true) {
                      await fetchClients();
                    }
                  },
                  child: const Text(
                    "Antrenör Ata +",
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              TextButton(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditClientScreen(client: client),
                    ),
                  );

                  if (result == true) {
                    await fetchClients();
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
        ],
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
          "Danışan Yönetimi",
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
                text: "+ Danışan Ekle",
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AddClientScreen(),
                    ),
                  );
                  await fetchClients();
                },
              ),
              const SizedBox(height: 18),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : list.isEmpty
                    ? const Center(
                  child: Text(
                    "Danışan bulunamadı",
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