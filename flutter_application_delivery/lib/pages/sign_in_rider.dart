import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_delivery/pages/home_rider.dart';

class SignInRiderPage extends StatelessWidget {
  const SignInRiderPage({super.key});

  @override
  Widget build(BuildContext context) {
    final phoneController = TextEditingController();
    final passwordController = TextEditingController();

    Future<void> loginRider() async {
      final phone = phoneController.text.trim();
      final password = passwordController.text.trim();

      if (phone.isEmpty || password.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('กรุณากรอกข้อมูลให้ครบ')));
        return;
      }

      try {
        // ดึง rider ตามเบอร์โทร
        final querySnapshot = await FirebaseFirestore.instance
            .collection('riders')
            .where('Phone', isEqualTo: phone)
            .limit(1)
            .get();

        if (querySnapshot.docs.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ไม่พบผู้ขับที่ใช้เบอร์นี้')),
          );
          return;
        }

        final riderData = querySnapshot.docs.first.data();
        final dbPassword = riderData['Password'];

        if (dbPassword == password) {
          // ล็อกอินสำเร็จ
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('เข้าสู่ระบบสำเร็จ')));

          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const HomeRider()),
          );
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('รหัสผ่านไม่ถูกต้อง')));
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
      }
    }

    return Scaffold(
      backgroundColor: Colors.green,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 50,
                  backgroundImage: AssetImage('assets/logo.png'),
                ),
                const SizedBox(height: 20),
                const Text(
                  "LoginRider",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 20),

                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: "หมายเลขโทรศัพท์",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 15),

                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "รหัสผ่าน",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: loginRider,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text("Log In"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
