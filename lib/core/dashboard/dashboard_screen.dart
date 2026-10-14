import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/crop_model.dart';
import '../../models/farm_model.dart';
import '../../models/farm_reminder.dart';
import '../../screens/crops_screen.dart';
import '../../screens/expenses_screen.dart';
import '../../screens/farms_screen.dart';
import '../../screens/insights_screen.dart';
import '../../screens/reminders_screen.dart';
import '../../screens/weather_screen.dart';
import '../../services/crop_database_service.dart';
import '../../services/farm_database_service.dart';
import '../../services/reminder_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  bool _isLoading = true;
  String? _errorMessage;

  List<FarmModel> _farms = [];
  List<CropModel> _crops = [];
  List<FarmReminder> _reminders = [];

  double _totalArea = 0;

  static const Color _primary = Color(0xFF176B45);
  static const Color _darkGreen = Color(0xFF0B3D2E);
  static const Color _background = Color(0xFFF5F8F5);

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final results = await Future.wait<dynamic>([
        FarmDatabaseService.instance.getFarms(),
        CropDatabaseService.instance.getCrops(),
        FarmDatabaseService.instance.getTotalArea(),
        ReminderService.instance.getReminders(),
      ]);

      if (!mounted) return;

      setState(() {
        _farms = List<FarmModel>.from(results[0] as List);
        _crops = List<CropModel>.from(results[1] as List);
        _totalArea = (results[2] as num).toDouble();
        _reminders = List<FarmReminder>.from(results[3] as List);
        _isLoading = false;
      });
    } catch (error, stackTrace) {
      debugPrint('Dashboard loading error: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to load dashboard data.';
      });
    }
  }

  Future<void> _refreshDashboard() async {
    await _loadDashboardData();
  }

  void _openTab(int index) {
    if (index < 0 || index >= 8) return;

    setState(() {
      _selectedIndex = index;
    });

    if (index == 0 || index == 4 || index == 5 ||
        index == 6 || index == 7) {
      _loadDashboardData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      _buildHomePage(),
      const FarmsScreen(),
      const CropsScreen(),
      const WeatherScreen(),
      const RemindersScreen(),
      const ExpensesScreen(),
      const InsightsScreen(),
      _buildProfilePage(),
    ];

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: pages,
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // HOME

  Widget _buildHomePage() {
    return RefreshIndicator(
      color: _primary,
      onRefresh: _refreshDashboard,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
              child: _buildHeader(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildWelcomeBanner(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 25, 20, 12),
              child: _buildSectionHeading(
                'Farm Overview',
                'Your farm at a glance',
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _isLoading
                  ? const SizedBox(
                      height: 160,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: _primary,
                        ),
                      ),
                    )
                  : _errorMessage != null
                      ? _buildErrorCard()
                      : _buildStatisticsGrid(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 26, 20, 12),
              child: _buildSectionHeading(
                'Quick Actions',
                'Manage your farm easily',
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildQuickActions(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 27, 20, 12),
              child: _buildUpcomingReminders(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 27, 20, 12),
              child: _buildSectionHeading(
                'Recent Crops',
                'Keep track of your crops',
                trailing: TextButton(
                  onPressed: () => _openTab(2),
                  child: const Text('View all'),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: _buildRecentCrops(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _primary,
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(
            Icons.eco_rounded,
            color: Colors.white,
            size: 29,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FarmPulse',
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                  color: _darkGreen,
                ),
              ),
              Text(
                'Smart farming, made simple',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: _refreshDashboard,
          icon: const Icon(Icons.refresh_rounded, color: _primary),
        ),
      ],
    );
  }

  Widget _buildWelcomeBanner() {
    final date = DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now());

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_darkGreen, _primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(23),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🌱 YOUR FARM, YOUR FUTURE',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Good farming\nstarts here.',
            style: TextStyle(
              fontSize: 28,
              height: 1.15,
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(date, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => _openTab(1),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white70),
            ),
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Manage your farms'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeading(
    String title,
    String subtitle, {
    Widget? trailing,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _darkGreen,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }

  Widget _buildStatisticsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 12) / 2;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: width,
              child: _statCard(
                'Total Farms',
                '${_farms.length}',
                Icons.agriculture,
                const Color(0xFFE4F4E9),
                _primary,
              ),
            ),
            SizedBox(
              width: width,
              child: _statCard(
                'Total Crops',
                '${_crops.length}',
                Icons.grass,
                const Color(0xFFFFF0D9),
                const Color(0xFFB87517),
              ),
            ),
            SizedBox(
              width: width,
              child: _statCard(
                'Land Area',
                _formatArea(_totalArea),
                Icons.landscape,
                const Color(0xFFE4F1FC),
                const Color(0xFF2876B8),
              ),
            ),
            SizedBox(
              width: width,
              child: _statCard(
                'Growing',
                '${_countGrowingCrops()}',
                Icons.trending_up,
                const Color(0xFFF0E8FC),
                const Color(0xFF7B55B7),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _statCard(
    String title,
    String value,
    IconData icon,
    Color background,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEBF0EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: background,
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 15),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.w800,
              color: _darkGreen,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: _darkGreen,
            ),
          ),
        ],
      ),
    );
  }

  String _formatArea(double area) {
    return area == area.roundToDouble()
        ? area.toInt().toString()
        : area.toStringAsFixed(2);
  }

  int _countGrowingCrops() {
    return _crops.where((crop) {
      final status = crop.status.toLowerCase().trim();
      return status == 'growing' ||
          status == 'in progress' ||
          status == 'active';
    }).length;
  }

  Widget _buildErrorCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.cloud_off, size: 36, color: Colors.orange),
            const SizedBox(height: 10),
            Text(_errorMessage!),
            const SizedBox(height: 10),
            FilledButton(
              onPressed: _refreshDashboard,
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  // QUICK ACTIONS

  Widget _buildQuickActions() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _quickAction(
          'Add Farm',
          Icons.add_business,
          () => _openTab(1),
        ),
        _quickAction(
          'Add Crop',
          Icons.grass,
          () => _openTab(2),
        ),
        _quickAction(
          'Expenses',
          Icons.account_balance_wallet,
          () => _openTab(5),
        ),
        _quickAction(
          'Insights',
          Icons.insights,
          () => _openTab(6),
        ),
      ],
    );
  }

  Widget _quickAction(
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return SizedBox(
      width: 145,
      child: Card(
        color: Colors.white,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              children: [
                Icon(icon, color: _primary, size: 27),
                const SizedBox(height: 8),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // REMINDERS

  Widget _buildUpcomingReminders() {
    final pending = _reminders
        .where((reminder) => !reminder.isCompleted)
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    final upcoming = pending.take(3).toList();
    final overdue = pending
        .where((reminder) => reminder.dueDate.isBefore(DateTime.now()))
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeading(
          'Farm Reminders',
          overdue > 0 ? '$overdue overdue task(s)' : 'Upcoming activities',
          trailing: TextButton(
            onPressed: () => _openTab(4),
            child: const Text('View all'),
          ),
        ),
        const SizedBox(height: 12),
        if (upcoming.isEmpty)
          const Card(
            color: Colors.white,
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Text('No pending reminders. Your schedule is clear!'),
            ),
          )
        else
          ...upcoming.map(
            (reminder) => Card(
              color: Colors.white,
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE4F4E9),
                  child: Icon(Icons.notifications, color: _primary),
                ),
                title: Text(
                  reminder.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${reminder.type} • '
                  '${DateFormat('dd MMM, hh:mm a').format(reminder.dueDate)}',
                ),
                trailing: reminder.dueDate.isBefore(DateTime.now())
                    ? const Icon(Icons.warning_amber, color: Colors.red)
                    : const Icon(Icons.chevron_right),
                onTap: () => _openTab(4),
              ),
            ),
          ),
      ],
    );
  }

  // RECENT CROPS

  Widget _buildRecentCrops() {
    if (_crops.isEmpty) {
      return Card(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              const Icon(Icons.grass, size: 42, color: _primary),
              const SizedBox(height: 10),
              const Text(
                'No crops added yet',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: () => _openTab(2),
                icon: const Icon(Icons.add),
                label: const Text('Manage crops'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _crops.reversed.take(5).map((crop) {
        final farm = _findFarm(crop.farmId);

        return Card(
          color: Colors.white,
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFE4F4E9),
              child: Icon(Icons.grass, color: _primary),
            ),
            title: Text(crop.name),
            subtitle: Text(
              '${crop.variety.isEmpty ? "Variety not specified" : crop.variety}\n'
              '${farm?.name ?? "Farm not found"}',
            ),
            isThreeLine: true,
            trailing: _statusBadge(crop.status),
          ),
        );
      }).toList(),
    );
  }

  FarmModel? _findFarm(int farmId) {
    for (final farm in _farms) {
      if (farm.id == farmId) return farm;
    }
    return null;
  }

  Widget _statusBadge(String status) {
    final normalized = status.toLowerCase();
    final harvested =
        normalized == 'harvested' || normalized == 'completed';
    final planned = normalized == 'planned';

    final color = harvested
        ? const Color(0xFF2876B8)
        : planned
            ? const Color(0xFFB87517)
            : _primary;

    final background = harvested
        ? const Color(0xFFE4F1FC)
        : planned
            ? const Color(0xFFFFF0D9)
            : const Color(0xFFE4F4E9);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        status.isEmpty ? 'Growing' : status,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // PROFILE

  Widget _buildProfilePage() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 25),
        const CircleAvatar(
          radius: 44,
          backgroundColor: Color(0xFFE4F4E9),
          child: Icon(Icons.person, color: _primary, size: 48),
        ),
        const SizedBox(height: 15),
        const Text(
          'FarmPulse Profile',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.w800,
            color: _darkGreen,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Your farm management overview',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 25),
        _profileInfo(Icons.agriculture, 'Registered Farms', '${_farms.length}'),
        _profileInfo(Icons.grass, 'Tracked Crops', '${_crops.length}'),
        _profileInfo(Icons.landscape, 'Total Land Area', _formatArea(_totalArea)),
        _profileInfo(
          Icons.notifications,
          'Pending Reminders',
          '${_reminders.where((r) => !r.isCompleted).length}',
        ),
        const SizedBox(height: 18),
        OutlinedButton.icon(
          onPressed: _refreshDashboard,
          icon: const Icon(Icons.refresh),
          label: const Text('Refresh dashboard data'),
        ),
      ],
    );
  }

  Widget _profileInfo(IconData icon, String title, String value) {
    return Card(
      color: Colors.white,
      child: ListTile(
        leading: Icon(icon, color: _primary),
        title: Text(title),
        trailing: Text(
          value,
          style: const TextStyle(
            color: _darkGreen,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // BOTTOM NAVIGATION: 8 TABS

  Widget _buildBottomNavigationBar() {
    return NavigationBar(
      selectedIndex: _selectedIndex,
      onDestinationSelected: _openTab,
      backgroundColor: Colors.white,
      indicatorColor: const Color(0xFFE4F4E9),
      height: 70,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard_rounded),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.agriculture_outlined),
          selectedIcon: Icon(Icons.agriculture_rounded),
          label: 'Farms',
        ),
        NavigationDestination(
          icon: Icon(Icons.grass_outlined),
          selectedIcon: Icon(Icons.grass_rounded),
          label: 'Crops',
        ),
        NavigationDestination(
          icon: Icon(Icons.cloud_outlined),
          selectedIcon: Icon(Icons.cloud_rounded),
          label: 'Weather',
        ),
        NavigationDestination(
          icon: Icon(Icons.notifications_outlined),
          selectedIcon: Icon(Icons.notifications_active_rounded),
          label: 'Reminders',
        ),
        NavigationDestination(
          icon: Icon(Icons.account_balance_wallet_outlined),
          selectedIcon: Icon(Icons.account_balance_wallet_rounded),
          label: 'Expenses',
        ),
        NavigationDestination(
          icon: Icon(Icons.insights_outlined),
          selectedIcon: Icon(Icons.insights_rounded),
          label: 'Insights',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline_rounded),
          selectedIcon: Icon(Icons.person_rounded),
          label: 'Profile',
        ),
      ],
    );
  }
}
