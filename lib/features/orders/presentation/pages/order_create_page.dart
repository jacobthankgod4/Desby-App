import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../../clients/presentation/providers/client_provider.dart';
import '../../../../theme/colors.dart';

class OrderCreatePage extends ConsumerStatefulWidget {
  const OrderCreatePage({super.key});

  @override
  ConsumerState<OrderCreatePage> createState() => _OrderCreatePageState();
}

class _OrderCreatePageState extends ConsumerState<OrderCreatePage> {
  String? _selectedClientId;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(clientsProvider(null));

    return Scaffold(
      backgroundColor: AppColors.darkNavy,
      appBar: AppBar(
        title: const Text('QUICK ORDER', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.amber, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('EXISTING CLIENT', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
            const SizedBox(height: 16),
            clientsAsync.when(
              data: (clients) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedClientId,
                    hint: const Text('Select verified client...', style: TextStyle(color: Colors.white24, fontSize: 13)),
                    dropdownColor: AppColors.darkNavy,
                    isExpanded: true,
                    items: clients.map((c) => DropdownMenuItem(
                      value: c.id, 
                      child: Text(c.name.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold))
                    )).toList(),
                    onChanged: (v) => setState(() => _selectedClientId = v),
                  ),
                ),
              ),
              loading: () => const LinearProgressIndicator(color: AppColors.amber),
              error: (_, __) => const Text('Client sync failed', style: TextStyle(color: Colors.redAccent)),
            ),
            
            const SizedBox(height: 40),
            const Text('PROJECT ARCHITECTURE', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
            const SizedBox(height: 16),
            _buildActionItem(Icons.add_circle_outline, 'Select Garment Configuration'),
            
            const SizedBox(height: 32),
            _buildDatePicker(),
            
            const SizedBox(height: 56),
            SizedBox(
              height: 64,
              child: ElevatedButton(
                onPressed: _selectedClientId == null ? null : () {
                  if (ref.canPopShell) {
                    ref.popShell();
                  } else {
                    ref.setShell('/main');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.amber,
                  foregroundColor: AppColors.darkNavy,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text('GENERATE ORDER', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.amber, size: 20),
          const SizedBox(width: 16),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _dueDate,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date != null) setState(() => _dueDate = date);
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined, color: AppColors.amber, size: 20),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('HANDOVER TARGET', style: TextStyle(color: Colors.white24, fontSize: 8, fontWeight: FontWeight.w900)),
                Text(_dueDate.toString().split(' ')[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
