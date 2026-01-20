import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase_helpers.dart';

class AuthConfirmationScreen extends StatefulWidget {
  final String? token;
  final String? type;
  
  const AuthConfirmationScreen({
    super.key,
    this.token,
    this.type,
  });

  @override
  State<AuthConfirmationScreen> createState() => _AuthConfirmationScreenState();
}

class _AuthConfirmationScreenState extends State<AuthConfirmationScreen> {
  bool _isLoading = true;
  bool _isSuccess = false;
  String _message = '';

  @override
  void initState() {
    super.initState();
    _handleConfirmation();
  }

  Future<void> _handleConfirmation() async {
    try {
      debugPrint('🔵 [AUTH_CONFIRM] Handling confirmation - Token: ${widget.token}, Type: ${widget.type}');
      
      if (widget.token != null && widget.type != null) {
        // Handle different types of confirmations
        if (widget.type == 'signup') {
          // Email confirmation for signup
          await supabase.auth.verifyOTP(
            token: widget.token!,
            type: OtpType.signup,
          );
          
          setState(() {
            _isSuccess = true;
            _message = 'Email confirmed successfully! Welcome to FocusFlow.';
          });
          
          debugPrint('✅ [AUTH_CONFIRM] Email confirmation successful');
          
          // Navigate to personalization after a short delay
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) {
            context.go('/personalization');
          }
        } else if (widget.type == 'recovery') {
          // Password reset confirmation
          await supabase.auth.verifyOTP(
            token: widget.token!,
            type: OtpType.recovery,
          );
          
          setState(() {
            _isSuccess = true;
            _message = 'Password reset confirmed. You can now set a new password.';
          });
          
          // Navigate to password reset page
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) {
            context.go('/reset-password');
          }
        }
      } else {
        setState(() {
          _isSuccess = false;
          _message = 'Invalid confirmation link. Please try again.';
        });
      }
    } catch (e) {
      debugPrint('🔴 [AUTH_CONFIRM] Confirmation error: $e');
      setState(() {
        _isSuccess = false;
        _message = 'Confirmation failed: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo/Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F46E5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.email_rounded,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Loading or Status Icon
                if (_isLoading)
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5)),
                  )
                else
                  Icon(
                    _isSuccess ? Icons.check_circle : Icons.error,
                    size: 48,
                    color: _isSuccess ? Colors.green : Colors.red,
                  ),
                
                const SizedBox(height: 24),
                
                // Title
                Text(
                  _isLoading
                      ? 'Confirming your email...'
                      : _isSuccess
                          ? 'Confirmation successful!'
                          : 'Confirmation failed',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 16),
                
                // Message
                Text(
                  _isLoading
                      ? 'Please wait while we confirm your email address...'
                      : _message,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 32),
                
                // Action Button
                if (!_isLoading && !_isSuccess)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        context.go('/login');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Back to Login',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}