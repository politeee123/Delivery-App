import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'select_location.dart';

class RegisterUserPage extends StatefulWidget {
  const RegisterUserPage({super.key});

  @override
  State<RegisterUserPage> createState() => _RegisterUserPageState();
}

class _RegisterUserPageState extends State<RegisterUserPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  LatLng? selectedLocation1;
  LatLng? selectedLocation2;
  File? _userImage;
  final ImagePicker _picker = ImagePicker();

  // เลือกรูปโปรไฟล์
  Future<void> pickUserImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _userImage = File(pickedFile.path);
      });
    }
  }

  Future<void> registerUser() async {
    if (_formKey.currentState!.validate()) {
      try {
        final supabase = Supabase.instance.client;

        // ✅ ตรวจสอบเบอร์โทรซ้ำ
        final existQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('Phone', isEqualTo: _phoneController.text.trim())
            .limit(1)
            .get();

        if (existQuery.docs.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('เบอร์โทรนี้ถูกใช้งานแล้ว')),
          );
          return;
        }

        // ✅ อัปโหลดรูปไป Supabase Storage
        String? userUrl;
        if (_userImage != null) {
          final fileName = 'user_${DateTime.now().millisecondsSinceEpoch}.jpg';
          await supabase.storage.from('users').upload(fileName, _userImage!);
          userUrl = supabase.storage.from('users').getPublicUrl(fileName);
        }

        // ✅ เพิ่ม user document
        final userRef =
            await FirebaseFirestore.instance.collection('users').add({
          'Name': _nameController.text.trim(),
          'Phone': _phoneController.text.trim(),
          'Password': _passwordController.text.trim(),
          'Image': userUrl ?? '',
          'createdAt': FieldValue.serverTimestamp(),
        });

        // ✅ ถ้ามีการเลือกพิกัด ให้บันทึกลง subcollection addresses
        if (selectedLocation1 != null) {
          await userRef.collection('addresses').add({
            'label': 'ที่อยู่ 1',
            'lat': selectedLocation1!.latitude,
            'lng': selectedLocation1!.longitude,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }

        if (selectedLocation2 != null) {
          await userRef.collection('addresses').add({
            'label': 'ที่อยู่ 2',
            'lat': selectedLocation2!.latitude,
            'lng': selectedLocation2!.longitude,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('สมัครสมาชิกสำเร็จ!')),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    }
  }

  Future<void> pickLocation(int slot) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SelectLocationPage(),
      ),
    );

    if (result != null) {
      setState(() {
        if (slot == 1) {
          selectedLocation1 = result;
        } else {
          selectedLocation2 = result;
        }
      });
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
            child: Form(
              key: _formKey,
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

                  // ชื่อ
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: "ชื่อ",
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value!.isEmpty ? 'กรุณากรอกชื่อ' : null,
                  ),
                  const SizedBox(height: 15),

                  // เบอร์โทร
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: "หมายเลขโทรศัพท์",
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value!.isEmpty ? 'กรุณากรอกเบอร์โทรศัพท์' : null,
                  ),
                  const SizedBox(height: 15),

                  // รูปโปรไฟล์
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: pickUserImage,
                        child: const Text("เลือกรูป"),
                      ),
                      const SizedBox(width: 10),
                      CircleAvatar(
                        radius: 25,
                        backgroundImage: _userImage != null
                            ? FileImage(_userImage!)
                            : const AssetImage('assets/profile_placeholder.png')
                                as ImageProvider,
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  // พิกัดที่อยู่ 1
                  ElevatedButton(
                    onPressed: () => pickLocation(1),
                    child: Text(
                      selectedLocation1 == null
                          ? "เลือกตำแหน่งที่อยู่ 1"
                          : "ที่อยู่ 1: ${selectedLocation1!.latitude}, ${selectedLocation1!.longitude}",
                    ),
                  ),
                  const SizedBox(height: 10),

                  // พิกัดที่อยู่ 2
                  ElevatedButton(
                    onPressed: () => pickLocation(2),
                    child: Text(
                      selectedLocation2 == null
                          ? "เลือกตำแหน่งที่อยู่ 2"
                          : "ที่อยู่ 2: ${selectedLocation2!.latitude}, ${selectedLocation2!.longitude}",
                    ),
                  ),
                  const SizedBox(height: 15),

                  // รหัสผ่าน
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    obscuringCharacter: '*',
                    decoration: const InputDecoration(
                      labelText: "รหัสผ่าน",
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value!.length < 6
                        ? 'รหัสผ่านต้องอย่างน้อย 6 ตัว'
                        : null,
                  ),
                  const SizedBox(height: 15),

                  // ยืนยันรหัสผ่าน
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    obscuringCharacter: '*',
                    decoration: const InputDecoration(
                      labelText: "ยืนยันรหัสผ่าน",
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value!.isEmpty) return 'กรุณากรอกยืนยันรหัสผ่าน';
                      if (value != _passwordController.text) {
                        return 'รหัสผ่านไม่ตรงกัน';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: registerUser,
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
      ),
    );
  }
}
