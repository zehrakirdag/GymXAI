import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/services/ai_service.dart';

class AIProgramRequestsScreen extends StatefulWidget {
  final int trainerProfileId;

  const AIProgramRequestsScreen({
    super.key,
    required this.trainerProfileId,
  });

  @override
  State<AIProgramRequestsScreen> createState() =>
      _AIProgramRequestsScreenState();
}

class _AIProgramRequestsScreenState extends State<AIProgramRequestsScreen> {
  final AIService _aiService = AIService();

  bool isLoading = true;
  List<dynamic> requests = [];

  @override
  void initState() {
    super.initState();
    fetchRequests();
  }

  Future<void> fetchRequests() async {
    try {
      final data = await _aiService.getTrainerAIRequests(
        widget.trainerProfileId,
      );

      if (!mounted) return;

      setState(() {
        requests = data;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst("Exception: ", ""),
          ),
        ),
      );
    }
  }

  Future<void> updateStatus(int requestId, String status) async {
    try {
      await _aiService.updateAIRequestStatus(
        requestId: requestId,
        status: status,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: status == "APPROVED" ? Colors.green : Colors.red,
          content: Text(
            status == "APPROVED"
                ? "AI programı onaylandı"
                : "AI programı reddedildi",
          ),
        ),
      );

      await fetchRequests();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst("Exception: ", ""),
          ),
        ),
      );
    }
  }

  Color getStatusColor(String? status) {
    switch (status) {
      case "APPROVED":
        return Colors.green;
      case "REJECTED":
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String getStatusText(String? status) {
    switch (status) {
      case "APPROVED":
        return "Onaylandı";
      case "REJECTED":
        return "Reddedildi";
      default:
        return "Bekliyor";
    }
  }

  String getSafeText(dynamic value) {
    if (value == null) return "-";
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("AI Program Talepleri"),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : requests.isEmpty
          ? const Center(
        child: Text("Henüz AI program talebi bulunmuyor."),
      )
          : RefreshIndicator(
        onRefresh: fetchRequests,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final item = requests[index] as Map<String, dynamic>;

            final client = item["client"];
            final user = client?["user"];

            final suggestedProgram = item["suggestedProgram"];
            final weeklyPlan =
                suggestedProgram?["weeklyPlan"] as List<dynamic>? ??
                    [];

            final status = item["status"]?.toString();

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Color(0xFFEDE9FE),
                        child: Text("🤖"),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          user?["fullName"] ?? "Danışan",
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: getStatusColor(status)
                              .withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          getStatusText(status),
                          style: TextStyle(
                            color: getStatusColor(status),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    "Program Tipi: ${getSafeText(item["programType"])}",
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (item["bmi"] != null)
                    Text("BMI: ${item["bmi"]}"),
                  if (item["goal"] != null)
                    Text("Hedef: ${item["goal"]}"),
                  if (item["activityLevel"] != null)
                    Text(
                      "Aktivite Seviyesi: ${item["activityLevel"]}",
                    ),
                  const SizedBox(height: 10),
                  const Text(
                    "AI Açıklaması:",
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(getSafeText(item["aiReason"])),
                  const SizedBox(height: 14),
                  const Text(
                    "Önerilen Haftalık Program",
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (weeklyPlan.isEmpty)
                    const Text("Program detayı bulunamadı.")
                  else
                    ...weeklyPlan.map<Widget>((day) {
                      final dayMap = day as Map<String, dynamic>;
                      final exercises =
                          dayMap["exercises"] as List<dynamic>? ?? [];

                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${getSafeText(dayMap["day"])} - ${getSafeText(dayMap["focus"])}",
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            if (exercises.isEmpty)
                              const Text("Egzersiz bulunamadı.")
                            else
                              ...exercises.map<Widget>((exercise) {
                                final exerciseMap = exercise
                                as Map<String, dynamic>;

                                return Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: 4,
                                  ),
                                  child: Text(
                                    "• ${getSafeText(exerciseMap["name"])} - "
                                        "${getSafeText(exerciseMap["sets"])} set / "
                                        "${getSafeText(exerciseMap["reps"])}",
                                  ),
                                );
                              }).toList(),
                          ],
                        ),
                      );
                    }).toList(),
                  if (status == "PENDING") ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => updateStatus(
                              item["id"],
                              "APPROVED",
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text("Onayla"),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => updateStatus(
                              item["id"],
                              "REJECTED",
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text("Reddet"),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}