import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class TranslationScreen extends StatefulWidget {
  const TranslationScreen({super.key});

  @override
  State<TranslationScreen> createState() => _TranslationScreenState();
}

class _TranslationScreenState extends State<TranslationScreen> {
  final TextEditingController _textController = TextEditingController();
  String _translatedText = '';
  List<String> _alternatives = [];
  String _detectedLanguage = '';
  double _confidence = 0.0;
  bool _isLoading = false;
  String _errorMessage = '';
  String _targetLanguage = 'ar'; // Arabic by default
// In your state class
  List<TranslationHistory> _history = [];

  // Available languages for translation
  final Map<String, String> languages = {
    'ar': 'Arabic',
    'en': 'English',
    'es': 'Spanish',
    'fr': 'French',
    'de': 'German',
    'it': 'Italian',
    'ja': 'Japanese',
    'ko': 'Korean',
    'zh': 'Chinese',
    'ru': 'Russian',
    'pt': 'Portuguese',
  };

  Future<void> _translateText() async {
    if (_textController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter text to translate';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _translatedText = '';
      _alternatives = [];
    });

    try {
      final url = Uri.parse('https://libretranslate.com/translate');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'q': _textController.text,
          'source': 'auto',
          'target': _targetLanguage,
          'format': 'text',
          'alternatives': 3,
          'api_key': '', // Add your API key if you have one
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        setState(() {
          _translatedText = data['translatedText'] ?? '';
          _alternatives = List<String>.from(data['alternatives'] ?? []);
          _detectedLanguage = data['detectedLanguage']['language'] ?? '';
          _confidence = (data['detectedLanguage']['confidence'] ?? 0).toDouble();
        });
      } else {
        setState(() {
          _errorMessage = 'Error: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

// Save to history after translation
  void _saveToHistory() {
    setState(() {
      _history.insert(0, TranslationHistory(
        originalText: _textController.text,
        translatedText: _translatedText,
        targetLanguage: _targetLanguage,
        timestamp: DateTime.now(),
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LibreTranslate'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Language Selection
              DropdownButtonFormField<String>(
                value: _targetLanguage,
                decoration: const InputDecoration(
                  labelText: 'Target Language',
                  border: OutlineInputBorder(),
                ),
                items: languages.entries.map((entry) {
                  return DropdownMenuItem<String>(
                    value: entry.key,
                    child: Text('${entry.value} (${entry.key})'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _targetLanguage = value!;
                  });
                },
              ),
              const SizedBox(height: 20),

              // Input Text Field
              TextField(
                controller: _textController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Text to translate',
                  hintText: 'Enter text here...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              // Translate Button
              ElevatedButton(
                onPressed: _isLoading ? null : _translateText,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : const Text(
                  'Translate',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 20),

              // Error Message
              if (_errorMessage.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),

              // Detection Info
              if (_detectedLanguage.isNotEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Detection Info',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('Detected language: $_detectedLanguage'),
                        Text('Confidence: ${(_confidence * 100).toStringAsFixed(1)}%'),
                      ],
                    ),
                  ),
                ),

              // Translated Text
              if (_translatedText.isNotEmpty)
                Card(
                  color: Colors.green[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Translated Text',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _translatedText,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Alternative Translations
              if (_alternatives.isNotEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Alternative Translations',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ..._alternatives.map((alternative) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.arrow_right, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    alternative,
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _textController.clear();
          setState(() {
            _translatedText = '';
            _alternatives = [];
            _detectedLanguage = '';
            _errorMessage = '';
          });
        },
        tooltip: 'Clear',
        child: const Icon(Icons.clear),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}

class TranslationHistory {
  final String originalText;
  final String translatedText;
  final String targetLanguage;
  final DateTime timestamp;

  TranslationHistory({
    required this.originalText,
    required this.translatedText,
    required this.targetLanguage,
    required this.timestamp,
  });
}
