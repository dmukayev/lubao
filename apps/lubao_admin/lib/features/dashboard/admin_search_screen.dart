import 'package:flutter/material.dart';
import 'package:lubao_core/lubao_core.dart';

import 'admin_search_bar.dart';

/// Отдельный экран поиска на телефоне (задача 030, п.2) — на компьютере
/// тот же поиск уже встроен в сводку сверху ([AdminSearchBar]), на
/// телефоне внизу своя вкладка «Поиск», т.к. до сводки не всегда
/// удобно скроллить.
class AdminSearchScreen extends StatelessWidget {
  const AdminSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(t.adminNavSearch)),
      body: const Padding(padding: EdgeInsets.all(16), child: AdminSearchBar()),
    );
  }
}
