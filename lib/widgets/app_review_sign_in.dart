import 'package:flutter/material.dart';

import '../services/app_review_demo.dart';
import '../theme.dart';

/// Login-Felder mit Apples Bezeichnungen User Name / Password.
class AppReviewSignIn extends StatefulWidget {
  const AppReviewSignIn({super.key, required this.onSuccess});

  final VoidCallback onSuccess;

  @override
  State<AppReviewSignIn> createState() => _AppReviewSignInState();
}

class _AppReviewSignInState extends State<AppReviewSignIn> {
  final _user = TextEditingController();
  final _pass = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _user.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AppReviewDemo.signIn(_user.text, _pass.text);
      if (!mounted) return;
      widget.onSuccess();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'App Review',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: cTextTertiary,
            fontWeight: FontWeight.w700,
            fontSize: 11,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Sign in',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: cText,
            fontWeight: FontWeight.w800,
            fontSize: 14,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 10),
        _box(_user, 'User Name', false),
        const SizedBox(height: 8),
        _box(_pass, 'Password', true),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!,
              style: const TextStyle(color: cRed, fontSize: 12),
              textAlign: TextAlign.center),
        ],
        const SizedBox(height: 12),
        SizedBox(
          height: 44,
          child: ElevatedButton(
            onPressed: _busy ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: cCard,
              foregroundColor: cText,
              side: const BorderSide(color: cOrange, width: 1),
            ),
            child: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: cOrange),
                  )
                : const Text('Sign in',
                    style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ),
      ],
    );
  }

  Widget _box(TextEditingController c, String label, bool obscure) {
    return TextField(
      controller: c,
      obscureText: obscure,
      autocorrect: false,
      enableSuggestions: false,
      style: const TextStyle(color: cText, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: cTextSecondary),
        filled: true,
        fillColor: cCard,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: cTileBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: cTileBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: cOrange),
        ),
      ),
    );
  }
}
