import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../theme/colors.dart';

class UberTrackingMap extends StatefulWidget {
  final String trackingUrl;

  const UberTrackingMap({super.key, required this.trackingUrl});

  @override
  State<UberTrackingMap> createState() => _UberTrackingMapState();
}

class _UberTrackingMapState extends State<UberTrackingMap> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.darkNavy)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) => setState(() => _isLoading = false),
        ),
      )
      ..loadRequest(Uri.parse(widget.trackingUrl));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: colors.scaffoldBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(color: AppColors.amber),
              ),
          ],
        ),
      ),
    );
  }
}
