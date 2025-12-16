import 'package:flutter/material.dart';
import 'dashboard_layout.dart';

class ManagerDashboard extends StatelessWidget {
  const ManagerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      title: 'Manager Dashboard',
      role: 'Manager',
      child: Column(
        children: [
          const Wrap(
            spacing: 20,
            runSpacing: 20,
            children: [
              SizedBox(
                width: 300,
                child: StatsCard(
                  title: 'Team Members',
                  value: '42',
                  subValue: 'All Active',
                  icon: Icons.group,
                  iconColor: Colors.indigo,
                  isPositive: true,
                ),
              ),
              SizedBox(
                width: 300,
                child: StatsCard(
                  title: 'Project Status',
                  value: '8',
                  subValue: 'On Track',
                  icon: Icons.assignment,
                  iconColor: Colors.teal,
                  isPositive: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const ChartPlaceholder(
            title: 'Team Performance',
            color: Colors.indigo,
          ),
        ],
      ),
    );
  }
}
