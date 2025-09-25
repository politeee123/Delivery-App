import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'select_location.dart';

class RegisterUserPage extends StatefulWidget {
  const RegisterUserPage({super.key});

  @override
  State<RegisterUserPage> createState() => _RegisterUserPageState();
}

class _RegisterUserPageState extends State<RegisterUserPage> {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  LatLng? selectedLocation; // เก็บพิกัดที่เลือก

  @override
  Widget build(BuildContext context) {
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
                  "Sign in",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),

                const SizedBox(height: 20),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: "ชื่อ",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: "หมายเลขโทรศัพท์",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 15),

                // ปุ่มเลือกรูปโปรไฟล์
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        // TODO: upload image
                      },
                      child: const Text("เลือกรูป"),
                    ),
                    const SizedBox(width: 10),
                    const CircleAvatar(
                      radius: 25,
                      backgroundImage: AssetImage(
                        'assets/profile_placeholder.png',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),

                // ปุ่มเลือก GPS
                ElevatedButton(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SelectLocationPage(),
                      ),
                    );
                    if (result != null) {
                      setState(() {
                        selectedLocation = result;
                      });
                    }
                  },
                  child: Text(
                    selectedLocation == null
                        ? "เลือกตำแหน่งที่อยู่"
                        : "พิกัด: ${selectedLocation!.latitude}, ${selectedLocation!.longitude}",
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
                const SizedBox(height: 15),

                TextField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "ยืนยันรหัสผ่าน",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: () {
                    // TODO: handle register
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text("Sign in"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
