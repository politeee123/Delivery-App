import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class RegisterRiderPage extends StatefulWidget {
  const RegisterRiderPage({super.key});

  @override
  State<RegisterRiderPage> createState() => _RegisterRiderPageState();
}

class _RegisterRiderPageState extends State<RegisterRiderPage> {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final licensePlateController = TextEditingController();

  File? profileImageFile;
  File? vehicleImageFile;

  Future<void> pickProfileImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        profileImageFile = File(picked.path);
      });
    }
  }

  Future<void> pickVehicleImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        vehicleImageFile = File(picked.path);
      });
    }
  }

  Future<void> registerRider() async {
  try {
    // upload รูปโปรไฟล์
    String? profileUrl;
    if (profileImageFile != null) {
      final ref = FirebaseStorage.instance.ref().child(
          'riders/profile_${DateTime.now().millisecondsSinceEpoch}.jpg');
      final uploadTask = await ref.putFile(profileImageFile!);
      profileUrl = await ref.getDownloadURL();
    }

    // upload รูปรถ
    String? vehicleUrl;
    if (vehicleImageFile != null) {
      final ref = FirebaseStorage.instance.ref().child(
          'riders/vehicle_${DateTime.now().millisecondsSinceEpoch}.jpg');
      final uploadTask = await ref.putFile(vehicleImageFile!);
      vehicleUrl = await ref.getDownloadURL();
    }

    // บันทึก Firestore
    await FirebaseFirestore.instance.collection('riders').add({
      'name': nameController.text,
      'phone': phoneController.text,
      'licensePlate': licensePlateController.text,
      'password': passwordController.text,
      'profileImageUrl': profileUrl ?? '',
      'vehicleImageUrl': vehicleUrl ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('สมัครสำเร็จ!')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
    );
  }
}


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
                  "Sign in rider",
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

                // เลือกรูปโปรไฟล์
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: pickProfileImage,
                      child: const Text("เลือกรูปโปรไฟล์"),
                    ),
                    const SizedBox(width: 10),
                    CircleAvatar(
                      radius: 25,
                      backgroundImage: profileImageFile != null
                          ? FileImage(profileImageFile!)
                          : const AssetImage('assets/profile_placeholder.png')
                                as ImageProvider,
                    ),
                  ],
                ),
                const SizedBox(height: 15),

                // เลือกรูปรถ
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: pickVehicleImage,
                      child: const Text("เลือกรูปยานพาหนะ"),
                    ),
                    const SizedBox(width: 10),
                    CircleAvatar(
                      radius: 25,
                      backgroundImage: vehicleImageFile != null
                          ? FileImage(vehicleImageFile!)
                          : const AssetImage('assets/vehicle_placeholder.png')
                                as ImageProvider,
                    ),
                  ],
                ),
                const SizedBox(height: 15),

                TextField(
                  controller: licensePlateController,
                  decoration: const InputDecoration(
                    labelText: "ทะเบียนรถ",
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
                  onPressed: registerRider,
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
