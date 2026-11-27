import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vidyut_vaani/core/services/api_client.dart';
import 'package:vidyut_vaani/core/theme/app_theme.dart';
import 'package:vidyut_vaani/features/auth/providers/auth_provider.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboardScreen> {
  Map<String, dynamic>? _dashData;
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
      final data = await ApiClient.instance.get('/admin/dashboard');
      setState(() => _dashData = data);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateTo(Widget screen) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => screen))
        .then((_) => _fetchDashboard());
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    return Scaffold(
      backgroundColor: AppColors.navyBlue,
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: AppColors.navyBlueMid,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.adminAccent,
        onRefresh: _fetchDashboard,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.adminAccent))
            : _error != null
                ? _errorView()
                : _body(user),
      ),
    );
  }

  Widget _errorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 48),
          const SizedBox(height: 12),
          Text(_error ?? 'Error', style: const TextStyle(color: AppColors.grey)),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: _fetchDashboard, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _body(dynamic user) {
    final complaints = _dashData?['complaints'] as Map<String, dynamic>? ?? {};
    final totalUsers = _dashData?['total_users'] ?? 0;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _AdminHeader(name: user?.fullName ?? 'Admin'),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 680;
            return GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isWide ? 4 : 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                mainAxisExtent: 104,
              ),
              children: [
                _AdminStatCard('Total Users', totalUsers.toString(),
                    Icons.people_outline, AppColors.adminAccent),
                _AdminStatCard(
                    'Total Complaints',
                    complaints['total']?.toString() ?? '0',
                    Icons.report_outlined,
                    AppColors.citizenAccent),
                _AdminStatCard(
                    'Active Outages',
                    complaints['active_outages']?.toString() ?? '0',
                    Icons.flash_on_outlined,
                    AppColors.error),
                _AdminStatCard(
                    'Resolved',
                    complaints['resolved']?.toString() ?? '0',
                    Icons.check_circle_outline,
                    AppColors.success),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        const Text('Administration',
            style: TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16)),
        const SizedBox(height: 14),
        _AdminMenuItem(
          icon: Icons.manage_accounts_outlined,
          label: 'User Management',
          subtitle: 'View, activate, suspend accounts',
          color: AppColors.adminAccent,
          onTap: () => _navigateTo(const _AdminUsersScreen()),
        ),
        _AdminMenuItem(
          icon: Icons.report_outlined,
          label: 'Complaint Management',
          subtitle: 'Assign and monitor all complaints',
          color: AppColors.citizenAccent,
          onTap: () => _navigateTo(const _AdminComplaintsScreen()),
        ),
        _AdminMenuItem(
          icon: Icons.card_giftcard_outlined,
          label: 'Scheme Management',
          subtitle: 'Manage electricity subsidy schemes',
          color: AppColors.success,
          onTap: () => _navigateTo(const _AdminSchemesScreen()),
        ),
        _AdminMenuItem(
          icon: Icons.bar_chart_outlined,
          label: 'Reports & Analytics',
          subtitle: 'Platform statistics and trends',
          color: AppColors.warning,
          onTap: () => _navigateTo(_AdminAnalyticsScreen(
            totalUsers: totalUsers as int,
            complaints: complaints,
          )),
        ),
        _AdminMenuItem(
          icon: Icons.history_outlined,
          label: 'Audit Logs',
          subtitle: 'Full administrative action trail',
          color: AppColors.grey,
          onTap: () => _navigateTo(const _AdminAuditLogsScreen()),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 1. Admin User Management
// ---------------------------------------------------------------------------
class _AdminUsersScreen extends StatefulWidget {
  const _AdminUsersScreen();

  @override
  State<_AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<_AdminUsersScreen> {
  List<dynamic> _users = [];
  bool _loading = true;
  String? _roleFilter;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final path =
          _roleFilter == null ? '/admin/users' : '/admin/users?role=$_roleFilter';
      final res = await ApiClient.instance.get(path);
      setState(() => _users = (res['users'] as List<dynamic>?) ?? []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleStatus(Map<String, dynamic> u) async {
    final current = u['status'] as String? ?? 'active';
    final next = current == 'active' ? 'suspended' : 'active';
    await ApiClient.instance.patch(
      '/admin/users/${u['id']}/status',
      {'status': next},
    );
    _load();
  }

  Future<void> _addUserDialog() async {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final usernameCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final localityCtrl = TextEditingController();
    String selectedRole = 'operator';
    String? errorMsg;
    bool submitting = false;

    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          backgroundColor: AppColors.navyBlueMid,
          title: const Text(
            'Add New Operator / User',
            style: TextStyle(color: AppColors.white, fontSize: 17),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selectedRole,
                    dropdownColor: AppColors.navyBlueLight,
                    style: const TextStyle(color: AppColors.white),
                    decoration: const InputDecoration(labelText: 'Role *'),
                    items: const [
                      DropdownMenuItem(
                          value: 'operator', child: Text('Field Operator')),
                      DropdownMenuItem(value: 'admin', child: Text('Admin')),
                      DropdownMenuItem(value: 'citizen', child: Text('Citizen')),
                    ],
                    onChanged: (v) {
                      if (v != null) setD(() => selectedRole = v);
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: nameCtrl,
                    style: const TextStyle(color: AppColors.white),
                    decoration: const InputDecoration(labelText: 'Full Name *'),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: emailCtrl,
                    style: const TextStyle(color: AppColors.white),
                    decoration: const InputDecoration(labelText: 'Email *'),
                    validator: (v) =>
                        v == null || !v.contains('@') ? 'Valid email required' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: usernameCtrl,
                    style: const TextStyle(color: AppColors.white),
                    decoration: const InputDecoration(labelText: 'Username *'),
                    validator: (v) =>
                        v == null || v.trim().length < 3 ? 'Min 3 chars' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: passwordCtrl,
                    obscureText: true,
                    style: const TextStyle(color: AppColors.white),
                    decoration: const InputDecoration(
                      labelText: 'Password *',
                      hintText: 'Min 8 chars, upper, lower, digit',
                    ),
                    validator: (v) =>
                        v == null || v.length < 8 ? 'Min 8 characters' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: localityCtrl,
                    style: const TextStyle(color: AppColors.white),
                    decoration:
                        const InputDecoration(labelText: 'Locality (optional)'),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: phoneCtrl,
                    style: const TextStyle(color: AppColors.white),
                    decoration:
                        const InputDecoration(labelText: 'Phone (optional)'),
                  ),
                  if (errorMsg != null) ...[
                    const SizedBox(height: 10),
                    Text(errorMsg!,
                        style: const TextStyle(
                            color: AppColors.error, fontSize: 12)),
                  ],
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
                      setD(() {
                        submitting = true;
                        errorMsg = null;
                      });
                      try {
                        await ApiClient.instance.post('/admin/users', {
                          'full_name': nameCtrl.text.trim(),
                          'email': emailCtrl.text.trim(),
                          'username': usernameCtrl.text.trim(),
                          'password': passwordCtrl.text,
                          'role': selectedRole,
                          if (localityCtrl.text.trim().isNotEmpty)
                            'locality': localityCtrl.text.trim(),
                          if (phoneCtrl.text.trim().isNotEmpty)
                            'phone': phoneCtrl.text.trim(),
                        });
                        if (ctx.mounted) Navigator.of(ctx).pop(true);
                      } catch (e) {
                        setD(() {
                          submitting = false;
                          errorMsg = e.toString();
                        });
                      }
                    },
              child: Text(submitting ? 'Creating...' : 'Create'),
            ),
          ],
        ),
      ),
    );

    nameCtrl.dispose();
    emailCtrl.dispose();
    usernameCtrl.dispose();
    passwordCtrl.dispose();
    phoneCtrl.dispose();
    localityCtrl.dispose();

    if (created == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created successfully.'),
          backgroundColor: AppColors.success,
        ),
      );
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navyBlue,
      appBar: AppBar(
        title: const Text('User Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined),
            tooltip: 'Add Operator / User',
            onPressed: _addUserDialog,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.adminAccent,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.person_add),
        label: const Text('Add Operator'),
        onPressed: _addUserDialog,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Wrap(
              spacing: 8,
              children: [null, 'citizen', 'operator', 'admin'].map((r) {
                final selected = _roleFilter == r;
                return ChoiceChip(
                  label: Text((r ?? 'All').toUpperCase()),
                  selected: selected,
                  selectedColor: AppColors.adminAccent,
                  labelStyle: TextStyle(
                    color: selected ? AppColors.white : AppColors.grey,
                    fontSize: 11,
                  ),
                  onSelected: (_) {
                    setState(() => _roleFilter = r);
                    _load();
                  },
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child:
                        CircularProgressIndicator(color: AppColors.adminAccent))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _users.length,
                    itemBuilder: (_, i) {
                      final u = _users[i] as Map<String, dynamic>;
                      final isActive = u['status'] == 'active';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.navyBlueMid,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${u['full_name']} (@${u['username']})',
                                    style: const TextStyle(
                                        color: AppColors.white,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${u['email']} • ${(u['role'] as String).toUpperCase()}',
                                    style: const TextStyle(
                                        color: AppColors.grey, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(100, 38),
                                side: BorderSide(
                                  color: isActive
                                      ? AppColors.error
                                      : AppColors.success,
                                ),
                              ),
                              onPressed: () => _toggleStatus(u),
                              child: Text(
                                isActive ? 'Suspend' : 'Activate',
                                style: TextStyle(
                                  color: isActive
                                      ? AppColors.error
                                      : AppColors.success,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 2. Admin Complaint Management
// ---------------------------------------------------------------------------
class _AdminComplaintsScreen extends StatefulWidget {
  const _AdminComplaintsScreen();

  @override
  State<_AdminComplaintsScreen> createState() => _AdminComplaintsScreenState();
}

class _AdminComplaintsScreenState extends State<_AdminComplaintsScreen> {
  List<dynamic> _complaints = [];
  List<dynamic> _operators = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final cRes = await ApiClient.instance.get('/admin/complaints');
      final oRes = await ApiClient.instance.get('/admin/users?role=operator');
      setState(() {
        _complaints = (cRes['complaints'] as List<dynamic>?) ?? [];
        _operators = (oRes['users'] as List<dynamic>?) ?? [];
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _assignDialog(Map<String, dynamic> complaint) async {
    if (_operators.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No field operators available.')),
      );
      return;
    }
    int selectedOpId = _operators.first['id'] as int;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          backgroundColor: AppColors.navyBlueMid,
          title: Text('Assign ${complaint['complaint_number']}',
              style: const TextStyle(color: AppColors.white, fontSize: 16)),
          content: DropdownButtonFormField<int>(
            initialValue: selectedOpId,
            dropdownColor: AppColors.navyBlueLight,
            style: const TextStyle(color: AppColors.white),
            decoration: const InputDecoration(labelText: 'Select Field Operator'),
            items: _operators.map((op) {
              final m = op as Map<String, dynamic>;
              return DropdownMenuItem<int>(
                value: m['id'] as int,
                child: Text('${m['full_name']} (${m['username']})'),
              );
            }).toList(),
            onChanged: (v) {
              if (v != null) setD(() => selectedOpId = v);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel', style: TextStyle(color: AppColors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                await ApiClient.instance.patch(
                  '/admin/complaints/${complaint['id']}/assign',
                  {'operator_id': selectedOpId},
                );
                if (ctx.mounted) Navigator.of(ctx).pop(true);
              },
              child: const Text('Assign'),
            ),
          ],
        ),
      ),
    );
    if (ok == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navyBlue,
      appBar: AppBar(title: const Text('Complaint Management')),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.adminAccent))
          : _complaints.isEmpty
              ? const Center(
                  child: Text('No complaints found.',
                      style: TextStyle(color: AppColors.grey)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _complaints.length,
                  itemBuilder: (_, i) {
                    final c = _complaints[i] as Map<String, dynamic>;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.navyBlueMid,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(c['title'] as String? ?? '',
                                    style: const TextStyle(
                                        color: AppColors.white,
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                Text(
                                  '${c['complaint_number']} • ${c['locality']} • ${(c['status'] as String).toUpperCase()}',
                                  style: const TextStyle(
                                      color: AppColors.grey, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          OutlinedButton(
                            onPressed: () => _assignDialog(c),
                            child: const Text('Assign'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}

// ---------------------------------------------------------------------------
// 3. Admin Scheme Management
// ---------------------------------------------------------------------------
class _AdminSchemesScreen extends StatefulWidget {
  const _AdminSchemesScreen();

  @override
  State<_AdminSchemesScreen> createState() => _AdminSchemesScreenState();
}

class _AdminSchemesScreenState extends State<_AdminSchemesScreen> {
  List<dynamic> _schemes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient.instance.get('/admin/schemes');
      setState(() => _schemes = (res['schemes'] as List<dynamic>?) ?? []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addSchemeDialog() async {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final benefitsCtrl = TextEditingController();
    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.navyBlueMid,
        title: const Text('Add Subsidy Scheme',
            style: TextStyle(color: AppColors.white, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: const TextStyle(color: AppColors.white),
              decoration: const InputDecoration(labelText: 'Scheme Name *'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: descCtrl,
              maxLines: 2,
              style: const TextStyle(color: AppColors.white),
              decoration: const InputDecoration(labelText: 'Description *'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: benefitsCtrl,
              style: const TextStyle(color: AppColors.white),
              decoration: const InputDecoration(labelText: 'Benefits'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty || descCtrl.text.trim().isEmpty) {
                return;
              }
              await ApiClient.instance.post('/admin/schemes', {
                'name': nameCtrl.text.trim(),
                'description': descCtrl.text.trim(),
                if (benefitsCtrl.text.trim().isNotEmpty)
                  'benefits': benefitsCtrl.text.trim(),
              });
              if (ctx.mounted) Navigator.of(ctx).pop(true);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
    nameCtrl.dispose();
    descCtrl.dispose();
    benefitsCtrl.dispose();
    if (created == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navyBlue,
      appBar: AppBar(
        title: const Text('Scheme Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Scheme',
            onPressed: _addSchemeDialog,
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.adminAccent))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _schemes.length,
              itemBuilder: (_, i) {
                final s = _schemes[i] as Map<String, dynamic>;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.navyBlueMid,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s['name'] as String? ?? '',
                          style: const TextStyle(
                              color: AppColors.teal,
                              fontWeight: FontWeight.w700,
                              fontSize: 15)),
                      const SizedBox(height: 4),
                      Text(s['description'] as String? ?? '',
                          style: const TextStyle(
                              color: AppColors.white, fontSize: 13)),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// 4. Admin Reports & Analytics
// ---------------------------------------------------------------------------
class _AdminAnalyticsScreen extends StatelessWidget {
  final int totalUsers;
  final Map<String, dynamic> complaints;
  const _AdminAnalyticsScreen({
    required this.totalUsers,
    required this.complaints,
  });

  @override
  Widget build(BuildContext context) {
    final total = (complaints['total'] as int?) ?? 0;
    final resolved = (complaints['resolved'] as int?) ?? 0;
    final rate = total == 0 ? 0 : ((resolved / total) * 100).round();

    return Scaffold(
      backgroundColor: AppColors.navyBlue,
      appBar: AppBar(title: const Text('Reports & Analytics')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _MetricRow('Registered Users', '$totalUsers', AppColors.adminAccent),
          _MetricRow('Total Complaints', '$total', AppColors.citizenAccent),
          _MetricRow('Pending Complaints', '${complaints['pending'] ?? 0}',
              AppColors.warning),
          _MetricRow('In Progress', '${complaints['in_progress'] ?? 0}',
              AppColors.teal),
          _MetricRow('Resolved', '$resolved', AppColors.success),
          _MetricRow('Resolution Rate', '$rate%', AppColors.success),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MetricRow(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.navyBlueMid,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: AppColors.white, fontSize: 15)),
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 20, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 5. Admin Audit Logs
// ---------------------------------------------------------------------------
class _AdminAuditLogsScreen extends StatefulWidget {
  const _AdminAuditLogsScreen();

  @override
  State<_AdminAuditLogsScreen> createState() => _AdminAuditLogsScreenState();
}

class _AdminAuditLogsScreenState extends State<_AdminAuditLogsScreen> {
  List<dynamic> _logs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient.instance.get('/admin/audit-logs');
      setState(() => _logs = (res['logs'] as List<dynamic>?) ?? []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navyBlue,
      appBar: AppBar(title: const Text('Administrative Audit Logs')),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.adminAccent))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _logs.length,
              itemBuilder: (_, i) {
                final l = _logs[i] as Map<String, dynamic>;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.navyBlueMid,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${l['action']} (User #${l['user_id'] ?? 'N/A'})',
                        style: const TextStyle(
                            color: AppColors.teal,
                            fontWeight: FontWeight.w700,
                            fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${l['created_at']} • ${l['details'] ?? ''}',
                        style: const TextStyle(
                            color: AppColors.grey, fontSize: 11),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Dashboard Sub-widgets
// ---------------------------------------------------------------------------
class _AdminHeader extends StatelessWidget {
  final String name;
  const _AdminHeader({required this.name});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.adminAccent.withValues(alpha: 0.3),
            AppColors.navyBlueMid
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: AppColors.adminAccent.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.adminAccent.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.admin_panel_settings,
                color: AppColors.adminAccent, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Administrator',
                    style: TextStyle(color: AppColors.grey, fontSize: 12)),
                Text(name,
                    style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _AdminStatCard(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.navyBlueMid,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 22),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800)),
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.grey, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdminMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  const _AdminMenuItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.navyBlueMid,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style:
                          const TextStyle(color: AppColors.grey, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.grey),
          ],
        ),
      ),
    );
  }
}
