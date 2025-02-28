import 'package:cloud_firestore/cloud_firestore.dart';

class Cat {
  final String id;
  final String name;
  final String breed;
  final String imagePath;
  final Timestamp? birthDate;
  final Map<String, dynamic>
      vaccinations; // เปลี่ยนจาก String เป็น Map เพื่อเก็บข้อมูลวัคซีนแบบละเอียด
  final String description;
  final bool isForSitting; // เพิ่มฟิลด์สำหรับติดตามสถานะการฝากเลี้ยง
  final String? sittingStatus; // เพิ่มฟิลด์สำหรับติดตามสถานะการจับคู่
  final Timestamp? lastSittingDate; // เพิ่มฟิลด์สำหรับเก็บวันที่ฝากเลี้ยงล่าสุด

  Cat({
    required this.id,
    required this.name,
    required this.breed,
    required this.imagePath,
    this.birthDate,
    required this.vaccinations,
    required this.description,
    this.isForSitting = false, // ค่าเริ่มต้นเป็น false
    this.sittingStatus, // สถานะเช่น 'pending', 'matched', 'completed'
    this.lastSittingDate,
  });

  factory Cat.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // จัดการกับข้อมูลวัคซีนที่อาจอยู่ในรูปแบบเก่า (String) หรือใหม่ (Map)
    Map<String, dynamic> vaccinationsData;
    if (data['vaccinations'] is String) {
      // รูปแบบเก่า เก็บเป็น String เดียว แปลงเป็น Map โดยแยกด้วย comma
      List<String> vaccinationList =
          data['vaccinations'].toString().split(', ');
      vaccinationsData = {};
      for (var vaccine in vaccinationList) {
        if (vaccine.isNotEmpty) {
          vaccinationsData[vaccine] = {
            'isSelected': true,
            'vaccinationDate': null // ไม่มีข้อมูลวันที่ในรูปแบบเก่า
          };
        }
      }
    } else if (data['vaccinations'] is Map) {
      // รูปแบบใหม่ เก็บเป็น Map
      vaccinationsData = Map<String, dynamic>.from(data['vaccinations']);
    } else {
      // กรณีไม่มีข้อมูลหรือข้อมูลไม่ตรงรูปแบบ
      vaccinationsData = {};
    }

    return Cat(
      id: doc.id,
      name: data['name'] ?? '',
      breed: data['breed'] ?? '',
      imagePath: data['imagePath'] ?? '',
      birthDate: data['birthDate'],
      vaccinations: vaccinationsData,
      description: data['description'] ?? '',
      isForSitting: data['isForSitting'] ?? false,
      sittingStatus: data['sittingStatus'],
      lastSittingDate: data['lastSittingDate'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'breed': breed,
      'imagePath': imagePath,
      'birthDate': birthDate,
      'vaccinations': vaccinations,
      'description': description,
      'isForSitting': isForSitting,
      'sittingStatus': sittingStatus,
      'lastSittingDate': lastSittingDate,
    };
  }

  // สร้าง Cat ตัวใหม่โดยอัพเดทฟิลด์บางตัว
  Cat copyWith({
    bool? isForSitting,
    String? sittingStatus,
    Timestamp? lastSittingDate,
    Map<String, dynamic>? vaccinations,
  }) {
    return Cat(
      id: id,
      name: name,
      breed: breed,
      imagePath: imagePath,
      birthDate: birthDate,
      vaccinations: vaccinations ?? this.vaccinations,
      description: description,
      isForSitting: isForSitting ?? this.isForSitting,
      sittingStatus: sittingStatus ?? this.sittingStatus,
      lastSittingDate: lastSittingDate ?? this.lastSittingDate,
    );
  }

  // ฟังก์ชันสำหรับแสดงผลข้อมูลวัคซีนในรูปแบบข้อความ
  String getVaccinationsAsString() {
    if (vaccinations.isEmpty) {
      return '';
    }

    List<String> vaccinationTexts = [];
    vaccinations.forEach((key, value) {
      if (value is Map && value['isSelected'] == true) {
        if (value['vaccinationDate'] != null) {
          // ถ้ามีวันที่ฉีด ให้แสดงชื่อวัคซีนพร้อมวันที่
          Timestamp timestamp = value['vaccinationDate'];
          DateTime date = timestamp.toDate();
          String formattedDate = "${date.day}/${date.month}/${date.year}";
          vaccinationTexts.add("$key ($formattedDate)");
        } else {
          // ถ้าไม่มีวันที่ แสดงแค่ชื่อวัคซีน
          vaccinationTexts.add(key);
        }
      }
    });

    return vaccinationTexts.join(', ');
  }
}
