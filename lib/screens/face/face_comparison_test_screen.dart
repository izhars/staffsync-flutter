// screens/face_comparison_test_screen.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/face_comparison_api.dart';

class FaceComparisonTestScreen extends StatefulWidget {
  const FaceComparisonTestScreen({super.key});

  @override
  State<FaceComparisonTestScreen> createState() =>
      _FaceComparisonTestScreenState();
}

class _FaceComparisonTestScreenState extends State<FaceComparisonTestScreen> {
  final ImagePicker _picker = ImagePicker();
  final FaceRecognitionService _api = FaceRecognitionService();

  File? _image1;
  File? _image2;

  bool _isLoading = false;
  String? _resultMessage;
  double? _similarityScore;
  String? _errorMessage;

  Future<void> _pickImage(bool isFirst, {bool fromCamera = false}) async {
    try {
      final source = fromCamera ? ImageSource.camera : ImageSource.gallery;

      final XFile? picked = await _picker.pickImage(
        source: source,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (picked == null) return;

      final file = File(picked.path);
      final sizeKB = (await file.length()) ~/ 1024;

      setState(() {
        if (isFirst) {
          _image1 = file;
        } else {
          _image2 = file;
        }
        _errorMessage = null;
        // Optional: show size info in debug mode
        // _errorMessage = 'Image size: ${sizeKB} KB';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to pick image: $e';
      });
    }
  }

  Future<String> _fileToBase64(File file) async {
    final bytes = await file.readAsBytes();
    return base64Encode(bytes);
  }

  Future<void> _compareFaces() async {
    if (_image1 == null || _image2 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both images'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _resultMessage = null;
      _similarityScore = null;
      _errorMessage = null;
    });

    try {
      final base64_1 = await _fileToBase64(_image1!);
      final base64_2 = await _fileToBase64(_image2!);

      final response = await _api.compareFaces(
        image1Base64: base64_1,
        image2Base64: base64_2,
      );

      if (!mounted) return;

      if (response['success'] == true && response['data']?['success'] == true) {
        final matched = response['data']['matched'] == true;
        final score = (response['data']['similarity'] ?? 0).toDouble();

        setState(() {
          _similarityScore = score;
          _resultMessage = matched
              ? 'Faces Match!'
              : 'Different Faces';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              matched
                  ? 'Match confirmed (${(score * 100).toStringAsFixed(1)}%)'
                  : 'No match (${(score * 100).toStringAsFixed(1)}%)',
            ),
            backgroundColor: matched ? Colors.green : Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        throw Exception(
          response['data']?['message'] ?? response['message'] ?? 'API error',
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Comparison failed: $_errorMessage'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _clearImages() {
    setState(() {
      _image1 = null;
      _image2 = null;
      _resultMessage = null;
      _similarityScore = null;
      _errorMessage = null;
    });
  }

  Widget _buildImageCard({
    required String label,
    File? image,
    required VoidCallback onGallery,
    required VoidCallback onCamera,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: onGallery,
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: image == null
                    ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 48,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap to select',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                )
                    : ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    image,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 180,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: onCamera,
                  icon: const Icon(Icons.camera_alt, size: 18),
                  label: const Text('Camera'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: onGallery,
                  icon: const Icon(Icons.photo_library_outlined, size: 18),
                  label: const Text('Gallery'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Face Comparison'),
        actions: [
          if (_image1 != null || _image2 != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Clear both images',
              onPressed: _clearImages,
            ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Image 1
                _buildImageCard(
                  label: 'Face 1',
                  image: _image1,
                  onGallery: () => _pickImage(true, fromCamera: false),
                  onCamera: () => _pickImage(true, fromCamera: true),
                ),

                const SizedBox(height: 24),

                // Image 2
                _buildImageCard(
                  label: 'Face 2',
                  image: _image2,
                  onGallery: () => _pickImage(false, fromCamera: false),
                  onCamera: () => _pickImage(false, fromCamera: true),
                ),

                const SizedBox(height: 32),

                // Compare Button
                FilledButton.icon(
                  onPressed: _isLoading ? null : _compareFaces,
                  icon: const Icon(Icons.compare_arrows),
                  label: const Text('Compare Faces', style: TextStyle(fontSize: 17)),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),

                const SizedBox(height: 32),

                // Result Area
                if (_resultMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _similarityScore != null && _similarityScore! > 0.6
                          ? Colors.green.shade50
                          : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _similarityScore != null && _similarityScore! > 0.6
                            ? Colors.green.shade300
                            : Colors.red.shade300,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          _resultMessage!,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: _similarityScore != null && _similarityScore! > 0.6
                                ? Colors.green.shade800
                                : Colors.red.shade800,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (_similarityScore != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Similarity: ${(_similarityScore! * 100).toStringAsFixed(1)}%',
                            style: const TextStyle(fontSize: 18),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],

                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Card(
                    color: Colors.red.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade800),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Comparing faces...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}