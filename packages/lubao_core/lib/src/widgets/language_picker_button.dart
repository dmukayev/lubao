import 'package:flutter/material.dart';

/// Плашка выбора языка в углу экрана (экран первого запуска, экраны входа —
/// decisions.md «Смена языка»). Параметризован кодом языка и колбэком,
/// чтобы не зависеть от Riverpod-провайдера приложения — переиспользуется
/// и до входа (когда ещё нет сессии для сохранения выбора на сервере).
class LanguagePickerButton extends StatelessWidget {
  const LanguagePickerButton({super.key, required this.languageCode, required this.onChanged});

  final String languageCode;
  final ValueChanged<String> onChanged;

  static const _labels = <String, String>{
    'kk': 'Қазақша',
    'ru': 'Русский',
    'zh': '中文',
    'en': 'English',
  };

  static const _shortCodes = <String, String>{
    'kk': 'KZ',
    'ru': 'RU',
    'zh': '中文',
    'en': 'EN',
  };

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      initialValue: languageCode,
      onSelected: onChanged,
      itemBuilder: (context) => _labels.entries
          .map((e) => PopupMenuItem(value: e.key, child: Text(e.value)))
          .toList(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          _shortCodes[languageCode] ?? _shortCodes['ru']!,
          style: Theme.of(context).textTheme.labelLarge,
        ),
      ),
    );
  }
}
