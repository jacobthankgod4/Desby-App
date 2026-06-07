#!/usr/bin/env python3
import re

# Read the file
with open('lib/features/clients/presentation/pages/client_onboarding_page.dart', 'r') as f:
    content = f.read()

# The original _buildReviewStep method to find
old_method = '''Widget _buildReviewStep() {
    return SingleChildScrollView(
      child: Column(
        children: [
          NeuralScanPreview(
            imageUrl: _styleDnaUrl,
            isGenerating: _isGeneratingStyleDna,
            label: 'PERSONAL STYLE DNA',
          ),
          const SizedBox(height: 32),
          _buildReviewCard('IDENTITY', '${_nameController.text}\\n${_phoneController.text}'),
          const SizedBox(height: 16),
          _buildReviewCard('LOCATION', '$_selectedLga, $_selectedState'),
          const SizedBox(height: 16),
          _buildReviewCard('OCCASIONS', _selectedOccasions.isNotEmpty ? _selectedOccasions.join(' • ') : 'None'),
          const SizedBox(height: 16),
          _buildReviewCard('FABRICS', _selectedFabrics.isNotEmpty ? _selectedFabrics.join(' • ') : 'None'),
          const SizedBox(height: 16),
          _buildReviewCard('FINDER', _selectedFinderStyle == 'uber' ? 'Map' : 'List'),
          const SizedBox(height: 40),
        ],
      ),
    );
  }'''

new_method = '''Widget _buildReviewStep() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Desktop: Show Uber-style split preview (>600px wide)
        if (constraints.maxWidth > 600) {
          return _buildDesktopReviewSplitView();
        }
        // Mobile: Original scrollable view
        return _buildMobileReviewView();
      },
    );
  }

  /// Desktop Uber-style split view preview - Step 5
  Widget _buildDesktopReviewSplitView() {
    return Row(
      children: [
        // LEFT: Preview of their selected finder style (50%)
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.amber.withValues(alpha: 0.3), width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: _selectedFinderStyle == 'uber' ? _buildUberMapPreviewCard() : _buildClassicListPreviewCard(),
            ),
          ),
        ),
        // RIGHT: Summary cards (50%)
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(child: Text('READY FOR THE PERFECT FIT', style: TextStyle(color: AppColors.amber, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2))),
                const SizedBox(height: 24),
                _buildReviewCard('IDENTITY', '${_nameController.text}\\n${_phoneController.text}'),
                const SizedBox(height: 12),
                _buildReviewCard('LOCATION', '$_selectedLga, $_selectedState'),
                const SizedBox(height: 12),
                _buildReviewCard('OCCASIONS', _selectedOccasions.isNotEmpty ? _selectedOccasions.join(' • ') : 'None'),
                const SizedBox(height: 12),
                _buildReviewCard('FABRICS', _selectedFabrics.isNotEmpty ? _selectedFabrics.join(' • ') : 'None'),
                const SizedBox(height: 12),
                _buildReviewCard('FINDER', _selectedFinderStyle == 'uber' ? 'Interactive Map' : 'Card Grid'),
                const SizedBox(height: 32),
                Center(child: _buildMiniStyleDnaPreview()),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Uber map preview card for desktop
  Widget _buildUberMapPreviewCard() {
    return Container(
      color: const Color(0xFF0A1921),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [Icon(Icons.map_rounded, color: AppColors.amber, size: 20), SizedBox(width: 8), Text('INTERACTIVE MAP', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900))]),
          const SizedBox(height: 16),
          Expanded(
            child: Stack(
              children: [
                CustomPaint(size: const Size(double.infinity, double.infinity), painter: _GridPainter(Colors.white.withValues(alpha: 0.05))),
                ...List.generate(4, (i) => Positioned(left: 20.0 + (i * 50), top: 30.0 + (i % 2 * 50), child: const Icon(Icons.location_on_rounded, color: AppColors.amber, size: 28))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: const Row(children: [Icon(Icons.search, color: Colors.grey, size: 16), SizedBox(width: 8), Text('Search tailors...', style: TextStyle(color: Colors.grey, fontSize: 12))]),
          ),
        ],
      ),
    );
  }

  /// Classic list preview card for desktop
  Widget _buildClassicListPreviewCard() {
    return Container(
      color: const Color(0xFF0A1921),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [Icon(Icons.list_rounded, color: AppColors.amber, size: 20), SizedBox(width: 8), Text('CARD GRID', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900))]),
          const SizedBox(height: 16),
          Expanded(
            child: Column(
              children: List.generate(3, (i) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white.withValues(alpha: 0.1))),
                child: Row(
                  children: [
                    CircleAvatar(radius: 16, backgroundColor: AppColors.amber.withValues(alpha: 0.2)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(width: 80, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))), const SizedBox(height: 4), Container(width: 50, height: 3, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(2)))])]),
                    const Icon(Icons.star_rounded, color: AppColors.amber, size: 14),
                  ],
                ),
              )),
            ),
          ),
        ],
      ),
    );
  }

  /// Mobile scrollable review view
  Widget _buildMobileReviewView() {
    return SingleChildScrollView(
      child: Column(
        children: [
          NeuralScanPreview(imageUrl: _styleDnaUrl, isGenerating: _isGeneratingStyleDna, label: 'PERSONAL STYLE DNA'),
          const SizedBox(height: 32),
          _buildReviewCard('IDENTITY', '${_nameController.text}\\n${_phoneController.text}'),
          const SizedBox(height: 16),
          _buildReviewCard('LOCATION', '$_selectedLga, $_selectedState'),
          const SizedBox(height: 16),
          _buildReviewCard('OCCASIONS', _selectedOccasions.isNotEmpty ? _selectedOccasions.join(' • ') : 'None'),
          const SizedBox(height: 16),
          _buildReviewCard('FABRICS', _selectedFabrics.isNotEmpty ? _selectedFabrics.join(' • ') : 'None'),
          const SizedBox(height: 16),
          _buildReviewCard('FINDER', _selectedFinderStyle == 'uber' ? 'Interactive Map' : 'Card Grid'),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  /// Mini Style DNA preview for desktop
  Widget _buildMiniStyleDnaPreview() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.amber.withValues(alpha: 0.2))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: AppColors.amber.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: _styleDnaUrl != null ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(_styleDnaUrl!, fit: BoxFit.cover)) : const Icon(Icons.auto_awesome, color: AppColors.amber, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('STYLE DNA', style: TextStyle(color: AppColors.amber, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
              Text(_isGeneratingStyleDna ? 'Generating...' : 'AI Powered', style: const TextStyle(color: Colors.white54, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }'''

# Check if we can find the old method
if old_method in content:
    print("Found old method, replacing...")
    content = content.replace(old_method, new_method)
    # Write back
    with open('lib/features/clients/presentation/pages/client_onboarding_page.dart', 'w') as f:
        f.write(content)
    print("Successfully updated _buildReviewStep method")
else:
    print("ERROR: Could not find the exact old method pattern")
    print("Searching for _buildReviewStep...")
    # Try to find any version
    if "Widget _buildReviewStep()" in content:
        print("Found _buildReviewStep method, but pattern didn't match exactly")
        # Find and show the actual content
        import re
        match = re.search(r'Widget _buildReviewStep\(\).*?\n  \}', content, re.DOTALL)
        if match:
            print("Found at position:", match.start())
            print("Actual content:")
            print(match.group()[:500])
    else:
        print("ERROR: Could not find _buildReviewStep at all!")
