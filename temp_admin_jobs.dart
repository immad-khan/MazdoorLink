import 'package:flutter/material.dart';

class JobsTab extends StatefulWidget {
  const JobsTab({super.key});

  @override
  State<JobsTab> createState() => _JobsTabState();
}

class _JobsTabState extends State<JobsTab> {
  final List<Map<String, dynamic>> _jobs = [
    {
      'title': 'Plumbing Repair',
      'worker': 'Ali Khan',
      'customer': 'Omer Farooq',
      'status': 'Completed',
      'date': '12 May 2025',
      'amount': '1500'
    },
    {
      'title': 'Electrical Wiring',
      'worker': 'Usman Ahmed',
      'customer': 'Raza',
      'status': 'On Going',
      'date': '14 May 2025',
      'amount': '4500'
    },
    {
      'title': 'AC Installation',
      'worker': 'Ahmed',
      'customer': 'Asad',
      'status': 'Completed',
      'date': '01 Apr 2025',
      'amount': '3500'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.all(20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final job = _jobs[index];
            final isCompleted = job['status'] == 'Completed';
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
                title: Text(job['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Worker: ${job['worker']} • Customer: ${job['customer']}\nDate: ${job['date']}'),
                isThreeLine: true,
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Rs. ${job['amount']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(job['status'], style: TextStyle(color: isCompleted ? Colors.green : Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
                onTap: isCompleted ? () => _showJobDetails(context, job) : null,
              ),
            );
          },
          childCount: _jobs.length,
        ),
      ),
    );
  }

  void _showJobDetails(BuildContext context, Map<String, dynamic> job) {
    final penaltyController = TextEditingController();

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
            Text('Job Details: ${job['title']}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text('Worker: ${job['worker']}'),
            Text('Customer: ${job['customer']}'),
            Text('Date: ${job['date']}'),
            Text('Amount: Rs. ${job['amount']}'),
            const Divider(height: 32),
            const Text('Add Penalty (Optional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => penaltyController.text = (int.parse(job['amount']) * 0.05).toStringAsFixed(0),
                    child: const Text('5%'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => penaltyController.text = (int.parse(job['amount']) * 0.10).toStringAsFixed(0),
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
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Penalty of Rs. ${penaltyController.text} applied to ${job['worker']}')));
                },
                child: const Text('Apply Penalty'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
