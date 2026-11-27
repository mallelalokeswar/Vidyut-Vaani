import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vidyut_vaani/core/services/api_client.dart';
import 'package:vidyut_vaani/core/theme/app_theme.dart';
import 'package:vidyut_vaani/features/auth/providers/auth_provider.dart';

class CitizenDashboardScreen extends ConsumerStatefulWidget {
  const CitizenDashboardScreen({super.key});

  @override
  ConsumerState<CitizenDashboardScreen> createState() =>
      _CitizenDashboardState();
}

class _CitizenDashboardState extends ConsumerState<CitizenDashboardScreen> {
  Map<String, dynamic>? _dashData;
  List<dynamic> _allComplaints = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchDashboard();
  }

  Future<void> _fetchDashboard() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await ApiClient.instance.get('/citizen/dashboard');
      final list = await ApiClient.instance.get('/citizen/complaints');
      setState(() {
        _dashData = data;
        _allComplaints = (list['complaints'] as List<dynamic>?) ?? [];
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openReportOutageDialog() async {
    final formKey = GlobalKey<FormState>();
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final localityCtrl = TextEditingController(
      text: ref.read(currentUserProvider)?.locality ?? '',
    );
    final landmarkCtrl = TextEditingController();
    String priority = 'medium';
    bool submitting = false;

    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.navyBlueMid,
          title: const Text(
            'Report Power Outage',
            style: TextStyle(color: AppColors.white, fontSize: 18),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: titleCtrl,
                    style: const TextStyle(color: AppColors.white),
                    decoration: const InputDecoration(
                      labelText: 'Issue Title *',
                      hintText: 'e.g. Transformer tripped in Sector 4',
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Title required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: localityCtrl,
                    style: const TextStyle(color: AppColors.white),
                    decoration: const InputDecoration(
                      labelText: 'Locality / Area *',
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Locality required'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: landmarkCtrl,
                    style: const TextStyle(color: AppColors.white),
                    decoration: const InputDecoration(
                      labelText: 'Landmark (optional)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: priority,
                    dropdownColor: AppColors.navyBlueLight,
                    style: const TextStyle(color: AppColors.white),
                    decoration: const InputDecoration(labelText: 'Priority'),
                    items: const [
                      DropdownMenuItem(value: 'low', child: Text('Low')),
                      DropdownMenuItem(value: 'medium', child: Text('Medium')),
                      DropdownMenuItem(value: 'high', child: Text('High')),
                      DropdownMenuItem(value: 'critical', child: Text('Critical')),
                    ],
                    onChanged: (v) {
                      if (v != null) setDialogState(() => priority = v);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descCtrl,
                    maxLines: 3,
                    style: const TextStyle(color: AppColors.white),
                    decoration: const InputDecoration(
                      labelText: 'Description *',
                      hintText: 'Describe the outage or voltage issue...',
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Description required'
                        : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: submitting ? null : () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel', style: TextStyle(color: AppColors.grey)),
            ),
            ElevatedButton(
              onPressed: submitting
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => submitting = true);
                      try {
                        await ApiClient.instance.post('/citizen/complaints', {
                          'title': titleCtrl.text.trim(),
                          'description': descCtrl.text.trim(),
                          'locality': localityCtrl.text.trim(),
                          if (landmarkCtrl.text.trim().isNotEmpty)
                            'landmark': landmarkCtrl.text.trim(),
                          'priority': priority,
                        });
                        if (ctx.mounted) Navigator.of(ctx).pop(true);
                      } catch (e) {
                        setDialogState(() => submitting = false);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text(e.toString()),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      }
                    },
              child: Text(submitting ? 'Submitting...' : 'Submit'),
            ),
          ],
        ),
      ),
    );

    titleCtrl.dispose();
    descCtrl.dispose();
    localityCtrl.dispose();
    landmarkCtrl.dispose();

    if (created == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Outage complaint submitted successfully.'),
          backgroundColor: AppColors.success,
        ),
      );
      _fetchDashboard();
    }
  }

  void _openPowerPulseMap() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const _PowerPulseMapScreen()),
    );
  }

  void _openBillInsights() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const _BillInsightsScreen()),
    );
  }

  void _openSubsidySchemes() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const _SubsidySchemesScreen()),
    );
  }

  void _openNotificationsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.navyBlueMid,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notifications',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            if (_allComplaints.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No recent complaint updates.',
                  style: TextStyle(color: AppColors.grey),
                ),
              )
            else
              ..._allComplaints.take(4).map((item) {
                final c = item as Map<String, dynamic>;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.notifications_active_outlined,
                      color: AppColors.teal),
                  title: Text(
                    c['title'] as String? ?? '',
                    style: const TextStyle(color: AppColors.white, fontSize: 14),
                  ),
                  subtitle: Text(
                    '${c['complaint_number']} • Status: ${(c['status'] as String).replaceAll('_', ' ').toUpperCase()}',
                    style: const TextStyle(color: AppColors.grey, fontSize: 12),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  void _openProfileSheet(dynamic user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.navyBlueMid,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.teal.withValues(alpha: 0.2),
                  child: const Icon(Icons.person, color: AppColors.teal, size: 28),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.fullName ?? 'Citizen',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '@${user?.username ?? ''}',
                      style: const TextStyle(color: AppColors.teal, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),
            _ProfileRow(Icons.email_outlined, 'Email', user?.email ?? '-'),
            _ProfileRow(Icons.phone_outlined, 'Phone', user?.phone ?? 'Not set'),
            _ProfileRow(
                Icons.location_on_outlined, 'Locality', user?.locality ?? 'Not set'),
            _ProfileRow(Icons.electric_meter_outlined, 'Meter No.',
                user?.meterNumber ?? 'Not set'),
          ],
        ),
      ),
    );
  }

  void _showComplaintDetail(Map<String, dynamic> c) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.navyBlueMid,
        title: Text(
          c['complaint_number'] as String? ?? 'Complaint',
          style: const TextStyle(color: AppColors.teal, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              c['title'] as String? ?? '',
              style: const TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              c['description'] as String? ?? '',
              style: const TextStyle(color: AppColors.grey, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Text('Locality: ${c['locality'] ?? '-'}',
                style: const TextStyle(color: AppColors.white, fontSize: 13)),
            Text(
                'Status: ${(c['status'] as String? ?? '').replaceAll('_', ' ').toUpperCase()}',
                style: const TextStyle(color: AppColors.teal, fontSize: 13)),
            Text('Priority: ${(c['priority'] as String? ?? '').toUpperCase()}',
                style: const TextStyle(color: AppColors.warning, fontSize: 13)),
            if (c['estimated_restoration'] != null)
              Text('Est. Restoration: ${c['estimated_restoration']}',
                  style: const TextStyle(color: AppColors.info, fontSize: 13)),
            if ((c['resolution_notes'] as String?)?.isNotEmpty ?? false)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('Notes: ${c['resolution_notes']}',
                    style: const TextStyle(color: AppColors.success, fontSize: 13)),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close', style: TextStyle(color: AppColors.teal)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.navyBlue,
      appBar: AppBar(
        title: const Text('Citizen Dashboard'),
        backgroundColor: AppColors.navyBlueMid,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Notifications',
            onPressed: _openNotificationsSheet,
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: 'Profile',
            onPressed: () => _openProfileSheet(user),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.teal,
        onRefresh: _fetchDashboard,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.teal))
            : _error != null
                ? _ErrorState(error: _error!, onRetry: _fetchDashboard)
                : _buildBody(user, _dashData),
      ),
    );
  }

  Widget _buildBody(dynamic user, Map<String, dynamic>? data) {
    final summary = data?['summary'] as Map<String, dynamic>? ?? {};

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _WelcomeCard(name: user?.fullName ?? 'Citizen'),
        const SizedBox(height: 16),
        const _PowerStatusBanner(),
        const SizedBox(height: 16),
        Row(children: [
          _StatTile('My Complaints', summary['my_complaints']?.toString() ?? '0',
              Icons.report_outlined, AppColors.citizenAccent),
          const SizedBox(width: 12),
          _StatTile('Pending', summary['pending']?.toString() ?? '0',
              Icons.pending_outlined, AppColors.warning),
          const SizedBox(width: 12),
          _StatTile('Resolved', summary['resolved']?.toString() ?? '0',
              Icons.check_circle_outline, AppColors.success),
        ]),
        const SizedBox(height: 24),
        const Text('Quick Actions',
            style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.white,
                fontSize: 16)),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 460;
            final cards = [
              _ActionButton(
                icon: Icons.report_problem_outlined,
                label: 'Report Outage',
                color: AppColors.error,
                onTap: _openReportOutageDialog,
              ),
              _ActionButton(
                icon: Icons.map_outlined,
                label: 'PowerPulse Map',
                color: AppColors.teal,
                onTap: _openPowerPulseMap,
              ),
              _ActionButton(
                icon: Icons.receipt_long_outlined,
                label: 'Bill Insights',
                color: AppColors.warning,
                onTap: _openBillInsights,
              ),
              _ActionButton(
                icon: Icons.card_giftcard_outlined,
                label: 'Subsidy Schemes',
                color: AppColors.success,
                onTap: _openSubsidySchemes,
              ),
            ];
            return GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isCompact ? 2 : 4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                mainAxisExtent: 94,
              ),
              children: cards,
            );
          },
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('My Complaints',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                    fontSize: 16)),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(110, 38),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('New'),
              onPressed: _openReportOutageDialog,
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_allComplaints.isEmpty)
          const _EmptyState('No complaints filed yet. Tap "Report Outage" to submit one.')
        else
          ..._allComplaints.map((c) {
            final map = c as Map<String, dynamic>;
            return _ComplaintTile(
              complaint: map,
              onTap: () => _showComplaintDetail(map),
            );
          }),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// PowerPulse Map Screen
