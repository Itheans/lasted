import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:myproject/page2.dart/scheduleincomepage.dart';
import 'package:myproject/widget/widget_support.dart';

class BookingAcceptancePage extends StatefulWidget {
  const BookingAcceptancePage({Key? key}) : super(key: key);

  @override
  State<BookingAcceptancePage> createState() => _BookingAcceptancePageState();
}

class _BookingAcceptancePageState extends State<BookingAcceptancePage> {
  bool _isLoading = true;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // บุคมาร์กสำหรับการเลื่อน (pagination)
  DocumentSnapshot? _lastVisible;
  bool _isMoreDataAvailable = true;
  bool _isLoadingMore = false;

  // รายการการจอง
  List<DocumentSnapshot> _bookings = [];

  // ตัวกรอง
  String _filterStatus = 'pending'; // pending, accepted, rejected
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  // โหลดข้อมูลการจอง
  Future<void> _loadBookings() async {
    setState(() => _isLoading = true);

    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      // แก้ตรงนี้: เปลี่ยนจาก 'bookings' เป็น 'booking_requests'
      Query query = _firestore
          .collection('booking_requests') // เปลี่ยนชื่อ collection ตรงนี้
          .where('sitterId', isEqualTo: currentUser.uid)
          .where('status', isEqualTo: _filterStatus)
          .orderBy('createdAt', descending: true)
          .limit(10);

      // เพิ่มโค้ดดีบักเพื่อตรวจสอบ
      print("กำลังค้นหาใน collection: booking_requests");
      print("UID ของผู้ใช้ปัจจุบัน: ${currentUser.uid}");
      print("กำลังกรองด้วย status: ${_filterStatus}");

      QuerySnapshot snapshot = await query.get();
      print("พบข้อมูลจำนวน: ${snapshot.docs.length} รายการ");

      // ส่วนการอัปเดต UI ยังคงเหมือนเดิม
      setState(() {
        _bookings = snapshot.docs;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading bookings: $e');
      setState(() => _isLoading = false);
    }
  }

  // โหลดข้อมูลเพิ่มเติม (pagination)
  Future<void> _loadMoreBookings() async {
    if (!_isMoreDataAvailable || _isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) return;

      Query query = _firestore
          .collection('bookings')
          .where('sitterId', isEqualTo: currentUser.uid)
          .where('status', isEqualTo: _filterStatus)
          .orderBy('createdAt', descending: true)
          .startAfterDocument(_lastVisible!)
          .limit(10);

      QuerySnapshot snapshot = await query.get();

      if (snapshot.docs.isNotEmpty) {
        _lastVisible = snapshot.docs[snapshot.docs.length - 1];
        setState(() {
          _bookings.addAll(snapshot.docs);
          _isMoreDataAvailable = snapshot.docs.length == 10;
        });
      } else {
        setState(() {
          _isMoreDataAvailable = false;
        });
      }
    } catch (e) {
      print('Error loading bookings: $e');
      setState(() {
        _isLoading = false;
        errorMessage = 'ไม่สามารถโหลดข้อมูลได้ กรุณาลองใหม่อีกครั้ง';
      });
    }
  }

