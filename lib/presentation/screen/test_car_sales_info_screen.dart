import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:advertising_app/presentation/providers/car_sales_info_provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TestCarSalesInfoScreen extends StatelessWidget {
  const TestCarSalesInfoScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Car Sales Info Test'),
        backgroundColor: const Color.fromRGBO(1, 84, 126, 1),
        foregroundColor: Colors.white,
      ),
      body: Consumer<CarSalesInfoProvider>(builder: (context, infoProvider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection('Makes', infoProvider.makes),
              const SizedBox(height: 20),
              _buildSection('Models', infoProvider.models),
              const SizedBox(height: 20),
              _buildSection('Trims', infoProvider.trims),
              const SizedBox(height: 20),
              _buildSection('Years', infoProvider.years),
              const SizedBox(height: 20),
              _buildSection('Specs', infoProvider.specs),
              const SizedBox(height: 20),
              _buildSection('Car Types', infoProvider.carTypes),
              const SizedBox(height: 20),
              _buildSection('Transmission Types', infoProvider.transmissionTypes),
              const SizedBox(height: 20),
              _buildSection('Fuel Types', infoProvider.fuelTypes),
              const SizedBox(height: 20),
              _buildSection('Colors', infoProvider.colors),
              const SizedBox(height: 20),
              _buildSection('Interior Colors', infoProvider.interiorColors),
              const SizedBox(height: 20),
              _buildSection('Engine Capacities', infoProvider.engineCapacities),
              const SizedBox(height: 20),
              _buildSection('Cylinders', infoProvider.cylinders),
              const SizedBox(height: 20),
              _buildSection('Horse Powers', infoProvider.horsePowers),
              const SizedBox(height: 20),
              _buildSection('Doors Numbers', infoProvider.doorsNumbers),
              const SizedBox(height: 20),
              _buildSection('Seats Numbers', infoProvider.seatsNumbers),
              const SizedBox(height: 20),
              _buildSection('Steering Sides', infoProvider.steeringSides),
              const SizedBox(height: 20),
              _buildSection('Advertiser Names', infoProvider.advertiserNames),
              const SizedBox(height: 20),
              _buildSection('Phone Numbers', infoProvider.phoneNumbers),
              const SizedBox(height: 20),
              _buildSection('Emirates', infoProvider.emirates),
              const SizedBox(height: 20),
              _buildSection('Advertiser Types', infoProvider.advertiserTypes),
              const SizedBox(height: 20),
              _buildSection('Warranty Options', infoProvider.warrantyOptions),
              const SizedBox(height: 20),
              _buildTestSection('Models for BMW', infoProvider.getModelsForMake('BMW')),
              const SizedBox(height: 20),
              _buildTestSection('Models for Honda', infoProvider.getModelsForMake('Honda')),
              const SizedBox(height: 20),
              _buildTestSection('Models for Toyota', infoProvider.getModelsForMake('Toyota')),
              const SizedBox(height: 20),
              _buildTestSection('Trims for Corolla', infoProvider.getTrimsForModel('Corolla')),
              const SizedBox(height: 20),
              _buildTestSection('Trims for Accord', infoProvider.getTrimsForModel('Accord')),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: const Color.fromRGBO(0, 30, 91, 1),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: const Color.fromRGBO(8, 194, 201, 1)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            children: items.map((item) => Chip(
              label: Text(item),
              backgroundColor: const Color.fromRGBO(8, 194, 201, 0.1),
              labelStyle: TextStyle(fontSize: 12.sp),
            )).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTestSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$title (Test Function)',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: const Color.fromRGBO(1, 84, 126, 1),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: const Color.fromRGBO(1, 84, 126, 1)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            children: items.map((item) => Chip(
              label: Text(item),
              backgroundColor: const Color.fromRGBO(1, 84, 126, 0.1),
              labelStyle: TextStyle(fontSize: 12.sp),
            )).toList(),
          ),
        ),
      ],
    );
  }
}