// ---------------------------------------------------------------------------
class _PowerPulseMapScreen extends StatefulWidget {
  const _PowerPulseMapScreen();

  @override
  State<_PowerPulseMapScreen> createState() => _PowerPulseMapScreenState();
}

class _PowerPulseMapScreenState extends State<_PowerPulseMapScreen> {
  String _filter = 'All';
  final _zones = const [
    {'zone': 'Sector 1 - Indiranagar', 'status': 'Normal', 'load': '62%', 'feeders': '4/4 Active'},
    {'zone': 'Sector 4 - Koramangala', 'status': 'Outage', 'load': '0%', 'feeders': '2/4 Active'},
    {'zone': 'Sector 7 - Jayanagar', 'status': 'Normal', 'load': '71%', 'feeders': '3/3 Active'},
    {'zone': 'Sector 12 - Whitefield', 'status': 'Maintenance', 'load': '38%', 'feeders': '2/4 Active'},
    {'zone': 'Sector 15 - Malleshwaram', 'status': 'Normal', 'load': '54%', 'feeders': '5/5 Active'},
  ];

  Color _colorFor(String status) {
    switch (status) {
      case 'Normal':
        return AppColors.success;
      case 'Outage':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filter == 'All'
        ? _zones
        : _zones.where((z) => z['status'] == _filter).toList();

    return Scaffold(
      backgroundColor: AppColors.navyBlue,
      appBar: AppBar(title: const Text('PowerPulse Live Grid Map')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Wrap(
            spacing: 8,
            children: ['All', 'Normal', 'Outage', 'Maintenance'].map((f) {
              final selected = _filter == f;
              return ChoiceChip(
                label: Text(f),
                selected: selected,
                selectedColor: AppColors.teal,
                labelStyle: TextStyle(
                  color: selected ? AppColors.navyBlue : AppColors.white,
                  fontWeight: FontWeight.w600,
                ),
                onSelected: (_) => setState(() => _filter = f),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          ...filtered.map((z) {
            final c = _colorFor(z['status']!);
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.navyBlueMid,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: c.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  Icon(Icons.bolt, color: c, size: 28),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(z['zone']!,
                            style: const TextStyle(
                                color: AppColors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15)),
                        const SizedBox(height: 4),
                        Text(
                            'Feeders: ${z['feeders']}  •  Grid Load: ${z['load']}',
                            style: const TextStyle(
                                color: AppColors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: c.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(z['status']!,
                        style: TextStyle(
                            color: c,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// AI Bill Tracking & Insights Screen
// ---------------------------------------------------------------------------
class _BillInsightsScreen extends StatefulWidget {
  const _BillInsightsScreen();

  @override
  State<_BillInsightsScreen> createState() => _BillInsightsScreenState();
}

class _BillInsightsScreenState extends State<_BillInsightsScreen> {
  final _unitsCtrl = TextEditingController();
  final _months = ['Jul', 'Aug', 'Sep', 'Oct', 'Nov'];
  final List<double> _kwh = [185, 210, 195, 240, 178];

  @override
  void dispose() {
    _unitsCtrl.dispose();
    super.dispose();
  }

  void _addBill() {
    final val = double.tryParse(_unitsCtrl.text.trim());
    if (val == null || val <= 0) return;
    setState(() {
      _kwh[_kwh.length - 1] = val;
      _unitsCtrl.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Updated current month reading & AI insights.'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final latest = _kwh.last;
    final avg = _kwh.reduce((a, b) => a + b) / _kwh.length;
    final estBill = (latest * 6.5).round();

    return Scaffold(
      backgroundColor: AppColors.navyBlue,
      appBar: AppBar(title: const Text('AI Bill Tracking & Insights')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.navyBlueMid,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.teal.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Estimated Current Bill',
                    style: TextStyle(color: AppColors.grey, fontSize: 12)),
                const SizedBox(height: 4),
                Text('Rs. $estBill  (${latest.toStringAsFixed(0)} kWh)',
                    style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(
                  latest <= avg
                      ? 'Great! Your usage is ${(avg - latest).toStringAsFixed(0)} kWh below your 5-month average.'
                      : 'Heads up: Usage is ${(latest - avg).toStringAsFixed(0)} kWh above your 5-month average.',
                  style: TextStyle(
                    color: latest <= avg ? AppColors.success : AppColors.warning,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) => Text(
                        _months[v.toInt()],
                        style:
                            const TextStyle(color: AppColors.grey, fontSize: 12),
                      ),
                    ),
                  ),
                ),
                barGroups: List.generate(
                  _kwh.length,
                  (i) => BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: _kwh[i],
                        color: i == _kwh.length - 1
                            ? AppColors.teal
                            : AppColors.navyBlueLight,
                        width: 24,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _unitsCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppColors.white),
                  decoration: const InputDecoration(
                    labelText: 'Log Latest Meter Reading (kWh)',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size(90, 52)),
                onPressed: _addBill,
                child: const Text('Update'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text('AI Energy Saving Tips',
              style: TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15)),
          const SizedBox(height: 10),
          const ListTile(
            leading: Icon(Icons.lightbulb_outline, color: AppColors.teal),
            title: Text('Shift heavy appliances to off-peak hours (10 PM - 6 AM)',
                style: TextStyle(color: AppColors.white, fontSize: 13)),
          ),
          const ListTile(
            leading: Icon(Icons.solar_power_outlined, color: AppColors.success),
            title: Text('Eligible for PM Surya Ghar rooftop solar subsidy under 300 units.',
                style: TextStyle(color: AppColors.white, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Subsidy Schemes Navigator Screen
// ---------------------------------------------------------------------------
class _SubsidySchemesScreen extends StatefulWidget {
  const _SubsidySchemesScreen();

  @override
  State<_SubsidySchemesScreen> createState() => _SubsidySchemesScreenState();
}

class _SubsidySchemesScreenState extends State<_SubsidySchemesScreen> {
  List<dynamic> _schemes = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ApiClient.instance.get('/citizen/schemes');
      setState(() => _schemes = (res['schemes'] as List<dynamic>?) ?? []);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navyBlue,
      appBar: AppBar(title: const Text('Subsidy Schemes Navigator')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.teal))
          : _error != null
              ? Center(
                  child: Text(_error!,
                      style: const TextStyle(color: AppColors.error)),
                )
              : _schemes.isEmpty
                  ? const Center(
                      child: Text('No active subsidy schemes found.',
                          style: TextStyle(color: AppColors.grey)),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _schemes.length,
                      itemBuilder: (_, i) {
                        final s = _schemes[i] as Map<String, dynamic>;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.navyBlueMid,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: AppColors.success.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s['name'] as String? ?? '',
                                  style: const TextStyle(
                                      color: AppColors.teal,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16)),
                              const SizedBox(height: 6),
                              Text(s['description'] as String? ?? '',
                                  style: const TextStyle(
                                      color: AppColors.white, fontSize: 13)),
                              if (s['benefits'] != null) ...[
                                const SizedBox(height: 8),
                                Text('Benefits: ${s['benefits']}',
                                    style: const TextStyle(
                                        color: AppColors.success, fontSize: 12)),
                              ],
                              if (s['eligibility_criteria'] != null) ...[
                                const SizedBox(height: 4),
                                Text('Eligibility: ${s['eligibility_criteria']}',
                                    style: const TextStyle(
                                        color: AppColors.grey, fontSize: 12)),
                              ],
                              if (s['application_process'] != null) ...[
                                const SizedBox(height: 4),
                                Text('How to apply: ${s['application_process']}',
                                    style: const TextStyle(
                                        color: AppColors.grey, fontSize: 12)),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared Sub-widgets
// ---------------------------------------------------------------------------
class _ProfileRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _ProfileRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: AppColors.grey, size: 18),
          const SizedBox(width: 10),
          Text('$label: ',
              style: const TextStyle(color: AppColors.grey, fontSize: 13)),
          Expanded(
            child: Text(value,
                style: const TextStyle(color: AppColors.white, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  final String name;
  const _WelcomeCard({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.navyBlueMid, AppColors.navyBlueLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.teal.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.teal.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: AppColors.teal, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Welcome back,',
                    style: TextStyle(color: AppColors.grey, fontSize: 12)),
                Text(name,
                    style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const Icon(Icons.bolt, color: AppColors.teal, size: 32),
        ],
      ),
    );
  }
}

class _PowerStatusBanner extends StatelessWidget {
  const _PowerStatusBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.electric_bolt, color: AppColors.success, size: 22),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Power Status',
                    style: TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
                Text('Your area: Normal Supply',
                    style: TextStyle(color: AppColors.grey, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('Active',
                style: TextStyle(
                    color: AppColors.success,
                    fontSize: 11,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatTile(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.navyBlueMid,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(value,
                style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(color: AppColors.grey, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComplaintTile extends StatelessWidget {
  final Map<String, dynamic> complaint;
  final VoidCallback onTap;
  const _ComplaintTile({required this.complaint, required this.onTap});

  Color _statusColor(String status) {
    switch (status) {
      case 'resolved':
        return AppColors.success;
      case 'in_progress':
      case 'assigned':
        return AppColors.teal;
      case 'pending':
        return AppColors.warning;
      default:
        return AppColors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = complaint['status'] as String? ?? 'pending';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.navyBlueMid,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 48,
              decoration: BoxDecoration(
                color: _statusColor(status),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    complaint['title'] as String? ?? '',
                    style: const TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    complaint['complaint_number'] as String? ?? '',
                    style: const TextStyle(color: AppColors.grey, fontSize: 11),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _statusColor(status).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                status.replaceAll('_', ' ').toUpperCase(),
                style: TextStyle(
                    color: _statusColor(status),
                    fontSize: 10,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState(this.message);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.grey),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorState({required this.error, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: 12),
            Text(error,
                style: const TextStyle(color: AppColors.grey),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
