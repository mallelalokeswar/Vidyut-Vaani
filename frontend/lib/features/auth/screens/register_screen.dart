import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vidyut_vaani/core/constants/app_constants.dart';
import 'package:vidyut_vaani/core/services/auth_api_service.dart';
import 'package:vidyut_vaani/core/theme/app_theme.dart';
import 'package:vidyut_vaani/core/widgets/vv_button.dart';
import 'package:vidyut_vaani/core/widgets/vv_text_field.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _localityCtrl = TextEditingController();
  final _meterCtrl = TextEditingController();

  bool _obscurePw = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    for (final c in [
      _fullNameCtrl, _emailCtrl, _usernameCtrl, _passwordCtrl,
      _confirmCtrl, _phoneCtrl, _localityCtrl, _meterCtrl
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      await AuthApiService.instance.register(
        fullName: _fullNameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        username: _usernameCtrl.text.trim(),
        password: _passwordCtrl.text,
        phone: _phoneCtrl.text.trim().isNotEmpty ? _phoneCtrl.text.trim() : null,
        locality: _localityCtrl.text.trim().isNotEmpty ? _localityCtrl.text.trim() : null,
        meterNumber: _meterCtrl.text.trim().isNotEmpty ? _meterCtrl.text.trim() : null,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created! Please log in.'),
            backgroundColor: AppColors.success,
          ),
        );
        context.go(AppConstants.routeLogin);
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navyBlue,
      appBar: AppBar(
        title: const Text('Create Account'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Join VidyuthVaani',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Create your citizen account to report outages and track complaints.',
                style: TextStyle(fontSize: 13, color: AppColors.grey),
              ),
              const SizedBox(height: 28),
              _sectionLabel('Personal Information'),
              const SizedBox(height: 12),
              VvTextField(
                controller: _fullNameCtrl,
                label: 'Full Name *',
                prefixIcon: Icons.badge_outlined,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Full name is required.' : null,
              ),
              const SizedBox(height: 14),
              VvTextField(
                controller: _emailCtrl,
                label: 'Email Address *',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Email is required.';
                  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())) {
                    return 'Enter a valid email address.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              VvTextField(
                controller: _usernameCtrl,
                label: 'Username *',
                prefixIcon: Icons.alternate_email,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Username is required.';
                  if (!RegExp(r'^[a-zA-Z0-9_]{3,30}$').hasMatch(v.trim())) {
                    return 'Username: 3–30 alphanumeric characters or underscores.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              VvTextField(
                controller: _phoneCtrl,
                label: 'Phone Number (optional)',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 24),
              _sectionLabel('Account Security'),
              const SizedBox(height: 12),
              VvTextField(
                controller: _passwordCtrl,
                label: 'Password *',
                prefixIcon: Icons.lock_outline,
                obscureText: _obscurePw,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePw ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: AppColors.grey,
                  ),
                  onPressed: () => setState(() => _obscurePw = !_obscurePw),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Password is required.';
                  if (v.length < 8) return 'At least 8 characters.';
                  if (!RegExp(r'[A-Z]').hasMatch(v)) return 'Include an uppercase letter.';
                  if (!RegExp(r'[a-z]').hasMatch(v)) return 'Include a lowercase letter.';
                  if (!RegExp(r'\d').hasMatch(v)) return 'Include a digit.';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              VvTextField(
                controller: _confirmCtrl,
                label: 'Confirm Password *',
                prefixIcon: Icons.lock_outline,
                obscureText: _obscureConfirm,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: AppColors.grey,
                  ),
                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
                validator: (v) {
                  if (v != _passwordCtrl.text) return 'Passwords do not match.';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              _sectionLabel('Service Details (optional)'),
              const SizedBox(height: 12),
              VvTextField(
                controller: _localityCtrl,
                label: 'Locality / Area',
                prefixIcon: Icons.location_on_outlined,
              ),
              const SizedBox(height: 14),
              VvTextField(
                controller: _meterCtrl,
                label: 'Meter Number',
                prefixIcon: Icons.electric_meter_outlined,
              ),
              const SizedBox(height: 24),
              if (_errorMessage != null) ...[
                Container(
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
                          _errorMessage!,
                          style: const TextStyle(color: AppColors.error, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              VvButton(
                label: 'Create Account',
                isLoading: _isLoading,
                onPressed: _isLoading ? null : _register,
                icon: Icons.person_add_outlined,
              ),
              const SizedBox(height: 20),
              Center(
                child: TextButton(
                  onPressed: () => context.go(AppConstants.routeLogin),
                  child: const Text(
                    'Already have an account? Login',
                    style: TextStyle(color: AppColors.teal),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.teal,
        letterSpacing: 1.2,
      ),
    );
  }
}
