import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/state/app_state.dart';
import '../../core/widgets/gradient_scaffold.dart';
import '../../core/widgets/section_header.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController baseUrlController;

  @override
  void initState() {
    super.initState();
    baseUrlController = TextEditingController();
  }

  @override
  void dispose() {
    baseUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (baseUrlController.text != state.baseUrl) {
      baseUrlController.text = state.baseUrl;
    }
    return GradientScaffold(
      appBar: AppBar(title: const Text('Settings')),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SectionHeader(
            title: 'App Configuration',
            subtitle: 'Change the backend URL, provider, theme, and language here.',
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: baseUrlController,
                    decoration: const InputDecoration(
                      labelText: 'Backend URL',
                      hintText: 'http://127.0.0.1:8000',
                    ),
                    onSubmitted: state.setBaseUrl,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: state.selectedProvider,
                    decoration: const InputDecoration(labelText: 'AI Provider'),
                    items: state.providers
                        .map((provider) => DropdownMenuItem(value: provider, child: Text(provider.toUpperCase())))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        state.setProvider(value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<ThemeMode>(
                    value: state.themeMode,
                    decoration: const InputDecoration(labelText: 'Theme'),
                    items: const [
                      DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
                      DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                      DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        state.toggleTheme(value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: state.settings.language,
                    decoration: const InputDecoration(labelText: 'Language'),
                    items: const [
                      DropdownMenuItem(value: 'English', child: Text('English')),
                      DropdownMenuItem(value: 'Hindi', child: Text('Hindi')),
                      DropdownMenuItem(value: 'Tamil', child: Text('Tamil')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        state.setLanguage(value);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('About RiceGPT AI'),
              subtitle: const Text('FastAPI backend, Flutter front end, and ML-ready rice disease workflow.'),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.code),
              title: const Text('Version'),
              subtitle: const Text('1.0.0'),
            ),
          ),
        ],
      ),
    );
  }
}
