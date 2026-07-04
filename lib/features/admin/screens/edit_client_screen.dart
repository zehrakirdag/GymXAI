import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/services/user_service.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';

class EditClientScreen extends StatefulWidget {
  final Map<String, dynamic> client;

  const EditClientScreen({
    super.key,
    required this.client,
  });

  @override
  State<EditClientScreen> createState() => _EditClientScreenState();
}

class _EditClientScreenState extends State<EditClientScreen> {
  late final TextEditingController fullNameController;
  late final TextEditingController emailController;
  late final TextEditingController phoneController;

  late final TextEditingController birthDateController;
  late final TextEditingController heightController;
  late final TextEditingController startWeightController;
  late final TextEditingController targetWeightController;
  late final TextEditingController goalController;
  late final TextEditingController activityLevelController;
  late final TextEditingController healthNotesController;
  late final TextEditingController injuryNotesController;

  final UserService userService = UserService();

  String selectedGender = "Kadın";
  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    final clientProfile = widget.client["clientProfile"];

    fullNameController = TextEditingController(
      text: widget.client["fullName"] ?? "",
    );

    emailController = TextEditingController(
      text: widget.client["email"] ?? "",
    );

    phoneController = TextEditingController(
      text: widget.client["phone"] ?? "",
    );

    if (clientProfile != null && clientProfile["gender"] != null) {
      selectedGender = clientProfile["gender"];
    }

    birthDateController = TextEditingController(
      text: formatDateForInput(clientProfile?["birthDate"]),
    );

    heightController = TextEditingController(
      text: clientProfile?["height"]?.toString() ?? "",
    );

    startWeightController = TextEditingController(
      text: clientProfile?["startWeight"]?.toString() ?? "",
    );

    targetWeightController = TextEditingController(
      text: clientProfile?["targetWeight"]?.toString() ?? "",
    );

    goalController = TextEditingController(
      text: clientProfile?["goal"] ?? "",
    );

    activityLevelController = TextEditingController(
      text: clientProfile?["activityLevel"] ?? "",
    );

    healthNotesController = TextEditingController(
      text: clientProfile?["healthNotes"] ?? "",
    );

    injuryNotesController = TextEditingController(
      text: clientProfile?["injuryNotes"] ?? "",
    );
  }

  String formatDateForInput(dynamic value) {
    if (value == null) return "";

    final date = DateTime.tryParse(value.toString());
    if (date == null) return "";

    final month = date.month.toString().padLeft(2, "0");
    final day = date.day.toString().padLeft(2, "0");

    return "${date.year}-$month-$day";
  }

  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    phoneController.dispose();

    birthDateController.dispose();
    heightController.dispose();
    startWeightController.dispose();
    targetWeightController.dispose();
    goalController.dispose();
    activityLevelController.dispose();
    healthNotesController.dispose();
    injuryNotesController.dispose();

    super.dispose();
  }

  Future<void> handleUpdate() async {
    if (fullNameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Lütfen zorunlu alanları doldurun"),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await userService.updateClient(
        id: widget.client["id"],
        fullName: fullNameController.text.trim(),
        email: emailController.text.trim(),
        phone: phoneController.text.trim(),
        gender: selectedGender,
        birthDate: birthDateController.text.trim().isEmpty
            ? null
            : birthDateController.text.trim(),
        height: double.tryParse(heightController.text.trim()),
        startWeight: double.tryParse(startWeightController.text.trim()),
        targetWeight: double.tryParse(targetWeightController.text.trim()),
        goal: goalController.text.trim().isEmpty
            ? null
            : goalController.text.trim(),
        activityLevel: activityLevelController.text.trim().isEmpty
            ? null
            : activityLevelController.text.trim(),
        healthNotes: healthNotesController.text.trim().isEmpty
            ? null
            : healthNotesController.text.trim(),
        injuryNotes: injuryNotesController.text.trim().isEmpty
            ? null
            : injuryNotesController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Danışan başarıyla güncellendi"),
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
    } finally {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  Widget buildGenderOption(String text) {
    final bool isSelected = selectedGender == text;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedGender = text;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? AppColors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }

  Widget buildOutlinedCancelButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: () {
          Navigator.pop(context);
        },
        child: const Text(
          "İptal",
          style: AppTextStyles.link,
        ),
      ),
    );
  }

  Widget buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.bold,
        fontSize: 16,
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
          "Danışan Düzenle",
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Danışan bilgilerini güncelle",
                style: AppTextStyles.subtitle,
              ),
              const SizedBox(height: 24),

              buildSectionTitle("Temel Bilgiler"),
              const SizedBox(height: 16),

              CustomTextField(
                label: "Ad Soyad *",
                hintText: "Danışanın ad soyadını girin",
                controller: fullNameController,
              ),
              const SizedBox(height: 18),

              CustomTextField(
                label: "E-mail *",
                hintText: "Danışanın e-posta adresini girin",
                controller: emailController,
              ),
              const SizedBox(height: 18),

              CustomTextField(
                label: "Telefon *",
                hintText: "Danışanın telefon numarasını girin",
                controller: phoneController,
              ),

              const SizedBox(height: 22),

              const Text(
                "Cinsiyet",
                style: AppTextStyles.label,
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  buildGenderOption("Kadın"),
                  const SizedBox(width: 12),
                  buildGenderOption("Erkek"),
                ],
              ),

              const SizedBox(height: 30),

              buildSectionTitle("Vücut ve Hedef Bilgileri"),
              const SizedBox(height: 16),

              CustomTextField(
                label: "Doğum Tarihi",
                hintText: "2003-11-13",
                controller: birthDateController,
              ),
              const SizedBox(height: 18),

              CustomTextField(
                label: "Boy (cm)",
                hintText: "165",
                controller: heightController,
              ),
              const SizedBox(height: 18),

              CustomTextField(
                label: "Başlangıç Kilo",
                hintText: "92",
                controller: startWeightController,
              ),
              const SizedBox(height: 18),

              CustomTextField(
                label: "Hedef Kilo",
                hintText: "75",
                controller: targetWeightController,
              ),
              const SizedBox(height: 18),

              CustomTextField(
                label: "Hedef",
                hintText: "Kilo Verme / Kas Kazanımı / Kondisyon",
                controller: goalController,
              ),
              const SizedBox(height: 18),

              CustomTextField(
                label: "Aktivite Seviyesi",
                hintText: "Başlangıç / Orta / İleri",
                controller: activityLevelController,
              ),

              const SizedBox(height: 30),

              buildSectionTitle("Sağlık Bilgileri"),
              const SizedBox(height: 16),

              CustomTextField(
                label: "Sağlık Bilgisi",
                hintText: "Hipotiroid, tansiyon vb. yoksa boş bırakın",
                controller: healthNotesController,
              ),
              const SizedBox(height: 18),

              CustomTextField(
                label: "Sakatlık Bilgisi",
                hintText: "Diz, omuz, bel vb. yoksa boş bırakın",
                controller: injuryNotesController,
              ),

              const SizedBox(height: 32),

              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : CustomButton(
                text: "Güncelle",
                onPressed: handleUpdate,
              ),
              const SizedBox(height: 12),
              buildOutlinedCancelButton(),
            ],
          ),
        ),
      ),
    );
  }
}