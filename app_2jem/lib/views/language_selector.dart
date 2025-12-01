import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_2jem/providers/language_provider.dart';

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: languageProvider.currentLocale.languageCode,
        icon: const Icon(Icons.language, color: Colors.white),
        dropdownColor: Theme.of(context).primaryColor,
        style: const TextStyle(color: Colors.white),
        onChanged: (String? newValue) {
          if (newValue != null) {
            languageProvider.changeLanguage(newValue);
          }
        },
        items: const [
          DropdownMenuItem(value: 'en', child: Text('EN')),
          DropdownMenuItem(value: 'fr', child: Text('FR')),
          DropdownMenuItem(value: 'pt', child: Text('PT')),
          DropdownMenuItem(value: 'es', child: Text('ES')),
        ],
      ),
    );
  }
}
