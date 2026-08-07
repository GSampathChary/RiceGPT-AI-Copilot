import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/state/app_state.dart';
import '../../core/models/chat_models.dart';
import '../../core/models/history_item.dart';
import '../../core/widgets/gradient_scaffold.dart';
import '../../core/widgets/section_header.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return DefaultTabController(
      length: 2,
      child: GradientScaffold(
        appBar: AppBar(
          title: const Text('History'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Chats'),
              Tab(text: 'Diagnoses'),
            ],
          ),
          actions: [
            IconButton(
              onPressed: state.clearAllHistory,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
        child: TabBarView(
          children: [
            _ChatHistoryList(items: state.chatHistory, onDelete: state.deleteChat),
            _DiagnosisHistoryList(items: state.diagnosisHistory, onDelete: state.deleteDiagnosis),
          ],
        ),
      ),
    );
  }
}

class _ChatHistoryList extends StatelessWidget {
  const _ChatHistoryList({required this.items, required this.onDelete});

  final List<ChatThread> items;
  final Future<void> Function(String id) onDelete;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _HistoryEmpty(
        title: 'No chat history',
        subtitle: 'Your rice conversations will appear here.',
        icon: Icons.chat_bubble_outline,
      );
    }
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SectionHeader(title: 'Saved chat sessions', subtitle: 'These are stored locally and mirrored to the backend when available.'),
        const SizedBox(height: 12),
        ...items.map(
          (item) => Dismissible(
            key: ValueKey(item.id),
            background: Container(
              color: Colors.redAccent,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 16),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            direction: DismissDirection.endToStart,
            onDismissed: (_) => onDelete(item.id),
            child: Card(
              child: ListTile(
                leading: const Icon(Icons.chat),
                title: Text(item.query, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(item.answer, maxLines: 2, overflow: TextOverflow.ellipsis),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DiagnosisHistoryList extends StatelessWidget {
  const _DiagnosisHistoryList({required this.items, required this.onDelete});

  final List<DiagnosisItem> items;
  final Future<void> Function(String id) onDelete;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _HistoryEmpty(
        title: 'No diagnosis history',
        subtitle: 'Upload a rice leaf image to save a prediction here.',
        icon: Icons.image_search_outlined,
      );
    }
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SectionHeader(title: 'Saved diagnoses', subtitle: 'Tap and swipe to manage previous predictions.'),
        const SizedBox(height: 12),
        ...items.map(
          (item) => Dismissible(
            key: ValueKey(item.id),
            background: Container(
              color: Colors.redAccent,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 16),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            direction: DismissDirection.endToStart,
            onDismissed: (_) => onDelete(item.id),
            child: Card(
              child: ListTile(
                leading: const Icon(Icons.image_search),
                title: Text(item.disease, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text('${(item.confidence * 100).toStringAsFixed(1)}% confidence'),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HistoryEmpty extends StatelessWidget {
  const _HistoryEmpty({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 44, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(subtitle, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
