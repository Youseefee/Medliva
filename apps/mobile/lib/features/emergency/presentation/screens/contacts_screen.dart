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

  static List<EmergencyContactModel> _sorted(
    List<EmergencyContactModel> list,
  ) {
    final copy = [...list]
      ..sort((a, b) {
        if (a.isPrimary == b.isPrimary) return 0;
        return a.isPrimary ? -1 : 1;
      });
    return copy;
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
    state = AsyncValue.data(_sorted([...current, created]));
    return created;
  }

  Future<EmergencyContactModel> updateContact(
    String contactId,
    EmergencyContactUpdateInput input,
  ) async {
    final repo = ref.read(emergencyRepositoryProvider);
    final updated = await repo.updateContact(contactId, input);
    final current = state.value ?? const [];
    final next = [
      for (final item in current)
        if (item.id == contactId) updated else item,
    ];
    state = AsyncValue.data(_sorted(next));
    return updated;
  }

  Future<void> deleteContact(String contactId) async {
    final repo = ref.read(emergencyRepositoryProvider);
    await repo.deleteContact(contactId);
    final current = state.value ?? const [];
    state = AsyncValue.data(
      current.where((item) => item.id != contactId).toList(),
    );
  }
}

final emergencyContactsNotifierProvider =
    AsyncNotifierProvider<
      EmergencyContactsNotifier,
      List<EmergencyContactModel>
    >(EmergencyContactsNotifier.new);

