import 'package:flutter/material.dart';
import 'dashboard_layout.dart';

class SuperAdminDashboard extends StatelessWidget {
  const SuperAdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      title: 'Analytics Dashboard',
      role: 'Super Admin',
      child: Column(
        children: [
          // Stats Row
          LayoutBuilder(
            builder: (context, constraints) {
              final double width = constraints.maxWidth;
              final int count = width > 1000 ? 3 : (width > 600 ? 2 : 1);

              return Wrap(
                spacing: 20,
                runSpacing: 20,
                children: [
                  SizedBox(
                    width: (width - (20 * (count - 1))) / count,
                    child: const StatsCard(
                      title: 'Total Users',
                      value: '12,345',
                      subValue: '12% Increase',
                      icon: Icons.people,
                      iconColor: Colors.blue,
                      isPositive: true,
                    ),
                  ),
                  SizedBox(
                    width: (width - (20 * (count - 1))) / count,
                    child: const StatsCard(
                      title: 'Revenue',
                      value: '\$45,200',
                      subValue: '5.4% Increase',
                      icon: Icons.attach_money,
                      iconColor: Colors.green,
                      isPositive: true,
                    ),
                  ),
                  SizedBox(
                    width: (width - (20 * (count - 1))) / count,
                    child: const StatsCard(
                      title: 'Pending Issues',
                      value: '23',
                      subValue: '2 Urgent',
                      icon: Icons.warning_amber,
                      iconColor: Colors.orange,
                      isPositive: false,
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 24),

          const Row(
            children: [
              Expanded(
                flex: 2,
                child: ChartPlaceholder(
                  title: 'Growth Statistics',
                  color: Colors.blue,
                ),
              ),
              SizedBox(width: 24),
              Expanded(
                flex: 1,
                child: ChartPlaceholder(
                  title: 'User Activity',
                  color: Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
