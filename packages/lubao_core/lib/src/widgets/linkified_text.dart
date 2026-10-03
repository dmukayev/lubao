import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

final RegExp _urlPattern = RegExp(r'https?://[^\s]+');

/// Текст, в котором ссылки (http/https) кликабельны и открываются во внешнем
/// приложении/браузере — не важно, Google Maps это, Amap, Baidu или что угодно
/// ещё, вставленное вручную.
class LinkifiedText extends StatelessWidget {
  const LinkifiedText(this.text, {super.key, this.style, this.linkStyle});

  final String text;
  final TextStyle? style;
  final TextStyle? linkStyle;

  @override
  Widget build(BuildContext context) {
    final baseStyle = style ?? DefaultTextStyle.of(context).style;
    final effectiveLinkStyle = linkStyle ??
        baseStyle.copyWith(color: Theme.of(context).colorScheme.primary, decoration: TextDecoration.underline);

    final matches = _urlPattern.allMatches(text);
    if (matches.isEmpty) {
      return Text(text, style: baseStyle);
    }

    final spans = <InlineSpan>[];
    var lastEnd = 0;
    for (final match in matches) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, match.start)));
      }
      final url = match.group(0)!;
      spans.add(TextSpan(
        text: url,
        style: effectiveLinkStyle,
        recognizer: TapGestureRecognizer()..onTap = () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      ));
      lastEnd = match.end;
    }
    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd)));
    }

    return Text.rich(TextSpan(style: baseStyle, children: spans));
  }
}
