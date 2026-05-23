import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/analytics_provider.dart';
import '../../../../core/widgets/error_state_widget.dart';

class ReportsPage extends ConsumerWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(revenueReportProvider((
      start: DateTime.now().subtract(const Duration(days: 90)),
      end: DateTime.now(),
    )));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
      ),
      body: reportAsync.when(
        data: (report) => ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _buildReportSummary(report),
            const SizedBox(height: 32),
            _buildGarmentBreakdown(report['garment_breakdown'] as List),
            const SizedBox(height: 32),
            _buildExportSection(),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => const ErrorStateWidget(message: 'Could not generate report.'),
      ),
    );
  }

  Widget _buildReportSummary(Map<String, dynamic> report) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text('Total Revenue (90 days)', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text(
              '\$${report['total_revenue']}',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGarmentBreakdown(List breakdown) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Revenue by Category', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ...breakdown.map((item) => ListTile(
          title: Text(item['type']),
          trailing: Text('\$${item['amount']}', style: const TextStyle(fontWeight: FontWeight.bold)),
        )),
      ],
    );
  }

  Widget _buildExportSection() {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.picture_as_pdf_outlined),
          label: const Text('Export to PDF'),
          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.table_chart_outlined),
          label: const Text('Export to CSV'),
          style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
        ),
      ],
    );
  }
}
