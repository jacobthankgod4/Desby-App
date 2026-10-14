import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../../../theme/colors.dart';
import '../../../../core/widgets/shell_app_bar.dart';

class DeliverySetupPage extends ConsumerStatefulWidget {
  final Map<String, dynamic> tailor;

  const DeliverySetupPage({super.key, required this.tailor});

  @override
  ConsumerState<DeliverySetupPage> createState() => _DeliverySetupPageState();
}

class _DeliverySetupPageState extends ConsumerState<DeliverySetupPage> {
  DateTime? _selectedDate;
  final _addressController = TextEditingController();

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: shellAppBar(context, title: 'Delivery Setup'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Select Date Panel
            _buildSelectionPanel(
              title: 'Enter date',
              label: 'Select date',
              child: InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 7)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 90)),
                  );
                  if (date != null) setState(() => _selectedDate = date);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surfaceHover,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _selectedDate == null
                            ? 'mm/dd/yyyy'
                            : _selectedDate!.toString().split(' ')[0],
                        style: TextStyle(
                          color: _selectedDate == null
                              ? colors.textMuted
                              : colors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.calendar_today_rounded,
                        color: AppColors.amber,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Select Address Panel
            _buildSelectionPanel(
              title: 'Enter Location',
              label: 'Select address',
              child: Column(
                children: [
                  TextField(
                    controller: _addressController,
                    style: TextStyle(color: colors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Delivery Address...',
                      hintStyle: TextStyle(color: colors.textMuted),
                      filled: true,
                      fillColor: colors.surfaceHover,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Location services coming soon'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          color: AppColors.amber,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Use Current Location',
                          style: TextStyle(
                            color: AppColors.amber,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ElevatedButton(
            onPressed: () => ref.popShell(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.amber,
              foregroundColor: AppColors.darkNavy,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Save Delivery Details',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionPanel({
    required String title,
    required String label,
    required Widget child,
  }) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }
}
