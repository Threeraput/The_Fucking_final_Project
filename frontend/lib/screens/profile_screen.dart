import 'dart:io';
import 'package:flutter/material.dart';
import '../models/users.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
class ProfilePage extends StatefulWidget {
  final User user;

  const ProfilePage({super.key, required this.user});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  File? _imageFile; // เก็บรูปที่เลือก

Future<void> saveProfileImage(String path) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('profileImage', path);
}

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);

    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });
      await saveProfileImage(image.path); // บันทึก path ของรูปลง SharedPreferences
    }
  }

  Future<void> loadProfileImage() async {
  final prefs = await SharedPreferences.getInstance();
  final path = prefs.getString('profileImage');
  if (path != null) {
    setState(() {
      _imageFile = File(path);
    });
  }
}

@override
void initState() {
  super.initState();
  loadProfileImage();
}

  void _showPickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('เลือกจากแกลเลอรี'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('ถ่ายรูป'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox(String title, String value, IconData icon, {String? tag}) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 5, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (tag != null)
            Align(
              alignment: Alignment.topRight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orangeAccent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  tag,
                  style: const TextStyle(fontSize: 10, color: Colors.white),
                ),
              ),
            ),
          Row(
            children: [
              Icon(icon, size: 20, color: Colors.orangeAccent),
              const SizedBox(width: 6),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.black54)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String fullName = '${widget.user.firstName ?? ''} ${widget.user.lastName ?? ''}';

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 54, 183, 219),
      body: SafeArea(
        child: Stack(
          children: [
            // แถวบน: Back + Settings
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildIconButton(Icons.arrow_back, () => Navigator.pop(context)),
                  _buildIconButton(Icons.settings, () {}),
                ],
              ),
            ),

            // Profile Card
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                margin: const EdgeInsets.only(top: 200),
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 5, offset: Offset(0, -2))],
                ),
                child: Padding(
                  padding: const EdgeInsets.only(top: 70, left: 16, right: 16, bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ชื่อ + อีเมล
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fullName.trim().isEmpty ? widget.user.username : fullName.trim(),
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(widget.user.email ?? '', style: const TextStyle(fontSize: 14, color: Colors.black54)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 50),
                      // กล่องสถิติ
                      Wrap(
                        spacing: 50,
                        runSpacing: 50,
                        children: [
                          _buildStatBox('Balance', '51', Icons.star),
                          _buildStatBox('Level', '1', Icons.emoji_events, tag: 'Record'),
                          _buildStatBox('Current League', 'Barefoot', Icons.directions_walk),
                          _buildStatBox('Total XP', '30', Icons.flash_on),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // รูปโปรไฟล์ + ปุ่มแก้ไข
            Positioned(
              top: 160,
              left: 16,
              child: GestureDetector(
                onTap: _showPickerOptions, // แตะเพื่อแก้ไขรูป
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 45,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: _imageFile != null
                          ? FileImage(_imageFile!)
                          : const AssetImage("assets/images/default.png") as ImageProvider,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.edit, color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6, offset: const Offset(0, 3))],
      ),
      child: IconButton(icon: Icon(icon, color: Colors.black), onPressed: onPressed),
    );
  }
}

