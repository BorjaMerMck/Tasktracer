import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme.dart';
import 'register_screen.dart';
import '../../group/group_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  bool _isPasswordVisible = false;

  Future<void> _signIn() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final email = _emailController.text.trim();
        final password = _passwordController.text.trim();

        UserCredential userCredential =
        await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        User? user = userCredential.user;

        if (user != null && !user.emailVerified) {
          await _auth.signOut();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Tu correo no está verificado. Por favor verifica tu cuenta antes de iniciar sesión.',
              ),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => GroupScreen()),
          );
        }
      } on FirebaseAuthException catch (e) {
        String errorMessage;
        switch (e.code) {
          case 'user-not-found':
            errorMessage = 'Usuario no encontrado. Verifica tu correo.';
            break;
          case 'wrong-password':
            errorMessage = 'Contraseña incorrecta. Inténtalo de nuevo.';
            break;
          default:
            errorMessage = 'Error de inicio de sesión. Inténtalo más tarde.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    Widget? suffixIcon,
    bool obscureText = false,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: labelText,
        border: OutlineInputBorder(),
        suffixIcon: suffixIcon,
      ),
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login'), backgroundColor: Colors.blue),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.network(
                  'https://cdn.icon-icons.com/icons2/294/PNG/256/Users_31113.png',
                  width: 120,
                  height: 120,
                ),
                SizedBox(height: 20),
                Text(
                  'Iniciar Sesión',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: MyTheme.darkBlue,
                  ),
                ),
                SizedBox(height: 20),
                _buildTextField(
                  controller: _emailController,
                  labelText: 'Correo electrónico',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa tu Correo electrónico';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                _buildTextField(
                  controller: _passwordController,
                  labelText: 'Contraseña',
                  obscureText: !_isPasswordVisible,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa tu contraseña';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                _isLoading
                    ? CircularProgressIndicator()
                    : ElevatedButton(
                  onPressed: _signIn,
                  child: Text(
                    'Ingresar',
                    style: TextStyle(fontSize: 20),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                        horizontal: 50, vertical: 15),
                    backgroundColor: MyTheme.mintGreen,
                  ),
                ),
                SizedBox(height: 40),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RegistrarScreen(),
                      ),
                    );
                  },
                  child: Text(
                    '¿No tienes una cuenta? Regístrate',
                    style: TextStyle(fontSize: 16, color: MyTheme.darkBlue),
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
