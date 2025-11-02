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
      constraints: const BoxConstraints(minWidth: 120, maxWidth: 300),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.red),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.blueAccent.withOpacity(0.12),
            child: Icon(icon, size: 20, color: Colors.blueAccent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 2),
                Text(title, style: const TextStyle(fontSize: 12, color: Colors.black54)),
              ],
            ),
          ),
          if (tag != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orangeAccent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(tag, style: const TextStyle(fontSize: 10, color: Colors.white)),
            ),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6, offset: const Offset(0, 3))],
      ),
      child: IconButton(icon: Icon(icon, color: Colors.black87), onPressed: onPressed),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String fullName = '${widget.user.firstName ?? ''} ${widget.user.lastName ?? ''}'.trim();
    final width = MediaQuery.of(context).size.width;
    final statSpacing = 12.0;
    final statWidth = (width - 40 - statSpacing) / 2; // padding 20 ซ้ายขวา

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 54, 183, 219),
      body: SafeArea(
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            // ส่วนเนื้อหาด้านล่าง
            SingleChildScrollView(
              child: Column(
                children: [
                  // Top row
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
                  const SizedBox(height: 90), // เผื่อพื้นที่ให้ avatar

                  // ส่วนการ์ดขาว
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
                      boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, -3))],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 70, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name + email + logout
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      fullName.isEmpty ? widget.user.username ?? '' : fullName,
                                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(widget.user.email ?? '',
                                        style: const TextStyle(fontSize: 14, color: Colors.black54)),
                                  ],
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: () {},
                                icon: const Icon(Icons.logout),
                                label: const Text('Logout'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 22),
                          const Divider(height: 1, thickness: 1),
                          const SizedBox(height: 18),

                          // Stats grid
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              SizedBox(width: statWidth, child: _buildStatBox('Balance', '51', Icons.star)),
                              SizedBox(
                                  width: statWidth,
                                  child: _buildStatBox('Level', '1', Icons.emoji_events, tag: 'Record')),
                              SizedBox(width: statWidth, child: _buildStatBox('Current League', 'Barefoot', Icons.directions_walk)),
                              SizedBox(width: statWidth, child: _buildStatBox('Total XP', '30', Icons.flash_on)),
                            ],
                          ),

                          const SizedBox(height: 18),

                          // Profile details
                          Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Profile Details', style: TextStyle(fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 8),
                                  ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: const Text('Username'),
                                    subtitle: Text(widget.user.username ?? ''),
                                  ),
                                  ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: const Text('Role'),                 
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Avatar (กลางบนสุด)
            Positioned(
              top: 100,
              child: GestureDetector(
                onTap: _showPickerOptions,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 56,
                      backgroundColor: Colors.white,
                      backgroundImage: _imageFile != null
                          ? FileImage(_imageFile!)
                          : const AssetImage("assets/images/default.png") as ImageProvider,
                    ),
                    Positioned(
                      bottom: -2,
                      right: -2,
                      child: Material(
                        elevation: 2,
                        shape: const CircleBorder(),
                        color: Colors.blue,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: _showPickerOptions,
                          child: const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Icon(Icons.edit, color: Colors.white, size: 18),
                          ),
                        ),
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
}
