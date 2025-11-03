import 'dart:async';
import 'package:advertising_app/constant/string.dart';
import 'package:advertising_app/generated/l10n.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:advertising_app/presentation/providers/auth_repository.dart';

class _SplashItemData {
  final String Function(BuildContext) title;
  final String image;
  const _SplashItemData({required this.title, required this.image});
}

class SplashGridScreen extends StatefulWidget {
  @override
  _SplashGridScreenState createState() => _SplashGridScreenState();
}

class _SplashGridScreenState extends State<SplashGridScreen> {
  int _visibleCount = 0;
  late Timer _timer;
  final List<_SplashItemData> items = [
    _SplashItemData(
      title: (ctx) => S.of(ctx).carsales,
      image: "assets/images/salesCar.jpg",
    ),
    _SplashItemData(
      title: (ctx) => S.of(ctx).realestate,
      image: "assets/images/realEstate.jpg",
    ),
    _SplashItemData(
      title: (ctx) => S.of(ctx).carrent,
      image: "assets/images/careRent.jpg",
    ),
    _SplashItemData(
      title: (ctx) => S.of(ctx).carservices,
      image: "assets/images/car_services.png",
    ),
    _SplashItemData(
      title: (ctx) => S.of(ctx).electronics,
      image: "assets/images/electronics.jpg",
    ),
    _SplashItemData(
      title: (ctx) => S.of(ctx).restaurants,
      image: "assets/images/restaurant.jpg",
    ),
    _SplashItemData(
      title: (ctx) => S.of(ctx).jobs,
      image: "assets/images/jobs.jpg",
    ),
    _SplashItemData(
      title: (ctx) => S.of(ctx).otherservices,
      image: "assets/images/service.jpg",
    ),
  ];

  @override
  void initState() {
    super.initState();
    _startRevealing();
  }

  void _startRevealing() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_visibleCount < items.length) {
        setState(() {
          _visibleCount++;
        });
      } else {
        _timer.cancel();
        Future.delayed(Duration(seconds:1), () {
          _checkAuthAndNavigate();
        });
      }
    });
  }

  Future<void> _checkAuthAndNavigate() async {
    if (!mounted) return;
    
    final authProvider = context.read<AuthProvider>();
    final hasValidSession = await authProvider.checkStoredSession();
    
    if (!mounted) return;
    
    if (hasValidSession) {
      context.go('/home');
    } else {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.02,
                vertical: screenHeight * 0.01,
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      height: screenHeight * 0.1,
                      width: screenWidth * 0.25,
                    ),
                   // SizedBox(width: screenWidth * 0.02),
                    Flexible(
                      child: Text(
                        S.of(context).enjoyFreeAds,
                        style: TextStyle(
                          fontSize: screenWidth * 0.06,
                          fontWeight: FontWeight.bold,
                          color: KTextColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: (screenWidth * 0.02)),
                    child: Wrap(
                      spacing: screenWidth * 0.03,
                      runSpacing: screenHeight * 0.005,
                      alignment: WrapAlignment.center,
                      children: List.generate(_visibleCount, (index) {
                        final item = items[index];
                        return SplashItem(
                          title: item.title(context),
                          image: item.image,
                          screenWidth: screenWidth,
                          isPortrait: isPortrait,
                        );
                      }),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SplashItem extends StatelessWidget {
  final String title;
  final String image;
  final double screenWidth;
  final bool isPortrait;

  const SplashItem({
    required this.title,
    required this.image,
    required this.screenWidth,
    required this.isPortrait,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate item width based on screen size and orientation
    final itemWidth = isPortrait ? screenWidth * 0.42 : screenWidth * 0.3;
    // final itemHeight = isPortrait ? itemWidth * 1.2 : itemWidth * 0.9;

    return Container(
      width: itemWidth,
      height: 150,
      padding: EdgeInsets.symmetric(horizontal: .01),
      decoration: BoxDecoration(
        color: Colors.white,
       // borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        // mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 3,
            child: ClipRRect(
              //borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                image,
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
          ),
          SizedBox(height: screenWidth * 0.01),
          Flexible(
            flex: 1,
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                color: KTextColor,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
