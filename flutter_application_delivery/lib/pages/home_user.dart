import 'package:flutter/material.dart';
import 'package:flutter_application_delivery/pages/proflie.dart';
import 'package:flutter_application_delivery/pages/sender_page.dart';
import 'package:flutter_application_delivery/pages/receiver_page.dart';

class HomeUser extends StatefulWidget {
  final String id; // ✅ รับ id จากหน้า login
  const HomeUser({super.key, required this.id});

  @override
  State<HomeUser> createState() => _HomeUserState();
}

class _HomeUserState extends State<HomeUser> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // ✅ เมื่อกดเมนูแต่ละอัน ให้ไปยังหน้านั้นเลย
    switch (index) {
      case 1: // Sender Page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SenderPage(id: widget.id),
          ),
        );
        break;
      case 2: // Receiver Page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReceiverPage(id: widget.id),
          ),
        );
        break;
      case 3: // Profile Page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfilePage(id: widget.id),
          ),
        );
        break;
    }
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
              Navigator.pop(context); // กลับไปหน้า login
            },
            child: const Text("log out"),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
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
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(10),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemCount: 6,
              itemBuilder: (context, index) {
                return Card(
                  child: Column(
                    children: [
                      Expanded(
                        child: Image.asset(
                          "assets/pizza.png",
                          fit: BoxFit.cover,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text("400 บาท"),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey[600],
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.send), label: "Sender"),
          BottomNavigationBarItem(icon: Icon(Icons.move_to_inbox), label: "Receiver"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}
