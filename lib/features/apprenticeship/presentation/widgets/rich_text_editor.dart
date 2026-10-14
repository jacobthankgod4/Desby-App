import 'package:flutter/material.dart';
import 'package:fleather/fleather.dart';
import 'package:desby_app/theme/colors.dart';

class RichTextEditor extends StatefulWidget {
  final FleatherController controller;
  final String hintText;
  final int maxLines;
  final double minHeight;

  const RichTextEditor({
    super.key,
    required this.controller,
    this.hintText = 'Start writing...',
    this.maxLines = 20,
    this.minHeight = 300,
  });

  @override
  State<RichTextEditor> createState() => _RichTextEditorState();
}

class _RichTextEditorState extends State<RichTextEditor> {
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return FleatherTheme(
      data: _darkThemeData(colors),
      child: Container(
        height: widget.minHeight + 48,
        decoration: BoxDecoration(
          color: colors.containerFill,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.borderDefault),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(
            iconTheme: const IconThemeData(color: AppColors.amber, size: 20),
            iconButtonTheme: IconButtonThemeData(
              style: IconButton.styleFrom(
                foregroundColor: AppColors.amber,
                backgroundColor: Colors.transparent,
                hoverColor: AppColors.amber.withValues(alpha: 0.1),
                focusColor: AppColors.amber.withValues(alpha: 0.1),
                padding: const EdgeInsets.all(6),
                minimumSize: const Size(32, 32),
              ),
            ),
            checkboxTheme: CheckboxThemeData(
              fillColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected))
                  return AppColors.amber;
                return colors.textMuted;
              }),
              checkColor: WidgetStateProperty.all(AppColors.darkNavy),
              side: BorderSide(color: colors.borderSubtle, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ),
          child: Column(
            children: [
              FleatherToolbar.basic(
                controller: widget.controller,
                hideBackgroundColor: true,
                hideForegroundColor: true,
                hideAlignment: true,
                hideDirection: true,
                hideInlineCode: false,
                hideCodeBlock: false,
                hideQuote: false,
                hideLink: false,
                hideHorizontalRule: false,
                hideListNumbers: false,
                hideListBullets: false,
                hideListChecks: false,
                hideIndentation: false,
                hideUndoRedo: false,
                hideHeadingStyle: false,
              ),
              Container(height: 1, color: colors.divider),
              Expanded(
                child: FleatherEditor(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  maxContentWidth: 800,
                  expands: false,
                  showCursor: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  FleatherThemeData _darkThemeData(DesbyThemeColors colors) {
    return FleatherThemeData(
      bold: TextStyle(fontWeight: FontWeight.bold, color: colors.textPrimary),
      italic: TextStyle(fontStyle: FontStyle.italic, color: colors.textPrimary),
      underline: TextStyle(
        decoration: TextDecoration.underline,
        color: colors.textPrimary,
      ),
      strikethrough: TextStyle(
        decoration: TextDecoration.lineThrough,
        color: colors.textPrimary,
      ),
      link: TextStyle(
        color: AppColors.amber,
        decoration: TextDecoration.underline,
      ),
      paragraph: TextBlockTheme(
        style: TextStyle(
          color: colors.textSecondary,
          fontSize: 14,
          height: 1.6,
        ),
        spacing: const VerticalSpacing(top: 4, bottom: 4),
        lineSpacing: const VerticalSpacing(top: 3, bottom: 0),
        decoration: const BoxDecoration(),
      ),
      heading1: TextBlockTheme(
        style: TextStyle(
          color: AppColors.amber,
          fontSize: 24,
          fontWeight: FontWeight.w900,
          height: 1.3,
        ),
        spacing: const VerticalSpacing(top: 16, bottom: 8),
        lineSpacing: const VerticalSpacing(top: 3, bottom: 0),
        decoration: const BoxDecoration(),
      ),
      heading2: TextBlockTheme(
        style: TextStyle(
          color: AppColors.amber,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          height: 1.3,
        ),
        spacing: const VerticalSpacing(top: 12, bottom: 6),
        lineSpacing: const VerticalSpacing(top: 3, bottom: 0),
        decoration: const BoxDecoration(),
      ),
      heading3: TextBlockTheme(
        style: TextStyle(
          color: AppColors.amber,
          fontSize: 17,
          fontWeight: FontWeight.w700,
          height: 1.3,
        ),
        spacing: const VerticalSpacing(top: 10, bottom: 4),
        lineSpacing: const VerticalSpacing(top: 3, bottom: 0),
        decoration: const BoxDecoration(),
      ),
      heading4: TextBlockTheme(
        style: TextStyle(
          color: AppColors.amber,
          fontSize: 15,
          fontWeight: FontWeight.w700,
          height: 1.3,
        ),
        spacing: const VerticalSpacing(top: 8, bottom: 4),
        lineSpacing: const VerticalSpacing(top: 3, bottom: 0),
        decoration: const BoxDecoration(),
      ),
      heading5: TextBlockTheme(
        style: TextStyle(
          color: AppColors.amber,
          fontSize: 14,
          fontWeight: FontWeight.w700,
          height: 1.3,
        ),
        spacing: const VerticalSpacing(top: 8, bottom: 4),
        lineSpacing: const VerticalSpacing(top: 3, bottom: 0),
        decoration: const BoxDecoration(),
      ),
      heading6: TextBlockTheme(
        style: TextStyle(
          color: AppColors.amber,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          height: 1.3,
        ),
        spacing: const VerticalSpacing(top: 8, bottom: 4),
        lineSpacing: const VerticalSpacing(top: 3, bottom: 0),
        decoration: const BoxDecoration(),
      ),
      lists: TextBlockTheme(
        style: TextStyle(
          color: colors.textSecondary,
          fontSize: 14,
          height: 1.6,
        ),
        spacing: const VerticalSpacing(top: 4, bottom: 4),
        lineSpacing: const VerticalSpacing(top: 3, bottom: 0),
        decoration: const BoxDecoration(),
      ),
      quote: TextBlockTheme(
        style: TextStyle(
          color: colors.textMuted,
          fontSize: 14,
          fontStyle: FontStyle.italic,
          height: 1.6,
        ),
        spacing: const VerticalSpacing(top: 8, bottom: 8),
        lineSpacing: const VerticalSpacing(top: 3, bottom: 0),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: AppColors.amber.withValues(alpha: 0.4),
              width: 3,
            ),
          ),
        ),
      ),
      code: TextBlockTheme(
        style: TextStyle(
          color: AppColors.amber.withValues(alpha: 0.8),
          fontFamily: 'monospace',
          fontSize: 13,
          height: 1.5,
        ),
        spacing: const VerticalSpacing(top: 8, bottom: 8),
        lineSpacing: const VerticalSpacing(top: 0, bottom: 0),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(6),
        ),
      ),
      inlineCode: InlineCodeThemeData(
        style: TextStyle(
          color: AppColors.amber.withValues(alpha: 0.8),
          fontFamily: 'monospace',
          fontSize: 13,
        ),
        backgroundColor: colors.inputFill,
      ),
      horizontalRule: HorizontalRuleThemeData(
        height: 1,
        thickness: 1,
        color: colors.divider,
      ),
    );
  }
}
