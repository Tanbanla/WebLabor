// import 'package:flutter/material.dart';
// import 'package:web_labor_contract/Common/common.dart';
// import 'package:web_labor_contract/Common/custom_field.dart';
// import 'package:web_labor_contract/Screen/User/Home/navigation_drawer.dart';

// class LoginScreen extends StatelessWidget {
//   const LoginScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     Size size = MediaQuery.of(context).size;
//     return Center(
//       child: Container(
//         height: size.height - 120,
//         padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(12),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.1),
//               blurRadius: 10,
//               spreadRadius: 2,
//               offset: Offset(0, 3),
//             ),
//           ],
//         ),
//         child: Padding(
//           padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: [
//               Text(
//                 'LABOR CONTRACT EVALUATION',
//                 style: TextStyle(
//                   fontSize: 32,
//                   fontWeight: FontWeight.bold,
//                   color: Common.primaryColor,
//                 ),
//               ),
//               Image.asset('assets/img/signin.png', height: 120),
//               const SizedBox(height: 8),
//               Text(
//                 'Sign In',
//                 style: TextStyle(
//                   fontSize: 24,
//                   fontWeight: FontWeight.w700,
//                   color: Common.primaryColor,
//                 ),
//                 textAlign: TextAlign.left,
//               ),
//               const SizedBox(height: 30),
//               const CustomField(
//                 icon: Icons.alternate_email,
//                 obscureText: false,
//                 hinText: 'ADID',
//               ),
//               const SizedBox(height: 16),
//               const CustomField(
//                 icon: Icons.lock,
//                 obscureText: true,
//                 hinText: 'Enter Password',
//               ),
//               const SizedBox(height: 10),
//               GestureDetector(
//                 onTap: () {
//                   Navigator.pushReplacement(
//                           context,
//                           MaterialPageRoute(
//                             builder: (_) => const MenuScreen() ,
//                           ),
//                         );
//                 },
//                 child: Container(
//                   width: size.width / 5,
//                   height: 50,
//                   decoration: BoxDecoration(
//                     color: Common.primaryColor,
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 10,
//                     vertical: 8,
//                   ),
//                   child: const Center(
//                     child: Text(
//                       'Sign In',
//                       style: TextStyle(color: Colors.white, fontSize: 14),
//                     ),
//                   ),
//                 ),
//               ),
//               //const SizedBox(height: 10),
//               Container(
//                 width: 300,
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     const Text("-----------"),
//                     Image.asset(
//                       'assets/img/logo_company.png',
//                       height: 100,
//                       width: 100,
//                     ),
//                     const Text("-----------"),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:web_labor_contract/Common/common.dart';
import 'package:web_labor_contract/Common/custom_field.dart';
import 'package:web_labor_contract/Screen/User/Home/navigation_drawer.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: size.width > 600 ? 500 : size.width * 0.9,
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 5,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo và tiêu đề
                Column(
                  children: [
                    Image.asset('assets/img/logo_company.png', height: 80),
                    const SizedBox(height: 20),
                    Text(
                      'LABOR CONTRACT EVALUATION',
                      style: TextStyle(
                        fontSize: size.width > 600 ? 24 : 20,
                        fontWeight: FontWeight.bold,
                        color: Common.primaryColor,
                        letterSpacing: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign In to Continue',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // Form đăng nhập
                Column(
                  children: [
                    const CustomField(
                      icon: Icons.person_outline,
                      obscureText: false,
                      hinText: 'ADID',
                    ),
                    const SizedBox(height: 20),
                    const CustomField(
                      icon: Icons.lock_outline,
                      obscureText: true,
                      hinText: 'Password',
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {},
                        child: Text(
                          'Forgot Password?',
                          style: TextStyle(color: Common.primaryColor),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Common.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 3,
                        ),
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const MenuScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'SIGN IN',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // Footer
                Text(
                  '©2025 Labor Contract Evaluation. All rights reserved',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
