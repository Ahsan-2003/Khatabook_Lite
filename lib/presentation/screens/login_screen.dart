import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:khatabook_lite/core/services/auth_service.dart';
import 'package:khatabook_lite/core/theme/app_colors.dart';
import 'package:khatabook_lite/core/theme/app_text_styles.dart';
import 'package:khatabook_lite/presentation/screens/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  String _verificationId = '';
  bool _isOtpSent = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  String _formatPhoneNumber(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'[^0-9]'), '');

    if (cleaned.startsWith('0')) {
      return '+92${cleaned.substring(1)}';
    } else if (cleaned.startsWith('92')) {
      return '+$cleaned';
    } else if (cleaned.startsWith('3')) {
      return '+92$cleaned';
    }
    return cleaned;
  }

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();

    if (phone.isEmpty || phone.length < 10) {
      _showSnackBar('Enter a valid phone number', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    final formattedPhone = _formatPhoneNumber(phone);
    print('DEBUG: Sending OTP to: $formattedPhone');

    await _authService.sendOtp(
      phoneNumber: formattedPhone,
      onCodeSent: (verificationId) {
        print('DEBUG: OTP sent, verificationId: $verificationId');
        setState(() {
          _verificationId = verificationId;
          _isOtpSent = true;
          _isLoading = false;
        });
        _showSnackBar('OTP sent successfully');
      },
      onError: (error) {
        print('DEBUG: OTP error: $error');
        setState(() => _isLoading = false);
        _showSnackBar(error, isError: true);
      },
    );
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();

    if (otp.isEmpty || otp.length < 6) {
      _showSnackBar('Enter valid OTP', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    final success = await _authService.verifyOtp(
      verificationId: _verificationId,
      otp: otp,
    );

    if (success) {
      print('DEBUG: OTP verified successfully');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      print('DEBUG: OTP verification failed');
      setState(() => _isLoading = false);
      _showSnackBar('Invalid OTP', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.credit : AppColors.payment,
        behavior: SnackBarBehavior.fixed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('login'.tr())),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.phone_android, size: 80, color: AppColors.primary),
            const SizedBox(height: 20),
            Text('phone_login'.tr(), style: AppTextStyles.heading),
            const SizedBox(height: 8),
            Text('phone_login_subtitle'.tr(), style: AppTextStyles.caption),
            const SizedBox(height: 40),

            if (!_isOtpSent) ...[
              // Phone Input
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: AppTextStyles.body.copyWith(fontSize: 18),
                decoration: InputDecoration(
                  hintText: '0300 1234567',
                  prefixIcon: const Icon(Icons.phone),
                  // hintText: 'enter_phone_number'.tr(),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _sendOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text('send_otp'.tr(), style: AppTextStyles.button),
              ),
            ] else ...[
              // OTP Input
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                style: AppTextStyles.body.copyWith(
                  fontSize: 24,
                  letterSpacing: 8,
                ),
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  hintText: '------',
                  counterText: '',
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _verifyOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text('verify_otp'.tr(), style: AppTextStyles.button),
              ),
              TextButton(
                onPressed: _isLoading ? null : _sendOtp,
                child: Text('resend_otp'.tr()),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
