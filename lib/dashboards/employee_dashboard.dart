import 'package:flutter/material.dart';
import 'dashboard_layout.dart';

class EmployeeDashboard extends StatelessWidget {
  const EmployeeDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      title: 'My Dashboard',
      role: 'Employee',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Give Attendance Button
          Container(
            margin: const EdgeInsets.only(bottom: 24),
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Attendance Marked Successfully!'),
                  ),
                );
              },
              icon: const Icon(Icons.fingerprint, size: 28),
              label: const Text('Give Attendance'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF5350),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 20,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Analytics Section
          Wrap(
            spacing: 20,
            runSpacing: 20,
            children: const [
              SizedBox(
                width: 300,
                child: StatsCard(
                  title: 'Attendance',
                  value: '92%',
                  subValue: 'Excellent',
                  icon: Icons.access_time_filled,
                  iconColor: Colors.purple,
                  isPositive: true,
                ),
              ),
              SizedBox(
                width: 300,
                child: StatsCard(
                  title: 'Tasks Pending',
                  value: '3',
                  subValue: 'Due this week',
                  icon: Icons.pending_actions,
                  iconColor: Colors.orange,
                  isPositive: false,
                ),
              ),
              SizedBox(
                width: 300,
                child: StatsCard(
                  title: 'Tasks Completed',
                  value: '45',
                  subValue: '+12 this month',
                  icon: Icons.task_alt,
                  iconColor: Colors.green,
                  isPositive: true,
                ),
              ),
              SizedBox(
                width: 300,
                child: StatsCard(
                  title: 'Leaves Left',
                  value: '12',
                  subValue: 'days remaining',
                  icon: Icons.beach_access,
                  iconColor: Colors.teal,
                  isPositive: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const ChartPlaceholder(
            title: 'Weekly Productivity',
            color: Colors.blue,
          ),
        ],
      ),
    );
  }
}
