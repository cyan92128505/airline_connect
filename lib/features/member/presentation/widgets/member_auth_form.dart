import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:app/features/shared/presentation/theme/app_colors.dart';
import 'package:gap/gap.dart';

/// Form widget for member authentication
class MemberAuthForm extends HookWidget {
  static const Key memberNumberFieldKey = Key('member_number_field');
  static const Key nameSuffixFieldKey = Key('name_suffix_field');
  static const Key submitButtonKey = Key('submit_button');

  final bool isLoading;
  final Function(String memberNumber, String nameSuffix) onSubmit;

  const MemberAuthForm({
    super.key,
    required this.isLoading,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final memberNumberController = useTextEditingController();
    final nameSuffixController = useTextEditingController();
    final memberNumberFocus = useFocusNode();
    final nameSuffixFocus = useFocusNode();

    // Auto-fill demo data for testing
    useEffect(() {
      // Pre-fill demo credentials for easier testing
      memberNumberController.text = 'AA123456';
      nameSuffixController.text = 'Aoma';
      return null;
    }, []);

    void handleSubmit() {
      if (isLoading) return;

      if (formKey.currentState?.validate() ?? false) {
        FocusScope.of(context).unfocus();
        onSubmit(
          memberNumberController.text.trim(),
          nameSuffixController.text.trim(),
        );
      }
    }

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Member number field
          _buildMemberNumberField(
            controller: memberNumberController,
            focusNode: memberNumberFocus,
            nextFocus: nameSuffixFocus,
          ),

          const Gap(20),

          // Name suffix field
          _buildNameSuffixField(
            controller: nameSuffixController,
            focusNode: nameSuffixFocus,
            onSubmitted: (_) => handleSubmit(),
          ),

          const Gap(32),

          // Submit button
          ElevatedButton(
            key: submitButtonKey,
            onPressed: isLoading ? null : handleSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: isLoading
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white.withAlpha(204),
                          ),
                        ),
                      ),
                      const Gap(12),
                      const Text('驗證中...'),
                    ],
                  )
                : const Text(
                    '登入驗證',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
    );
  }

  /// Build member number input field
  Widget _buildMemberNumberField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required FocusNode nextFocus,
  }) {
    return TextFormField(
      key: memberNumberFieldKey,
      controller: controller,
      focusNode: focusNode,
      decoration: InputDecoration(
        labelText: '會員號碼',
        hintText: '請輸入會員號碼',
        prefixIcon: Icon(Icons.person_outline, color: AppColors.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.error),
        ),
        filled: true,
        fillColor: AppColors.surface,
      ),
      textInputAction: TextInputAction.next,
      textCapitalization: TextCapitalization.characters,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
        LengthLimitingTextInputFormatter(8),
      ],
      validator: (value) {
        if (value?.trim().isEmpty ?? true) {
          return '請輸入會員號碼';
        }

        final trimmed = value!.trim();
        if (trimmed.length < 6) {
          return '會員號碼長度不足';
        }

        // Basic format validation: 2 letters + numbers
        if (!RegExp(r'^[A-Z]{2}[0-9]+$').hasMatch(trimmed)) {
          return '會員號碼格式錯誤（例如：AA123456）';
        }

        return null;
      },
      onFieldSubmitted: (_) {
        FocusScope.of(focusNode.context!).requestFocus(nextFocus);
      },
    );
  }

  /// Build name suffix input field
  Widget _buildNameSuffixField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required Function(String) onSubmitted,
  }) {
    return TextFormField(
      key: nameSuffixFieldKey,
      controller: controller,
      focusNode: focusNode,
      decoration: InputDecoration(
        labelText: '姓名後四碼',
        hintText: '請輸入姓名後四碼',
        prefixIcon: Icon(Icons.security_outlined, color: AppColors.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.error),
        ),
        filled: true,
        fillColor: AppColors.surface,
        helperText: '用於身份驗證的安全碼',
        helperStyle: TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
      textInputAction: TextInputAction.done,
      maxLength: 4,
      inputFormatters: [LengthLimitingTextInputFormatter(4)],
      validator: (value) {
        if (value?.trim().isEmpty ?? true) {
          return '請輸入姓名後四碼';
        }

        final trimmed = value!.trim();
        if (trimmed.length != 4) {
          return '姓名後四碼必須為4個字元';
        }

        return null;
      },
      onFieldSubmitted: onSubmitted,
    );
  }
}
