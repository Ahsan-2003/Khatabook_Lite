import 'package:contacts_service/contacts_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khatabook_lite/core/theme/app_colors.dart';
import 'package:khatabook_lite/core/theme/app_text_styles.dart';
import 'package:khatabook_lite/presentation/bloc/customer/customer_bloc.dart';
import 'package:khatabook_lite/presentation/bloc/customer/customer_event.dart';
import 'package:khatabook_lite/presentation/bloc/customer/customer_state.dart';
import 'package:permission_handler/permission_handler.dart';

class ContactImportScreen extends StatefulWidget {
  const ContactImportScreen({super.key});

  @override
  State<ContactImportScreen> createState() => _ContactImportScreenState();
}

class _ContactImportScreenState extends State<ContactImportScreen> {
  List<Contact> _contacts = [];
  List<Contact> _filteredContacts = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _requestPermission();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _requestPermission() async {
    final status = await Permission.contacts.request();
    
    if (status.isGranted) {
      setState(() {
        _hasPermission = true;
      });
      _loadContacts();
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadContacts() async {
    try {
      final contacts = await ContactsService.getContacts(
        withThumbnails: false,
        iOSLocalizedLabels: false,
      );
      
      // Filter contacts with phone numbers
      final validContacts = contacts.where((c) {
        return c.phones != null && c.phones!.isNotEmpty;
      }).toList();
      
      // Sort alphabetically
      validContacts.sort((a, b) {
        final nameA = a.displayName ?? '';
        final nameB = b.displayName ?? '';
        return nameA.compareTo(nameB);
      });
      
      setState(() {
        _contacts = validContacts;
        _filteredContacts = validContacts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _searchContacts(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredContacts = _contacts;
      } else {
        _filteredContacts = _contacts.where((contact) {
          final name = contact.displayName?.toLowerCase() ?? '';
          final phone = contact.phones?.first.value ?? '';
          return name.contains(query.toLowerCase()) || phone.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _importContact(Contact contact) async {
    final name = contact.displayName ?? 'Unknown';
    final phone = contact.phones?.first.value;
    
    // Show confirmation
    final shouldImport = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('import_customer'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: AppTextStyles.heading),
            if (phone != null) ...[
              const SizedBox(height: 4),
              Text(phone, style: AppTextStyles.caption),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('import'.tr()),
          ),
        ],
      ),
    );
    
    if (shouldImport == true) {
      context.read<CustomerBloc>().add(
        AddCustomerEvent(
          name: name,
          phoneNumber: phone,
        ),
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('customer_added'.tr()),
          backgroundColor: AppColors.payment,
          behavior: SnackBarBehavior.fixed,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('import_contacts'.tr()),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _searchContacts,
              decoration: InputDecoration(
                hintText: 'search_contacts'.tr(),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _searchContacts('');
                        },
                      )
                    : null,
              ),
            ),
          ),

          // Content
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_hasPermission) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.contact_phone,
              size: 64,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 12),
            Text('permission_required'.tr(), style: AppTextStyles.heading),
            const SizedBox(height: 8),
            Text('contacts_permission_text'.tr(), style: AppTextStyles.caption),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _requestPermission,
              child: Text('grant_permission'.tr()),
            ),
          ],
        ),
      );
    }

    if (_filteredContacts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.contacts_outlined,
              size: 64,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 12),
            Text('no_contacts'.tr(), style: AppTextStyles.body),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _filteredContacts.length,
      itemBuilder: (context, index) {
        final contact = _filteredContacts[index];
        return _buildContactTile(contact);
      },
    );
  }

  Widget _buildContactTile(Contact contact) {
    final name = contact.displayName ?? 'Unknown';
    final phone = contact.phones?.first.value;
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary.withOpacity(0.1),
          ),
          child: Center(
            child: Text(
              initials,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
        title: Text(name, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
        subtitle: phone != null ? Text(phone, style: AppTextStyles.caption) : null,
        trailing: IconButton(
          icon: const Icon(Icons.add_circle_outline, color: AppColors.payment),
          onPressed: () => _importContact(contact),
        ),
      ),
    );
  }
}