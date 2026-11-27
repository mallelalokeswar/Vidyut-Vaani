import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vidyut_vaani/core/constants/app_constants.dart';
import 'package:vidyut_vaani/core/services/auth_api_service.dart';
import 'package:vidyut_vaani/core/theme/app_theme.dart';
import 'package:vidyut_vaani/core/widgets/vv_button.dart';
import 'package:vidyut_vaani/core/widgets/vv_text_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _isLoading = false;
  bool _submitted = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await AuthApiService.instance.forgotPassword(_emailCtrl.text.trim());
      setState(() => _submitted = true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navyBlue,
      appBar: AppBar(
        title: const Text('Forgot Password'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _submitted ? _successView() : _formView(),
      ),
    );
  }

  Widget _formView() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lock_reset, size: 56, color: AppColors.teal),
          const SizedBox(height: 20),
          const Text(
            'Reset your password',
            style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter your registered email address. If the account exists, you will receive a password reset link.',
            style: TextStyle(fontSize: 13, color: AppColors.grey),
          ),
          const SizedBox(height: 28),
          VvTextField(
            controller: _emailCtrl,
            label: 'Email Address',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Email is required.';
              if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())) {
                return 'Enter a valid email.';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          VvButton(label: 'Send Reset Link', isLoading: _isLoading, onPressed: _submit),
        ],
      ),
    );
  }

  Widget _successView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.mark_email_read_outlined, size: 72, color: AppColors.success),
        const SizedBox(height: 24),
        const Text(
          'Check your inbox',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.white),
        ),
        const SizedBox(height: 10),
        Text(
          'If ${_emailCtrl.text} is registered, a password reset link has been sent.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: AppColors.grey),
        ),
        const SizedBox(height: 32),
        VvButton(
          label: 'Back to Login',
          onPressed: () => context.go(AppConstants.routeLogin),
        ),
      ],
    );
  }
}
