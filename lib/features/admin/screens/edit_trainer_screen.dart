import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/services/user_service.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';

class EditTrainerScreen extends StatefulWidget {
  final Map<String, dynamic> trainer;

  const EditTrainerScreen({
    super.key,
    required this.trainer,
  });

  @override
  State<EditTrainerScreen> createState() => _EditTrainerScreenState();
}

class _EditTrainerScreenState extends State<EditTrainerScreen> {
  late final TextEditingController fullNameController;
  late final TextEditingController specialtyController;
  late final TextEditingController phoneController;
  late final TextEditingController emailController;
  late final TextEditingController bioController;

  final UserService userService = UserService();

  bool isAvailable = true;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    final trainerProfile = widget.trainer["trainerProfile"];

    fullNameController = TextEditingController(
      text: widget.trainer["fullName"] ?? "",
    );
    specialtyController = TextEditingController(
      text: trainerProfile != null ? (trainerProfile["specialty"] ?? "") : "",
    );
    phoneController = TextEditingController(
      text: widget.trainer["phone"] ?? "",
    );
    emailController = TextEditingController(
      text: widget.trainer["email"] ?? "",
    );
    bioController = TextEditingController(
      text: trainerProfile != null ? (trainerProfile["bio"] ?? "") : "",
    );

    isAvailable = trainerProfile != null
        ? (trainerProfile["isAvailable"] ?? true)
        : true;
  }

  @override
  void dispose() {
    fullNameController.dispose();
    specialtyController.dispose();
    phoneController.dispose();
    emailController.dispose();
    bioController.dispose();
    super.dispose();
  }

  Future<void> handleUpdate() async {
    if (fullNameController.text.trim().isEmpty ||
        specialtyController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
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
      await userService.updateTrainer(
        id: widget.trainer["id"],
        fullName: fullNameController.text.trim(),
        email: emailController.text.trim(),
        phone: phoneController.text.trim(),
        specialty: specialtyController.text.trim(),
        bio: bioController.text.trim(),
        isAvailable: isAvailable,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Antrenör başarıyla güncellendi")),
      );

      Navigator.pop(context, true);
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

  Future<void> handleDelete() async {
    setState(() {
      isLoading = true;
    });

    try {
      await userService.deleteTrainer(widget.trainer["id"]);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Antrenör silindi")),
      );

      Navigator.pop(context, true);
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
              content: Text("Fotoğraf güncelleme bir sonraki adımda eklenecek"),
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

  Widget buildDeleteButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.red),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: isLoading ? null : handleDelete,
        child: const Text(
          "Antrenörü Sil",
          style: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.w600,
            fontSize: 16,
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
          "Antrenör Düzenle",
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
                "Antrenör bilgilerini güncelle",
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
                  : Column(
                children: [
                  CustomButton(
                    text: "Kaydet",
                    onPressed: handleUpdate,
                  ),
                  const SizedBox(height: 12),
                  buildDeleteButton(),
                  const SizedBox(height: 12),
                  buildOutlinedCancelButton(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}