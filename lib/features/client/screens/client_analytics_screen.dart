import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/services/client_service.dart';

class ClientAnalyticsScreen extends StatefulWidget {
  final int clientId;

  const ClientAnalyticsScreen({
    super.key,
    required this.clientId,
  });

  @override
  State<ClientAnalyticsScreen> createState() => _ClientAnalyticsScreenState();
}

class _ClientAnalyticsScreenState extends State<ClientAnalyticsScreen> {
  final ClientService clientService = ClientService();

  bool isLoading = true;
  Map<String, dynamic>? analytics;

  @override
  void initState() {
    super.initState();
    fetchAnalytics();
  }

  Future<void> fetchAnalytics() async {
    try {
      final data = await clientService.getAnalytics(clientId: widget.clientId);

      if (!mounted) return;

      setState(() {
        analytics = data;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst("Exception: ", ""))),
      );
    } finally {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  String formatDate(dynamic value) {
    if (value == null) return "-";

    final date = DateTime.tryParse(value.toString());
    if (date == null) return "-";

    const months = [
      "Oca",
      "Şub",
      "Mar",
      "Nis",
      "May",
      "Haz",
      "Tem",
      "Ağu",
      "Eyl",
      "Eki",
      "Kas",
      "Ara",
    ];

    return "${date.day} ${months[date.month - 1]}";
  }

  void showFitBotDialog() {
    final comments = analytics?["coachComments"] as List<dynamic>? ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.72,
          minChildSize: 0.45,
          maxChildSize: 0.92,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: SafeArea(
                child: ListView(
                  controller: scrollController,
                  children: [
                    Center(
                      child: Container(
                        width: 54,
                        height: 5,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Container(
                        width: 74,
                        height: 74,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.smart_toy_rounded,
                          color: AppColors.primary,
                          size: 40,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Center(
                      child: Text(
                        "FitBot Yorumları",
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Son ölçüm ve antrenman verilerine göre oluşturuldu.",
                      style: AppTextStyles.subtitle,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 22),
                    if (comments.isEmpty)
                      const Text(
                        "Henüz yorum oluşturmak için yeterli veri yok.",
                        style: AppTextStyles.subtitle,
                        textAlign: TextAlign.center,
                      )
                    else
                      ...comments.map(
                            (comment) => Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.inputFill,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.auto_awesome_rounded,
                                color: AppColors.primary,
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  comment.toString(),
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    height: 1.4,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget buildFitBotCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 18),
      child: Material(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: showFitBotDialog,
          child: Container(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.smart_toy_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "FitBot hazır!",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        "Gelişimin hakkında kısa yorumları görmek için dokun.",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    String? subtitle,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primary, size: 26),
            const SizedBox(height: 12),
            Text(title, style: AppTextStyles.subtitle),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle, style: AppTextStyles.subtitle),
            ],
          ],
        ),
      ),
    );
  }

  Widget buildSectionCard({
    required String title,
    required String description,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(description, style: AppTextStyles.subtitle),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  List<FlSpot> buildMeasurementSpots(
      List<dynamic> measurements,
      String key,
      ) {
    final spots = <FlSpot>[];

    for (int i = 0; i < measurements.length; i++) {
      final value = measurements[i][key];

      if (value != null) {
        spots.add(
          FlSpot(
            i.toDouble(),
            double.tryParse(value.toString()) ?? 0,
          ),
        );
      }
    }

    return spots;
  }

  Widget buildLineChart({
    required List<dynamic> measurements,
    required String key,
    required String unit,
  }) {
    final spots = buildMeasurementSpots(measurements, key);

    if (spots.length < 2) {
      return const Text(
        "Grafik için yeterli ölçüm verisi yok.",
        style: AppTextStyles.subtitle,
      );
    }

    final firstValue = spots.first.y;
    final lastValue = spots.last.y;
    final change = lastValue - firstValue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "İlk: ${firstValue.toStringAsFixed(1)}$unit  •  Son: ${lastValue.toStringAsFixed(1)}$unit  •  Değişim: ${change.toStringAsFixed(1)}$unit",
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 245,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: (measurements.length - 1).toDouble(),
              gridData: const FlGridData(show: true),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  axisNameWidget: Text(
                    "Değer ($unit)",
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 44,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toStringAsFixed(0),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  axisNameWidget: const Text(
                    "Ölçüm Tarihi",
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    reservedSize: 38,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();

                      if (index < 0 || index >= measurements.length) {
                        return const SizedBox.shrink();
                      }

                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          formatDate(measurements[index]["date"]),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 10,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(color: AppColors.border),
              ),
              lineTouchData: LineTouchData(
                enabled: true,
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (items) {
                    return items.map((item) {
                      final index = item.x.toInt();
                      final dateText =
                      index >= 0 && index < measurements.length
                          ? formatDate(measurements[index]["date"])
                          : "-";

                      return LineTooltipItem(
                        "$dateText\n${item.y.toStringAsFixed(1)}$unit",
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  barWidth: 4,
                  color: AppColors.primary,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppColors.primary.withOpacity(0.12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget buildWeeklyBarChart(List<dynamic> weeklyPerformance) {
    if (weeklyPerformance.isEmpty) {
      return const Text(
        "Haftalık performans verisi yok.",
        style: AppTextStyles.subtitle,
      );
    }

    return SizedBox(
      height: 245,
      child: BarChart(
        BarChartData(
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: AppColors.border),
          ),
          gridData: const FlGridData(show: true),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              axisNameWidget: const Text(
                "Set",
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              axisNameWidget: const Text(
                "Hafta",
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 38,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();

                  if (index < 0 || index >= weeklyPerformance.length) {
                    return const SizedBox.shrink();
                  }

                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      "H${index + 1}",
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final week = weeklyPerformance[group.x.toInt()];
                return BarTooltipItem(
                  "${week["week"]}\n${rod.toY.toInt()} set",
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ),
          barGroups: List.generate(weeklyPerformance.length, (index) {
            final item = weeklyPerformance[index];
            final value =
                double.tryParse((item["completedSets"] ?? 0).toString()) ?? 0;

            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: value,
                  width: 18,
                  borderRadius: BorderRadius.circular(8),
                  color: AppColors.primary,
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget buildDayPerformance(List<dynamic> dayPerformance) {
    if (dayPerformance.isEmpty) {
      return const Text(
        "Gün bazlı performans verisi yok.",
        style: AppTextStyles.subtitle,
      );
    }

    return Column(
      children: dayPerformance.map((day) {
        final percent = int.tryParse((day["percent"] ?? 0).toString()) ?? 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    day["dayName"] ?? "-",
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    "%$percent",
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(
                  value: percent / 100,
                  minHeight: 9,
                  backgroundColor: AppColors.inputFill,
                  valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget buildMostActiveDayCard(Map<String, dynamic> summary) {
    final mostActiveDay = summary["mostActiveDay"];

    if (mostActiveDay == null) {
      return const SizedBox.shrink();
    }

    return buildSectionCard(
      title: "En Verimli Gün",
      description:
      "Program verilerine göre en yüksek tamamlanan set sayısına sahip gün.",
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.local_fire_department_rounded,
              color: AppColors.primary,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mostActiveDay["dayName"] ?? "-",
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${mostActiveDay["completedSets"] ?? 0} set tamamlandı • %${mostActiveDay["percent"] ?? 0}",
                  style: AppTextStyles.subtitle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildMonthlySummaryCard() {
    final monthlySummary = analytics?["monthlySummary"];

    if (monthlySummary == null) {
      return const SizedBox.shrink();
    }

    return buildSectionCard(
      title: "Aylık Gelişim Özeti",
      description: "Son ayın antrenman performans özeti.",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            monthlySummary["message"] ?? "-",
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Tamamlanan set: ${monthlySummary["completedSets"] ?? 0}",
            style: AppTextStyles.subtitle,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final summary = analytics?["summary"] ?? {};
    final measurements = analytics?["measurements"] as List<dynamic>? ?? [];
    final weeklyPerformance =
        analytics?["weeklyPerformance"] as List<dynamic>? ?? [];
    final dayPerformance = analytics?["dayPerformance"] as List<dynamic>? ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: const Text(
          "Analizler",
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: showFitBotDialog,
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.smart_toy_rounded,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
          onRefresh: fetchAnalytics,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            children: [
              buildFitBotCard(),
              Row(
                children: [
                  buildSummaryCard(
                    title: "Kilo",
                    value: "${summary["currentWeight"] ?? "-"} kg",
                    icon: Icons.monitor_weight_rounded,
                    subtitle:
                    "Değişim: ${summary["weightChange"] ?? 0} kg",
                  ),
                  const SizedBox(width: 12),
                  buildSummaryCard(
                    title: "Program",
                    value: "%${summary["programProgress"] ?? 0}",
                    icon: Icons.fitness_center_rounded,
                    subtitle:
                    "${summary["completedSets"] ?? 0}/${summary["totalSets"] ?? 0} set",
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  buildSummaryCard(
                    title: "Yağ Oranı",
                    value: "%${summary["currentBodyFat"] ?? "-"}",
                    icon: Icons.local_fire_department_rounded,
                    subtitle:
                    "Değişim: ${summary["bodyFatChange"] ?? 0}%",
                  ),
                  const SizedBox(width: 12),
                  buildSummaryCard(
                    title: "Bel",
                    value: "${summary["currentWaist"] ?? "-"} cm",
                    icon: Icons.straighten_rounded,
                    subtitle:
                    "Değişim: ${summary["waistChange"] ?? 0} cm",
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  buildSummaryCard(
                    title: "BMI",
                    value: "${summary["currentBmi"] ?? "-"}",
                    icon: Icons.favorite_border_rounded,
                    subtitle: "Değişim: ${summary["bmiChange"] ?? 0}",
                  ),
                  const SizedBox(width: 12),
                  buildSummaryCard(
                    title: "Hedef",
                    value:
                    "${summary["targetWeightRemaining"] ?? "-"} kg",
                    icon: Icons.flag_rounded,
                    subtitle: "Kalan hedef kilo",
                  ),
                ],
              ),
              const SizedBox(height: 22),
              buildMostActiveDayCard(summary),
              buildMonthlySummaryCard(),
              buildSectionCard(
                title: "Kilo Değişimi",
                description:
                "Bu grafik ölçüm tarihlerine göre kilo değişimini gösterir. X ekseni ölçüm tarihi, Y ekseni kilogramdır.",
                child: buildLineChart(
                  measurements: measurements,
                  key: "weight",
                  unit: "kg",
                ),
              ),
              buildSectionCard(
                title: "Yağ Oranı Değişimi",
                description:
                "Bu grafik ölçüm tarihlerine göre vücut yağ oranını gösterir. X ekseni ölçüm tarihi, Y ekseni yüzdedir.",
                child: buildLineChart(
                  measurements: measurements,
                  key: "bodyFat",
                  unit: "%",
                ),
              ),
              buildSectionCard(
                title: "BMI Değişimi",
                description:
                "Bu grafik ölçüm tarihlerine göre BMI değişimini gösterir.",
                child: buildLineChart(
                  measurements: measurements,
                  key: "bmi",
                  unit: "",
                ),
              ),
              buildSectionCard(
                title: "Haftalık Tamamlanan Setler",
                description:
                "Bu grafik haftalara göre tamamlanan set sayısını gösterir. X ekseni hafta, Y ekseni set sayısıdır.",
                child: buildWeeklyBarChart(weeklyPerformance),
              ),
              buildSectionCard(
                title: "Gün Bazlı Program İlerlemesi",
                description:
                "Aktif programındaki her gün için tamamlanan set yüzdesi gösterilir.",
                child: buildDayPerformance(dayPerformance),
              ),
            ],
          ),
        ),
      ),
    );
  }
}