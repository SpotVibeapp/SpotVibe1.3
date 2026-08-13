import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isRegister = false;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  String? _socialLoading; // 'google' | 'facebook' | 'apple' | null

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email is required';
    final re = RegExp(r'^[\w\.\-]+@[\w\-]+\.\w{2,}$');
    if (!re.hasMatch(v.trim())) return 'Enter a valid email address';
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  String? _validateName(String? v) {
    if (!_isRegister) return null;
    if (v == null || v.trim().isEmpty) return 'Full name is required';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    bool success;
    if (_isRegister) {
      success = await auth.register(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
      );
    } else {
      success = await auth.login(
        _emailController.text.trim(),
        _passwordController.text,
      );
    }
    if (success && mounted) context.pop();
  }

  Future<void> _socialLogin(String provider) async {
    if (_socialLoading != null) return;
    setState(() => _socialLoading = provider.toLowerCase());
    final auth = context.read<AuthProvider>();
    bool success = false;
    try {
      switch (provider) {
        case 'Google':
          success = await auth.loginWithGoogle();
          break;
        case 'Facebook':
          success = await auth.loginWithFacebook();
          break;
        case 'Apple':
          success = await auth.loginWithApple();
          break;
      }
    } finally {
      if (mounted) setState(() => _socialLoading = null);
    }
    if (success && mounted) context.pop();
    if (!success && mounted && auth.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error!),
          behavior: SnackBarBehavior.floating,
        ),
      );
      auth.clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Gradient Header ──────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colors.primary,
                      colors.tertiary,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: AppTheme.spacingLg),
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: colors.onPrimary.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.celebration_rounded,
                          size: AppTheme.iconLg + 4,
                          color: colors.onPrimary,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingSm),
                      Text(
                        'SpotVibe',
                        style: text.headlineMedium?.copyWith(
                          color: colors.onPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            leading: IconButton(
              onPressed: () => context.pop(),
              icon: Icon(Icons.arrow_back_rounded, color: colors.onPrimary),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppTheme.spacingSm),
                    Text(
                      _isRegister ? 'Create your account' : 'Welcome back!',
                      style: text.headlineSmall,
                    ),
                    const SizedBox(height: AppTheme.spacingXs),
                    Text(
                      _isRegister
                          ? 'Join thousands discovering local events'
                          : 'Sign in to bookmark, chat, and connect',
                      style: text.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingLg),

                    // ── Error Banner ───────────────────────────────────────
                    if (auth.error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(AppTheme.spacingSm),
                        decoration: BoxDecoration(
                          color: colors.errorContainer,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusSmall),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline_rounded,
                                size: AppTheme.iconSm,
                                color: colors.onErrorContainer),
                            const SizedBox(width: AppTheme.spacingXs),
                            Expanded(
                              child: Text(
                                auth.error!,
                                style: text.bodySmall?.copyWith(
                                    color: colors.onErrorContainer),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingMd),
                    ],

                    // ── Social Login Row ───────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: _SocialButton(
                            label: 'Google',
                            icon: Icons.g_mobiledata_rounded,
                            color: const Color(0xFF4285F4),
                            isLoading: _socialLoading == 'google',
                            onTap: () => _socialLogin('Google'),
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingSm),
                        Expanded(
                          child: _SocialButton(
                            label: 'Facebook',
                            icon: Icons.facebook_rounded,
                            color: const Color(0xFF1877F2),
                            isLoading: _socialLoading == 'facebook',
                            onTap: () => _socialLogin('Facebook'),
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingSm),
                        Expanded(
                          child: _SocialButton(
                            label: 'Apple',
                            icon: Icons.apple_rounded,
                            color: colors.onSurface,
                            isLoading: _socialLoading == 'apple',
                            onTap: () => _socialLogin('Apple'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingLg),

                    // ── Divider ────────────────────────────────────────────
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.spacingSm),
                          child: Text('or continue with email',
                              style: text.labelSmall),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingLg),

                    // ── Name Field (register only) ─────────────────────────
                    if (_isRegister) ...[
                      TextFormField(
                        controller: _nameController,
                        validator: _validateName,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: AppTheme.spacingMd),
                    ],

                    // ── Email Field ────────────────────────────────────────
                    TextFormField(
                      controller: _emailController,
                      validator: _validateEmail,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      onChanged: (_) => auth.clearError(),
                    ),
                    const SizedBox(height: AppTheme.spacingMd),

                    // ── Password Field ─────────────────────────────────────
                    TextFormField(
                      controller: _passwordController,
                      validator: _validatePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          onPressed: () =>
                              setState(() => _obscure = !_obscure),
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                        ),
                      ),
                      obscureText: _obscure,
                      onFieldSubmitted: (_) => _submit(),
                      onChanged: (_) => auth.clearError(),
                    ),

                    // ── Forgot Password ────────────────────────────────────
                    if (!_isRegister) ...[
                      const SizedBox(height: AppTheme.spacingXs),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Password reset requires a backend integration.'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 32),
                          ),
                          child: Text(
                            'Forgot password?',
                            style: text.labelMedium?.copyWith(
                                color: colors.primary),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: AppTheme.spacingLg),

                    // ── Submit Button ──────────────────────────────────────
                    ElevatedButton(
                      onPressed: auth.isLoading ? null : _submit,
                      child: auth.isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colors.onPrimary,
                              ),
                            )
                          : Text(
                              _isRegister ? 'Create Account' : 'Sign In'),
                    ),
                    const SizedBox(height: AppTheme.spacingMd),

                    // ── Toggle Register/Login ──────────────────────────────
                    TextButton(
                      onPressed: () => setState(() {
                        _isRegister = !_isRegister;
                        _formKey.currentState?.reset();
                        auth.clearError();
                      }),
                      child: Text(
                        _isRegister
                            ? 'Already have an account? Sign in'
                            : "Don't have an account? Create one",
                        style:
                            text.labelMedium?.copyWith(color: colors.primary),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingSm),

                    // ── Guest Access ───────────────────────────────────────
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.spacingSm),
                          child: Text('or', style: text.labelSmall),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    OutlinedButton.icon(
                      onPressed: () {
                        context.read<AuthProvider>().continueAsGuest();
                        context.go('/');
                      },
                      icon: const Icon(Icons.person_outline_rounded),
                      label: const Text('Continue as Guest'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        foregroundColor: colors.onSurfaceVariant,
                        side: BorderSide(
                            color: colors.outlineVariant),
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingLg),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isLoading;

  const _SocialButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color: colors.outlineVariant.withValues(alpha: 0.4),
            width: AppTheme.borderDefault,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              SizedBox(
                height: AppTheme.iconMd,
                width: AppTheme.iconMd,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: color,
                ),
              )
            else
              Icon(icon, color: color, size: AppTheme.iconMd),
            const SizedBox(height: 2),
            Text(
              label,
              style: text.labelSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
