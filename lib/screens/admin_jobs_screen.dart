import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class JobsTab extends StatefulWidget {
  const JobsTab({super.key});

  @override
  State<JobsTab> createState() => _JobsTabState();
}

class _JobsTabState extends State<JobsTab> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5FA),
        appBar: AppBar(
          title: const Text('Jobs', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF006B5E),
          automaticallyImplyLeading: false,
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Color(0xFFFFC107),
            tabs: [
              Tab(text: 'Completed'),
              Tab(text: 'Ongoing'),
            ],
          ),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('jobs')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(child: Text('Error loading jobs'));
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final allDocs = snapshot.data?.docs ?? [];
            final completedJobs = allDocs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return data['status'] == 'completed';
            }).toList();
            final ongoingJobs = allDocs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return data['status'] == 'accepted' || data['status'] == 'pending';
            }).toList();

            return TabBarView(
              children: [
                _buildJobsList(context, completedJobs),
                _buildJobsList(context, ongoingJobs),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildJobsList(BuildContext context, List<QueryDocumentSnapshot> docs) {
    if (docs.isEmpty) {
      return const Center(child: Text('No jobs found.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final job = docs[index].data() as Map<String, dynamic>;
        final isCompleted = job['status'] == 'completed';
        final title = job['descriptionEn']?.toString() ?? job['descriptionUr']?.toString() ?? 'Service';
        final worker = job['workerName']?.toString() ?? 'Unknown';
        final customer = job['customerName']?.toString() ?? 'Unknown';
        final price = (job['price'] as num?)?.toDouble() ?? 0;
        final status = job['status']?.toString() ?? '';
        final timestamp = job['createdAt'] as Timestamp?;
        final date = timestamp != null
            ? '${timestamp.toDate().day} ${_monthName(timestamp.toDate().month)} ${timestamp.toDate().year}'
            : 'N/A';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isCompleted ? Colors.green.shade100 : Colors.orange.shade100,
              child: Icon(isCompleted ? Icons.check_circle : Icons.handyman, color: isCompleted ? Colors.green : Colors.orange),
            ),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Worker: $worker • Customer: $customer\nDate: $date'),
            isThreeLine: true,
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Rs. ${price.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text(_statusLabel(status), style: TextStyle(
                  color: isCompleted ? Colors.green : Colors.orange,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                )),
              ],
            ),
            onTap: () => _showJobDetails(context, job, price),
          ),
        );
      },
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'completed': return 'Completed';
      case 'accepted': return 'Ongoing';
      case 'pending': return 'Pending';
      case 'rejected': return 'Rejected';
      default: return status;
    }
  }

  String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  void _showJobDetails(BuildContext context, Map<String, dynamic> job, double price) {
    final penaltyController = TextEditingController();
    final title = job['descriptionEn']?.toString() ?? job['descriptionUr']?.toString() ?? 'Service';
    final worker = job['workerName']?.toString() ?? 'Unknown';
    final customer = job['customerName']?.toString() ?? 'Unknown';
    final status = job['status']?.toString() ?? '';
    final isCompleted = status == 'completed';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Job Details: $title', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text('Worker: $worker', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 4),
            Text('Customer: $customer', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 4),
            Text('Status: ${_statusLabel(status)}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 4),
            Text('Amount: Rs. ${price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 16)),
            const Divider(height: 32),
            if (isCompleted) ...[
              const Text('Add Penalty (Optional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => penaltyController.text = (price * 0.05).toStringAsFixed(0),
                      child: const Text('5%'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => penaltyController.text = (price * 0.10).toStringAsFixed(0),
                      child: const Text('10%'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: penaltyController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Custom Penalty Amount (PKR)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Penalty of Rs. ${penaltyController.text} applied to $worker')));
                  },
                  child: const Text('Apply Penalty'),
                ),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                  },
                  child: const Text('Close'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

