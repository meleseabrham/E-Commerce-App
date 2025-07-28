import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/admin_drawer.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'admin_dashboard_screen.dart';

class AdminAnalysisScreen extends StatefulWidget {
  const AdminAnalysisScreen({Key? key}) : super(key: key);

  @override
  State<AdminAnalysisScreen> createState() => _AdminAnalysisScreenState();
}

class _AdminAnalysisScreenState extends State<AdminAnalysisScreen> {
  int _orderCount = 0;
  double _totalSales = 0.0;
  int _userCount = 0;
  bool _isLoading = true;

  Map<String, int> _ordersByMonth = {};
  Map<String, double> _salesByMonth = {
    'Jan': 1200, 'Feb': 1800, 'Mar': 1500, 'Apr': 2200, 'May': 1700, 'Jun': 2500
  };
  Map<String, int> _orderStatus = {};
  Map<String, double> _orderStatusPercent = {};
  String _topProduct = 'Coffee Beans';
  int _topProductSales = 120;
  double _salesGrowth = 0.15; // 15% growth

  @override
  void initState() {
    super.initState();
    _fetchStats();
    _fetchOrdersByMonth();
    _fetchOrderStatusPercent();
  }

  Future<void> _fetchStats() async {
    setState(() => _isLoading = true);
    try {
      final orders = await Supabase.instance.client.from('orders').select();
      final users = await Supabase.instance.client.from('users').select();
      _orderCount = (orders as List).length;
      _userCount = (users as List).length;
      _totalSales = orders.fold(0.0, (sum, o) => sum + (o['total'] ?? 0.0));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
    setState(() => _isLoading = false);
  }

  Future<void> _fetchOrdersByMonth() async {
    final orders = await Supabase.instance.client
        .from('orders')
        .select('id, created_at');
    Map<String, int> ordersByMonth = {};
    for (final order in orders) {
      final date = DateTime.parse(order['created_at']);
      final month = DateFormat('MMM').format(date); // e.g., 'Jan'
      ordersByMonth[month] = (ordersByMonth[month] ?? 0) + 1;
    }
    setState(() {
      _ordersByMonth = ordersByMonth;
    });
  }

  Future<void> _fetchOrderStatusPercent() async {
    final orders = await Supabase.instance.client
        .from('orders')
        .select('status');
    Map<String, int> statusCounts = {};
    for (final order in orders) {
      final status = order['status'] ?? 'Unknown';
      statusCounts[status] = (statusCounts[status] ?? 0) + 1;
    }
    int total = statusCounts.values.fold(0, (a, b) => a + b);
    Map<String, double> statusPercent = {};
    statusCounts.forEach((status, count) {
      statusPercent[status] = total > 0 ? (count / total) * 100 : 0;
    });
    setState(() {
      _orderStatus = statusCounts;
      _orderStatusPercent = statusPercent;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
              (route) => false,
            );
          },
        ),
        title: Text('Admin: Analysis')),
      drawer: AdminDrawer(selected: '/analytics'),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _buildStatCard('Total Orders', _orderCount.toString(), Icons.shopping_cart, Colors.black),
                      _buildStatCard('Total Sales', ' ${_totalSales.toStringAsFixed(2)}', Icons.attach_money, Colors.green[900]!),
                      _buildStatCard('Total Users', _userCount.toString(), Icons.people, Colors.black),
                      _buildInsightCard('Top Product', _topProduct, Icons.star, Colors.orange, trailing: '$_topProductSales sales'),
                      _buildInsightCard('Sales Growth', '', Icons.trending_up, Colors.green, trailing: '${(_salesGrowth * 100).toStringAsFixed(1)}%'),
                    ],
                  ),
                  SizedBox(height: 32),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Orders by Month', style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(height: 200, child: _buildOrdersBarChart()),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 32),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Order Status Breakdown', style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(height: 200, child: _buildOrderStatusPieChart()),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return SizedBox(
      width: 260,
      child: Card(
        margin: EdgeInsets.only(bottom: 0),
        child: ListTile(
          leading: Icon(icon, size: 40, color: color),
          title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
          trailing: Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        ),
      ),
    );
  }

  Widget _buildInsightCard(String title, String value, IconData icon, Color color, {String? trailing}) {
    return SizedBox(
      width: 260,
      child: Card(
        margin: EdgeInsets.only(bottom: 0),
        child: ListTile(
          leading: Icon(icon, size: 36, color: color),
          title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: value.isNotEmpty ? Text(value) : null,
          trailing: trailing != null ? Text(trailing, style: TextStyle(fontWeight: FontWeight.bold, color: color)) : null,
        ),
      ),
    );
  }

  Widget _buildOrdersBarChart() {
    final months = _ordersByMonth.keys.toList();
    final data = _ordersByMonth.values.toList();
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        barGroups: List.generate(data.length, (i) {
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: data[i].toDouble(),
                color: Colors.blueAccent,
                width: 18,
                borderRadius: BorderRadius.circular(6),
              ),
            ],
          );
        }),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                return Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    idx >= 0 && idx < months.length ? months[idx] : '',
                    style: TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderStatusPieChart() {
    final status = _orderStatusPercent.keys.toList();
    final data = _orderStatusPercent.values.toList();
    final colors = [Colors.teal, Colors.amber, Colors.green, Colors.red, Colors.blue, Colors.purple];
    return PieChart(
      PieChartData(
        sections: List.generate(data.length, (i) {
          return PieChartSectionData(
            color: colors[i % colors.length],
            value: data[i],
            title: '${status[i]}\n${data[i].toStringAsFixed(1)}%',
            radius: 50,
            titleStyle: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
          );
        }),
        sectionsSpace: 2,
        centerSpaceRadius: 30,
      ),
    );
  }
} 