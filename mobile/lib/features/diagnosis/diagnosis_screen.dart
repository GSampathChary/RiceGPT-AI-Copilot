import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/services/api_client.dart';
import '../../core/state/app_state.dart';
import '../../core/widgets/gradient_scaffold.dart';
import '../../core/widgets/section_header.dart';

class DiagnosisScreen extends StatefulWidget {
  const DiagnosisScreen({super.key});

  @override
  State<DiagnosisScreen> createState() => _DiagnosisScreenState();
}

class _DiagnosisScreenState extends State<DiagnosisScreen> {
  File? image;
  int _imageVersion = 0;

  Future<void> _pick(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 85);
    if (picked != null) {
      setState(() {
        image = File(picked.path);
        _imageVersion += 1;
      });
      if (mounted) {
        context.read<AppState>().clearLatestDiagnosis();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return GradientScaffold(
      appBar: AppBar(title: const Text('Diagnose Leaf')),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SectionHeader(
            title: 'Image-Based Disease Detection',
            subtitle: 'Upload a rice leaf photo and let the backend predict the disease, then explain it clearly.',
          ),
          const SizedBox(height: 16),
          _ImageCard(
            image: image,
            imageVersion: _imageVersion,
            onCamera: () => _pick(ImageSource.camera),
            onGallery: () => _pick(ImageSource.gallery),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: image == null || state.isDiagnosing ? null : () => context.read<AppState>().diagnoseImage(image!),
            icon: state.isDiagnosing
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.auto_awesome),
            label: Text(state.isDiagnosing ? 'Analyzing...' : 'Predict Disease'),
          ),
          const SizedBox(height: 20),
          if (state.latestDiagnosis != null) ...[
            _DiagnosisResultCard(
              disease: state.latestDiagnosis!.disease,
              confidence: state.latestDiagnosis!.confidence,
              provider: state.latestDiagnosis!.provider,
            ),
            const SizedBox(height: 12),
            _ExplanationCard(result: state.latestDiagnosis!),
            const SizedBox(height: 12),
            _SummaryCard(
              result: state.latestDiagnosis!,
              onCopy: () => _copySummary(context, state.latestDiagnosis!),
            ),
          ],
          const SizedBox(height: 20),
          if (state.diseases.isNotEmpty)
            const SectionHeader(title: 'Disease Library', subtitle: 'Common rice disease references loaded in the app.'),
          const SizedBox(height: 8),
          ...state.diseases.take(3).map(
                (disease) => Card(
                  child: ExpansionTile(
                    title: Text(disease.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(disease.symptoms, maxLines: 2, overflow: TextOverflow.ellipsis),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: [
                      _DetailRow(title: 'Cause', value: disease.cause),
                      _DetailRow(title: 'Treatment', value: disease.treatment),
                      _DetailRow(title: 'Prevention', value: disease.prevention),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

void _copySummary(BuildContext context, DiagnosisResult result) {
  final summary = [
    'RiceGPT Diagnosis Summary',
    'Disease: ${result.disease}',
    'Confidence: ${(result.confidence * 100).toStringAsFixed(1)}%',
    'Provider: ${result.provider.toUpperCase()}',
    'Symptoms: ${result.explanation.symptoms}',
    'Treatment: ${result.explanation.treatment}',
    'Prevention: ${result.explanation.prevention}',
  ].join('\n');

  Clipboard.setData(ClipboardData(text: summary));
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Diagnosis summary copied to clipboard')),
  );
}

class _ImageCard extends StatelessWidget {
  const _ImageCard({required this.image, required this.imageVersion, required this.onCamera, required this.onGallery});

  final File? image;
  final int imageVersion;
  final VoidCallback onCamera;
  final VoidCallback onGallery;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          Container(
            key: ValueKey(imageVersion),
            height: 220,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(24),
              image: image != null
                  ? DecorationImage(image: FileImage(image!), fit: BoxFit.cover)
                  : null,
            ),
            child: image == null
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.image_search, size: 44),
                        SizedBox(height: 10),
                        Text('No leaf image selected yet'),
                      ],
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onCamera,
                  icon: const Icon(Icons.photo_camera),
                  label: const Text('Camera'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onGallery,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Gallery'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DiagnosisResultCard extends StatelessWidget {
  const _DiagnosisResultCard({required this.disease, required this.confidence, required this.provider});

  final String disease;
  final double confidence;
  final String provider;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Latest Result', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(disease, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: confidence.clamp(0, 1)),
            const SizedBox(height: 8),
            Text('${(confidence * 100).toStringAsFixed(1)}% confidence via ${provider.toUpperCase()}'),
          ],
        ),
      ),
    );
  }
}

class _ExplanationCard extends StatelessWidget {
  const _ExplanationCard({required this.result});

  final DiagnosisResult result;

  @override
  Widget build(BuildContext context) {
    final explanation = result.explanation;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('AI Explanation', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            _DetailRow(title: 'Disease', value: explanation.name),
            _DetailRow(title: 'Symptoms', value: explanation.symptoms),
            _DetailRow(title: 'Cause', value: explanation.cause),
            _DetailRow(title: 'Treatment', value: explanation.treatment),
            _DetailRow(title: 'Prevention', value: explanation.prevention),
            _DetailRow(title: 'Recommended Fungicide', value: explanation.recommendedFungicide),
            _DetailRow(title: 'Organic Solution', value: explanation.organicSolution),
            _DetailRow(title: 'Farmer Tips', value: explanation.farmerTips),
            _DetailRow(title: 'Fertilizer Recommendation', value: explanation.fertilizerRecommendation),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.result, required this.onCopy});

  final DiagnosisResult result;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Quick Summary',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: onCopy,
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Copy'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Use this summary for sharing with a farmer, agronomist, or WhatsApp chat.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 10),
            _DetailRow(title: 'Disease', value: result.disease),
            _DetailRow(title: 'Confidence', value: '${(result.confidence * 100).toStringAsFixed(1)}%'),
            _DetailRow(title: 'Provider', value: result.provider.toUpperCase()),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(value),
        ],
      ),
    );
  }
}
