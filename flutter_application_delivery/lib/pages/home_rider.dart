import 'package:flutter/material.dart';

class HomeRider extends StatefulWidget {
  const HomeRider({super.key});

  @override
  State<HomeRider> createState() => _HomeRiderState();
}

class _HomeRiderState extends State<HomeRider> {
  int _selectedIndex = 0;

  final List<String> orders = ["400 บาท", "400 บาท", "400 บาท", "400 บาท"];

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
        title: const Text("Home_rider"),
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
            // ปุ่มรับออเดอร์
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.delivery_dining),
              label: const Text("รับออเดอร์"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            // รายการออเดอร์
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(10),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  return Card(
                    child: Column(
                      children: [
                        Expanded(
                          child: Image.asset(
                            "assets/pizza.png", // ใช้รูปแทน
                            fit: BoxFit.cover,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(orders[index]),
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
          BottomNavigationBarItem(icon: Icon(Icons.list), label: "รายการ"),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on),
            label: "สถานที่",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.moped), label: "การส่ง"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "โปรไฟล์"),
        ],
      ),
    );
  }
}
