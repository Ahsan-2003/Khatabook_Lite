import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/transaction.dart';
import '../bloc/transaction/transaction_bloc.dart';
import '../bloc/transaction/transaction_event.dart';
import '../bloc/transaction/transaction_state.dart';

class TransactionEntryScreen extends StatefulWidget {
  final Customer customer;
  final String transactionType; // 'credit' or 'payment'

  const TransactionEntryScreen({
    super.key,
    required this.customer,
    required this.transactionType,
  });

  @override
  State<TransactionEntryScreen> createState() => _TransactionEntryScreenState();
}

class _TransactionEntryScreenState extends State<TransactionEntryScreen> {
  final _noteController = TextEditingController();
  final _imagePicker = ImagePicker();
  final _audioRecorder = AudioRecorder();
  final _audioPlayer = AudioPlayer();

  String _amount = '';
  bool _isSubmitting = false;
  DateTime _selectedDate = DateTime.now();

  File? _selectedImage;
  String? _voiceNotePath;
  bool _isRecording = false;

  @override
  void dispose() {
    _noteController.dispose();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  // Pick image
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 70,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      _showSnackBar('Failed to pick image', isError: true);
    }
  }

  // Toggle voice recording
  // Toggle voice recording
  Future<void> _toggleRecording() async {
    try {
      if (_isRecording) {
        // Stop recording
        final path = await _audioRecorder.stop();
        print('DEBUG: Recording stopped at path: $path');

        setState(() {
          _isRecording = false;
          _voiceNotePath = path;
        });

        _showSnackBar('Voice note recorded successfully');
      } else {
        // Check permission first
        if (await _audioRecorder.hasPermission()) {
          // Start recording
          final dir = await getApplicationDocumentsDirectory();
          final path =
              '${dir.path}/voice_note_${DateTime.now().millisecondsSinceEpoch}.m4a';

          print('DEBUG: Starting recording at: $path');

          await _audioRecorder.start(
            const RecordConfig(
              encoder: AudioEncoder.aacLc,
              bitRate: 128000,
              sampleRate: 44100,
              numChannels: 1,
            ),
            path: path,
          );

          setState(() {
            _isRecording = true;
          });

          _showSnackBar('Recording started...');
        } else {
          _showSnackBar('Microphone permission denied', isError: true);
        }
      }
    } catch (e) {
      print('DEBUG: Recording error: $e');
      _showSnackBar('Recording error: $e', isError: true);
    }
  }

  // Play voice note
  // Play voice note
  Future<void> _playVoiceNote() async {
    if (_voiceNotePath == null) {
      _showSnackBar('No voice note to play', isError: true);
      return;
    }

    print('DEBUG: Playing voice note from: $_voiceNotePath');

    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(DeviceFileSource(_voiceNotePath!));
      _showSnackBar('Playing voice note...');
    } catch (e) {
      print('DEBUG: Playback error: $e');
      _showSnackBar('Failed to play voice note: $e', isError: true);
    }
  }

  // Remove last digit
  void _removeDigit() {
    setState(() {
      if (_amount.isNotEmpty) {
        _amount = _amount.substring(0, _amount.length - 1);
      }
    });
  }

  // Clear amount
  void _clearAmount() {
    setState(() {
      _amount = '';
    });
  }

  // Submit transaction
  void _submitTransaction() {
    if (_amount.isEmpty || double.parse(_amount) <= 0) {
      _showSnackBar('Please enter an amount', isError: true);
      return;
    }

    print('DEBUG: Submitting transaction');
    print('DEBUG: Voice note path: $_voiceNotePath');
    print('DEBUG: Photo path: ${_selectedImage?.path}');
    setState(() {
      _isSubmitting = true;
    });

    context.read<TransactionBloc>().add(
      AddTransactionEvent(
        customerId: widget.customer.id,
        type: widget.transactionType == 'credit'
            ? TransactionType.credit
            : TransactionType.payment,
        amount: double.parse(_amount),
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        timestamp: _selectedDate,
        photoPath: _selectedImage?.path,
        voiceNotePath: _voiceNotePath,
      ),
    );
  }

  // Show snackbar
  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.credit : AppColors.payment,
        behavior: SnackBarBehavior.fixed,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCredit = widget.transactionType == 'credit';
    final color = isCredit ? AppColors.credit : AppColors.payment;
    final title = isCredit ? 'Gave (Credit)' : 'Got (Payment)';
    final icon = isCredit ? Icons.arrow_upward : Icons.arrow_downward;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: color,
        foregroundColor: Colors.white,
      ),
      body: BlocListener<TransactionBloc, TransactionState>(
        listener: (context, state) {
          if (state is TransactionLoaded && _isSubmitting) {
            _isSubmitting = false;
            Navigator.pop(context, true);
            _showSnackBar('Transaction saved successfully');
          } else if (state is TransactionError) {
            _isSubmitting = false;
            _showSnackBar(state.message, isError: true);
          }
        },
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Amount Display
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                color: color.withOpacity(0.1),
                child: Column(
                  children: [
                    Text(
                      widget.customer.name,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _amount.isEmpty ? 'Rs. 0' : 'Rs. $_amount',
                      style: AppTextStyles.displayLarge.copyWith(color: color),
                    ),
                  ],
                ),
              ),

              // Note Field
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _noteController,
                  style: AppTextStyles.body,
                  decoration: const InputDecoration(
                    hintText: 'Note (Optional)',
                    prefixIcon: Icon(Icons.note, size: 24),
                  ),
                ),
              ),

              // Date Picker
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Transaction Date'),
                subtitle: Text(
                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                ),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() {
                      _selectedDate = date;
                    });
                  }
                },
              ),

              // Voice Note & Photo Options
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    // Voice Note Button
                    Expanded(
                      child: _buildOptionButton(
                        icon: _isRecording ? Icons.stop : Icons.mic,
                        label: _isRecording ? 'Recording...' : 'Voice Note',
                        color: _isRecording
                            ? AppColors.credit
                            : AppColors.primary,
                        onPressed: _toggleRecording,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Photo Button
                    Expanded(
                      child: _buildOptionButton(
                        icon: Icons.photo_camera,
                        label: _selectedImage != null
                            ? 'Photo Added'
                            : 'Add Photo',
                        color: AppColors.payment,
                        onPressed: _pickImage,
                      ),
                    ),
                  ],
                ),
              ),

              // Voice Note Playback
              if (_voiceNotePath != null && !_isRecording) ...[
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(
                    Icons.play_circle,
                    color: AppColors.primary,
                  ),
                  title: const Text('Voice Note Recorded'),
                  trailing: IconButton(
                    icon: const Icon(Icons.play_arrow),
                    onPressed: _playVoiceNote,
                  ),
                ),
              ],

              // Photo Preview
              if (_selectedImage != null) ...[
                const SizedBox(height: 8),
                Container(
                  height: 100,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: FileImage(_selectedImage!),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Numeric Keypad
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  _buildKeypadButton('1'),
                  _buildKeypadButton('2'),
                  _buildKeypadButton('3'),
                  _buildKeypadButton('4'),
                  _buildKeypadButton('5'),
                  _buildKeypadButton('6'),
                  _buildKeypadButton('7'),
                  _buildKeypadButton('8'),
                  _buildKeypadButton('9'),
                  _buildKeypadButton('C', isClear: true),
                  _buildKeypadButton('0'),
                  _buildKeypadButton('⌫', isDelete: true),
                ],
              ),

              // Save Button
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitTransaction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    minimumSize: const Size(double.infinity, 60),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(icon, size: 28),
                            const SizedBox(width: 8),
                            Text('Save $title', style: AppTextStyles.button),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build option button
  Widget _buildOptionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(label, style: AppTextStyles.button.copyWith(fontSize: 14)),
        ],
      ),
    );
  }

  // Build keypad button
  Widget _buildKeypadButton(
    String label, {
    bool isClear = false,
    bool isDelete = false,
  }) {
    return ElevatedButton(
      onPressed: () {
        if (isClear) {
          _clearAmount();
        } else if (isDelete) {
          _removeDigit();
        } else {
          _addDigit(label);
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isClear || isDelete
            ? AppColors.textSecondary
            : AppColors.surface,
        foregroundColor: isClear || isDelete
            ? Colors.white
            : AppColors.textPrimary,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }
}
