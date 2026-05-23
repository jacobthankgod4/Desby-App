import 'package:flutter/material.dart';
import '../../../../theme/colors.dart';

class SearchHero extends StatelessWidget {
  const SearchHero({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.darkNavy,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              // Location Selector
              _buildLocationSelector(),
              
              Container(width: 1, height: 32, color: Colors.grey[200]),
              
              // Keyword Search Field
              const Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search premium silk, cotton, wool...',
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 20),
                  ),
                ),
              ),
              
              // Embedded Search Icon
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundColor: AppColors.darkNavy,
                  child: IconButton(
                    icon: const Icon(Icons.search_rounded, color: AppColors.amber, size: 20),
                    onPressed: () {},
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationSelector() {
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            const Icon(Icons.location_on_outlined, color: AppColors.amber, size: 20),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('LOCATION', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.grey)),
                Text('Lagos, NG', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey[800])),
              ],
            ),
            const SizedBox(width: 8),
            const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey, size: 16),
          ],
        ),
      ),
    );
  }
}
