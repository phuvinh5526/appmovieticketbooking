import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:movieticketbooking/Services/ticket_service.dart';

class RevenueStatisticsScreen extends StatefulWidget {
  const RevenueStatisticsScreen({Key? key}) : super(key: key);

  @override
  _RevenueStatisticsScreenState createState() =>
      _RevenueStatisticsScreenState();
}

class _RevenueStatisticsScreenState extends State<RevenueStatisticsScreen> {
  String selectedFilter = "Tháng";
  DateTime selectedDate = DateTime.now();
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  final TicketService _ticketService = TicketService();
  bool isLoading = false;

  Map<String, dynamic> revenueData = {
    'totalRevenue': 0.0,
    'ticketCount': 0,
    'dailyRevenue': {},
  };

  @override
  void initState() {
    super.initState();
    _loadRevenueData();
  }

  Future<void> _loadRevenueData() async {
    setState(() {
      isLoading = true;
    });

    try {
      Map<String, dynamic> data;
      switch (selectedFilter) {
        case "Ngày":
          data = await _ticketService.getDailyRevenue(selectedDate);
          break;
        case "Tháng":
          data = await _ticketService.getMonthlyRevenue(selectedDate);
          break;
        case "Năm":
          data = await _ticketService.getYearlyRevenue(selectedDate);
          break;
        default:
          data = await _ticketService.getMonthlyRevenue(selectedDate);
      }

      setState(() {
        revenueData = data;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading revenue data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Có lỗi xảy ra khi tải dữ liệu'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff252429),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.orange,
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadRevenueData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFilterSection(),
                      const SizedBox(height: 24),
                      _buildStatisticsCards(),
                      const SizedBox(height: 24),
                      _buildChartSection(),
                      const SizedBox(height: 24),
                      _buildDetailedStats(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.filter_list, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Bộ lọc',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildFilterDropdown(),
              ),
              const SizedBox(width: 16),
              _buildDatePicker(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedFilter,
          isExpanded: true,
          dropdownColor: const Color(0xff252429),
          style: const TextStyle(color: Colors.white),
          items: ["Ngày", "Tháng", "Năm"].map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              selectedFilter = value!;
              _loadRevenueData();
            });
          },
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    String displayDate;
    switch (selectedFilter) {
      case "Ngày":
        displayDate = DateFormat('dd/MM/yyyy').format(selectedDate);
        break;
      case "Tháng":
        displayDate = DateFormat('MM/yyyy').format(selectedDate);
        break;
      case "Năm":
        displayDate = selectedDate.year.toString();
        break;
      default:
        displayDate = DateFormat('dd/MM/yyyy').format(selectedDate);
    }

    return InkWell(
      onTap: () => _selectDate(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: Colors.orange, size: 20),
            const SizedBox(width: 8),
            Text(
              displayDate,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            "Tổng doanh thu",
            currencyFormat.format(revenueData['totalRevenue'] ?? 0),
            Icons.monetization_on,
            Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            "Số vé đã bán",
            "${revenueData['ticketCount'] ?? 0} vé",
            Icons.confirmation_number,
            Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection() {
    Map<String, dynamic> chartData = {};

    switch (selectedFilter) {
      case "Năm":
        chartData = revenueData['yearlyRevenue'] ?? {};
        break;
      case "Tháng":
        chartData = revenueData['monthlyRevenue'] ?? {};
        break;
      default:
        chartData = revenueData['dailyRevenue'] ?? {};
    }

    if (chartData.isEmpty) {
      return Container(
        height: 400,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black12,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
        ),
        child: const Center(
          child: Text(
            "Không có dữ liệu",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    return Container(
      height: 400,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Biểu đồ doanh thu",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: BarChart(
              BarChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.white12,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final entries = chartData.entries.toList();
                        if (value >= 0 && value < entries.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              entries[value.toInt()].key,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          _formatChartValue(value),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        );
                      },
                      reservedSize: 40,
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: _generateChartData(),
                maxY: chartData.values
                        .map((v) => (v as num).toDouble())
                        .reduce((a, b) => a > b ? a : b) *
                    1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<BarChartGroupData> _generateChartData() {
    Map<String, dynamic> chartData = {};

    switch (selectedFilter) {
      case "Năm":
        chartData = revenueData['yearlyRevenue'] ?? {};
        break;
      case "Tháng":
        chartData = revenueData['monthlyRevenue'] ?? {};
        break;
      default:
        chartData = revenueData['dailyRevenue'] ?? {};
    }

    if (chartData.isEmpty) return [];

    final entries = chartData.entries.toList();

    return List.generate(
      entries.length,
      (index) => BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: (entries[index].value as num).toDouble(),
            color: Colors.orange,
            width: 16,
            borderRadius: BorderRadius.circular(4),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: chartData.values
                  .map((v) => (v as num).toDouble())
                  .reduce((a, b) => a > b ? a : b),
              color: Colors.white.withOpacity(0.05),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedStats() {
    Map<String, dynamic> detailData = {};

    switch (selectedFilter) {
      case "Năm":
        detailData = revenueData['yearlyRevenue'] ?? {};
        break;
      case "Tháng":
        detailData = revenueData['monthlyRevenue'] ?? {};
        break;
      default:
        detailData = revenueData['dailyRevenue'] ?? {};
    }

    if (detailData.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black12,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
        ),
        child: const Center(
          child: Text(
            "Không có dữ liệu chi tiết",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    String periodText = "";
    switch (selectedFilter) {
      case "Năm":
        periodText = selectedDate.year.toString();
        break;
      case "Tháng":
        periodText = "${selectedDate.month}/${selectedDate.year}";
        break;
      default:
        periodText = DateFormat('dd/MM/yyyy').format(selectedDate);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Chi tiết doanh thu ${selectedFilter.toLowerCase()} $periodText",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...detailData.entries.map((entry) => _buildDetailRow(
                entry.key,
                currencyFormat.format(entry.value),
              )),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    String displayLabel = label;

    switch (selectedFilter) {
      case "Năm":
        // Chuyển số tháng thành tên tháng
        final monthNumber = int.tryParse(label);
        if (monthNumber != null) {
          displayLabel = '$monthNumber/${selectedDate.year}';
        }
        break;
      case "Tháng":
        // Định dạng lại ngày/tháng
        final parts = label.split('/');
        if (parts.length == 2) {
          displayLabel = '${parts[0]}/${parts[1]}/${selectedDate.year}';
        }
        break;
      default:
        // Giữ nguyên format cho ngày
        displayLabel = label;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(displayLabel, style: const TextStyle(color: Colors.white70)),
          Text(value, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  String _formatChartValue(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(0)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}K';
    }
    return value.toStringAsFixed(0);
  }

  Future<void> _selectDate(BuildContext context) async {
    if (selectedFilter == "Năm") {
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: const Color(0xff252429),
            title:
                const Text('Chọn năm', style: TextStyle(color: Colors.white)),
            content: SizedBox(
              width: double.minPositive,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: 5,
                itemBuilder: (BuildContext context, int index) {
                  final year = DateTime.now().year - index;
                  return ListTile(
                    title: Text(year.toString(),
                        style: const TextStyle(color: Colors.white)),
                    onTap: () {
                      setState(() {
                        selectedDate = DateTime(year);
                        _loadRevenueData();
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          );
        },
      );
      return;
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.orange,
              onPrimary: Colors.white,
              surface: Color(0xff252429),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        _loadRevenueData();
      });
    }
  }
}
