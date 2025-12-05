import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({
    super.key,
    required this.onToggleTheme,
    required this.isDarkMode,
  });

  final VoidCallback onToggleTheme;
  final bool isDarkMode;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final repeatPassController = TextEditingController();

  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();

  bool _isLoading = false;

  Future<void> _register() async {
    if (passwordController.text != repeatPassController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match.")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final uid = cred.user!.uid;

      
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'firstName': firstNameController.text.trim(),
        'lastName': lastNameController.text.trim(),
        'email': emailController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Registration successful! Please log in."),
        ),
      );
    } on FirebaseAuthException catch (e) {
      String message = 'Error during registration.';
      if (e.code == 'email-already-in-use') {
        message = 'This email is already registered.';
      } else if (e.code == 'weak-password') {
        message = 'The password is too weak.';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unknown error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _inputDecoration(BuildContext context, String label,
      {IconData? icon}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InputDecoration(
      labelText: label,
      prefixIcon: icon != null ? Icon(icon) : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(width: 2),
      ),
      filled: true,
      fillColor: isDark
          ? theme.colorScheme.surfaceVariant
          : Colors.grey.shade100,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: true, 
        actions: [
          IconButton(
            icon: Icon(
              widget.isDarkMode ? Icons.light_mode : Icons.dark_mode,
            ),
            tooltip: widget.isDarkMode
                ? 'Switch to light mode'
                : 'Switch to dark mode',
            onPressed: widget.onToggleTheme,
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 32.0,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.school,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Create your account",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Join StudyTracker and start organizing your study sessions.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 24),

                    
                    TextField(
                      controller: firstNameController,
                      decoration: _inputDecoration(
                        context,
                        "First name",
                        icon: Icons.person_outline,
                      ),
                    ),
                    const SizedBox(height: 16),

                    
                    TextField(
                      controller: lastNameController,
                      decoration: _inputDecoration(
                        context,
                        "Last name",
                        icon: Icons.person,
                      ),
                    ),
                    const SizedBox(height: 16),

                    
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _inputDecoration(
                        context,
                        "Email",
                        icon: Icons.email_outlined,
                      ),
                    ),
                    const SizedBox(height: 16),

                    
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: _inputDecoration(
                        context,
                        "Password",
                        icon: Icons.lock_outline,
                      ),
                    ),
                    const SizedBox(height: 16),

                    
                    TextField(
                      controller: repeatPassController,
                      obscureText: true,
                      decoration: _inputDecoration(
                        context,
                        "Confirm password",
                        icon: Icons.lock_reset,
                      ),
                    ),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _register,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text(
                                "Sign up",
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
        ),
      ),
    );
  }
}
