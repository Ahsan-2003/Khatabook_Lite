import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:khatabook_lite/core/theme/app_colors.dart';
import 'package:khatabook_lite/core/theme/app_text_styles.dart';
import 'package:khatabook_lite/domain/entities/customer.dart';
import 'package:khatabook_lite/domain/entities/transaction.dart';
import 'package:khatabook_lite/presentation/bloc/transaction/transaction_bloc.dart';
import 'package:khatabook_lite/presentation/bloc/transaction/transaction_event.dart';
import 'package:khatabook_lite/presentation/bloc/transaction/transaction_state.dart';
import 'package:permission_handler/permission_handler.dart';

class TransactionEntryScreen extends StatefulWidget {
  final Customer customer;
  final String transactionType;
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
  final stt.SpeechToText _speech = stt.SpeechToText();

  String _amount = '';
  bool _isSubmitting = false;
  DateTime _selectedDate = DateTime.now();
  File? _selectedImage;
  String? _voiceNotePath;
  bool _isRecording = false;
  bool _isPlayingPreview = false;
  bool _isListening = false;
  String _spokenText = '';

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
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 70,
      );
      if (image != null) setState(() => _selectedImage = File(image.path));
    } catch (e) {
      _showSnackBar('error'.tr(), isError: true);
    }
  }

  // Toggle voice recording
  Future<void> _toggleRecording() async {
    try {
      if (_isRecording) {
        final path = await _audioRecorder.stop();
        setState(() {
          _isRecording = false;
          _voiceNotePath = path;
        });
        _showSnackBar('voice_note_recorded'.tr());
      } else {
        if (await _audioRecorder.hasPermission()) {
          final dir = await getApplicationDocumentsDirectory();
          final path =
              '${dir.path}/voice_note_${DateTime.now().millisecondsSinceEpoch}.wav';
          await _audioRecorder.start(
            const RecordConfig(
              encoder: AudioEncoder.wav,
              sampleRate: 16000,
              numChannels: 1,
            ),
            path: path,
          );
          setState(() => _isRecording = true);
        } else {
          _showSnackBar('microphone_permission_denied'.tr(), isError: true);
        }
      }
    } catch (e) {
      _showSnackBar('error'.tr(), isError: true);
    }
  }

  // Play preview voice note
  Future<void> _playPreviewVoiceNote() async {
    if (_voiceNotePath == null) return;
    try {
      if (_isPlayingPreview) {
        await _audioPlayer.stop();
        setState(() => _isPlayingPreview = false);
        return;
      }
      await _audioPlayer.play(DeviceFileSource(_voiceNotePath!));
      setState(() => _isPlayingPreview = true);
      _audioPlayer.onPlayerComplete.listen((event) {
        if (mounted) setState(() => _isPlayingPreview = false);
      });
    } catch (e) {
      setState(() => _isPlayingPreview = false);
    }
  }

  // Start voice input for amount
  Future<void> _startVoiceInput() async {
    try {
      // Request microphone permission
      final micStatus = await Permission.microphone.request();
      if (!micStatus.isGranted) {
        _showSnackBar('microphone_permission_denied'.tr(), isError: true);
        return;
      }

      // Initialize speech with default settings
      bool available = await _speech.initialize();

      if (!available) {
        _showSnackBar('speech_not_available'.tr(), isError: true);
        return;
      }

      setState(() {
        _isListening = true;
        _spokenText = '';
      });

      // Listen without specifying locale (use device default)
      await _speech.listen(
        onResult: (result) {
          print('DEBUG: Speech recognized: "${result.recognizedWords}"');
          print('DEBUG: Final result: ${result.finalResult}');

          setState(() {
            _spokenText = result.recognizedWords;
          });

          if (result.finalResult && result.recognizedWords.isNotEmpty) {
            _extractAmountFromSpeech(result.recognizedWords);
            _stopVoiceInput();
          }
        },
        listenFor: const Duration(seconds: 10),
        pauseFor: const Duration(seconds: 3),
      );
    } catch (e) {
      print('DEBUG: Speech error: $e');
      setState(() => _isListening = false);
      _showSnackBar('speech_error'.tr(), isError: true);
    }
  }

  // Stop voice input
  Future<void> _stopVoiceInput() async {
    await _speech.stop();
    setState(() => _isListening = false);
  }

  // Extract amount from speech
  void _extractAmountFromSpeech(String text) {
    print('DEBUG: Extracting amount from: "$text"');

    // First, try to extract direct numbers
    final regex = RegExp(r'\d+');
    final matches = regex.allMatches(text);

    if (matches.isNotEmpty) {
      final number = matches.first.group(0);
      if (number != null) {
        setState(() {
          _amount = number;
        });
        print('DEBUG: Extracted direct number: $number');
        return;
      }
    }

    // Word to number mapping
    final numberMap = {
      // English
      'zero': '0', 'one': '1', 'two': '2', 'three': '3', 'four': '4',
      'five': '5', 'six': '6', 'seven': '7', 'eight': '8', 'nine': '9',
      'ten': '10', 'eleven': '11', 'twelve': '12', 'thirteen': '13',
      'fourteen': '14', 'fifteen': '15', 'sixteen': '16',
      'seventeen': '17', 'eighteen': '18', 'nineteen': '19',
      'twenty': '20', 'thirty': '30', 'forty': '40',
      'fifty': '50', 'sixty': '60', 'seventy': '70', 'eighty': '80',
      'ninety': '90', 'hundred': '100', 'thousand': '1000',
      // Urdu (Roman)
      'sifar': '0', 'aik': '1', 'do': '2', 'teen': '3', 'char': '4',
      'panch': '5', 'chay': '6', 'saat': '7', 'aath': '8', 'nau': '9',
      'das': '10', 'gyara': '11', 'bara': '12', 'tera': '13',
      'chauda': '14', 'pandra': '15', 'sola': '16', 'satara': '17',
      'athara': '18', 'unis': '19', 'bees': '20', 'tees': '30',
      'chalis': '40', 'pachas': '50', 'saath': '60', 'sattar': '70',
      'assi': '80', 'nabbay': '90', 'so': '100', 'hazar': '1000',
    };

    final words = text.toLowerCase().split(RegExp(r'[\s,]+'));
    final result = StringBuffer();

    for (final word in words) {
      if (numberMap.containsKey(word)) {
        result.write(numberMap[word]);
      }
    }

    if (result.isNotEmpty) {
      setState(() {
        _amount = result.toString();
      });
      print('DEBUG: Extracted word number: $_amount');
    }
  }

  // Add digit
  void _addDigit(String digit) {
    setState(() {
      if (_amount.length < 7) _amount += digit;
    });
  }

  // Remove digit
  void _removeDigit() {
    setState(() {
      if (_amount.isNotEmpty)
        _amount = _amount.substring(0, _amount.length - 1);
    });
  }

  // Clear amount
  void _clearAmount() {
    setState(() => _amount = '');
  }

  // Submit transaction
  void _submitTransaction() {
    if (_amount.isEmpty || double.parse(_amount) <= 0) {
      _showSnackBar('please_enter_amount'.tr(), isError: true);
      return;
    }
    setState(() => _isSubmitting = true);
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
    final title = isCredit
        ? '${'gave'.tr()} (${'credit'.tr()})'
        : '${'got'.tr()} (${'payment'.tr()})';

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
            _showSnackBar('transaction_saved'.tr());
          } else if (state is TransactionError) {
            _isSubmitting = false;
            _showSnackBar(state.message, isError: true);
          }
        },
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Amount Display with Voice Input
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
                    const SizedBox(height: 12),

                    // Voice Input Button
                    GestureDetector(
                      onTap: _isListening ? _stopVoiceInput : _startVoiceInput,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: _isListening ? AppColors.credit : Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isListening ? Icons.stop : Icons.mic,
                              color: _isListening ? Colors.white : color,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isListening
                                  ? 'listening'.tr()
                                  : 'speak_amount'.tr(),
                              style: AppTextStyles.caption.copyWith(
                                color: _isListening ? Colors.white : color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (_isListening) ...[
                      const SizedBox(height: 12),
                      Text(
                        _spokenText.isEmpty
                            ? 'listening_hint'.tr()
                            : _spokenText,
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Note Field
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _noteController,
                  style: AppTextStyles.body,
                  decoration: InputDecoration(
                    hintText: 'note_optional'.tr(),
                    prefixIcon: const Icon(Icons.note, size: 24),
                  ),
                ),
              ),

              // Date Picker
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text('transaction_date'.tr()),
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
                  if (date != null) setState(() => _selectedDate = date);
                },
              ),

              // Voice Note & Photo Options
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _toggleRecording,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isRecording
                              ? AppColors.credit
                              : AppColors.primary,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _isRecording ? Icons.stop : Icons.mic,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isRecording
                                  ? 'recording'.tr()
                                  : 'voice_note'.tr(),
                              style: AppTextStyles.button.copyWith(
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _pickImage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.payment,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.photo_camera, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              _selectedImage != null
                                  ? 'photo_added'.tr()
                                  : 'add_photo'.tr(),
                              style: AppTextStyles.button.copyWith(
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Voice Note Preview
              if (_voiceNotePath != null && !_isRecording) ...[
                const SizedBox(height: 8),
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: ListTile(
                    leading: Icon(
                      _isPlayingPreview ? Icons.stop : Icons.play_circle,
                      color: AppColors.primary,
                      size: 32,
                    ),
                    title: Text(
                      _isPlayingPreview
                          ? 'playing'.tr()
                          : 'voice_note_ready'.tr(),
                      style: AppTextStyles.body,
                    ),
                    subtitle: Text(
                      'tap_to_listen'.tr(),
                      style: AppTextStyles.caption,
                    ),
                    onTap: _playPreviewVoiceNote,
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
                            Icon(
                              isCredit
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              size: 28,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${'save'.tr()} $title',
                              style: AppTextStyles.button,
                            ),
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

  Widget _buildKeypadButton(
    String label, {
    bool isClear = false,
    bool isDelete = false,
  }) {
    return ElevatedButton(
      onPressed: () {
        if (isClear)
          _clearAmount();
        else if (isDelete)
          _removeDigit();
        else
          _addDigit(label);
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
