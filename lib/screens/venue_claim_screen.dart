import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../data/pricing.dart';
import '../models/event.dart';
import '../models/event_claim.dart';
import '../providers/auth_provider.dart';
import '../providers/subscription_provider.dart';
import '../repositories/event_claim_repository.dart';
import '../theme/theme.dart';

/// Verify first. First approved claim is free; later claims need Premium.
class VenueClaimScreen extends StatelessWidget {
  final Event event;
  const VenueClaimScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return _VerifyOwnershipView(event: event);
  }
}

class _VerifyOwnershipView extends StatefulWidget {
  final Event event;
  const _VerifyOwnershipView({required this.event});

  @override
  State<_VerifyOwnershipView> createState() => _VerifyOwnershipViewState();
}

class _VerifyOwnershipViewState extends State<_VerifyOwnershipView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _orgController = TextEditingController();
  final _proofUrlController = TextEditingController();
  final _statementController = TextEditingController();
  ClaimRole _role = ClaimRole.promoter;
  ClaimProofMethod _proof = ClaimProofMethod.officialEmail;
  bool _authorized = false;
  bool _saving = false;
  EventClaim? _result;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _orgController.dispose();
    _proofUrlController.dispose();
    _statementController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_authorized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Confirm you are authorized to represent this event.')),
      );
      return;
    }
    final auth = context.read<AuthProvider>();
    final uid = auth.user?.id;
    if (uid == null || auth.isGuest) {
      context.push('/login');
      return;
    }
    setState(() => _saving = true);
    final claim = await context.read<EventClaimRepository>().submit(
          EventClaim(
            id: '',
            eventId: widget.event.id,
            eventTitle: widget.event.title,
            venueName: widget.event.location,
            userId: uid,
            fullName: _nameController.text.trim(),
            email: _emailController.text.trim(),
            phone: _phoneController.text.trim(),
            organization: _orgController.text.trim(),
            role: _role,
            proofMethod: _proof,
            proofUrl: _proofUrlController.text.trim(),
            statement: _statementController.text.trim(),
            status: ClaimStatus.pending,
            createdAt: DateTime.now(),
          ),
          isPremium: context.read<SubscriptionProvider>().isSubscribed,
        );
    if (!mounted) return;
    setState(() {
      _saving = false;
      _result = claim;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    final sub = context.watch<SubscriptionProvider>();

    if (_result != null) {
      return _ClaimResultView(
        event: widget.event,
        claim: _result!,
        isPremium: sub.isSubscribed,
        appColors: appColors,
        text: text,
        colors: colors,
      );
    }

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Verify this listing'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Verify first. Your first approved claim is free. '
                'After that, Premium ($kPremiumMonthlyLabel after a $kPremiumTrialLabel) unlocks more claims.',
                style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: AppTheme.spacingLg),
              Text('Claiming page for', style: text.labelMedium?.copyWith(color: colors.onSurfaceVariant)),
              const SizedBox(height: AppTheme.spacingXs),
              Text(widget.event.title, style: text.titleMedium),
              Text(widget.event.location, style: text.bodySmall),
              const SizedBox(height: AppTheme.spacingLg),
              Text('Your details', style: text.titleSmall),
              const SizedBox(height: AppTheme.spacingMd),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full name *',
                  prefixIcon: Icon(Icons.person_rounded),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your name' : null,
              ),
              const SizedBox(height: AppTheme.spacingMd),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Work email *',
                  prefixIcon: Icon(Icons.email_rounded),
                  helperText: 'A venue or company domain verifies faster than Gmail.',
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Please enter your email';
                  if (!isValidEmail(v)) return 'Enter a valid email address';
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.spacingMd),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone number',
                  prefixIcon: Icon(Icons.phone_rounded),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: AppTheme.spacingMd),
              TextFormField(
                controller: _orgController,
                decoration: const InputDecoration(
                  labelText: 'Organization *',
                  prefixIcon: Icon(Icons.apartment_rounded),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your organization' : null,
              ),
              const SizedBox(height: AppTheme.spacingMd),
              DropdownButtonFormField<ClaimRole>(
                initialValue: _role,
                decoration: const InputDecoration(
                  labelText: 'Your role',
                  prefixIcon: Icon(Icons.badge_rounded),
                ),
                items: ClaimRole.values
                    .map((r) => DropdownMenuItem(value: r, child: Text(r.label)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _role = v);
                },
              ),
              const SizedBox(height: AppTheme.spacingMd),
              DropdownButtonFormField<ClaimProofMethod>(
                initialValue: _proof,
                decoration: const InputDecoration(
                  labelText: 'How we can verify you',
                  prefixIcon: Icon(Icons.verified_user_rounded),
                ),
                items: ClaimProofMethod.values
                    .map((p) => DropdownMenuItem(value: p, child: Text(p.label)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _proof = v);
                },
              ),
              const SizedBox(height: AppTheme.spacingMd),
              TextFormField(
                controller: _proofUrlController,
                decoration: const InputDecoration(
                  labelText: 'Website or social proof (optional)',
                  prefixIcon: Icon(Icons.link_rounded),
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: AppTheme.spacingMd),
              TextFormField(
                controller: _statementController,
                decoration: const InputDecoration(
                  labelText: 'How you are authorized *',
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
                maxLines: 3,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Tell us how you represent this event'
                    : null,
              ),
              const SizedBox(height: AppTheme.spacingMd),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _authorized,
                onChanged: (v) => setState(() => _authorized = v ?? false),
                title: Text(
                  'I am authorized to represent this venue or event. False claims may result in account suspension.',
                  style: text.bodySmall,
                ),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: AppTheme.spacingLg),
              FilledButton.icon(
                onPressed: _saving ? null : _submit,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.verified_rounded),
                label: Text(_saving ? 'Submitting…' : 'Submit verification'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, AppTheme.buttonHeight),
                  backgroundColor: appColors.proGold,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: AppTheme.spacingXl),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClaimResultView extends StatelessWidget {
  final Event event;
  final EventClaim claim;
  final bool isPremium;
  final AppColorsExtension appColors;
  final TextTheme text;
  final ColorScheme colors;

  const _ClaimResultView({
    required this.event,
    required this.claim,
    required this.isPremium,
    required this.appColors,
    required this.text,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final needsPay = claim.status == ClaimStatus.approved && !claim.unlocked;
    final pending = claim.status == ClaimStatus.pending;
    final title = claim.unlocked
        ? 'You can edit this listing'
        : pending
            ? 'Verification submitted'
            : 'Verified — subscribe to unlock';
    final body = claim.unlocked
        ? 'Your first claim is free. You can now update “${event.title}”.'
        : pending
            ? 'We received your request for “${event.title}”. '
                'Work emails are approved automatically; personal inboxes are reviewed within 2 business days. '
                'Your first approved claim stays free.'
            : 'This listing is verified, but you already used your free claim. '
                'Start a $kPremiumTrialLabel to unlock edits, recurring tools, and featured placement.';

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingXl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                claim.unlocked
                    ? Icons.verified_rounded
                    : pending
                        ? Icons.mark_email_read_rounded
                        : Icons.workspace_premium_rounded,
                size: 72,
                color: appColors.proGold,
              ),
              const SizedBox(height: AppTheme.spacingLg),
              Text(title, style: text.headlineSmall, textAlign: TextAlign.center),
              const SizedBox(height: AppTheme.spacingSm),
              Text(
                body,
                style: text.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacingXl),
              if (needsPay && !isPremium)
                FilledButton(
                  onPressed: () async {
                    final ok = await context.push<bool>('/paywall');
                    if (!context.mounted) return;
                    if (ok == true) {
                      await context.read<EventClaimRepository>().unlockEligibleForUser(claim.userId);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Claim unlocked. You can edit this listing.')),
                      );
                      context.pop();
                    }
                  },
                  child: Text('Start $kPremiumTrialLabel'),
                )
              else
                ElevatedButton(
                  onPressed: () => context.pop(),
                  child: const Text('Back to event'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
