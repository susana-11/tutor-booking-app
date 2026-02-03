import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/loading_overlay.dart';
import '../providers/auth_provider.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;

  const EmailVerificationScreen({
    Key? key,
    required this.email,
  }) : super(key: key);

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  
  Timer? _timer;
  int _resendCountdown = 0;
  bool _canResend = true;

  @override
  void dispose() {
    _otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startResendCountdown() {
    setState(() {
      _canResend = false;
      _resendCountdown = 60;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _resendCountdown--;
      });

      if (_resendCountdown <= 0) {
        timer.cancel();
        setState(() {
          _canResend = true;
        });
      }
    });
  }

  Future<void> _verifyEmail() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    
    final success = await authProvider.verifyEmail(
      email: widget.email,
      otp: _otpController.text.trim(),
    );

    if (mounted) {
      if (success) {
        // Navigation is handled by the router redirect logic
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.error ?? 'Verification failed'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _resendOTP() async {
    if (!_canResend) return;

    final authProvider = context.read<AuthProvider>();
    
    final success = await authProvider.resendOTP(email: widget.email);

    if (mounted) {
      if (success) {
        _startResendCountdown();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification code sent successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.error ?? 'Failed to send verification code'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return LoadingOverlay(
            isLoading: authProvider.isLoading,
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.spacingLG),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: AppTheme.spacingXXL),
                      
                      // Header
                      _buildHeader(),
                      
                      const SizedBox(height: AppTheme.spacingXXL),
                      
                      // Email Display
                      _buildEmailDisplay(),
                      
                      const SizedBox(height: AppTheme.spacingXL),
                      
                      // OTP Input
                      _buildOTPInput(),
                      
                      const SizedBox(height: AppTheme.spacingLG),
                      
                      // Verify Button
                      CustomButton(
                        text: 'Verify Email',
                        onPressed: _verifyEmail,
                        isLoading: authProvider.isLoading,
                      ),
                      
                      const SizedBox(height: AppTheme.spacingLG),
                      
                      // Resend OTP
                      _buildResendSection(),
                      
                      const SizedBox(height: AppTheme.spacingXL),
                      
                      // Back to Login
                      _buildBackToLogin(),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
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
            Icons.email_outlined,
            size: 40,
            color: AppTheme.primaryColor,
          ),
        ),
        
        const SizedBox(height: AppTheme.spacingLG),
        
        Text(
          'Verify Your Email',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        
        const SizedBox(height: AppTheme.spacingSM),
        
        Text(
          'We\'ve sent a verification code to your email address. Please enter it below to verify your account.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.textSecondaryColor,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildEmailDisplay() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMD),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.email,
            color: AppTheme.primaryColor,
            size: 20,
          ),
          
          const SizedBox(width: AppTheme.spacingMD),
          
          Expanded(
            child: Text(
              widget.email,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOTPInput() {
    return CustomTextField(
      controller: _otpController,
      label: 'Verification Code',
      hintText: 'Enter 6-digit code',
      keyboardType: TextInputType.number,
      prefixIcon: Icons.security,
      maxLength: 6,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter the verification code';
        }
        if (value.length != 6) {
          return 'Verification code must be 6 digits';
        }
        return null;
      },
      onChanged: (value) {
        // Auto-verify when 6 digits are entered
        if (value.length == 6) {
          _verifyEmail();
        }
      },
    );
  }

  Widget _buildResendSection() {
    return Column(
      children: [
        Text(
          'Didn\'t receive the code?',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.textSecondaryColor,
          ),
        ),
        
        const SizedBox(height: AppTheme.spacingSM),
        
        if (_canResend)
          TextButton(
            onPressed: _resendOTP,
            child: const Text(
              'Resend Code',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        else
          Text(
            'Resend code in ${_resendCountdown}s',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondaryColor,
            ),
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
          color: AppTheme.textSecondaryColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}