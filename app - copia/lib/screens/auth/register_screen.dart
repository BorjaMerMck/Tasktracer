import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme.dart';
import 'email_verification_screen.dart';

class RegistrarScreen extends StatefulWidget {
  @override
  _RegistrarScreenState createState() => _RegistrarScreenState();
}

class _RegistrarScreenState extends State<RegistrarScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _showInstructions = true;

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final email = _emailController.text.trim();
        final password = _passwordController.text.trim();

        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        User? user = userCredential.user;

        if (user != null && !user.emailVerified) {
          await user.sendEmailVerification();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Registro exitoso. Verifica tu correo.'),
            ),
          );
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => EmailVerificationScreen()),
        );
      } on FirebaseAuthException catch (e) {
        String errorMessage = 'Error en el registro.';
        if (e.code == 'email-already-in-use') {
          errorMessage = 'El correo ya está en uso.';
        } else if (e.code == 'weak-password') {
          errorMessage = 'La contraseña es demasiado débil.';
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
    bool obscureText = false,
    Widget? suffixIcon,
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
      appBar: AppBar(title: Text('Registrar'), backgroundColor: Colors.blue),
      body: SingleChildScrollView(
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
              Text(
                'Crear una Cuenta',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: MyTheme.darkBlue,
                ),
              ),
              SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  setState(() {
                    _showInstructions = !_showInstructions;
                  });
                },
                child: Text(
                  _showInstructions ? 'Ocultar instrucciones' : 'Mostrar instrucciones',
                  style: TextStyle(
                    fontSize: 14,
                    color: MyTheme.darkBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 10),
              if (_showInstructions)
                Container(
                  padding: EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Instrucciones para Crear tu Cuenta:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: MyTheme.darkBlue,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text('1. Usa un correo electrónico válido.'),
                      Text('2. Usa una contraseña segura con mínimo 8 caracteres.'),
                      Text('3. Verifica tu cuenta por correo.'),
                    ],
                  ),
                ),
              SizedBox(height: 20),
              _buildTextField(
                controller: _emailController,
                labelText: 'Correo electrónico',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa tu correo electrónico';
                  }
                  final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                  if (!regex.hasMatch(value)) {
                    return 'Correo inválido';
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
                    _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa una contraseña';
                  }
                  if (value.length < 8) {
                    return 'Debe tener al menos 8 caracteres';
                  }
                  if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])')
                      .hasMatch(value)) {
                    return 'Debe contener mayúsculas, minúsculas, números y símbolos';
                  }
                  return null;
                },
              ),
              SizedBox(height: 40),
              _isLoading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: _register,
                child: Text('Registrarse', style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  backgroundColor: MyTheme.mintGreen,
                ),
              ),
              SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  '¿Ya tienes una cuenta? Inicia sesión',
                  style: TextStyle(fontSize: 16, color: MyTheme.darkBlue),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
