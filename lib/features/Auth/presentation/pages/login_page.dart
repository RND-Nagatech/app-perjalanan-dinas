import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class LoginPage extends StatefulWidget {
  final AuthBloc authBloc;

  const LoginPage({super.key, required this.authBloc});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool showSheet = false;
  bool obscurePassword = true;
  bool rememberMe = false;
  bool _isLoading = false;

  late final AuthBloc _authBloc;
  // Using BlocListener instead of manual StreamSubscription

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    // No manual subscription to cancel when using BlocListener
    // AuthBloc is a singleton managed by GetIt; do not close it here.
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 600), () {
      setState(() => showSheet = true);
    });
    _loadSavedCredentials();

    _authBloc = widget.authBloc;
  }

  void _onAuthStateChanged(AuthState state) {
    if (!mounted) return;
    setState(() => _isLoading = state is AuthLoading);

    if (state is Authenticated) {
      _handleAuthenticated();
    } else if (state is AuthError) {
      _showError(state.message);
    }
  }

  Future<void> _handleAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    if (rememberMe) {
      await prefs.setBool('remember_me', true);
      await prefs.setString('saved_email', _emailController.text.trim());
      await prefs.setString('saved_password', _passwordController.text);
    } else {
      await prefs.setBool('remember_me', false);
      await prefs.remove('saved_email');
      await prefs.remove('saved_password');
    }
    if (mounted) context.go('/home');
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool('remember_me') ?? false;
    if (saved) {
      final email = prefs.getString('saved_email') ?? '';
      final password = prefs.getString('saved_password') ?? '';
      setState(() {
        rememberMe = true;
        _emailController.text = email;
        _passwordController.text = password;
      });
    }
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showError('Email dan password harus diisi');
      return;
    }

    // Delegate login to AuthBloc; UI reacts via subscription above
    _authBloc.add(
      LoginRequested(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      bloc: _authBloc,
      listener: (context, state) => _onAuthStateChanged(state),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: const Color(0xFF0E7C7B),
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusScope.of(context).unfocus(),
          child: Stack(
            children: [
              /// ================= HEADER ICON ONLY =================
              SizedBox(
                width: double.infinity,
                child: Column(
                  children: [
                    const SizedBox(height: 250),
                    Image.asset('assets/png/login.png', height: 200),
                  ],
                ),
              ),

              /// ================= BOTTOM SHEET =================
              AnimatedPositioned(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutCubic,
                left: 0,
                right: 0,
                bottom: showSheet ? 0 : -600,
                child: _loginSheet(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ================= LOGIN SHEET =================
  Widget _loginSheet(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.78,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFF6F8F7),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Login",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0E7C7B),
              ),
            ),
            const SizedBox(height: 20),

            _styledInput("Email", Icons.email, _emailController),
            const SizedBox(height: 14),
            _styledInput(
              "Password",
              Icons.lock,
              _passwordController,
              isPassword: true,
            ),

            const SizedBox(height: 8),
            Row(
              children: [
                Checkbox(
                  value: rememberMe,
                  activeColor: const Color(0xFF0E7C7B),
                  onChanged: (value) {
                    setState(() => rememberMe = value!);
                  },
                ),
                const Text("Remember Me"),
              ],
            ),

            const SizedBox(height: 18),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0E7C7B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  elevation: 6,
                  shadowColor: Colors.black26,
                ),
                onPressed: _isLoading ? null : _handleLogin,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        "Login",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 18),

            Center(
              child: GestureDetector(
                onTap: () {
                  context.push('/signup');
                },
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                    children: [
                      const TextSpan(
                        text: "Don't have an account? ",
                        style: TextStyle(
                          color: Color.fromARGB(255, 62, 63, 63),
                        ),
                      ),
                      TextSpan(
                        text: "Sign Up",
                        style: const TextStyle(color: Color(0xFF0E7C7B)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _styledInput(
    String hint,
    IconData icon,
    TextEditingController controller, {
    bool isPassword = false,
  }) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? obscurePassword : false,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.black45),
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
          prefixIcon: Container(
            margin: const EdgeInsets.only(left: 8, right: 8),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.grey[700]),
          ),
          suffixIcon: isPassword
              ? IconButton(
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      obscurePassword ? Icons.visibility_off : Icons.visibility,
                      key: ValueKey(obscurePassword),
                      color: Colors.grey,
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      obscurePassword = !obscurePassword;
                    });
                  },
                )
              : null,
        ),
      ),
    );
  }
}

/// ================= SLIDE + FADE ROUTE =================
// Navigation now uses GoRouter + slideFadePage helper.
