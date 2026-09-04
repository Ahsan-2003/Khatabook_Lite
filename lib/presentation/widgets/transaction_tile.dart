import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:khatabook_lite/core/theme/app_colors.dart';
import 'package:khatabook_lite/core/theme/app_text_styles.dart';
import 'package:khatabook_lite/domain/entities/transaction.dart';

class TransactionTile extends StatefulWidget {
  final Transaction transaction;
  final VoidCallback? onDelete;

  const TransactionTile({super.key, required this.transaction, this.onDelete});

  @override
  State<TransactionTile> createState() => _TransactionTileState();
}

class _TransactionTileState extends State<TransactionTile> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _audioPlayer.onLog.listen((msg) => print('DEBUG: AP LOG -> $msg'));
    _audioPlayer.setReleaseMode(ReleaseMode.stop);
    _audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) setState(() => _isPlaying = false);
    });
  }

  Future<void> _togglePlayback(String path) async {
    try {
      if (_isPlaying) {
        await _audioPlayer.stop();
        setState(() => _isPlaying = false);
        return;
      }

      print('DEBUG: Playing: $path');
      print('DEBUG: File exists: ${File(path).existsSync()}');
      print('DEBUG: File size: ${File(path).lengthSync()} bytes');

      // Force audio routing + volume — this is what was missing
      await _audioPlayer.setAudioContext(
        AudioContext(
          android: AudioContextAndroid(
            isSpeakerphoneOn: true,
            stayAwake: true,
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.media,
            audioFocus: AndroidAudioFocus.gain,
          ),
        ),
      );
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.play(DeviceFileSource(path));

      setState(() => _isPlaying = true);
      _audioPlayer.onPlayerStateChanged.listen((state) {
        print('DEBUG: PlayerState -> $state');
      });

      _audioPlayer.getDuration().then((d) => print('DEBUG: Duration -> $d'));
      print('DEBUG: Playback command sent');
    } catch (e) {
      print('DEBUG: Playback error: $e');
      if (mounted) setState(() => _isPlaying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final transaction = widget.transaction;
    final isCredit = transaction.type == TransactionType.credit;
    final color = isCredit ? AppColors.credit : AppColors.payment;
    final icon = isCredit ? Icons.arrow_upward : Icons.arrow_downward;
    final label = isCredit ? 'Gave (Credit)' : 'Got (Payment)';
    final sign = isCredit ? '+' : '-';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.1),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            title: Text(
              label,
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              _formatDate(transaction.timestamp),
              style: AppTextStyles.caption,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$sign Rs. ${transaction.amount.toStringAsFixed(0)}',
                  style: AppTextStyles.heading.copyWith(
                    color: color,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          if (transaction.voiceNotePath != null)
            ListTile(
              dense: true,
              leading: Icon(
                _isPlaying ? Icons.stop_circle : Icons.play_circle_fill,
                color: AppColors.primary,
              ),
              title: Text(
                _isPlaying ? 'Playing voice note...' : 'Play voice note',
                style: AppTextStyles.caption,
              ),
              onTap: () => _togglePlayback(transaction.voiceNotePath!),
            ),

          if (transaction.photoPath != null)
            Padding(
              padding: const EdgeInsets.all(8),
              child: GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) =>
                        Dialog(child: Image.file(File(transaction.photoPath!))),
                  );
                },
                child: Container(
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: FileImage(File(transaction.photoPath!)),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final transactionDate = DateTime(
      dateTime.year,
      dateTime.month,
      dateTime.day,
    );

    String time =
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';

    if (transactionDate == today) {
      return 'Today at $time';
    } else if (transactionDate == yesterday) {
      return 'Yesterday at $time';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} at $time';
    }
  }
}
