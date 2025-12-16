import 'package:flutter/material.dart';
import 'dashboard_layout.dart';

class TeamLeaderDashboard extends StatelessWidget {
  const TeamLeaderDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      title: 'Team Leader Dashboard',
      role: 'Team Leader',
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
                  title: 'Team Attendance',
                  value: '95%',
                  subValue: 'Excellent',
                  icon: Icons.access_time_filled,
                  iconColor: Colors.purple,
                  isPositive: true,
                ),
              ),
              SizedBox(
                width: 300,
                child: StatsCard(
                  title: 'Team Tasks',
                  value: '12',
                  subValue: 'Due this week',
                  icon: Icons.pending_actions,
                  iconColor: Colors.orange,
                  isPositive: false,
                ),
              ),
              SizedBox(
                width: 300,
                child: StatsCard(
                  title: 'Completed',
                  value: '145',
                  subValue: '+12 this month',
                  icon: Icons.task_alt,
                  iconColor: Colors.green,
                  isPositive: true,
                ),
              ),
              SizedBox(
                width: 300,
                child: StatsCard(
                  title: 'Reports',
                  value: '8',
                  subValue: 'Pending Review',
                  icon: Icons.assessment,
                  iconColor: Colors.blue,
                  isPositive: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const ChartPlaceholder(
            title: 'Team Productivity',
            color: Colors.blue,
          ),
        ],
      ),
    );
  }
}
