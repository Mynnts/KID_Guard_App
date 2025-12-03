import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/contact_model.dart';
import '../../../data/services/contact_service.dart';
import '../../../logic/providers/auth_provider.dart';

class ParentContactsScreen extends StatelessWidget {
  const ParentContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.userModel;
    // For now, assume we are viewing the first child or need a selector.
    // In a real app, we'd pass the childId as an argument or have a selected child in provider.
    // Let's use the first child for now if available.
    final childId = authProvider.children.isNotEmpty
        ? authProvider.children.first.id
        : null;

    if (user == null || childId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Contacts')),
        body: const Center(child: Text('No child selected')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Child Contacts')),
      body: StreamBuilder<List<ContactModel>>(
        stream: ContactService().streamContacts(user.uid, childId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final contacts = snapshot.data ?? [];

          if (contacts.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.contacts_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No contacts synced yet.'),
                  Text('Make sure the child app is running and synced.'),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: contacts.length,
            itemBuilder: (context, index) {
              final contact = contacts[index];
              return ListTile(
                leading: CircleAvatar(
                  child: Text(
                    contact.displayName.isNotEmpty
                        ? contact.displayName[0]
                        : '?',
                  ),
                ),
                title: Text(contact.displayName),
                subtitle: Text(contact.phones.join(', ')),
              );
            },
          );
        },
      ),
    );
  }
}
