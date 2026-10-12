import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../l10n/context_extension.dart';

class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.hintText,
    this.keyboardType,
    this.obscureText = false,
    this.maxLines = 1,
    this.focusNode,
    this.onSubmitted,
    this.onChanged,
    this.errorText,
    this.enabled = true,
    this.suffixText,
  });

  final String label;
  final TextEditingController? controller;
  final String? hintText;
  final TextInputType? keyboardType;
  final bool obscureText;
  final int maxLines;
  final FocusNode? focusNode;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final bool enabled;

  /// Подпись справа в поле («дней после выгрузки», «₸»).
  final String? suffixText;

  /// Текст ошибки под полем (красным) — для required-полей, которые не
  /// заполнены при сабмите (задача 021: не молчать, а показать причину).
  final String? errorText;

   @override
  State<AppTextField> createState() => _AppTextFieldState();
}

/// Поле пароля — со «глазом»: показать / скрыть введённое.
class _AppTextFieldState extends State<AppTextField> {
  late bool _hidden = widget.obscureText;

 @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      keyboardType: widget.keyboardType,
      obscureText: widget.obscureText && _hidden,
      maxLines: widget.maxLines,
      onSubmitted: widget.onSubmitted,
      onChanged: widget.onChanged,
      enabled: widget.enabled,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hintText,
        errorText: widget.errorText,
        suffixText: widget.suffixText,
        suffixIcon: widget.obscureText
            ? IconButton(
                key: const Key('passwordVisibilityToggle'),
                tooltip: _hidden ? context.l10n.companyLoginShowPassword : context.l10n.companyLoginHidePassword,
                icon: Icon(_hidden ? LucideIcons.eye : LucideIcons.eyeOff),
                onPressed: () => setState(() => _hidden = !_hidden),
              )
            : null,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
