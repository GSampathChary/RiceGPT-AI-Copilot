import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';

import '../../core/state/app_state.dart';
import '../../core/widgets/gradient_scaffold.dart';
import '../../core/widgets/section_header.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final controller = TextEditingController();
  final scrollController = ScrollController();

  @override
  void dispose() {
    controller.dispose();
    scrollController.dispose();
    super.dispose();
  }

  Future<void> _send(AppState state) async {
    final message = controller.text;
    controller.clear();
    await state.sendMessage(message);
    await Future<void>.delayed(const Duration(milliseconds: 150));
    if (scrollController.hasClients) {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final messages = state.currentConversation;
    if (state.draftPrompt != null && controller.text.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        controller.text = state.draftPrompt ?? '';
        state.consumeDraftPrompt();
      });
    }

    return GradientScaffold(
      appBar: AppBar(
        title: const Text('Ask AI'),
        actions: [
          IconButton(
            onPressed: state.clearConversation,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
            child: const SectionHeader(
              title: 'RiceGPT Chat',
              subtitle: 'Ask anything about rice disease, irrigation, fertilizer, or pest control.',
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _SuggestionChip(text: 'Why are my rice leaves yellow?', onTap: () => controller.text = 'Why are my rice leaves yellow?'),
                _SuggestionChip(text: 'Explain brown spot disease', onTap: () => controller.text = 'Explain brown spot disease.'),
                _SuggestionChip(text: 'Best fertilizer for paddy', onTap: () => controller.text = 'Best fertilizer for paddy.'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              itemCount: messages.length + (state.isBusy ? 1 : 0),
              itemBuilder: (context, index) {
                if (state.isBusy && index == messages.length) {
                  return const _TypingBubble();
                }
                final message = messages[index];
                final isUser = message.role == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    constraints: const BoxConstraints(maxWidth: 560),
                    decoration: BoxDecoration(
                      color: isUser
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment:
                          isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        Text(
                          isUser ? 'You' : 'RiceGPT',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: isUser ? Colors.white70 : Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 8),
                        isUser
                            ? Text(message.content, style: const TextStyle(color: Colors.white, height: 1.4))
                            : MarkdownBody(
                                data: message.content,
                                styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                                  p: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
                                ),
                              ),
                        if (!isUser) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextButton.icon(
                                onPressed: () => controller.text = 'Regenerate: ${messages.lastWhere((item) => item.role == "user").content}',
                                icon: const Icon(Icons.refresh, size: 18),
                                label: const Text('Regenerate'),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        maxLines: 4,
                        minLines: 1,
                        textInputAction: TextInputAction.send,
                        decoration: const InputDecoration(
                          hintText: 'Ask about rice crops, leaves, fertilizer, or disease...',
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => _send(state),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: state.isBusy ? null : () => _send(state),
                      child: const Icon(Icons.send),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(label: Text(text), onPressed: onTap);
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: 12),
            Text('Thinking...'),
          ],
        ),
      ),
    );
  }
}
