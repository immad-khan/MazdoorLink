import 'package:flutter/material.dart';
import '../app_state.dart';

class WorkerSupportScreen extends StatefulWidget {
  const WorkerSupportScreen({super.key});

  @override
  State<WorkerSupportScreen> createState() => _WorkerSupportScreenState();
}

class _WorkerSupportScreenState extends State<WorkerSupportScreen> {
  final _complaintController = TextEditingController();
  final _amountController = TextEditingController();
  int? _selectedOrderIndex;

  final List<Map<String, dynamic>> _pastOrders = [
    {
      'title': 'Plumbing Repair',
      'date': '24 May 2025',
      'worker': 'Ali Khan',
      'status': 'Completed',
    },
    {
      'title': 'Electrical Wiring',
      'date': '12 May 2025',
      'worker': 'Usman Ahmed',
      'status': 'Completed',
    },
    {
      'title': 'AC Installation',
      'date': '01 Apr 2025',
      'worker': 'Raza',
      'status': 'Completed',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isUrdu = AppScope.of(context).isUrdu;

    if (_selectedOrderIndex != null) {
      return _buildComplaintForm(isUrdu);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(isUrdu ? 'کسٹمر سپورٹ' : 'Customer Support'),
        backgroundColor: Colors.white,
        scrolledUnderElevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              isUrdu ? 'آپ کو کس آرڈر میں مدد چاہیے؟' : 'Which order do you need help with?',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _pastOrders.length,
              itemBuilder: (context, index) {
                final order = _pastOrders[index];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedOrderIndex = index;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D9488).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.history, color: Color(0xFF0D9488)),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(order['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 4),
                              Text('${order['worker']} • ${order['date']}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComplaintForm(bool isUrdu) {
    final order = _pastOrders[_selectedOrderIndex!];
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(isUrdu ? 'شکایت درج کریں' : 'File a Complaint'),
        backgroundColor: Colors.white,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() {
              _selectedOrderIndex = null;
            });
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFF0D9488)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isUrdu ? '${order['title']} کے لئے شکایت درج کی جا رہی ہے' : 'Filing complaint for ${order['title']}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(isUrdu ? 'تفصیلات بتائیں' : 'Describe the issue', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            TextField(
              controller: _complaintController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: isUrdu ? 'مسئلہ تفصیل سے لکھیں...' : 'Write your complaint in detail...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0D9488))),
              ),
            ),
            const SizedBox(height: 20),
            Text(isUrdu ? 'تصاویر شامل کریں (اختیاری)' : 'Add Photos (Optional)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: const Icon(Icons.add_a_photo, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(isUrdu ? 'کیا کوئی نقصان ہوا؟ (اختیاری)' : 'Claim Amount? (Optional)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'PKR',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0D9488))),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/shared/chat');
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0D9488),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  isUrdu ? 'ایڈمن سے بات کریں' : 'Submit & Chat with Admin',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
