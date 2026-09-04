import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:khatabook_lite/core/theme/app_colors.dart';
import 'package:khatabook_lite/core/theme/app_text_styles.dart';
import 'package:khatabook_lite/domain/entities/customer.dart';
import 'package:khatabook_lite/presentation/bloc/customer/customer_bloc.dart';
import 'package:khatabook_lite/presentation/bloc/customer/customer_event.dart';
import 'package:khatabook_lite/presentation/bloc/customer/customer_state.dart';

class EditCustomerScreen extends StatefulWidget {
  final Customer customer;
  const EditCustomerScreen({super.key, required this.customer});

  @override
  State<EditCustomerScreen> createState() => _EditCustomerScreenState();
}

class _EditCustomerScreenState extends State<EditCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  File? _selectedImage;
  bool _isSubmitting = false;
  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.customer.name);
    _phoneController = TextEditingController(
      text: widget.customer.phoneNumber ?? '',
    );
    if (widget.customer.photoPath != null &&
        File(widget.customer.photoPath!).existsSync()) {
      _selectedImage = File(widget.customer.photoPath!);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 70,
      );
      if (image != null) {
        setState(() => _selectedImage = File(image.path));
      }
    } catch (e) {
      _showSnackBar('error'.tr(), isError: true);
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);
      context.read<CustomerBloc>().add(
        UpdateCustomerEvent(
          customerId: widget.customer.id,
          name: _nameController.text.trim(),
          phoneNumber: _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
          photoPath: _selectedImage?.path,
        ),
      );
    }
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
    return Scaffold(
      appBar: AppBar(title: Text('edit_customer'.tr())),
      body: BlocListener<CustomerBloc, CustomerState>(
        listener: (context, state) {
          if (state is CustomerLoaded && _isSubmitting) {
            _isSubmitting = false;
            Navigator.pop(context, true);
            _showSnackBar('customer_updated'.tr());
          } else if (state is CustomerError) {
            _isSubmitting = false;
            _showSnackBar(state.message, isError: true);
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.surface,
                        border: Border.all(color: AppColors.divider, width: 2),
                      ),
                      child: _selectedImage != null
                          ? ClipOval(
                              child: Image.file(
                                _selectedImage!,
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.camera_alt,
                                  size: 40,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'change_photo'.tr(),
                                  style: AppTextStyles.caption,
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  'customer_name'.tr(),
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  style: AppTextStyles.body.copyWith(fontSize: 18),
                  decoration: InputDecoration(
                    hintText: 'enter_customer_name'.tr(),
                    prefixIcon: const Icon(Icons.person, size: 28),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty)
                      return 'name_required'.tr();
                    if (value.trim().length < 2) return 'name_too_short'.tr();
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                Text(
                  'phone_number'.tr(),
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneController,
                  style: AppTextStyles.body.copyWith(fontSize: 18),
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: 'enter_phone_number'.tr(),
                    prefixIcon: const Icon(Icons.phone, size: 28),
                  ),
                  validator: (value) {
                    if (value != null &&
                        value.isNotEmpty &&
                        value.length < 10) {
                      return 'phone_invalid'.tr();
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
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
                      : Text(
                          'update_customer'.tr(),
                          style: AppTextStyles.button,
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
