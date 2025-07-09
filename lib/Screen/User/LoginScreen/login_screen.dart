import 'package:flutter/material.dart';
import 'package:web_labor_contract/Screen/custom_field.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset('assets/img/signin.png',height: 350,),
            const Text(
              'Sign In',
              style: TextStyle(
                fontSize: 35,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(
              height: 30,
            ),
            const CustomField(
                icon: Icons.alternate_email,
                obscureText: false,
                hinText: 'Enter Email'),
            const CustomField(
                icon: Icons.lock, obscureText: true, hinText: 'Enter Password'),
            const SizedBox(
              height: 10,
            ),
          ],
        ),
        )
    );
  }
}

