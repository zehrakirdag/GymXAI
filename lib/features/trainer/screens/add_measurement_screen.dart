import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/services/measurement_service.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';

class AddMeasurementScreen extends StatefulWidget {
  final Map<String, dynamic> clientProfile;

  const AddMeasurementScreen({
    super.key,
    required this.clientProfile,
  });

  @override
  State<AddMeasurementScreen> createState() => _AddMeasurementScreenState();
}

class _AddMeasurementScreenState extends State<AddMeasurementScreen> {
  final MeasurementService measurementService = MeasurementService();

  final TextEditingController weightController = TextEditingController();
  final TextEditingController bodyFatController = TextEditingController();
  final TextEditingController heightController = TextEditingController();
  final TextEditingController bmiController = TextEditingController();
  final TextEditingController waistController = TextEditingController();
  final TextEditingController hipController = TextEditingController();
  final TextEditingController shoulderController = TextEditingController();
  final TextEditingController armController = TextEditingController();
  final TextEditingController legController = TextEditingController();
  final TextEditingController calfController = TextEditingController();
  final TextEditingController noteController = TextEditingController();

  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    weightController.addListener(() => setState(() {}));
    bodyFatController.addListener(() => setState(() {}));
    waistController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    weightController.dispose();
    bodyFatController.dispose();
    heightController.dispose();
    bmiController.dispose();
    waistController.dispose();
    hipController.dispose();
    shoulderController.dispose();
    armController.dispose();
    legController.dispose();
    calfController.dispose();
    noteController.dispose();
    super.dispose();
  }

  double? parseDouble(String value) {
    final normalized = value.trim().replaceAll(",", ".");
    if (normalized.isEmpty) return null;
    return double.tryParse(normalized);
  }

  void calculateBmi() {
    final weight = parseDouble(weightController.text);
    final heightCm = parseDouble(heightController.text);

    if (weight == null || heightCm == null || heightCm <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("BMI için kilo ve boy girilmeli")),
      );
      return;
    }

    final heightM = heightCm / 100;
    final bmi = weight / (heightM * heightM);

    bmiController.text = bmi.toStringAsFixed(1);
  }

  Widget buildEvaluationCard() {
    final weight = parseDouble(weightController.text);
    final bodyFat = parseDouble(bodyFatController.text);
    final waist = parseDouble(waistController.text);

    String text = "Veri girildikçe değerlendirme burada görünecek.";

    if (weight != null || bodyFat != null || waist != null) {
      text =
      "Kilo: ${weight?.toStringAsFixed(1) ?? "-"} kg • "
          "Yağ: ${bodyFat?.toStringAsFixed(1) ?? "-"}% • "
          "Bel: ${waist?.toStringAsFixed(1) ?? "-"} cm";
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Değerlendirme",
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(text, style: AppTextStyles.subtitle),
        ],
      ),
    );
  }

  Future<void> saveMeasurement() async {
    final weight = parseDouble(weightController.text);

    if (weight == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Kilo alanı zorunlu")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      await measurementService.createMeasurement(
        clientId: widget.clientProfile["id"],
        weight: weight,
        bodyFat: parseDouble(bodyFatController.text),
        height: parseDouble(heightController.text),
        bmi: parseDouble(bmiController.text),
        waist: parseDouble(waistController.text),
        hip: parseDouble(hipController.text),
        shoulder: parseDouble(shoulderController.text),
        arm: parseDouble(armController.text),
        leg: parseDouble(legController.text),
        calf: parseDouble(calfController.text),
        note: noteController.text.trim().isEmpty
            ? null
            : noteController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ölçüm başarıyla kaydedildi")),
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
      setState(() => isLoading = false);
    }
  }

  Widget sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget twoFields({
    required Widget left,
    required Widget right,
  }) {
    return Row(
      children: [
        Expanded(child: left),
        const SizedBox(width: 12),
        Expanded(child: right),
      ],
    );
  }

  Widget buildAnalysisButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Ölçüm analizleri ekranı bir sonraki aşamada eklenecek",
              ),
            ),
          );
        },
        child: const Text(
          "Ölçüm Analizlerine Git →",
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.clientProfile["user"];
    final clientName = user?["fullName"] ?? "-";

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: const Text(
          "Ölçüm Ekle",
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text("Danışan: $clientName", style: AppTextStyles.subtitle),
            const SizedBox(height: 22),

            sectionTitle("Temel Bilgiler"),
            twoFields(
              left: CustomTextField(
                label: "Kilo (kg)",
                hintText: "Örn: 62.5",
                controller: weightController,
              ),
              right: CustomTextField(
                label: "Yağ Oranı (%)",
                hintText: "Örn: 24",
                controller: bodyFatController,
              ),
            ),
            const SizedBox(height: 14),
            twoFields(
              left: CustomTextField(
                label: "Boy (cm)",
                hintText: "Örn: 168",
                controller: heightController,
              ),
              right: CustomTextField(
                label: "BMI",
                hintText: "Otomatik / manuel",
                controller: bmiController,
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: calculateBmi,
              child: const Text("BMI Hesapla"),
            ),

            const SizedBox(height: 26),

            sectionTitle("Vücut Ölçüleri"),
            twoFields(
              left: CustomTextField(
                label: "Bel (cm)",
                hintText: "Örn: 72",
                controller: waistController,
              ),
              right: CustomTextField(
                label: "Kalça (cm)",
                hintText: "Örn: 96",
                controller: hipController,
              ),
            ),
            const SizedBox(height: 14),
            twoFields(
              left: CustomTextField(
                label: "Omuz (cm)",
                hintText: "Örn: 102",
                controller: shoulderController,
              ),
              right: CustomTextField(
                label: "Kol (cm)",
                hintText: "Örn: 28",
                controller: armController,
              ),
            ),
            const SizedBox(height: 14),
            twoFields(
              left: CustomTextField(
                label: "Bacak (cm)",
                hintText: "Örn: 54",
                controller: legController,
              ),
              right: CustomTextField(
                label: "Baldır (cm)",
                hintText: "Örn: 34",
                controller: calfController,
              ),
            ),

            const SizedBox(height: 26),

            sectionTitle("Not"),
            CustomTextField(
              label: "Antrenör Notu",
              hintText: "Örn: Bel ölçüsü azalmış, kardiyo devam.",
              controller: noteController,
            ),

            const SizedBox(height: 20),
            buildEvaluationCard(),
            const SizedBox(height: 12),
            buildAnalysisButton(),

            const SizedBox(height: 24),

            isLoading
                ? const Center(child: CircularProgressIndicator())
                : CustomButton(
              text: "Ölçümü Kaydet",
              onPressed: saveMeasurement,
            ),
          ],
        ),
      ),
    );
  }
}