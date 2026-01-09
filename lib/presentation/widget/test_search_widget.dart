import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TestSearchWidget extends StatefulWidget {
  const TestSearchWidget({Key? key}) : super(key: key);

  @override
  State<TestSearchWidget> createState() => _TestSearchWidgetState();
}

class _TestSearchWidgetState extends State<TestSearchWidget> {
  final TextEditingController _controller = TextEditingController();
  String _displayText = '';

  @override
  void initState() {
    super.initState();
    print('TestSearchWidget initialized');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged(String value) {
    print('Text changed: "$value"');
    setState(() {
      _displayText = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    print('Building TestSearchWidget');
    
    return Column(
      children: [
        Container(
          height: 50.h,
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: TextField(
            controller: _controller,
            onChanged: _onTextChanged,
            decoration: InputDecoration(
              hintText: 'اكتب للبحث...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
              prefixIcon: const Icon(Icons.search),
            ),
          ),
        ),
        SizedBox(height: 16.h),
        Text(
          'النص المكتوب: $_displayText',
          style: TextStyle(fontSize: 16.sp),
        ),
        SizedBox(height: 8.h),
        Text(
          'Controller text: ${_controller.text}',
          style: TextStyle(fontSize: 14.sp, color: Colors.grey),
        ),
      ],
    );
  }
}