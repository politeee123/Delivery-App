import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegisterRiderPage extends StatefulWidget {
  const RegisterRiderPage({super.key});

  @override
  State<RegisterRiderPage> createState() => _RegisterRiderPageState();
}

class _RegisterRiderPageState extends State<RegisterRiderPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _vehicleNumberController =
      TextEditingController();

  File? _riderImage;
  File? _vehicleImage;
  final ImagePicker _picker = ImagePicker();

  // เลือกรูปผู้ขับ
  Future<void> pickRiderImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _riderImage = File(pickedFile.path);
      });
    }
  }

  // เลือกรูปยานพาหนะ
  Future<void> pickVehicleImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _vehicleImage = File(pickedFile.path);
      });
    }
  }

  Future<void> registerRider() async {
  if (_formKey.currentState!.validate()) {
    try {
      final supabase = Supabase.instance.client;

      // upload รูปผู้ขับ
      String? riderUrl;
      if (_riderImage != null) {
        final fileName =
            'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';

        // upload ไป bucket "riders"
        await supabase.storage
            .from('riders') // ชื่อ bucket
            .upload(fileName, _riderImage!);

        // เอา URL public
        riderUrl = supabase.storage.from('riders').getPublicUrl(fileName);
      }

      // upload รูปรถ
      String? vehicleUrl;
      if (_vehicleImage != null) {
        final fileName =
            'vehicle_${DateTime.now().millisecondsSinceEpoch}.jpg';

        await supabase.storage
            .from('riders') // bucket เดียวกันได้
            .upload(fileName, _vehicleImage!);

        vehicleUrl = supabase.storage.from('riders').getPublicUrl(fileName);
      }

      // บันทึกข้อมูลใน Firestore (ถ้าคุณยังอยากใช้ Firestore เก็บข้อมูลผู้ขับ)
      await FirebaseFirestore.instance.collection('riders').add({
        'Name': _nameController.text,
        'Phone': _phoneController.text,
        'Password': _passwordController.text,
        'VehicleNumber': _vehicleNumberController.text,
        'RiderImage': riderUrl ?? '',
        'VehicleImage': vehicleUrl ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // หรือบันทึกข้อมูลไป Supabase Database ก็ได้
      // await supabase.from('riders').insert({
      //   'name': _nameController.text,
      //   'phone': _phoneController.text,
      //   'password': _passwordController.text,
      //   'vehicle_number': _vehicleNumberController.text,
      //   'rider_image': riderUrl ?? '',
      //   'vehicle_image': vehicleUrl ?? '',
      // });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('สมัครสำเร็จ!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    }
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
                    "Sign in rider",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 20),

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

                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: "หมายเลขโทรศัพท์",
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value!.isEmpty ? 'กรุณากรอกเบอร์โทร' : null,
                  ),
                  const SizedBox(height: 15),

                  // เลือกรูปผู้ขับ
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: pickRiderImage,
                        child: const Text("เลือกรูปโปรไฟล์"),
                      ),
                      const SizedBox(width: 10),
                      CircleAvatar(
                        radius: 25,
                        backgroundImage: _riderImage != null
                            ? FileImage(_riderImage!)
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
                        backgroundImage: _vehicleImage != null
                            ? FileImage(_vehicleImage!)
                            : const AssetImage('assets/vehicle_placeholder.png')
                                as ImageProvider,
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  TextFormField(
                    controller: _vehicleNumberController,
                    decoration: const InputDecoration(
                      labelText: "ทะเบียนรถ",
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value!.isEmpty ? 'กรุณากรอกทะเบียนรถ' : null,
                  ),
                  const SizedBox(height: 15),

                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: "รหัสผ่าน",
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value!.length < 6 ? 'รหัสผ่านต้องอย่างน้อย 6 ตัว' : null,
                  ),
                  const SizedBox(height: 15),

                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: true,
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
      ),
    );
  }
}
