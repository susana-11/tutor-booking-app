import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../providers/auth_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetLink() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    
    final success = await authProvider.forgotPassword(
      email: _emailController.text.trim(),
    );

    if (mounted) {
      if (success) {
        setState(() {
          _emailSent = true;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.error ?? 'Failed to send reset link'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgot Password'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.textPrimaryColor,
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return LoadingOverlay(
            isLoading: authProvider.isLoading,
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.spacingLG),
                child: _emailSent ? _buildSuccessView() : _buildFormView(),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFormView() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppTheme.spacingXL),
          
          // Header
          _buildHeader(),
          
          const SizedBox(height: AppTheme.spacingXXL),
          
          // Email Input
          EmailTextField(
            controller: _emailController,
          ),
          
          const SizedBox(height: AppTheme.spacingLG),
          
          // Send Reset Link Button
          Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              return CustomButton(
                text: 'Send Reset Link',
                onPressed: _sendResetLink,
                isLoading: authProvider.isLoading,
              );
            },
          ),
          
          const SizedBox(height: AppTheme.spacingXL),
          
          // Back to Login
          _buildBackToLogin(),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppTheme.spacingXXL),
        
        // Success Icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppTheme.successColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusXL),
          ),
          child: const Icon(
            Icons.check_circle_outline,
            size: 40,
            color: AppTheme.successColor,
          ),
        ),
        
        const SizedBox(height: AppTheme.spacingLG),
        
        Text(
          'Reset Link Sent!',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: AppTheme.spacingMD),
        
        Text(
          'We\'ve sent a password reset link to ${_emailController.text}. Please check your email and follow the instructions to reset your password.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.textSecondaryColor,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: AppTheme.spacingXL),
        
        // Email Display
        Container(
          padding: const EdgeInsets.all(AppTheme.spacingMD),
          decoration: BoxDecoration(
            color: AppTheme.successColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            border: Border.all(
              color: AppTheme.successColor.withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.email,
                color: AppTheme.successColor,
                size: 20,
              ),
              
              const SizedBox(width: AppTheme.spacingMD),
              
              Expanded(
                child: Text(
                  _emailController.text,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: AppTheme.spacingXL),
        
        // Resend Button
        CustomButton(
          text: 'Resend Email',
          type: ButtonType.outline,
          onPressed: () {
            setState(() {
              _emailSent = false;
            });
          },
        ),
        
        const SizedBox(height: AppTheme.spacingLG),
        
        // Back to Login
        _buildBackToLogin(),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppTheme.radiusXL),
          ),
          child: const Icon(
            Icons.lock_reset,
            size: 40,
            color: AppTheme.primaryColor,
          ),
        ),
        
        const SizedBox(height: AppTheme.spacingLG),
        
        Text(
          'Reset Password',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        
        const SizedBox(height: AppTheme.spacingSM),
        
        Text(
          'Enter your email address and we\'ll send you a link to reset your password.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.textSecondaryColor,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildBackToLogin() {
    return TextButton(
      onPressed: () {
        context.go('/login');
      },
      child: const Text(
        'Back to Login',
        style: TextStyle(
          color: AppTheme.primaryColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}