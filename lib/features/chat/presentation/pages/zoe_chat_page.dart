import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/zoe_chat_provider.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../../../core/providers/layout_provider.dart';
import '../../../../core/services/ai/zoe_chat_service.dart';
import '../../../../core/services/image_upload_service.dart';
import '../../../../core/widgets/zoe_avatar.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../theme/colors.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/shell_scope.dart';

class ZoeChatPage extends ConsumerStatefulWidget {
  const ZoeChatPage({super.key});

  @override
  ConsumerState<ZoeChatPage> createState() => _ZoeChatPageState();
}

class _ZoeChatPageState extends ConsumerState<ZoeChatPage>
    with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  late AnimationController _inputFocusAnim;
  late Animation<double> _inputGlowAnim;
  bool _hasText = false;
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;

  @override
  void initState() {
    super.initState();
    _inputFocusAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _inputGlowAnim = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _inputFocusAnim, curve: Curves.easeOut));
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _inputFocusAnim.forward();
      } else {
        _inputFocusAnim.reverse();
      }
    });
    _controller.addListener(() {
      final hasText = _controller.text.trim().isNotEmpty;
      if (hasText != _hasText) {
        setState(() => _hasText = hasText);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _inputFocusAnim.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty && _selectedImageBytes == null) return;
    HapticFeedback.lightImpact();

    final msg = text.trim().isNotEmpty
        ? text.trim()
        : 'What do you see in this image?';

    String? imageUrl;
    if (_selectedImageBytes != null) {
      final user = ref.read(currentUserProvider);
      if (user == null) return;
      try {
        final xFile = XFile.fromData(
          _selectedImageBytes!,
          name: _selectedImageName ?? 'image.jpg',
          mimeType: 'image/jpeg',
        );
        imageUrl = await ImageUploadService().uploadImage(
          xFile,
          user.id,
          'chats/zoe',
        );
      } on ImageUploadException catch (e) {
        debugPrint('Zoe image upload failed: $e');
      } catch (e) {
        debugPrint('Zoe image upload failed: $e');
      }
      if (imageUrl == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image upload failed — please try again'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
    }

    if (!mounted) return;
    await ref
        .read(zoeChatProvider.notifier)
        .sendMessage(msg, imageUrl: imageUrl);

    _controller.clear();
    setState(() {
      _selectedImageBytes = null;
      _selectedImageName = null;
    });
    _focusNode.unfocus();
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  Future<void> _pickImage() async {
    final service = ImageUploadService();
    final file = await service.pickImageFromGallery();
    if (file != null) {
      final bytes = await file.readAsBytes();
      setState(() {
        _selectedImageBytes = bytes;
        _selectedImageName = file.name;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final chatState = ref.watch(zoeChatProvider);
    final quickActions = ref.watch(zoeQuickActionsProvider);
    final bool isMobile = !ref.watch(isDesktopProvider);

    ref.listen<ZoeChatState>(zoeChatProvider, (prev, next) {
      if (next.messages.length > (prev?.messages.length ?? 0)) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      backgroundColor: colors.scaffoldBg,
      appBar: _buildAppBar(chatState, isMobile),
      body: Column(
        children: [
          Expanded(
            child: chatState.messages.isEmpty
                ? _buildWelcomeScreen(
                    quickActions,
                    ref.watch(currentUserProvider)?.userType ?? 'client',
                  )
                : _buildMessageList(chatState),
          ),
          if (chatState.isLoading) _buildTypingIndicator(),
          if (chatState.escalationSuccess && chatState.lastTicketId != null)
            _buildEscalationBanner(chatState.lastTicketId!),
          if (chatState.showEscalateButton &&
              !chatState.isLoading &&
              !chatState.escalationSuccess)
            _buildEscalateButton(chatState.isEscalating),
          _buildInputArea(chatState.isLoading),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ZoeChatState chatState, bool isMobile) {
    final colors = context.colors;
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1005), Color(0xFF2A1A08), colors.scaffoldBg],
          ),
        ),
      ),
      leading: (isMobile && !ShellScope.isInside(context))
          ? IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.amber,
                size: 18,
              ),
              onPressed: () {
                // Without the fallback this was a dead button at stack depth 1.
                if (ref.canPopShell) {
                  ref.popShell();
                } else {
                  ref.setShell('/main');
                }
              },
            )
          : const SizedBox.shrink(),
      title: Row(
        children: [
          // Animated Zoe avatar
          ZoeAvatar(size: 36, isThinking: chatState.isLoading, showGlow: false),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ZOE',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  letterSpacing: 2,
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  chatState.isLoading ? 'Thinking...' : 'Online',
                  key: ValueKey(chatState.isLoading),
                  style: TextStyle(
                    color: chatState.isLoading
                        ? AppColors.amber
                        : AppColors.successGreen,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        if (chatState.messages.isNotEmpty)
          IconButton(
            icon: Icon(
              Icons.delete_sweep_rounded,
              color: colors.textMuted,
              size: 20,
            ),
            onPressed: () {
              ref.read(zoeChatProvider.notifier).clearChat();
            },
            tooltip: 'Clear conversation',
          ),
        const SizedBox(width: 8),
      ],
    );
  }

  String _getWelcomeText(String userType) {
    switch (userType) {
      case 'tailor':
        return 'Your AI business partner for tailoring.\nAsk me about pricing, fabrics, clients, apprentices, or growing your business.';
      case 'client':
        return 'Your personal fashion advisor.\nAsk me about styles, fabrics, measurements, finding a tailor, or tracking your order.';
      case 'apprentice':
        return 'Your learning companion on the tailoring journey.\nAsk me about techniques, measurements, patterns, or your curriculum.';
      case 'fabric_seller':
        return 'Your marketplace partner for selling fabrics.\nAsk me about pricing, listings, inventory, attracting buyers, or managing orders.';
      default:
        return 'Your personal AI fashion assistant.\nAsk me anything about tailoring, fabrics, styling, or the platform.';
    }
  }

  Widget _buildWelcomeScreen(List<String> quickActions, String userType) {
    final colors = context.colors;
    final welcomeText = _getWelcomeText(userType);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          // Animated Zoe avatar
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 800),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: const ZoeAvatar(size: 88),
              );
            },
          ),
          const SizedBox(height: 28),
          // Animated text
          _DelayedFadeIn(
            delay: const Duration(milliseconds: 200),
            child: Text(
              'Hi, I\'m Zoe',
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 22,
              ),
            ),
          ),
          const SizedBox(height: 10),
          _DelayedFadeIn(
            delay: const Duration(milliseconds: 400),
            child: Text(
              welcomeText,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textMuted,
                fontSize: 13,
                height: 1.6,
              ),
            ),
          ),
          const SizedBox(height: 48),
          // Quick actions header
          _DelayedFadeIn(
            delay: const Duration(milliseconds: 600),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Quick Actions',
                style: TextStyle(
                  color: AppColors.amber.withValues(alpha: 0.6),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Animated quick action chips
          ...List.generate(quickActions.length, (index) {
            return _DelayedFadeIn(
              delay: Duration(milliseconds: 700 + (index * 100)),
              child: _buildQuickActionChip(quickActions[index]),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildQuickActionChip(String action) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _sendMessage(action),
          borderRadius: BorderRadius.circular(16),
          splashColor: AppColors.amber.withValues(alpha: 0.1),
          highlightColor: AppColors.amber.withValues(alpha: 0.05),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.amber.withValues(alpha: 0.12),
                width: 1,
              ),
              gradient: LinearGradient(
                colors: [colors.surface, colors.surface],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: AppColors.amber.withValues(alpha: 0.7),
                    size: 14,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    action,
                    style: TextStyle(
                      color: colors.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: colors.textMuted,
                  size: 12,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageList(ZoeChatState chatState) {
    final colors = context.colors;
    final visibleMessages = chatState.messages
        .where((m) => !m.content.startsWith('[SILENT]'))
        .toList();

    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: visibleMessages.length,
      separatorBuilder: (_, _) => const SizedBox(height: 18),
      itemBuilder: (context, index) {
        final msg = visibleMessages[index];
        final isUser = msg.role == 'user';
        final showTimestamp =
            index == 0 ||
            visibleMessages[index - 1].timestamp
                    .difference(msg.timestamp)
                    .inMinutes >
                5;

        return _AnimatedMessageBubble(
          key: ValueKey(msg.id),
          isUser: isUser,
          child: Column(
            crossAxisAlignment: isUser
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              if (showTimestamp)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6, left: 4, right: 4),
                  child: Text(
                    _formatTime(msg.timestamp),
                    style: TextStyle(color: colors.textMuted, fontSize: 10),
                  ),
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: isUser
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.start,
                children: [
                  if (!isUser) const ZoeAvatarSmall(),
                  if (!isUser) const SizedBox(width: 10),
                  Flexible(
                    child: isUser
                        ? _buildUserBubble(msg)
                        : _buildAssistantBubble(msg),
                  ),
                  if (isUser) const SizedBox(width: 10),
                  if (isUser) _buildUserAvatar(),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Widget _buildUserAvatar() {
    final colors = context.colors;
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Icon(Icons.person_rounded, color: colors.textMuted, size: 18),
      ),
    );
  }

  Widget _buildUserBubble(ZoeMessage msg) {
    final imageUrl = msg.imageUrl;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.amber, Color(0xFFFFCA28)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(
          18,
        ).copyWith(bottomRight: const Radius.circular(4)),
        boxShadow: [
          BoxShadow(
            color: AppColors.amber.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (imageUrl != null && imageUrl.isNotEmpty) ...[
            GestureDetector(
              onTap: () => _showImageFullscreen(imageUrl),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AppNetworkImage(
                  url: imageUrl,
                  fit: BoxFit.cover,
                  width: 180,
                ),
              ),
            ),
            if (msg.content.isNotEmpty) const SizedBox(height: 10),
          ],
          if (msg.content.isNotEmpty)
            SelectableText(
              msg.content,
              style: TextStyle(
                color: context.colors.textOnAmber,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAssistantBubble(ZoeMessage msg) {
    final colors = context.colors;
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(
          18,
        ).copyWith(bottomLeft: const Radius.circular(4)),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (msg.imageUrls != null && msg.imageUrls!.isNotEmpty) ...[
            for (final url in msg.imageUrls!) ...[
              _buildImageWidget(url),
              if (url != msg.imageUrls!.last) const SizedBox(height: 8),
            ],
            if (msg.content.isNotEmpty) const SizedBox(height: 12),
          ] else if (msg.imageUrl != null) ...[
            _buildImageWidget(msg.imageUrl!),
            if (msg.content.isNotEmpty) const SizedBox(height: 12),
          ],
          if (msg.content.isNotEmpty)
            MarkdownBody(
              data: msg.content,
              selectable: true,
              styleSheet: MarkdownStyleSheet(
                p: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.6,
                ),
                strong: const TextStyle(
                  color: AppColors.amber,
                  fontWeight: FontWeight.w700,
                ),
                em: TextStyle(
                  color: colors.textPrimary,
                  fontStyle: FontStyle.italic,
                ),
                code: TextStyle(
                  color: AppColors.amber.withValues(alpha: 0.8),
                  backgroundColor: colors.surface,
                  fontSize: 12,
                ),
                codeblockDecoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                blockquote: TextStyle(color: colors.textMuted, fontSize: 12),
                listBullet: TextStyle(
                  color: AppColors.amber.withValues(alpha: 0.6),
                ),
                h1: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
                h2: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
                h3: const TextStyle(
                  color: AppColors.amber,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImageWidget(String imageUrl) {
    final colors = context.colors;
    final isDataUrl = imageUrl.startsWith('data:');
    return GestureDetector(
      onTap: () => _showImageFullscreen(imageUrl),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: isDataUrl
            ? Image.memory(
                Uri.parse(imageUrl).data!.contentAsBytes(),
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (_, _, _) => _imageErrorWidget(),
              )
            : AppNetworkImage(
                url: imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
              ),
      ),
    );
  }

  Widget _imageErrorWidget() {
    final colors = context.colors;
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.image_outlined, color: colors.textMuted, size: 28),
            const SizedBox(height: 6),
            Text(
              'Image unavailable',
              style: TextStyle(color: colors.textMuted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  void _showImageFullscreen(String imageUrl) {
    final colors = context.colors;
    final isDataUrl = imageUrl.startsWith('data:');
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Image',
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (ctx, a1, a2, child) =>
          FadeTransition(opacity: a1, child: child),
      pageBuilder: (ctx, a1, a2) => Material(
        color: Colors.black,
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Center(
                  child: isDataUrl
                      ? Image.memory(
                          Uri.parse(imageUrl).data!.contentAsBytes(),
                          fit: BoxFit.contain,
                        )
                      : AppNetworkImage(url: imageUrl, fit: BoxFit.contain),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(ctx).padding.top + 12,
              left: 16,
              child: GestureDetector(
                onTap: () => Navigator.of(ctx).pop(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.borderSubtle,
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    color: colors.textPrimary,
                    size: 22,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Row(
        children: [
          const ZoeAvatarSmall(),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const _BouncingDots(),
          ),
        ],
      ),
    );
  }

  Widget _buildEscalationBanner(String ticketId) {
    final colors = context.colors;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.successGreen.withValues(alpha: 0.15),
              AppColors.successGreen.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.successGreen.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.successGreen.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.successGreen,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Support Ticket Created',
                    style: TextStyle(
                      color: AppColors.successGreen,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Ticket: $ticketId',
                    style: TextStyle(color: colors.textMuted, fontSize: 11),
                  ),
                  Text(
                    'Our support team will email you within 24 hours.\nCheck your inbox for updates.',
                    style: TextStyle(
                      color: colors.textMuted,
                      fontSize: 10,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.close_rounded,
                color: colors.textMuted,
                size: 16,
              ),
              onPressed: () =>
                  ref.read(zoeChatProvider.notifier).dismissEscalationBanner(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEscalateButton(bool isEscalating) {
    final colors = context.colors;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 15 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: SizedBox(
          width: double.infinity,
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: isEscalating
                  ? null
                  : () =>
                        ref.read(zoeChatProvider.notifier).escalateToSupport(),
              borderRadius: BorderRadius.circular(14),
              splashColor: AppColors.amber.withValues(alpha: 0.1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isEscalating
                        ? colors.borderSubtle
                        : AppColors.amber.withValues(alpha: 0.25),
                  ),
                  gradient: isEscalating
                      ? null
                      : LinearGradient(
                          colors: [
                            AppColors.amber.withValues(alpha: 0.08),
                            AppColors.amber.withValues(alpha: 0.03),
                          ],
                        ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isEscalating)
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.amber,
                        ),
                      )
                    else
                      Icon(
                        Icons.support_agent_rounded,
                        color: AppColors.amber.withValues(alpha: 0.8),
                        size: 18,
                      ),
                    const SizedBox(width: 10),
                    Text(
                      isEscalating
                          ? 'Creating Support Ticket...'
                          : 'Talk to a Human',
                      style: TextStyle(
                        color: isEscalating
                            ? colors.textMuted
                            : AppColors.amber,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea(bool isLoading) {
    final colors = context.colors;
    return AnimatedBuilder(
      animation: _inputGlowAnim,
      builder: (context, child) {
        return Container(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: MediaQuery.of(context).padding.bottom + 12,
          ),
          decoration: BoxDecoration(
            color: colors.scaffoldBg,
            border: Border(
              top: BorderSide(
                color: Color.lerp(
                  colors.borderSubtle,
                  AppColors.amber.withValues(alpha: 0.2),
                  _inputGlowAnim.value,
                )!,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_selectedImageBytes != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.amber.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          _selectedImageBytes!,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _selectedImageName ?? 'Image',
                          style: TextStyle(
                            color: colors.textMuted,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() {
                          _selectedImageBytes = null;
                          _selectedImageName = null;
                        }),
                        child: Icon(
                          Icons.close_rounded,
                          color: colors.textMuted,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              Row(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colors.surface),
                      ),
                      child: Icon(
                        Icons.image_outlined,
                        color: AppColors.amber.withValues(alpha: 0.6),
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: Color.lerp(
                          colors.surface,
                          colors.surface,
                          _inputGlowAnim.value,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Color.lerp(
                            colors.borderSubtle,
                            AppColors.amber.withValues(alpha: 0.15),
                            _inputGlowAnim.value,
                          )!,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.amber.withValues(
                              alpha: 0.05 * _inputGlowAnim.value,
                            ),
                            blurRadius: 12,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 14,
                          height: 1.5,
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: _sendMessage,
                        decoration: InputDecoration(
                          hintText: 'Ask Zoe anything...',
                          hintStyle: TextStyle(color: colors.textMuted),
                          filled: false,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          suffixIcon: AnimatedScale(
                            scale: _hasText ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOut,
                            child: AnimatedOpacity(
                              opacity: _hasText ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 150),
                              child: IconButton(
                                icon: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.amber,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.arrow_upward_rounded,
                                    color: context.colors.textOnAmber,
                                    size: 16,
                                  ),
                                ),
                                onPressed: () => _sendMessage(_controller.text),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// ANIMATED MESSAGE BUBBLE
// ---------------------------------------------------------------------------

class _AnimatedMessageBubble extends StatefulWidget {
  final Widget child;
  final bool isUser;

  const _AnimatedMessageBubble({
    required Key key,
    required this.child,
    required this.isUser,
  }) : super(key: key);

  @override
  State<_AnimatedMessageBubble> createState() => _AnimatedMessageBubbleState();
}

class _AnimatedMessageBubbleState extends State<_AnimatedMessageBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(position: _slideAnim, child: widget.child),
    );
  }
}

// ---------------------------------------------------------------------------
// DELAYED FADE-IN WRAPPER
// ---------------------------------------------------------------------------

class _DelayedFadeIn extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const _DelayedFadeIn({required this.child, required this.delay});

  @override
  State<_DelayedFadeIn> createState() => _DelayedFadeInState();
}

class _DelayedFadeInState extends State<_DelayedFadeIn>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    Timer(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(position: _slideAnim, child: widget.child),
    );
  }
}

// ---------------------------------------------------------------------------
// BOUNCING DOTS TYPING INDICATOR
// ---------------------------------------------------------------------------

class _BouncingDots extends StatefulWidget {
  const _BouncingDots();

  @override
  State<_BouncingDots> createState() => _BouncingDotsState();
}

class _BouncingDotsState extends State<_BouncingDots>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (index) {
      return AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      );
    });

    _animations = _controllers.map((controller) {
      return Tween<double>(
        begin: 0,
        end: -6,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));
    }).toList();

    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(3, (index) {
          return AnimatedBuilder(
            animation: _animations[index],
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _animations[index].value),
                child: Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: AppColors.amber.withValues(alpha: 0.7),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
