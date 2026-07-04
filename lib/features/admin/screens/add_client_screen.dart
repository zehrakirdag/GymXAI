import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/services/user_service.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';

class AddClientScreen extends StatefulWidget {
  const AddClientScreen({super.key});

  @override
  State<AddClientScreen> createState() => _AddClientScreenState();
}

class _AddClientScreenState extends State<AddClientScreen> {
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final TextEditingController birthDateController = TextEditingController();
  final TextEditingController heightController = TextEditingController();
  final TextEditingController startWeightController = TextEditingController();
  final TextEditingController targetWeightController = TextEditingController();
  final TextEditingController goalController = TextEditingController();
  final TextEditingController activityLevelController =
  TextEditingController();
  final TextEditingController healthNotesController = TextEditingController();
  final TextEditingController injuryNotesController = TextEditingController();

  final UserService userService = UserService();

  String selectedGender = "Kadın";
  bool isLoading = false;

  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();

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

  Future<void> handleSave() async {
    if (fullNameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
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
      await userService.createClient(
        fullName: fullNameController.text.trim(),
        email: emailController.text.trim(),
        phone: phoneController.text.trim(),
        password: passwordController.text.trim(),
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
          content: Text("Danışan başarıyla eklendi"),
        ),
      );

      Navigator.pop(context);
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

  Widget buildPhotoUploadBox() {
    return Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Fotoğraf yükleme bir sonraki adımda eklenecek"),
            ),
          );
        },
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_a_photo_outlined,
              color: AppColors.primary,
              size: 28,
            ),
            SizedBox(height: 8),
            Text(
              "Yükle",
              style: AppTextStyles.link,
            ),
          ],
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
          "Danışan Ekle",
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
                "Yeni danışan bilgilerini doldur",
                style: AppTextStyles.subtitle,
              ),
              const SizedBox(height: 24),

              buildSectionTitle("Temel Bilgiler"),
              const SizedBox(height: 16),

              const Text(
                "Foto",
                style: AppTextStyles.label,
              ),
              const SizedBox(height: 10),
              buildPhotoUploadBox(),
              const SizedBox(height: 24),

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
              const SizedBox(height: 18),

              CustomTextField(
                label: "Geçici Şifre *",
                hintText: "Danışan için geçici şifre girin",
                controller: passwordController,
                obscureText: true,
              ),

              const SizedBox(height: 24),

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
                text: "Kaydet",
                onPressed: handleSave,
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