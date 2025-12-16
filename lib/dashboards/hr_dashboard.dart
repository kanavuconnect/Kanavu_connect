import 'package:flutter/material.dart';
import 'dashboard_layout.dart';

class HRDashboard extends StatelessWidget {
  const HRDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      title: 'Human Resources',
      role: 'HR',
      child: Column(
        children: [
          Wrap(
            spacing: 20,
            runSpacing: 20,
            children: const [
              SizedBox(
                width: 300,
                child: StatsCard(
                  title: 'Employees',
                  value: '156',
                  subValue: '+3 New',
                  icon: Icons.badge,
                  iconColor: Colors.pink,
                  isPositive: true,
                ),
              ),
              SizedBox(
                width: 300,
                child: StatsCard(
                  title: 'Applications',
                  value: '24',
                  subValue: 'Pending Review',
                  icon: Icons.description,
                  iconColor: Colors.orange,
                  isPositive: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const ChartPlaceholder(
            title: 'Recruitment Funnel',
            color: Colors.pink,
          ),
        ],
      ),
    );
  }
}
