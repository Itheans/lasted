import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'cat.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CatEditPage extends StatefulWidget {
  final Cat cat;

  const CatEditPage({Key? key, required this.cat}) : super(key: key);

  @override
  State<CatEditPage> createState() => _CatEditPageState();
}

class _CatEditPageState extends State<CatEditPage> {
  late TextEditingController nameController;
  late TextEditingController breedController;
  late TextEditingController vaccinationsController;
  late TextEditingController descriptionController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.cat.name);
    breedController = TextEditingController(text: widget.cat.breed);
    // Convert Map to formatted string
    vaccinationsController = TextEditingController(
        text: _formatVaccinations(widget.cat.vaccinations));
    descriptionController = TextEditingController(text: widget.cat.description);
  }

  // Add this helper method to your class
  String _formatVaccinations(Map<String, dynamic> vaccinations) {
    return vaccinations.entries.map((e) => '${e.key}: ${e.value}').join('\n');
  }

  // Add this helper method to parse vaccinations string back to Map
  Map<String, dynamic> _parseVaccinations(String vaccinationsText) {
    Map<String, dynamic> result = {};
    if (vaccinationsText.isEmpty) return result;

    for (String pair in vaccinationsText.split('\n')) {
      if (pair.contains(':')) {
        List<String> parts = pair.split(':');
        String key = parts[0].trim();
        String value = parts[1].trim();
        result[key] = value;
      }
    }
    return result;
  }

  @override
  void dispose() {
    nameController.dispose();
    breedController.dispose();
    vaccinationsController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  void _saveChanges() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No user logged in');

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cats')
          .doc(widget.cat.id)
          .update({
        'name': nameController.text,
        'breed': breedController.text,
        'vaccinations':
            _parseVaccinations(vaccinationsController.text), // Convert to Map
        'description': descriptionController.text,
      });

      Navigator.pop(
        context,
        Cat(
          id: widget.cat.id,
          name: nameController.text,
          breed: breedController.text,
          imagePath: widget.cat.imagePath,
          birthDate: widget.cat.birthDate,
          vaccinations:
              _parseVaccinations(vaccinationsController.text), // Convert to Map
          description: descriptionController.text,
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Successfully updated ${widget.cat.name}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update cat data: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit ${widget.cat.name}'),
        backgroundColor: Colors.orange.shade400,
        elevation: 0,
      ),
      backgroundColor: Colors.grey[100],
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.orange.shade200, Colors.white],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // รูปแมว
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: widget.cat.imagePath.isNotEmpty
                        ? Image.network(
                            widget.cat.imagePath,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            color: Colors.grey[200],
                            child: Icon(
                              Icons.pets,
                              size: 50,
                              color: Colors.grey[400],
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),

                // ฟอร์มแก้ไข
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildTextField(
                        controller: nameController,
                        label: 'Name',
                        icon: Icons.pets,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: breedController,
                        label: 'Breed',
                        icon: Icons.category,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: vaccinationsController,
                        label: 'Vaccinations',
                        icon: Icons.medical_services,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: descriptionController,
                        label: 'Description',
                        icon: Icons.description,
                        maxLines: 4,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ปุ่มบันทึก
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _saveChanges,
                    child: const Text(
                      'Save Changes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.orange),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.orange, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }
}