  // อัพเดทสถานะการจอง
  Future<void> _updateBookingStatus(String bookingId, String status) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // รีโหลดข้อมูล
      _loadBookings();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('อัพเดทสถานะเรียบร้อย')),
      );
    } catch (e) {
      print('Error updating booking status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    }
  }

  // แสดงรายละเอียดการจอง
  void _showBookingDetails(DocumentSnapshot booking) {
    if (!mounted) return; // เช็ค mounted ก่อนดำเนินการต่อ

    final bookingData = booking.data() as Map<String, dynamic>;
    final dates = (bookingData['dates'] as List<dynamic>)
        .map((date) => (date as Timestamp).toDate())
        .toList();

    // ดึงข้อมูลผู้ใช้
    _firestore
        .collection('users')
        .doc(bookingData['userId'])
        .get()
        .then((userDoc) {
      if (!userDoc.exists) return;
      if (!mounted) return; // เช็ค mounted อีกครั้งหลังจาก async operation

      final userData = userDoc.data() as Map<String, dynamic>;

      // แสดง BottomSheet
      if (mounted) {
        // เพิ่มการตรวจสอบ mounted ก่อนแสดง UI
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          builder: (context) {
            return Container(
              padding: const EdgeInsets.all(20),
              height: MediaQuery.of(context).size.height * 0.7,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'รายละเอียดการจอง',
                        style: AppWidget.HeadlineTextFeildStyle(),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 10),
                  ListTile(
                    leading: CircleAvatar(
                      backgroundImage: userData['photo'] != null &&
                              userData['photo'].isNotEmpty
                          ? NetworkImage(userData['photo'])
                          : null,
                      child:
                          userData['photo'] == null || userData['photo'].isEmpty
                              ? const Icon(Icons.person)
                              : null,
                    ),
                    title: Text(
                      userData['name'] ?? 'ไม่ระบุชื่อ',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(userData['email'] ?? 'ไม่ระบุอีเมล'),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'วันที่ต้องการจ้าง:',
                    style: AppWidget.semiboldTextFeildStyle(),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 60,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: dates.length,
                      itemBuilder: (context, index) {
                        return Card(
                          margin: const EdgeInsets.only(right: 10),
                          color: Colors.orange.shade100,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Center(
                              child: Text(
                                DateFormat('dd MMM yyyy').format(dates[index]),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade800,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'ข้อมูลแมว:',
                    style: AppWidget.semiboldTextFeildStyle(),
                  ),
                  FutureBuilder<QuerySnapshot>(
                    future: _firestore
                        .collection('users')
                        .doc(bookingData['userId'])
                        .collection('cats')
                        .where(FieldPath.documentId,
                            whereIn: bookingData['catIds'] ?? [])
                        .get(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(10),
                          child: Text('ไม่พบข้อมูลแมว'),
                        );
                      }
                      if (errorMessage != null) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline,
                                  size: 64, color: Colors.red[300]),
                              const SizedBox(height: 16),
                              Text(
                                errorMessage!,
                                style: TextStyle(
                                    fontSize: 16, color: Colors.red[700]),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    errorMessage = null;
                                  });
                                  _loadBookings();
                                },
                                child: const Text('ลองใหม่'),
                              ),
                            ],
                          ),
                        );
                      }

                      return Container(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: snapshot.data!.docs.length,
                          itemBuilder: (context, index) {
                            final catData = snapshot.data!.docs[index].data()
                                as Map<String, dynamic>;
                            return Card(
                              margin: const EdgeInsets.only(right: 10, top: 10),
                              child: Container(
                                width: 180,
                                padding: const EdgeInsets.all(10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            image: catData['imagePath'] !=
                                                        null &&
                                                    catData['imagePath']
                                                        .isNotEmpty
                                                ? DecorationImage(
                                                    image: NetworkImage(
                                                        catData['imagePath']),
                                                    fit: BoxFit.cover,
                                                  )
                                                : null,
                                          ),
                                          child: catData['imagePath'] == null ||
                                                  catData['imagePath'].isEmpty
                                              ? const Icon(Icons.pets,
                                                  color: Colors.grey)
                                              : null,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                catData['name'] ??
                                                    'ไม่ระบุชื่อ',
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                catData['breed'] ??
                                                    'ไม่ระบุสายพันธุ์',
                                                style: const TextStyle(
                                                    fontSize: 12),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'วัคซีน: ${catData['vaccinations'] ?? 'ไม่ระบุ'}',
                                      style: const TextStyle(fontSize: 12),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Icon(Icons.payments, color: Colors.green[700]),
                      const SizedBox(width: 8),
                      Text(
                        'ราคารวม: ${bookingData['totalPrice'] ?? 0} บาท',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (bookingData['notes'] != null &&
                      bookingData['notes'].isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'บันทึกเพิ่มเติม:',
                          style: AppWidget.semiboldTextFeildStyle(),
                        ),
                        const SizedBox(height: 5),
                        Text(bookingData['notes']),
                        const SizedBox(height: 10),
                      ],
                    ),
                  const Spacer(),
                  // ถ้าสถานะเป็น pending ให้แสดงปุ่มยอมรับและปฏิเสธ
                  if (bookingData['status'] == 'pending')
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _updateBookingStatus(booking.id, 'rejected');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('ปฏิเสธการจอง'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _updateBookingStatus(booking.id, 'accepted');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('ยอมรับการจอง'),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            );
          },
        );
      }
    }).catchError((e) {
      if (mounted) {
        // เช็ค mounted ก่อนแสดง SnackBar
        print('Error fetching user data: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาดในการโหลดข้อมูลผู้ใช้: $e')),
        );
      }
    });
  }

  // เพิ่มเมธอดนี้ในคลาส _BookingAcceptancePageState
  Future<void> _debugCheckAllData() async {
    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // ลองดึงข้อมูลโดยไม่มีเงื่อนไขเพิ่มเติมเพื่อดูว่ามีข้อมูลหรือไม่
      final allDocsSnapshot = await _firestore
          .collection('booking_requests')
          .where('sitterId', isEqualTo: currentUser.uid)
          .get();

      print("พบข้อมูลทั้งหมด: ${allDocsSnapshot.docs.length} รายการ");

      // แสดงข้อมูลทั้งหมดเพื่อตรวจสอบโครงสร้าง
      for (var doc in allDocsSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        print("Document ID: ${doc.id}");
        print("Document data: $data");
      }
    } catch (e) {
      print("Error checking all data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'คำขอฝากเลี้ยงแมว',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal,
        elevation: 0,
      ),
      body: Column(
        children: [
          // ส่วนแถบตัวกรอง
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              border: Border(
                bottom: BorderSide(color: Colors.teal.shade200, width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildFilterButton('รอการยืนยัน', 'pending'),
                ),
                Expanded(
                  child: _buildFilterButton('ยอมรับแล้ว', 'accepted'),
                ),
                Expanded(
                  child: _buildFilterButton('ปฏิเสธแล้ว', 'rejected'),
                ),
              ],
            ),
          ),

          // ส่วนเนื้อหา
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _bookings.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'ไม่พบรายการคำขอฝากเลี้ยง',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 20),
                            // เพิ่มปุ่มเพื่อโหลดข้อมูลใหม่และเรียกเมธอดดีบัก
                            ElevatedButton.icon(
                              onPressed: () {
                                _loadBookings();
                                _debugCheckAllData(); // เพิ่มเมธอดนี้
                              },
                              icon: Icon(Icons.refresh),
                              label: Text('โหลดใหม่'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                padding: EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadBookings, // เพิ่มการรีเฟรชเมื่อดึงลง
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount:
                              _bookings.length + (_isMoreDataAvailable ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _bookings.length) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(8),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            return _buildBookingCard(_bookings[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
      // เพิ่ม Floating Action Button สำหรับดูรายได้และตารางงาน
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ScheduleIncomePage(),
            ),
          );
        },
        icon: const Icon(Icons.calendar_month),
        label: const Text('ตารางงาน'),
        backgroundColor: Colors.teal,
      ),
    );
  }

  Widget _buildFilterButton(String title, String status) {
    final isSelected = _filterStatus == status;
    return GestureDetector(
      onTap: () {
        if (_filterStatus != status) {
          setState(() => _filterStatus = status);
          _loadBookings();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.teal : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.teal.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildBookingCard(DocumentSnapshot booking) {
    final bookingData = booking.data() as Map<String, dynamic>;
    final createdAt = bookingData['createdAt'] as Timestamp?;
    final dates = (bookingData['dates'] as List<dynamic>)
        .map((date) => (date as Timestamp).toDate())
        .toList();

    // จัดการกับวันที่
    String dateRange;
    if (dates.length == 1) {
      dateRange = DateFormat('d MMM yyyy').format(dates[0]);
    } else {
      dates.sort();
      dateRange =
          '${DateFormat('d MMM').format(dates[0])} - ${DateFormat('d MMM yyyy').format(dates[dates.length - 1])}';
    }

    return FutureBuilder<DocumentSnapshot>(
      future: _firestore.collection('users').doc(bookingData['userId']).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Card(
            margin: EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>?;
        final userName = userData?['name'] ?? 'ไม่ระบุชื่อ';
        final userPhoto = userData?['photo'];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: _getStatusColor(bookingData['status']).withOpacity(0.5),
              width: 1,
            ),
          ),
          child: InkWell(
            onTap: () => _showBookingDetails(booking),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundImage:
                            userPhoto != null && userPhoto.isNotEmpty
                                ? NetworkImage(userPhoto)
                                : null,
                        child: userPhoto == null || userPhoto.isEmpty
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'สร้างเมื่อ: ${createdAt != null ? DateFormat('d MMM yyyy, HH:mm').format(createdAt.toDate()) : 'ไม่ระบุ'}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(bookingData['status'])
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _getStatusColor(bookingData['status']),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          _getStatusText(bookingData['status']),
                          style: TextStyle(
                            color: _getStatusColor(bookingData['status']),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoItem(
                          Icons.calendar_today,
                          'วันที่จอง',
                          dateRange,
                          Colors.blue,
                        ),
                      ),
                      Expanded(
                        child: _buildInfoItem(
                          Icons.payments,
                          'ค่าบริการ',
                          '${bookingData['totalPrice'] ?? 0} บาท',
                          Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoItem(
                          Icons.pets,
                          'จำนวนแมว',
                          '${(bookingData['catIds'] as List<dynamic>?)?.length ?? 0} ตัว',
                          Colors.orange,
                        ),
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: bookingData['status'] == 'pending'
                                  ? Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton(
                                          onPressed: () => _updateBookingStatus(
                                              booking.id, 'rejected'),
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.red,
                                          ),
                                          child: const Text('ปฏิเสธ'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () => _updateBookingStatus(
                                              booking.id, 'accepted'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                          ),
                                          child: const Text('ยอมรับ'),
                                        ),
                                      ],
                                    )
                                  : Container(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoItem(
      IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'pending':
        return 'รอการยืนยัน';
      case 'accepted':
        return 'ยอมรับแล้ว';
      case 'rejected':
        return 'ปฏิเสธแล้ว';
      default:
        return 'ไม่ระบุ';
    }
  }
}
