
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main.dart';
import 'core/theme.dart';
class RegistrarScreen extends StatefulWidget {
  @override
  _RegistrarScreenState createState() => _RegistrarScreenState();
}

class _RegistrarScreenState extends State<RegistrarScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isPasswordVisible = false; // Controla la visibilidad de la contraseña
  bool _isLoading = false;
  bool _showInstructions = true; // Controla la visibilidad del mensaje

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
          await user.sendEmailVerification(); // Envía correo de verificación
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Registro exitoso. Por favor verifica tu correo electrónico.',
              ),
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
      appBar: AppBar(
        title: Text('Registrar'),
        backgroundColor: Colors.blue,
      ),
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
              // Botón para mostrar/ocultar instrucciones
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
              // Guía para el usuario
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
                      Text(
                        '1. Usa un correo electrónico válido que uses.',
                        style: TextStyle(fontSize: 14),
                      ),
                      Text(
                        '2. Crea una contraseña segura con al menos 8 caracteres, incluyendo mayúsculas, minúsculas, números y caracteres especiales.',
                        style: TextStyle(fontSize: 14),
                      ),
                      Text(
                        '3. Verificarás tu cuenta con un enlace enviado a tu correo electrónico.',
                        style: TextStyle(fontSize: 14),
                      ),
                      SizedBox(height: 8),
                   
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
                    return 'Por favor ingresa un correo válido';
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
                    return 'Por favor ingresa una contraseña';
                  }
                  if (value.length < 8) {
                    return 'La contraseña debe tener al menos 8 caracteres';
                  }
                  if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$')
                      .hasMatch(value)) {
                    return 'Debe incluir mayúsculas, minúsculas, números y caracteres especiales';
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
                        padding:
                            EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                        backgroundColor: MyTheme.mintGreen,
                      ),
                    ),
              SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
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

// Pantalla de espera de verificación de correo

class EmailVerificationScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Verificación de Correo'),
        backgroundColor: Colors.blue,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icono decorativo
              Icon(
                Icons.mark_email_read,
                size: 100,
                color: MyTheme.mintGreen,
              ),
              SizedBox(height: 30),

              // Título
              Text(
                '¡Verifica tu correo electrónico!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: MyTheme.darkBlue,
                ),
              ),
              SizedBox(height: 10),

              // Subtítulo
              Text(
                'Te hemos enviado un enlace de verificación a tu correo electrónico. Por favor, revisa tu bandeja de entrada y sigue las instrucciones para activar tu cuenta.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 40),

              // Botón de regresar al inicio
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context); // Redirige a la pantalla de inicio
                },
                icon: Icon(Icons.arrow_back, size: 20),
                label: Text('Regresar al Inicio'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
              SizedBox(height: 20),

            ],
          ),
        ),
      ),
    );
  }
}