class EmergencyContactsScreen extends ConsumerStatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  ConsumerState<EmergencyContactsScreen> createState() =>
      _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState
    extends ConsumerState<EmergencyContactsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _relationController = TextEditingController();
  bool _isPrimary = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _relationController.dispose();
    super.dispose();
  }

  String? _validatePhone(String? value, AppLocalizations l10n) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty || trimmed.length < 6 || trimmed.length > 20) {
      return l10n.contactPhoneRequired;
    }
    return null;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final relation = _relationController.text.trim();

    setState(() => _isSaving = true);
    try {
      await ref
          .read(emergencyContactsNotifierProvider.notifier)
          .addContact(
            EmergencyContactCreateInput(
              name: name,
              phone: phone,
              relationship: relation.isEmpty ? null : relation,
              isPrimary: _isPrimary,
            ),
          );
      _nameController.clear();
      _phoneController.clear();
      _relationController.clear();
      if (mounted) {
        setState(() => _isPrimary = false);
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.contactSavedSuccess)));
      }
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

  Future<void> _openEditDialog(EmergencyContactModel contact) async {
    final l10n = AppLocalizations.of(context)!;
    final savedInput = await showDialog<EmergencyContactUpdateInput>(
      context: context,
      builder: (_) => _EditEmergencyContactDialog(contact: contact),
    );

    if (savedInput == null || !mounted) return;
    try {
      await ref
          .read(emergencyContactsNotifierProvider.notifier)
          .updateContact(contact.id, savedInput);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.contactSavedSuccess)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _confirmDelete(EmergencyContactModel contact) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteButton),
        content: Text(l10n.contactDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
            child: Text(l10n.cancelButton),
          ),
          ElevatedButton(
            key: const ValueKey('confirm_delete_contact_btn'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
              minimumSize: const Size(0, 48),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.deleteButton),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    try {
      await ref
          .read(emergencyContactsNotifierProvider.notifier)
          .deleteContact(contact.id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.contactDeletedSuccess)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final contactsAsync = ref.watch(emergencyContactsNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.emergencyContactsTitle)),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(emergencyContactsNotifierProvider.future),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsetsDirectional.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  margin: EdgeInsetsDirectional.zero,
                  child: Padding(
                    padding: const EdgeInsetsDirectional.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            key: const ValueKey('contact_name_field'),
                            controller: _nameController,
                            textInputAction: TextInputAction.next,
                            style: theme.textTheme.bodyLarge,
                            decoration: InputDecoration(
                              labelText: l10n.contactNameLabel,
                            ),
                            validator: (v) => (v?.trim().isEmpty ?? true)
                                ? l10n.contactNameRequired
                                : null,
                          ),
                          const SizedBox(height: 12),
                          Directionality(
                            textDirection: TextDirection.ltr,
                            child: TextFormField(
                              key: const ValueKey('contact_phone_field'),
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.next,
                              maxLength: 20,
                              style: theme.textTheme.bodyLarge,
                              decoration: InputDecoration(
                                labelText: l10n.phoneLabel,
                                counterText: '',
                              ),
                              validator: (v) => _validatePhone(v, l10n),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            key: const ValueKey('contact_relation_field'),
                            controller: _relationController,
                            textInputAction: TextInputAction.done,
                            style: theme.textTheme.bodyLarge,
                            decoration: InputDecoration(
                              labelText: l10n.contactRelationLabel,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SwitchListTile(
                            key: const ValueKey('contact_primary_switch'),
                            contentPadding: EdgeInsetsDirectional.zero,
                            title: Text(
                              l10n.contactPrimaryLabel,
                              style: theme.textTheme.bodyLarge,
                            ),
                            value: _isPrimary,
                            onChanged: _isSaving
                                ? null
                                : (value) => setState(() => _isPrimary = value),
                          ),
                          const SizedBox(height: 10),
                          ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 54),
                            child: ElevatedButton.icon(
                              key: const ValueKey('add_contact_btn'),
                              onPressed: _isSaving ? null : _submit,
                              icon: _isSaving
                                  ? SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: theme.colorScheme.onPrimary,
                                      ),
                                    )
                                  : const Icon(Icons.person_add_alt_1_rounded),
                              label: Text(l10n.addContactButton),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                contactsAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsetsDirectional.symmetric(vertical: 32),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (err, _) => Padding(
                    padding: const EdgeInsetsDirectional.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 44,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          err.toString(),
                          style: theme.textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 48),
                          child: ElevatedButton.icon(
                            onPressed: () => ref.invalidate(
                              emergencyContactsNotifierProvider,
                            ),
                            icon: const Icon(Icons.refresh_rounded),
                            label: Text(l10n.retry),
                          ),
                        ),
                      ],
                    ),
                  ),
                  data: (contacts) {
                    if (contacts.isEmpty) {
                      return Card(
                        key: const ValueKey('contacts_empty_state'),
                        child: Padding(
                          padding: const EdgeInsetsDirectional.all(24),
                          child: Column(
                            children: [
                              Icon(
                                Icons.contact_emergency_rounded,
                                size: 48,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                l10n.noEmergencyContacts,
                                style: theme.textTheme.bodyLarge,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: [
                        for (final contact in contacts) ...[
                          Card(
                            key: ValueKey('contact_card_${contact.id}'),
                            child: Padding(
                              padding: const EdgeInsetsDirectional.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.contact_phone_rounded,
                                    color: theme.colorScheme.primary,
                                    size: 32,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 4,
                                          crossAxisAlignment:
                                              WrapCrossAlignment.center,
                                          children: [
                                            Text(
                                              contact.name,
                                              style: theme.textTheme.titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                            ),
                                            if (contact.isPrimary)
                                              Container(
                                                key: ValueKey(
                                                  'primary_badge_${contact.id}',
                                                ),
                                                padding:
                                                    const EdgeInsetsDirectional.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: theme
                                                      .colorScheme
                                                      .primaryContainer,
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: Text(
                                                  l10n.contactPrimaryLabel,
                                                  style: theme
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                        color: theme
                                                            .colorScheme
                                                            .onPrimaryContainer,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 2,
                                          crossAxisAlignment:
                                              WrapCrossAlignment.center,
                                          children: [
                                            Directionality(
                                              textDirection: TextDirection.ltr,
                                              child: Text(
                                                contact.phone,
                                                style:
                                                    theme.textTheme.bodyMedium,
                                              ),
                                            ),
                                            if (contact.relationship != null &&
                                                contact.relationship!
                                                    .trim()
                                                    .isNotEmpty)
                                              Text(
                                                '• ${contact.relationship!.trim()}',
                                                style:
                                                    theme.textTheme.bodyMedium,
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    key: ValueKey(
                                      'edit_contact_btn_${contact.id}',
                                    ),
                                    tooltip: l10n.contactEditTitle,
                                    constraints: const BoxConstraints(
                                      minWidth: 48,
                                      minHeight: 48,
                                    ),
                                    icon: Icon(
                                      Icons.edit_rounded,
                                      color: theme.colorScheme.primary,
                                    ),
                                    onPressed: () => _openEditDialog(contact),
                                  ),
                                  IconButton(
                                    key: ValueKey(
                                      'delete_contact_btn_${contact.id}',
                                    ),
                                    tooltip: l10n.deleteButton,
                                    constraints: const BoxConstraints(
                                      minWidth: 48,
                                      minHeight: 48,
                                    ),
                                    icon: Icon(
                                      Icons.delete_outline_rounded,
                                      color: theme.colorScheme.error,
                                    ),
                                    onPressed: () => _confirmDelete(contact),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EditEmergencyContactDialog extends StatefulWidget {
  const _EditEmergencyContactDialog({required this.contact});

  final EmergencyContactModel contact;

  @override
  State<_EditEmergencyContactDialog> createState() =>
      _EditEmergencyContactDialogState();
}

class _EditEmergencyContactDialogState
    extends State<_EditEmergencyContactDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _relationCtrl;
  late bool _isPrimary;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.contact.name);
    _phoneCtrl = TextEditingController(text: widget.contact.phone);
    _relationCtrl = TextEditingController(
      text: widget.contact.relationship ?? '',
    );
    _isPrimary = widget.contact.isPrimary;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _relationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.contactEditTitle),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                key: const ValueKey('edit_contact_name_field'),
                controller: _nameCtrl,
                decoration: InputDecoration(labelText: l10n.contactNameLabel),
                validator: (v) => (v?.trim().isEmpty ?? true)
                    ? l10n.contactNameRequired
                    : null,
              ),
              const SizedBox(height: 12),
              Directionality(
                textDirection: TextDirection.ltr,
                child: TextFormField(
                  key: const ValueKey('edit_contact_phone_field'),
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  maxLength: 20,
                  decoration: InputDecoration(
                    labelText: l10n.phoneLabel,
                    counterText: '',
                  ),
                  validator: (v) {
                    final trimmed = v?.trim() ?? '';
                    if (trimmed.isEmpty ||
                        trimmed.length < 6 ||
                        trimmed.length > 20) {
                      return l10n.contactPhoneRequired;
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const ValueKey('edit_contact_relation_field'),
                controller: _relationCtrl,
                decoration: InputDecoration(
                  labelText: l10n.contactRelationLabel,
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                key: const ValueKey('edit_contact_primary_switch'),
                contentPadding: EdgeInsetsDirectional.zero,
                title: Text(l10n.contactPrimaryLabel),
                value: _isPrimary,
                onChanged: (value) => setState(() => _isPrimary = value),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
          child: Text(l10n.cancelButton),
        ),
        ElevatedButton(
          key: const ValueKey('save_edit_contact_btn'),
          style: ElevatedButton.styleFrom(minimumSize: const Size(0, 48)),
          onPressed: () {
            if (!(_formKey.currentState?.validate() ?? false)) return;
            final rel = _relationCtrl.text.trim();
            Navigator.of(context).pop(
              EmergencyContactUpdateInput(
                name: _nameCtrl.text.trim(),
                phone: _phoneCtrl.text.trim(),
                relationship: rel.isEmpty ? null : rel,
                isPrimary: _isPrimary,
              ),
            );
          },
          child: Text(l10n.saveButton),
        ),
      ],
    );
  }
}
