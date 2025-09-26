import 'package:flutter/material.dart';

class HomeUser extends StatefulWidget {
  const HomeUser({super.key});

  @override
  State<HomeUser> createState() => _HomeUserState();
}

class _HomeUserState extends State<HomeUser> {
  int _selectedIndex = 0;

  final List<String> foods = [
    "400 บาท",
    "356 บาท",
    "400 บาท",
    "400 บาท",
    "400 บาท",
    "400 บาท",
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlueAccent,
      appBar: AppBar(
        backgroundColor: Colors.lightBlueAccent,
        elevation: 0,
        title: const Text("Home"),
        actions: [
          TextButton(
            onPressed: () {
              // logout logic
            },
            child: const Text("log out"),
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        color: Colors.green,
        child: Column(
          children: [
            const SizedBox(height: 10),
            // ปุ่มสั่งอาหาร
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.restaurant),
              label: const Text("สั่งอาหาร"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            // รายการอาหาร
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(10),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
                itemCount: foods.length,
                itemBuilder: (context, index) {
                  return Card(
                    child: Column(
                      children: [
                        Expanded(
                          child: Image.asset(
                            "assets/pizza.png", // ใส่รูปแทน
                            fit: BoxFit.cover,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(foods[index]),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "หน้าหลัก"),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: "คำสั่งซื้อ",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: "รายการโปรด",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "บัญชี"),
        ],
      ),
    );
  }
}
