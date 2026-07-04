import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/services/user_service.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';

class AddTrainerScreen extends StatefulWidget {
  const AddTrainerScreen({super.key});

  @override
  State<AddTrainerScreen> createState() => _AddTrainerScreenState();
}

class _AddTrainerScreenState extends State<AddTrainerScreen> {
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController specialtyController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController bioController = TextEditingController();

  final UserService userService = UserService();

  bool isAvailable = true;
  bool isLoading = false;

  @override
  void dispose() {
    fullNameController.dispose();
    specialtyController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    bioController.dispose();
    super.dispose();
  }

  Future<void> handleSave() async {
    if (fullNameController.text.trim().isEmpty ||
        specialtyController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty ||
        bioController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen tüm alanları doldurun")),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await userService.createTrainer(
        fullName: fullNameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        phone: phoneController.text.trim(),
        specialty: specialtyController.text.trim(),
        bio: bioController.text.trim(),
        isAvailable: isAvailable,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Antrenör başarıyla eklendi")),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget buildStatusOption({
    required String text,
    required bool value,
  }) {
    final bool isSelected = isAvailable == value;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            isAvailable = value;
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.add_a_photo_outlined,
              color: AppColors.primary,
              size: 28,
            ),
            SizedBox(height: 8),
            Text("Yükle", style: AppTextStyles.link),
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
        child: const Text("İptal", style: AppTextStyles.link),
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
          "Antrenör Ekle",
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
                "Yeni antrenör bilgilerini doldur",
                style: AppTextStyles.subtitle,
              ),
              const SizedBox(height: 24),
              const Text("Fotoğraf", style: AppTextStyles.label),
              const SizedBox(height: 10),
              buildPhotoUploadBox(),
              const SizedBox(height: 24),
              CustomTextField(
                label: "Ad Soyad",
                hintText: "Ad Soyad giriniz...",
                controller: fullNameController,
              ),
              const SizedBox(height: 18),
              CustomTextField(
                label: "Uzmanlık Alanı",
                hintText: "Örn: Pilates, Kondisyon...",
                controller: specialtyController,
              ),
              const SizedBox(height: 18),
              CustomTextField(
                label: "Telefon",
                hintText: "Telefon numarası giriniz...",
                controller: phoneController,
              ),
              const SizedBox(height: 18),
              CustomTextField(
                label: "E-mail",
                hintText: "E-mail adresi giriniz...",
                controller: emailController,
              ),
              const SizedBox(height: 18),
              CustomTextField(
                label: "Geçici Şifre",
                hintText: "Geçici şifre giriniz...",
                controller: passwordController,
                obscureText: true,
              ),
              const SizedBox(height: 22),
              const Text("Çalışma Durumu", style: AppTextStyles.label),
              const SizedBox(height: 12),
              Row(
                children: [
                  buildStatusOption(text: "Salonda", value: true),
                  const SizedBox(width: 12),
                  buildStatusOption(text: "İzinli", value: false),
                ],
              ),
              const SizedBox(height: 22),
              CustomTextField(
                label: "Hakkımda",
                hintText:
                "Kısa biyografi ekleyin. Deneyim, sertifika, uzmanlık alanı gibi bilgiler buraya yazılır.",
                controller: bioController,
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