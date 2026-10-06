import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app.dart';

void main() {
  // Чистые адреса без «#» (задача 042, п.2): https://<хост>/invite/<токен>
  // открывает экран принятия приглашения на вебе; на мобильных — no-op.
  usePathUrlStrategy();
  runApp(const ProviderScope(child: LubaoApp()));
}
