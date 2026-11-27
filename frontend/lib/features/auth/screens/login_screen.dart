import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vidyut_vaani/core/constants/app_constants.dart';
import 'package:vidyut_vaani/core/theme/app_theme.dart';
import 'package:vidyut_vaani/features/auth/providers/auth_provider.dart';
import 'package:vidyut_vaani/features/auth/widgets/role_selection_card.dart';
import 'package:vidyut_vaani/core/widgets/vv_text_field.dart';
import 'package:vidyut_vaani/core/widgets/vv_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _identifierCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  String _selectedRole = AppConstants.roleCitizen;
  bool _obscurePassword = true;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _identifierCtrl.dispose();
    _passwordCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _onRoleSelected(String role) {
    setState(() => _selectedRole = role);
    ref.read(authProvider.notifier).clearError();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    await ref.read(authProvider.notifier).login(
          identifier: _identifierCtrl.text.trim(),
          password: _passwordCtrl.text,
          role: _selectedRole,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.status == AuthStatus.loading;
    final error = authState.errorMessage;

    return Scaffold(
      backgroundColor: AppColors.navyBlue,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── Header ──────────────────────────────────────────────
                _AppHeader(),
                const SizedBox(height: 36),

                // ── Role selection ───────────────────────────────────────
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Select your role',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.grey,
                          letterSpacing: 0.4,
                        ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: RoleSelectionCard(
                        role: AppConstants.roleCitizen,
                        label: 'Citizen',
                        icon: Icons.people_alt_outlined,
                        accentColor: AppColors.citizenAccent,
                        isSelected: _selectedRole == AppConstants.roleCitizen,
                        onTap: () => _onRoleSelected(AppConstants.roleCitizen),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: RoleSelectionCard(
                        role: AppConstants.roleAdmin,
                        label: 'Admin',
                        icon: Icons.admin_panel_settings_outlined,
                        accentColor: AppColors.adminAccent,
                        isSelected: _selectedRole == AppConstants.roleAdmin,
                        onTap: () => _onRoleSelected(AppConstants.roleAdmin),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: RoleSelectionCard(
                        role: AppConstants.roleOperator,
                        label: 'Operator',
                        icon: Icons.engineering_outlined,
                        accentColor: AppColors.operatorAccent,
                        isSelected: _selectedRole == AppConstants.roleOperator,
                        onTap: () => _onRoleSelected(AppConstants.roleOperator),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // ── Form ─────────────────────────────────────────────────
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      VvTextField(
                        controller: _identifierCtrl,
                        label: 'Email or Username',
                        hint: 'Enter your email or username',
                        prefixIcon: Icons.person_outline,
                        textInputAction: TextInputAction.next,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Email or username is required.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      VvTextField(
                        controller: _passwordCtrl,
                        label: 'Password',
                        hint: 'Enter your password',
                        prefixIcon: Icons.lock_outline,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppColors.grey,
                          ),
                          onPressed: () =>
                              setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Password is required.';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // ── Forgot password link ─────────────────────────────────
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push(AppConstants.routeForgotPassword),
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(color: AppColors.teal),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // ── Error banner ─────────────────────────────────────────
                if (error != null) ...[
                  _ErrorBanner(message: error),
                  const SizedBox(height: 16),
                ],

                // ── Login button ─────────────────────────────────────────
                VvButton(
                  label: 'Login',
                  isLoading: isLoading,
                  onPressed: isLoading ? null : _submit,
                ),
                const SizedBox(height: 24),

                // ── Divider ───────────────────────────────────────────────
                Row(
                  children: [
                    const Expanded(child: Divider(color: AppColors.navyBlueLight)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'New to VidyuthVaani?',
                        style: TextStyle(color: AppColors.grey, fontSize: 13),
                      ),
                    ),
                    const Expanded(child: Divider(color: AppColors.navyBlueLight)),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Register link ────────────────────────────────────────
                OutlinedButton.icon(
                  icon: const Icon(Icons.person_add_outlined, color: AppColors.teal),
                  label: const Text(
                    'Create Citizen Account',
                    style: TextStyle(color: AppColors.teal),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    side: const BorderSide(color: AppColors.teal),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => context.push(AppConstants.routeRegister),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _AppHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.teal, AppColors.tealDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: AppColors.teal.withOpacity(0.35),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.bolt, size: 52, color: AppColors.navyBlue),
        ),
        const SizedBox(height: 20),
        const Text(
          'VidyuthVaani',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: AppColors.white,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Smart Electricity Services for Every Citizen',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: AppColors.grey,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.teal.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'Powered by DISCOMS of India',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.teal,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.error.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.error, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
