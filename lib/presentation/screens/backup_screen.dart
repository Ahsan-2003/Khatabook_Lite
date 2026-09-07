import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:khatabook_lite/core/services/backup_service.dart';
import 'package:khatabook_lite/core/theme/app_colors.dart';
import 'package:khatabook_lite/core/theme/app_text_styles.dart';
import 'package:file_picker/file_picker.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final BackupService _backupService = BackupService();
  bool _isWorking = false;

  Future<void> _createAndShareBackup() async {
    setState(() => _isWorking = true);

    try {
      final file = await _backupService.createBackup();

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'KhataBook Lite Backup',
        text:
            'KhataBook Lite Backup - ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
      );
    } catch (e) {
      _showSnackBar('backup_failed'.tr(), isError: true);
    } finally {
      setState(() => _isWorking = false);
    }
  }

  Future<void> _restoreFromBackup() async {
    setState(() => _isWorking = true);

    try {
      final PlatformFile? pickedFile = await FilePicker.pickFile(
        type: FileType.any,
      );

      if (pickedFile != null && pickedFile.path != null) {
        final file = File(pickedFile.path!);
        final content = await file.readAsString();

        if (!_backupService.isValidBackup(content)) {
          _showSnackBar('invalid_backup'.tr(), isError: true);
          return;
        }

        // Show confirmation
        final shouldRestore = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text('restore_backup'.tr()),
            content: Text('restore_backup_confirm'.tr()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text('cancel'.tr()),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                style: TextButton.styleFrom(foregroundColor: AppColors.credit),
                child: Text('restore'.tr()),
              ),
            ],
          ),
        );

        if (shouldRestore == true) {
          final counts = await _backupService.restoreFromBackup(file);
          _showSnackBar(
            'restore_success'.tr(
              namedArgs: {
                'customers': counts['customers'].toString(),
                'transactions': counts['transactions'].toString(),
              },
            ),
          );
        }
      }
      // pickedFile == null → user canceled, no action needed
    } catch (e) {
      _showSnackBar('restore_failed'.tr(), isError: true);
    } finally {
      setState(() => _isWorking = false);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.credit : AppColors.payment,
        behavior: SnackBarBehavior.fixed,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('backup_restore'.tr())),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Backup Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.backup,
                          color: AppColors.primary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text('create_backup'.tr(), style: AppTextStyles.heading),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text('backup_description'.tr(), style: AppTextStyles.caption),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _isWorking ? null : _createAndShareBackup,
                    icon: _isWorking
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.share),
                    label: Text('create_share_backup'.tr()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Restore Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppColors.payment.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.restore,
                          color: AppColors.payment,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text('restore_backup'.tr(), style: AppTextStyles.heading),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'restore_description'.tr(),
                    style: AppTextStyles.caption,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _isWorking ? null : _restoreFromBackup,
                    icon: _isWorking
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.file_open),
                    label: Text('select_backup_file'.tr()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.payment,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Info Card
          Card(
            color: AppColors.primary.withOpacity(0.05),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.credit),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'backup_info'.tr(),
                      style: AppTextStyles.caption,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
