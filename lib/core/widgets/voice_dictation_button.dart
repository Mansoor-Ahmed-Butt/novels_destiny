import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/theme/app_theme.dart';
import '../services/speech_recognition_service.dart';

class VoiceDictationButton extends StatefulWidget {
  final TextEditingController controller;
  final String? label;
  final String? tooltip;
  final bool showLanguageSelector;
  final DictationLanguage initialLanguage;
  final ValueChanged<DictationLanguage>? onLanguageChanged;
  final VoidCallback? onTextUpdated;

  const VoiceDictationButton({
    super.key,
    required this.controller,
    this.label,
    this.tooltip,
    this.showLanguageSelector = true,
    this.initialLanguage = DictationLanguage.english,
    this.onLanguageChanged,
    this.onTextUpdated,
  });

  @override
  State<VoiceDictationButton> createState() => _VoiceDictationButtonState();
}

class _VoiceDictationButtonState extends State<VoiceDictationButton>
    with SingleTickerProviderStateMixin {
  final SpeechRecognitionService _speechService = SpeechRecognitionService();
  bool _isListening = false;
  late DictationLanguage _selectedLanguage;

  String _baseTextBeforeSession = '';
  String _confirmedSpeechInSession = '';

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _selectedLanguage = widget.initialLanguage;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _speechService.setStatusListener((status) {
      if (!mounted) return;
      if (status == 'notListening' || status == 'done') {
        if (_isListening) {
          setState(() => _isListening = false);
        }
      }
    });
  }

  @override
  void dispose() {
    if (_isListening) {
      _speechService.stopListening();
    }
    _speechService.setStatusListener(null);
    _pulseController.dispose();
    super.dispose();
  }

  void _onSelectLanguage(DictationLanguage lang) {
    if (_selectedLanguage == lang) return;
    setState(() {
      _selectedLanguage = lang;
    });
    widget.onLanguageChanged?.call(lang);

    // If currently listening, smoothly restart with the newly selected language
    if (_isListening) {
      _restartListeningInNewLanguage(lang);
    }
  }

  Future<void> _restartListeningInNewLanguage(DictationLanguage lang) async {
    await _speechService.stopListening();
    _baseTextBeforeSession = widget.controller.text;
    _confirmedSpeechInSession = '';

    final result = await _speechService.startListeningDetailed(
      language: lang,
      onResult: (words, isFinal) => _handleSpeechResult(words, isFinal),
    );

    if (!result.success) {
      setState(() => _isListening = false);
      _showVoiceUnavailableNotice(result);
    }
  }

  void _handleSpeechResult(String words, bool isFinal) {
    if (!mounted || words.trim().isEmpty) return;

    if (isFinal) {
      _confirmedSpeechInSession = _confirmedSpeechInSession.isEmpty
          ? words.trim()
          : '$_confirmedSpeechInSession ${words.trim()}';
      final fullText = _combine(
        _baseTextBeforeSession,
        _confirmedSpeechInSession,
      );
      widget.controller.text = fullText;
      widget.controller.selection = TextSelection.fromPosition(
        TextPosition(offset: fullText.length),
      );
    } else {
      final currentPhrase = _confirmedSpeechInSession.isEmpty
          ? words.trim()
          : '$_confirmedSpeechInSession ${words.trim()}';
      final fullText = _combine(_baseTextBeforeSession, currentPhrase);
      widget.controller.text = fullText;
      widget.controller.selection = TextSelection.fromPosition(
        TextPosition(offset: fullText.length),
      );
    }

    widget.onTextUpdated?.call();
  }

  String _combine(String base, String added) {
    if (base.trim().isEmpty) return added;
    if (added.trim().isEmpty) return base;
    if (base.endsWith(' ') || base.endsWith('\n')) {
      return '$base$added';
    }
    return '$base $added';
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _speechService.stopListening();
      if (mounted) {
        setState(() => _isListening = false);
      }
      return;
    }

    _baseTextBeforeSession = widget.controller.text;
    _confirmedSpeechInSession = '';

    final result = await _speechService.startListeningDetailed(
      language: _selectedLanguage,
      onResult: (words, isFinal) => _handleSpeechResult(words, isFinal),
    );

    if (result.success) {
      if (mounted) {
        setState(() => _isListening = true);
      }
    } else {
      _showVoiceUnavailableNotice(result);
    }
  }

  void _showVoiceUnavailableNotice(SpeechStartResult result) {
    if (!mounted) return;

    if (_speechService.isWindows && _selectedLanguage == DictationLanguage.urdu) {
      // Friendly dialog explaining Urdu voice recognition on Windows
      Get.defaultDialog(
        title: 'voice_unavailable_title'.tr,
        titleStyle: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700),
        middleText: result.detailedHelp ??
            'voice_windows_urdu_note'.tr,
        middleTextStyle: AppTextStyles.bodyMedium,
        backgroundColor: AppColors.background,
        radius: AppRadii.m,
        textConfirm: 'Switch to English',
        confirmTextColor: AppColors.textInverse,
        buttonColor: AppColors.primary,
        onConfirm: () {
          Get.back();
          _onSelectLanguage(DictationLanguage.english);
        },
        textCancel: 'close'.tr,
        cancelTextColor: AppColors.textSecondary,
      );
    } else {
      Get.snackbar(
        'voice_unavailable_title'.tr,
        result.message ?? 'voice_unavailable_msg'.tr,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.surface,
        colorText: AppColors.textPrimary,
        duration: const Duration(seconds: 5),
      );
    }
  }

  Widget _buildLanguageSelector() {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLanguageChip(DictationLanguage.english, 'EN', 'English'),
          const SizedBox(width: 2),
          _buildLanguageChip(DictationLanguage.urdu, 'اردو', 'Urdu'),
        ],
      ),
    );
  }

  Widget _buildLanguageChip(
    DictationLanguage lang,
    String label,
    String tooltip,
  ) {
    final isSelected = _selectedLanguage == lang;
    final isSupportedOnWindows =
        !_speechService.isWindows || lang == DictationLanguage.english;

    return Tooltip(
      message: isSupportedOnWindows
          ? (lang == DictationLanguage.urdu
              ? 'write_in_urdu'.tr
              : 'write_in_english'.tr)
          : 'Urdu voice input is available on mobile (Android/iOS)',
      child: InkWell(
        onTap: () => _onSelectLanguage(lang),
        borderRadius: BorderRadius.circular(AppRadii.pill),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadii.pill),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: isSelected
                  ? AppColors.textInverse
                  : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              fontSize: lang == DictationLanguage.urdu ? 11.5 : 10.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVoiceButton() {
    final activeColor = AppColors.error;
    final idleColor = AppColors.primary;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return InkWell(
          onTap: _toggleListening,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _isListening
                  ? activeColor.withValues(alpha: 0.15)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadii.pill),
              border: Border.all(
                color: _isListening ? activeColor : AppColors.cardBorder,
                width: _isListening ? 1.5 : 1.0,
              ),
              boxShadow: _isListening
                  ? [
                      BoxShadow(
                        color: activeColor.withValues(alpha: 0.35),
                        blurRadius: 10 * _pulseAnimation.value,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.scale(
                  scale: _isListening ? _pulseAnimation.value : 1.0,
                  child: Icon(
                    _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                    size: 16,
                    color: _isListening ? activeColor : idleColor,
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    _isListening
                        ? '${'listen_voice'.tr} (${_selectedLanguage.nativeName})'
                        : (widget.label != null
                            ? '${widget.label!} (${_selectedLanguage.nativeName})'
                            : '${'voice_input'.tr} (${_selectedLanguage.nativeName})'),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: _isListening ? activeColor : AppColors.textPrimary,
                      fontWeight: _isListening
                          ? FontWeight.w700
                          : FontWeight.w600,
                    ),
                  ),
                ),
                if (_isListening) ...[
                  const SizedBox(width: 6),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: activeColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.showLanguageSelector) {
      return Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppSpacing.s,
        runSpacing: AppSpacing.xs,
        children: [_buildLanguageSelector(), _buildVoiceButton()],
      );
    }

    return _buildVoiceButton();
  }
}
