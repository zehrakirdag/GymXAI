import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/session_service.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';

import '../../admin/screens/admin_home_screen.dart';
import '../../trainer/screens/trainer_home_screen.dart';
import '../../client/screens/client_home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final AuthService authService = AuthService();

  bool isLoading = false;

  Future<void> handleLogin() async {
    if (emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen e-posta ve şifre girin')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await authService.login(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      await SessionService.saveSession(
        token: response.token,
        user: {
          "id": response.user.id,
          "fullName": response.user.fullName,
          "email": response.user.email,
          "role": response.user.role,
        },
      );

      if (!mounted) return;

      if (response.user.role == "ADMIN") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminHomeScreen()),
        );
      } else if (response.user.role == "TRAINER") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => TrainerHomeScreen(
              trainerUserId: response.user.id,
              trainerName: response.user.fullName,
            ),
          ),
        );
      } else if (response.user.role == "CLIENT") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ClientHomeScreen(
              clientUserId: response.user.id,
              clientName: response.user.fullName,
            ),
          ),
        );
      } else {
        await SessionService.logout();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bilinmeyen kullanıcı rolü')),
        );
      }
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

  void showRegisterInfo() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Hesap oluşturma işlemi yönetici tarafından yapılmaktadır.'),
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 50),

              Center(
                child: Image.asset(
                  "assets/images/gymxai_logo.png",
                  width: 120,
                  height: 120,
                ),
              ),

              const SizedBox(height: 24),

              const Text('GymXAI', style: AppTextStyles.title),

              const SizedBox(height: 8),

              const Text(
                'Yapay zekâ destekli spor salonu yönetim sistemine giriş yap',
                style: AppTextStyles.subtitle,
              ),

              const SizedBox(height: 40),

              CustomTextField(
                label: 'E-posta',
                hintText: 'E-posta adresinizi girin',
                controller: emailController,
              ),

              const SizedBox(height: 20),

              CustomTextField(
                label: 'Şifre',
                hintText: 'Şifrenizi girin',
                controller: passwordController,
                obscureText: true,
              ),

              const SizedBox(height: 14),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: const Text(
                    'Şifremi unuttum',
                    style: AppTextStyles.link,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : CustomButton(
                text: 'Giriş Yap',
                onPressed: handleLogin,
              ),

              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Hesabın yok mu?',
                    style: AppTextStyles.subtitle,
                  ),
                  TextButton(
                    onPressed: showRegisterInfo,
                    child: const Text(
                      'Kayıt Ol',
                      style: AppTextStyles.link,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}