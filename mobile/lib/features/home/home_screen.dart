import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/state/app_state.dart';
import '../../core/widgets/gradient_scaffold.dart';
import '../../core/widgets/quick_action_chip.dart';
import '../../core/widgets/section_header.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.onOpenChat,
    required this.onOpenDiagnosis,
    required this.onOpenLibrary,
    required this.onOpenHistory,
  });

  final VoidCallback onOpenChat;
  final VoidCallback onOpenDiagnosis;
  final VoidCallback onOpenLibrary;
  final VoidCallback onOpenHistory;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return GradientScaffold(
      appBar: AppBar(
        title: const Text('RiceGPT AI'),
        actions: [
          IconButton(
            onPressed: () => state.refreshHistory(),
            icon: const Icon(Icons.sync),
          ),
        ],
      ),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF266B2F), Color(0xFF7A3FFC)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.rice_bowl, color: Colors.white, size: 36),
                const SizedBox(height: 14),
                Text(
                  'Ask rice questions, diagnose leaf problems, and save every result.',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Connected provider: ${state.selectedProvider.toUpperCase()}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _StatusChip(
                      label: state.backendHealthy ? 'Backend online' : 'Backend offline',
                      icon: state.backendHealthy ? Icons.cloud_done : Icons.cloud_off,
                      color: state.backendHealthy ? const Color(0xFFDFF6DE) : const Color(0xFFFFE0E0),
                    ),
                    _StatusChip(
                      label: '${state.diseases.length} library cards',
                      icon: Icons.menu_book_outlined,
                      color: const Color(0xFFF3ECFF),
                    ),
                    _StatusChip(
                      label: '${state.stressLabels.length} label classes',
                      icon: Icons.label_outline,
                      color: const Color(0xFFE3F4E4),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Quick Actions', subtitle: 'Start from one of the common rice workflows.'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              QuickActionChip(label: 'Ask AI', icon: Icons.chat, onTap: onOpenChat),
              QuickActionChip(label: 'Diagnose Leaf', icon: Icons.image_search, onTap: onOpenDiagnosis),
              QuickActionChip(label: 'Disease Library', icon: Icons.menu_book, onTap: onOpenLibrary),
              QuickActionChip(label: 'History', icon: Icons.history, onTap: onOpenHistory),
            ],
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Suggested Questions', subtitle: 'Tap a chip to jump into an answer.'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _PromptChip(text: 'Brown Spot', onTap: () => _openPrompt(context, onOpenChat, 'Brown Spot disease')),
              _PromptChip(text: 'Blast Disease', onTap: () => _openPrompt(context, onOpenChat, 'Explain blast disease in rice.')),
              _PromptChip(text: 'Bacterial Blight', onTap: () => _openPrompt(context, onOpenChat, 'Explain bacterial blight in rice.')),
              _PromptChip(text: 'Fertilizer', onTap: () => _openPrompt(context, onOpenChat, 'Best fertilizer for paddy.')),
              _PromptChip(text: 'Water Management', onTap: () => _openPrompt(context, onOpenChat, 'How much water does rice need?')),
              _PromptChip(text: 'Pest Control', onTap: () => _openPrompt(context, onOpenChat, 'How do I control rice pests?')),
            ],
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Recent Chats', subtitle: 'Your latest rice conversations stay here.'),
          const SizedBox(height: 12),
          if (state.chatHistory.isEmpty)
            const _EmptyState(
              icon: Icons.chat_bubble_outline,
              title: 'No chats yet',
              subtitle: 'Ask RiceGPT about yellow leaves, diseases, fertilizer, or irrigation.',
            )
          else
            ...state.chatHistory.take(3).map(
                  (item) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.chat),
                      title: Text(item.query, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(item.answer, maxLines: 2, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.icon, required this.color});

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _PromptChip extends StatelessWidget {
  const _PromptChip({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(label: Text(text), onPressed: onTap);
  }
}

void _openPrompt(BuildContext context, VoidCallback openChat, String prompt) {
  context.read<AppState>().setDraftPrompt(prompt);
  openChat();
}


class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Icon(icon, size: 34, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 10),
          Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(subtitle, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
