import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class VaccineSelectionPage extends StatefulWidget {
  final Map<String, Map<String, dynamic>> initialSelections;

  const VaccineSelectionPage({
    Key? key,
    required this.initialSelections,
  }) : super(key: key);

  @override
  State<VaccineSelectionPage> createState() => _VaccineSelectionPageState();
}

class _VaccineSelectionPageState extends State<VaccineSelectionPage> {
  late Map<String, Map<String, dynamic>> vaccinationGroups;
  final DateFormat _dateFormatter = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    // คัดลอกข้อมูลจาก initialSelections และแปลงให้อยู่ในรูปแบบที่ต้องการ
    vaccinationGroups = {};

    widget.initialSelections.forEach((groupKey, vaccines) {
      vaccinationGroups[groupKey] = {};
      vaccines.forEach((vaccineName, value) {
        // ถ้าค่าที่ได้รับเป็น bool เปลี่ยนเป็น Map ที่มี isSelected และ vaccinationDate
        if (value is bool) {
          vaccinationGroups[groupKey]![vaccineName] = {
            'isSelected': value,
            'vaccinationDate': null,
          };
        } else if (value is Map<String, dynamic>) {
          // ถ้าเป็น Map อยู่แล้วก็ใช้ค่านั้น
          vaccinationGroups[groupKey]![vaccineName] = value;
        }
      });
    });
  }

  String _getVaccineDescription(String vaccine) {
    Map<String, String> descriptions = {
      'FPV (Feline Panleukopenia)': 'Protects against feline distemper',
      'FHV (Feline Viral Rhinotracheitis)': 'Prevents respiratory infections',
      'FCV (Feline Calicivirus)':
          'Guards against oral disease and upper respiratory infections',
      'FeLV (Feline Leukemia Virus)': 'Protects against feline leukemia',
      'Rabies': 'Required by law, prevents rabies infection',
    };
    return descriptions[vaccine] ?? '';
  }

  int getSelectedCount() {
    int count = 0;
    vaccinationGroups.forEach((_, vaccines) {
      count += vaccines.values
          .where((vaccine) => vaccine['isSelected'] == true)
          .length;
    });
    return count;
  }

  // ฟังก์ชันสำหรับเลือกวันที่ฉีดวัคซีน
  Future<void> _selectVaccinationDate(
      String groupKey, String vaccineName, BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.orange,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        // แปลงเป็น Timestamp ก่อนเก็บในตัวแปร
        vaccinationGroups[groupKey]![vaccineName]['vaccinationDate'] =
            Timestamp.fromDate(picked);

        // เพิ่ม Log เพื่อตรวจสอบ
        print('Selected date for $vaccineName: $picked');
        print(
            'Stored as Timestamp: ${vaccinationGroups[groupKey]![vaccineName]['vaccinationDate']}');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Vaccinations',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            Text(
              '${getSelectedCount()} selected',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange, // เปลี่ยนเป็นสีส้ม
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context, null),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context, vaccinationGroups);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                'Done',
                style: TextStyle(
                  color: Colors.orange.shade700,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.orange.shade50, Colors.white],
          ),
        ),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: vaccinationGroups.length,
          itemBuilder: (context, groupIndex) {
            final group = vaccinationGroups.entries.elementAt(groupIndex);
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ส่วนหัวของกลุ่มวัคซีน
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(15),
                        topRight: Radius.circular(15),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.medical_services,
                            color: Colors.orange.shade700,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          group.key,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // รายการวัคซีนในกลุ่ม
                  ...group.value.entries.map((vaccine) {
                    bool isSelected = vaccine.value['isSelected'] ?? false;
                    DateTime? vaccinationDate =
                        vaccine.value['vaccinationDate'];

                    return Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey.shade100,
                                width: 1,
                              ),
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            leading: Transform.scale(
                              scale: 1.2,
                              child: Checkbox(
                                value: isSelected,
                                activeColor: Colors.orange,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                onChanged: (bool? value) {
                                  setState(() {
                                    vaccinationGroups[group.key]![vaccine.key]
                                        ['isSelected'] = value ?? false;
                                  });
                                },
                              ),
                            ),
                            title: Text(
                              vaccine.key,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    _getVaccineDescription(vaccine.key),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                                if (isSelected) // แสดงส่วนเลือกวันที่เมื่อเลือกวัคซีน
                                  InkWell(
                                    onTap: () => _selectVaccinationDate(
                                        group.key, vaccine.key, context),
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Row(
                                        children: [
                                          Icon(Icons.calendar_today,
                                              size: 16,
                                              color: Colors.orange.shade700),
                                          const SizedBox(width: 4),
                                          Text(
                                            vaccinationDate != null
                                                ? 'วันที่ฉีด: ${_formatDate(vaccinationDate)}'
                                                : 'เลือกวันที่ฉีดวัคซีน',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: vaccinationDate != null
                                                  ? Colors.orange.shade700
                                                  : Colors.grey.shade600,
                                              fontWeight:
                                                  vaccinationDate != null
                                                      ? FontWeight.bold
                                                      : FontWeight.normal,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            trailing: isSelected
                                ? IconButton(
                                    icon: Icon(
                                      Icons.calendar_month,
                                      color: Colors.orange.shade700,
                                    ),
                                    onPressed: () => _selectVaccinationDate(
                                      group.key,
                                      vaccine.key,
                                      context,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date is Timestamp) {
      final dateTime = date.toDate();
      return _dateFormatter.format(dateTime);
    } else if (date is DateTime) {
      return _dateFormatter.format(date);
    }
    return 'Invalid date';
  }
}
