import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medliva/features/auth/presentation/auth_notifier.dart';
import 'package:medliva/features/emergency/data/emergency_repository.dart';
import 'package:medliva/features/emergency/domain/models/emergency.dart';
import 'package:medliva/l10n/app_localizations.dart';

class EmergencyContactsNotifier
    extends AsyncNotifier<List<EmergencyContactModel>> {
  @override
  Future<List<EmergencyContactModel>> build() async {
    final patientId = ref.watch(currentPatientIdProvider);
    if (patientId == null || patientId.isEmpty) {
      return const [];
    }
    final repo = ref.watch(emergencyRepositoryProvider);
    return await repo.listContacts(patientId);
  }

  Future<EmergencyContactModel> addContact(
    EmergencyContactCreateInput input,
  ) async {
    final patientId = ref.read(currentPatientIdProvider);
    if (patientId == null || patientId.isEmpty) {
      throw StateError('No active patient selected');
    }
    final repo = ref.read(emergencyRepositoryProvider);
    final created = await repo.createContact(patientId, input);
    final current = state.value ?? const [];
    state = AsyncValue.data([...current, created]);
    return created;
  }
}

final emergencyContactsNotifierProvider = AsyncNotifierProvider<
    EmergencyContactsNotifier, List<EmergencyContactModel>>(
  EmergencyContactsNotifier.new,
);

class EmergencyContactsScreen extends ConsumerStatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  ConsumerState<EmergencyContactsScreen> createState() =>
      _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState
    extends ConsumerState<EmergencyContactsScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _relationController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _relationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    if (name.isEmpty || phone.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      await ref.read(emergencyContactsNotifierProvider.notifier).addContact(
            EmergencyContactCreateInput(
              name: name,
              phone: phone,
              relationship: _relationController.text.trim().isEmpty
                  ? null
                  : _relationController.text.trim(),
            ),
          );
      _nameController.clear();
      _phoneController.clear();
      _relationController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final contactsAsync = ref.watch(emergencyContactsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.emergencyContactsTitle),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Card(
              margin: const EdgeInsetsDirectional.all(16),
              child: Padding(
                padding: const EdgeInsetsDirectional.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      key: const ValueKey('contact_name_field'),
                      controller: _nameController,
                      style: theme.textTheme.bodyLarge,
                      decoration: InputDecoration(
                        labelText: l10n.contactNameLabel,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const ValueKey('contact_phone_field'),
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: theme.textTheme.bodyLarge,
                      decoration: InputDecoration(
                        labelText: l10n.phoneLabel,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const ValueKey('contact_relation_field'),
                      controller: _relationController,
                      style: theme.textTheme.bodyLarge,
                      decoration: InputDecoration(
                        labelText: l10n.contactRelationLabel,
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 54,
                      child: ElevatedButton.icon(
                        key: const ValueKey('add_contact_btn'),
                        onPressed: _isSaving ? null : _submit,
                        icon: const Icon(Icons.person_add_alt_1_rounded),
                        label: Text(l10n.addContactButton),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: contactsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(err.toString()),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () => ref.invalidate(emergencyContactsNotifierProvider),
                        icon: const Icon(Icons.refresh_rounded),
                        label: Text(l10n.retry),
                      ),
                    ],
                  ),
                ),
                data: (contacts) => ListView.separated(
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: contacts.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final contact = contacts[index];
                    return Card(
                      key: ValueKey('contact_card_${contact.id}'),
                      child: ListTile(
                        leading: const Icon(
                          Icons.contact_phone_rounded,
                          color: Color(0xFF00796B),
                          size: 32,
                        ),
                        title: Text(
                          contact.name,
                          style: theme.textTheme.titleMedium,
                        ),
                        subtitle: Text(
                          contact.relationship != null
                              ? '${contact.phone} • ${contact.relationship}'
                              : contact.phone,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
