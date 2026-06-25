import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController(text: 'admin');
  final _passwordController = TextEditingController();
  
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _errorMessage = null;
    });

    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final success = await appState.login(
      _usernameController.text,
      _passwordController.text,
    );

    if (!success) {
      setState(() {
        _errorMessage = "Invalid username or password. Please try again.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            child: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // App Brand Logo
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.neonLime.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.neonLime.withOpacity(0.3), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.neonLime.withOpacity(0.08),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.sports_tennis,
                          color: AppTheme.neonLime,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "PickleQ",
                            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                              color: AppTheme.textPrimary,
                              letterSpacing: -1,
                            ),
                          ),
                          Text(
                            "Fair Rotation System",
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.electricTeal,
                              letterSpacing: 0.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // Login Glass Box
                  GlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            "ADMINISTRATOR ACCESS",
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textSecondary,
                              letterSpacing: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: _usernameController,
                            style: const TextStyle(color: AppTheme.textPrimary),
                            decoration: const InputDecoration(
                              labelText: "Username",
                              hintText: "Enter admin username",
                              prefixIcon: Icon(Icons.person_outline, size: 20, color: AppTheme.textSecondary),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return "Username is required";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 18),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            style: const TextStyle(color: AppTheme.textPrimary),
                            decoration: const InputDecoration(
                              labelText: "Password",
                              hintText: "Enter administrator password",
                              prefixIcon: Icon(Icons.lock_outline, size: 20, color: AppTheme.textSecondary),
                            ),
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return "Password is required";
                              }
                              return null;
                            },
                            onFieldSubmitted: (_) => _handleLogin(),
                          ),
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppTheme.coralRed.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppTheme.coralRed.withOpacity(0.3)),
                              ),
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  color: AppTheme.coralRed,
                                  fontSize: 12,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 28),
                          ElevatedButton(
                            onPressed: _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.neonLime,
                              foregroundColor: Colors.black,
                              shadowColor: AppTheme.neonLime.withOpacity(0.4),
                              elevation: 8,
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.login, size: 18),
                                SizedBox(width: 8),
                                Text("LOG IN"),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Helper hint
                  Text(
                    "Default credentials: admin / admin123",
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: AppTheme.textSecondary.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
