import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vidyut_vaani/core/services/api_client.dart';
import 'package:vidyut_vaani/core/theme/app_theme.dart';
import 'package:vidyut_vaani/features/auth/providers/auth_provider.dart';

class OperatorDashboardScreen extends ConsumerStatefulWidget {
  const OperatorDashboardScreen({super.key});

  @override
  ConsumerState<OperatorDashboardScreen> createState() =>
      _OperatorDashboardScreenState();
}

class _OperatorDashboardScreenState
    extends ConsumerState<OperatorDashboardScreen> {
  List<dynamic> _complaints = [];
  int _assignedCount = 0;
  bool _isLoading = true;
  String? _error;
  String _taskFilter = 'all';

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
      final dash = await ApiClient.instance.get('/operator/dashboard');
      final list = await ApiClient.instance.get('/operator/complaints');
      setState(() {
        _assignedCount = (dash['assigned_complaints'] as int?) ?? 0;
        _complaints = (list['complaints'] as List<dynamic>?) ?? [];
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showUpdateDialog(Map<String, dynamic> complaint) async {
    String selectedStatus = complaint['status'] as String? ?? 'in_progress';
    if (!['in_progress', 'resolved', 'closed'].contains(selectedStatus)) {
      selectedStatus = 'in_progress';
    }
    final notesCtrl = TextEditingController(
      text: complaint['resolution_notes'] as String? ?? '',
    );
    DateTime? estTime = complaint['estimated_restoration'] != null
        ? DateTime.tryParse(complaint['estimated_restoration'] as String)
        : null;

    final updated = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.navyBlueMid,
          title: Text(
            'Update ${complaint['complaint_number'] ?? 'Task'}',
            style: const TextStyle(color: AppColors.white, fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedStatus,
                dropdownColor: AppColors.navyBlueLight,
                style: const TextStyle(color: AppColors.white),
                decoration: const InputDecoration(labelText: 'Status'),
                items: const [
                  DropdownMenuItem(value: 'in_progress', child: Text('In Progress')),
                  DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
                  DropdownMenuItem(value: 'closed', child: Text('Closed')),
                ],
                onChanged: (v) {
                  if (v != null) setDialogState(() => selectedStatus = v);
                },
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                  side: const BorderSide(color: AppColors.teal),
                ),
                icon: const Icon(Icons.schedule, color: AppColors.teal, size: 18),
                label: Text(
                  estTime == null
                      ? 'Set Est. Restoration Time'
                      : 'ETA: ${estTime!.toLocal().toString().substring(0, 16)}',
                  style: const TextStyle(color: AppColors.teal, fontSize: 12),
                ),
                onPressed: () {
                  setDialogState(() {
                    estTime = DateTime.now().add(const Duration(hours: 2));
                  });
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesCtrl,
                maxLines: 3,
                style: const TextStyle(color: AppColors.white),
                decoration: const InputDecoration(
                  labelText: 'Resolution Notes',
                  hintText: 'Enter restoration details or notes...',
                ),
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
                try {
                  await ApiClient.instance.patch(
                    '/operator/complaints/${complaint['id']}/status',
                    {
                      'status': selectedStatus,
                      'resolution_notes': notesCtrl.text.trim(),
                      if (estTime != null)
                        'estimated_restoration': estTime!.toUtc().toIso8601String(),
                    },
                  );
                  if (ctx.mounted) Navigator.of(ctx).pop(true);
                } catch (e) {
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
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    notesCtrl.dispose();
    if (updated == true) {
      _fetchDashboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.navyBlue,
      appBar: AppBar(
        title: const Text('Field Operator Dashboard'),
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
        color: AppColors.operatorAccent,
        onRefresh: _fetchDashboard,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.operatorAccent),
              )
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppColors.error, size: 48),
                        const SizedBox(height: 12),
                        Text(_error!, style: const TextStyle(color: AppColors.grey)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchDashboard,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _buildBody(user),
      ),
    );
  }

  Widget _buildBody(dynamic user) {
    final pendingCount = _complaints
        .where((c) => c['status'] == 'assigned' || c['status'] == 'pending')
        .length;
    final inProgressCount =
        _complaints.where((c) => c['status'] == 'in_progress').length;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.operatorAccent.withOpacity(0.25),
                AppColors.navyBlueMid,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.operatorAccent.withOpacity(0.4)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.operatorAccent.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.engineering,
                    color: AppColors.operatorAccent, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Field Operator',
                        style: TextStyle(color: AppColors.grey, fontSize: 12)),
                    Text(
                      user?.fullName ?? 'Operator',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            _OpStatCard('Assigned', _assignedCount.toString(),
                AppColors.operatorAccent),
            const SizedBox(width: 12),
            _OpStatCard('Pending', pendingCount.toString(), AppColors.warning),
            const SizedBox(width: 12),
            _OpStatCard('In Progress', inProgressCount.toString(), AppColors.teal),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'Assigned Tasks & History',
          style: TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: [
            ('all', 'All'),
            ('assigned', 'Assigned'),
            ('in_progress', 'In Progress'),
            ('resolved', 'History'),
          ].map((entry) {
            final selected = _taskFilter == entry.$1;
            return ChoiceChip(
              label: Text(entry.$2),
              selected: selected,
              selectedColor: AppColors.operatorAccent,
              labelStyle: TextStyle(
                color: selected ? AppColors.navyBlue : AppColors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              onSelected: (_) => setState(() => _taskFilter = entry.$1),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        if (_complaints.where((c) {
          if (_taskFilter == 'all') return true;
          if (_taskFilter == 'resolved') {
            return c['status'] == 'resolved' || c['status'] == 'closed';
          }
          return c['status'] == _taskFilter;
        }).isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: Text(
                'No tasks in this category.',
                style: TextStyle(color: AppColors.grey),
              ),
            ),
          )
        else
          ..._complaints.where((c) {
            if (_taskFilter == 'all') return true;
            if (_taskFilter == 'resolved') {
              return c['status'] == 'resolved' || c['status'] == 'closed';
            }
            return c['status'] == _taskFilter;
          }).map((item) {
            final c = item as Map<String, dynamic>;
            final status = c['status'] as String? ?? 'assigned';
            final priority = c['priority'] as String? ?? 'medium';
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.navyBlueMid,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.navyBlueLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        c['complaint_number'] as String? ?? '',
                        style: const TextStyle(
                          color: AppColors.teal,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.operatorAccent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${priority.toUpperCase()} • ${status.replaceAll('_', ' ').toUpperCase()}',
                          style: const TextStyle(
                            color: AppColors.operatorAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    c['title'] as String? ?? '',
                    style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Locality: ${c['locality'] ?? 'N/A'}',
                    style: const TextStyle(color: AppColors.grey, fontSize: 12),
                  ),
                  if (c['estimated_restoration'] != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Est. Restoration: ${c['estimated_restoration']}',
                      style: const TextStyle(color: AppColors.teal, fontSize: 12),
                    ),
                  ],
                  if ((c['resolution_notes'] as String?)?.isNotEmpty ?? false) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Notes: ${c['resolution_notes']}',
                      style: const TextStyle(color: AppColors.grey, fontSize: 12),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.edit_note,
                          color: AppColors.teal, size: 18),
                      label: const Text('Update Status',
                          style: TextStyle(color: AppColors.teal)),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(148, 42),
                        side: const BorderSide(color: AppColors.teal),
                      ),
                      onPressed: () => _showUpdateDialog(c),
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}

class _OpStatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _OpStatCard(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.navyBlueMid,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(color: AppColors.grey, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
