import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/state/app_state.dart';
import '../../core/widgets/gradient_scaffold.dart';
import '../../core/widgets/section_header.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final items = state.diseases.where((disease) {
      if (query.trim().isEmpty) return true;
      final q = query.toLowerCase();
      return disease.name.toLowerCase().contains(q) ||
          disease.symptoms.toLowerCase().contains(q) ||
          disease.cause.toLowerCase().contains(q);
    }).toList();

    return GradientScaffold(
      appBar: AppBar(title: const Text('Disease Library')),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SectionHeader(
            title: 'Search rice diseases',
            subtitle: 'Search by symptoms, disease name, or likely cause.',
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search diseases...',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => setState(() => query = value),
          ),
          const SizedBox(height: 16),
          ...items.map(
            (disease) => Card(
              child: ExpansionTile(
                title: Text(disease.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text(disease.symptoms, maxLines: 2, overflow: TextOverflow.ellipsis),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  _InfoLine(label: 'Cause', value: disease.cause),
                  _InfoLine(label: 'Treatment', value: disease.treatment),
                  _InfoLine(label: 'Prevention', value: disease.prevention),
                  _InfoLine(label: 'Fungicide', value: disease.recommendedFungicide),
                  _InfoLine(label: 'Farmer Tips', value: disease.farmerTips),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const SectionHeader(
            title: 'Model Stress Labels',
            subtitle: 'These are the exact classes your trained model can predict.',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: state.stressLabels
                .where((label) {
                  if (query.trim().isEmpty) return true;
                  final q = query.toLowerCase();
                  return label.label.toLowerCase().contains(q) ||
                      label.displayName.toLowerCase().contains(q) ||
                      label.category.toLowerCase().contains(q);
                })
                .map(
                  (label) => Chip(
                    avatar: CircleAvatar(
                      radius: 9,
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      child: Text(label.category.isNotEmpty ? label.category.substring(0, 1) : '?', style: const TextStyle(fontSize: 10)),
                    ),
                    label: Text(label.displayName),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(value),
        ],
      ),
    );
  }
}
