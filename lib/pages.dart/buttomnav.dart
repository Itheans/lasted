import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:myproject/pages.dart/chat.dart';
import 'package:myproject/pages.dart/home.dart';
import 'package:myproject/pages.dart/payment.dart';
import 'package:myproject/pages.dart/profile.dart';

class BottomNav extends StatefulWidget {
  const BottomNav({super.key});

  @override
  State<BottomNav> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<BottomNav> {
  int currentTapIndex = 0;
  late List<Widget> pages;
  late Widget currentPage;
  late Home homePage;
  late Chat chat;
  late Profile profile;
  late Payment payment;
  int pendingBookingsCount = 0;

  @override
  void initState() {
    homePage = const Home();
    chat = const Chat();
    profile = const Profile();
    payment = const Payment();
    pages = [homePage, chat, payment, profile];
    super.initState();
    _fetchPendingBookingsCount();
    super.initState();
  }

  Future<void> _fetchPendingBookingsCount() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final snapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: currentUser.uid)
          .where('status', isEqualTo: 'pending')
          .get();

      setState(() {
        pendingBookingsCount = snapshot.docs.length;
      });
    } catch (e) {
      print('Error fetching pending bookings count: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: CurvedNavigationBar(
        height: 65,
        backgroundColor: Colors.white,
        color: Colors.black,
        animationDuration: const Duration(milliseconds: 500),
        onTap: (int index) {
          setState(() {
            currentTapIndex = index;
          });
        },
        items: [
          const Icon(
            Icons.home_outlined,
            color: Colors.white,
          ),
          const Icon(
            Icons.chat_bubble_outline,
            color: Colors.white,
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              const Icon(
                Icons.payment,
                color: Colors.white,
              ),
              if (pendingBookingsCount > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 12,
                      minHeight: 12,
                    ),
                    child: Text(
                      pendingBookingsCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const Icon(
            Icons.person_outline,
            color: Colors.white,
          )
        ],
      ),
      body: pages[currentTapIndex],
    );
  }
}
