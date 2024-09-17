import 'package:flutter/material.dart';
import 'package:job_verse/services/auth.dart';
import 'login.dart';

class SignupPage extends StatefulWidget {
  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  String _email = '';
  String _password = '';
  String _name = '';
  bool _isCompany = false;
  bool _isLoading = false;

  // Function to sign up a user
  Future<void> _submitSignupForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });
      try {
        await _authService.signUp(_email, _password, _name, _isCompany, context);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Login()),
        );
      } catch (error) {
        setState(() {
          _isLoading = false;
        });
        // Handle error display here if needed
        _showErrorDialog(error.toString());
      }
    }
  }

  // Helper function to show error dialogs
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: Text('Okay'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sign Up'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextField(
                labelText: 'Name',
                onChanged: (value) => _name = value,
                validator: (value) => value == null || value.isEmpty ? 'Please enter your name' : null,
              ),
              _buildTextField(
                labelText: 'Email',
                keyboardType: TextInputType.emailAddress,
                onChanged: (value) => _email = value,
                validator: (value) => value == null || value.isEmpty ? 'Please enter an email' : null,
              ),
              _buildTextField(
                labelText: 'Password',
                obscureText: true,
                onChanged: (value) => _password = value,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter a password';
                  if (value.length < 6) return 'Password should be at least 6 characters long';
                  return null;
                },
              ),
              Row(
                children: [
                  Checkbox(
                    value: _isCompany,
                    onChanged: (bool? value) {
                      setState(() {
                        _isCompany = value ?? false;
                      });
                    },
                  ),
                  Text('Sign up as a company'),
                ],
              ),
              SizedBox(height: 20),
              _isLoading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: _submitSignupForm,
                child: Text('Sign Up'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Navigate back to login page
                },
                child: Text('Already have an account? Log in'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper function to build text fields
  Widget _buildTextField({
    required String labelText,
    required ValueChanged<String> onChanged,
    required String? Function(String?) validator,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      decoration: InputDecoration(labelText: labelText),
      obscureText: obscureText,
      keyboardType: keyboardType,
      onChanged: onChanged,
      validator: validator,
    );
  }
}
