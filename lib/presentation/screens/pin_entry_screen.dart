import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:khatabook_lite/core/services/app_lock_service.dart';
import 'package:khatabook_lite/core/theme/app_colors.dart';
import 'package:khatabook_lite/core/theme/app_text_styles.dart';

class PinEntryScreen extends StatefulWidget {
  final bool
  isSetup; // true = setting up new PIN, false = entering existing PIN
  final VoidCallback? onUnlocked;

  const PinEntryScreen({super.key, this.isSetup = false, this.onUnlocked});

  @override
  State<PinEntryScreen> createState() => _PinEntryScreenState();
}

class _PinEntryScreenState extends State<PinEntryScreen> {
  final AppLockService _appLockService = AppLockService();
  String _enteredPin = '';
  String _confirmPin = '';
  bool _isConfirming = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    if (!widget.isSetup) {
      _checkBiometric();
    }
  }

  Future<void> _checkBiometric() async {
    if (await _appLockService.isBiometricEnabled() &&
        await _appLockService.isBiometricAvailable()) {
      final authenticated = await _appLockService.authenticateWithBiometric();
      if (authenticated && mounted) {
        widget.onUnlocked?.call();
      }
    }
  }

  void _addDigit(String digit) {
    setState(() {
      _hasError = false;
      if (_enteredPin.length < 4) {
        _enteredPin += digit;

        if (_enteredPin.length == 4) {
          _processPin();
        }
      }
    });
  }

  void _removeDigit() {
    setState(() {
      if (_enteredPin.isNotEmpty) {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        _hasError = false;
      }
    });
  }

  Future<void> _processPin() async {
    if (widget.isSetup) {
      if (!_isConfirming) {
        // First entry - ask to confirm
        await Future.delayed(const Duration(milliseconds: 200));
        setState(() {
          _isConfirming = true;
          _confirmPin = _enteredPin;
          _enteredPin = '';
        });
      } else {
        // Confirmation entry
        if (_enteredPin == _confirmPin) {
          await _appLockService.savePin(_enteredPin);
          if (mounted) {
            Navigator.pop(context, true);
          }
        } else {
          setState(() {
            _hasError = true;
            _enteredPin = '';
            _confirmPin = '';
            _isConfirming = false;
          });
        }
      }
    } else {
      // Verify existing PIN
      final isValid = await _appLockService.verifyPin(_enteredPin);
      if (isValid) {
        widget.onUnlocked?.call();
      } else {
        setState(() {
          _hasError = true;
          _enteredPin = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Icon(
              widget.isSetup ? Icons.lock_outline : Icons.lock,
              size: 64,
              color: AppColors.primary,
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              _getTitle(),
              style: AppTextStyles.heading.copyWith(fontSize: 28),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Subtitle
            if (_hasError)
              Text(
                widget.isSetup ? 'pin_mismatch'.tr() : 'wrong_pin'.tr(),
                style: AppTextStyles.body.copyWith(color: AppColors.credit),
              )
            else
              Text(
                _getSubtitle(),
                style: AppTextStyles.caption,
                textAlign: TextAlign.center,
              ),

            const SizedBox(height: 40),

            // PIN Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                return Container(
                  width: 16,
                  height: 16,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index < _enteredPin.length
                        ? AppColors.primary
                        : Colors.transparent,
                    border: Border.all(
                      color: _hasError ? AppColors.credit : AppColors.primary,
                      width: 2,
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 40),

            // Numeric Keypad
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.3,
                children: [
                  _buildPinButton('1'),
                  _buildPinButton('2'),
                  _buildPinButton('3'),
                  _buildPinButton('4'),
                  _buildPinButton('5'),
                  _buildPinButton('6'),
                  _buildPinButton('7'),
                  _buildPinButton('8'),
                  _buildPinButton('9'),
                  const SizedBox.shrink(),
                  _buildPinButton('0'),
                  _buildPinButton('⌫', isDelete: true),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Biometric Button
            if (!widget.isSetup)
              FutureBuilder<bool>(
                future: _appLockService.isBiometricAvailable(),
                builder: (context, snapshot) {
                  if (snapshot.data == true) {
                    return TextButton.icon(
                      onPressed: () async {
                        final authenticated = await _appLockService
                            .authenticateWithBiometric();
                        if (authenticated && mounted) {
                          widget.onUnlocked?.call();
                        }
                      },
                      icon: const Icon(Icons.fingerprint, size: 28),
                      label: Text('use_fingerprint'.tr()),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
          ],
        ),
      ),
    );
  }

  String _getTitle() {
    if (widget.isSetup) {
      return _isConfirming ? 'confirm_pin'.tr() : 'set_pin'.tr();
    }
    return 'enter_pin'.tr();
  }

  String _getSubtitle() {
    if (widget.isSetup) {
      return _isConfirming ? 'reenter_pin'.tr() : 'create_pin'.tr();
    }
    return 'enter_pin_subtitle'.tr();
  }

  Widget _buildPinButton(String label, {bool isDelete = false}) {
    return ElevatedButton(
      onPressed: () {
        if (isDelete) {
          _removeDigit();
        } else {
          _addDigit(label);
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isDelete ? AppColors.textSecondary : AppColors.surface,
        foregroundColor: isDelete ? Colors.white : AppColors.textPrimary,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }
}
