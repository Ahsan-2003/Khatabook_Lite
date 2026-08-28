import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../data/repositories/customer_repository.dart';

class AddCustomerScreen extends StatefulWidget {
  const AddCustomerScreen({super.key});

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  File? _selectedImage;
  bool _isSaving = false;

  final _customerRepository = CustomerRepository();
  final _imagePicker = ImagePicker();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // Pick image from gallery
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 70,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
    }
  }

  // Save customer
  Future<void> _saveCustomer() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });

      try {
        await _customerRepository.addCustomer(
          name: _nameController.text.trim(),
          phoneNumber: _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
          photoPath: _selectedImage?.path,
        );

        if (mounted) {
          Navigator.pop(context, true); // Return true to refresh home
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error saving customer: $e')));
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Customer')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo Picker
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.background,
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
                                'Add Photo',
                                style: AppTextStyles.captionText,
                              ),
                            ],
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Customer Name Field
              Text(
                'Customer Name *',
                style: AppTextStyles.bodyText.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                style: AppTextStyles.bodyText.copyWith(fontSize: 18),
                decoration: const InputDecoration(
                  hintText: 'Enter customer name',
                  prefixIcon: Icon(Icons.person, size: 28),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Phone Number Field
              Text(
                'Phone Number (Optional)',
                style: AppTextStyles.bodyText.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phoneController,
                style: AppTextStyles.bodyText.copyWith(fontSize: 18),
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: '03XX-XXXXXXX',
                  prefixIcon: Icon(Icons.phone, size: 28),
                ),
              ),

              const SizedBox(height: 40),

              // Save Button
              ElevatedButton(
                onPressed: _isSaving ? null : _saveCustomer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentBlue,
                  minimumSize: const Size(double.infinity, 60),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Save Customer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
