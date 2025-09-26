import 'package:flutter/material.dart';
import 'sign_in.dart';
import 'register_user.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundImage: AssetImage('assets/logo.png'),
            ),
            const SizedBox(height: 30),

            // ปุ่ม "มีบัญชีแล้ว"
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink[100],
                minimumSize: const Size(250, 60),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SignInPage()),
                );
              },
              child: const Text("มีบัญชีแล้ว"),
            ),
            const SizedBox(height: 20),

            // ปุ่ม "สมัครเป็นผู้ใช้งาน"
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink[100],
                minimumSize: const Size(250, 60),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RegisterUserPage(),
                  ),
                );
              },
              child: const Text("สมัครเป็นผู้ใช้งาน"),
            ),
            const SizedBox(height: 20),

            // ปุ่ม "สมัครเป็นคนส่งสินค้า"
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink[100],
                minimumSize: const Size(250, 60),
              ),
              onPressed: () {
                // TODO: ทำหน้า register_delivery.dart
              },
              child: const Text("สมัครเป็นคนส่งสินค้า"),
            ),
          ],
        ),
      ),
    );
  }
}
