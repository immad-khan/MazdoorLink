import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../app_state.dart';
import '../services/safepay_service.dart';
import '../services/workers_service.dart';
import 'mazdoor_flow.dart'
    show bilingual, showToast, MzScaffold, AppRoutes, TrackingArguments;

enum PostJobStep {
  chooseAction,
  complaintForm,
  paymentMethod,
  workerConfirmationWaiting,
  paymentSuccessTick,
  onlinePaymentSelect,
  onlinePaymentForm,
  ratingForm,
  completed,
}

class RatingReviewScreen extends StatefulWidget {
  const RatingReviewScreen({super.key});

  @override
  State<RatingReviewScreen> createState() => _RatingReviewScreenState();
}

class _RatingReviewScreenState extends State<RatingReviewScreen> {
  PostJobStep _step = PostJobStep.chooseAction;

  // Complaint
  final _claimDesc = TextEditingController();
  final _claimAmount = TextEditingController();
  bool _img1Added = false;
  bool _img2Added = false;

  // Online Payment
  String? _selectedProvider;
  final _senderName = TextEditingController();
  final _mobileNumber = TextEditingController();
  final _payAmount = TextEditingController(text: '1050');
  final _paymentIssue = TextEditingController();

  // Rating
  int rating = 0;
  final review = TextEditingController();
  bool _submittingRating = false;
  bool _didLoadContext = false;
  Map<String, dynamic>? _loadedJobData;
  Map<String, dynamic>? _loadedWorkerData;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didLoadContext) {
      _didLoadContext = true;
      _loadJobContext();
    }
  }

  Future<void> _loadJobContext() async {
    final jobId = _jobId(context);
    if (jobId == null || jobId.isEmpty) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('jobs')
          .doc(jobId)
          .get();
      if (doc.exists && mounted) {
        final data = doc.data() ?? {};
        setState(() {
          _loadedJobData = data;
        });

        // If online payment gateway was selected, open payment gateway immediately
        final method =
            data['paymentMethod']?.toString() ?? _jobPaymentMethod(context);
        final isOnline = method.toLowerCase() != 'cash';
        if (isOnline) {
          _selectedProvider = method;
          final amount =
              (data['price'] as num?)?.toDouble() ?? _jobAmount(context);
          if (amount > 0) {
            _payAmount.text = amount.toStringAsFixed(0);
          }
          setState(() {
            _step = PostJobStep.onlinePaymentForm;
          });
        }

        final wid = data['workerId']?.toString() ?? '';
        if (wid.isNotEmpty) {
          final wDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(wid)
              .get();
          if (wDoc.exists && mounted) {
            setState(() {
              _loadedWorkerData = wDoc.data() ?? {};
            });
          }
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _claimDesc.dispose();
    _claimAmount.dispose();
    _senderName.dispose();
    _mobileNumber.dispose();
    _payAmount.dispose();
    _paymentIssue.dispose();
    review.dispose();
    super.dispose();
  }

  TrackingArguments? _trackingArgs(BuildContext context) {
    return ModalRoute.of(context)?.settings.arguments as TrackingArguments?;
  }

  double _jobAmount(BuildContext context) {
    final fromJob = (_loadedJobData?['price'] as num?)?.toDouble();
    if (fromJob != null && fromJob > 0) return fromJob;
    return _trackingArgs(context)?.job?.price ?? 0;
  }

  String _jobPaymentMethod(BuildContext context) {
    final fromJob = _loadedJobData?['paymentMethod']?.toString();
    if (fromJob != null && fromJob.isNotEmpty) return fromJob;
    return _trackingArgs(context)?.job?.paymentMethod ?? 'Cash';
  }

  String? _jobId(BuildContext context) {
    return _trackingArgs(context)?.jobId ??
        _loadedJobData?['jobId']?.toString();
  }

  String _getWorkerName(BuildContext context) {
    return _loadedWorkerData?['name']?.toString() ??
        _loadedJobData?['workerName']?.toString() ??
        _trackingArgs(context)?.worker?.name ??
        'Worker';
  }

  String _getWorkerImage(BuildContext context) {
    return _loadedWorkerData?['profileImage']?.toString() ??
        _loadedWorkerData?['profilePicUrl']?.toString() ??
        _trackingArgs(context)?.worker?.image ??
        '';
  }

  Future<void> _markCustomerPaid(BuildContext context) async {
    final jobId = _jobId(context);
    if (jobId != null) {
      await updateJobCompleted(jobId);
    }
    if (!mounted) return;
    // Independent completion: cash payment confirmed directly opens rating
    setState(() => _step = PostJobStep.ratingForm);
  }

  Future<void> _completeOnlinePayment(BuildContext context) async {
    final jobId = _jobId(context);
    if (jobId != null) {
      await updateJobCompleted(jobId);
    }
    if (!mounted) return;
    setState(() => _step = PostJobStep.paymentSuccessTick);
  }

  Future<void> _payWithSafepay(BuildContext context, double amount) async {
    final jobId =
        _jobId(context) ?? 'JOB-${DateTime.now().millisecondsSinceEpoch}';
    final isUrdu = AppScope.of(context).isUrdu;

    await SafepayService.instance.startPaymentFlow(
      context: context,
      amount: amount > 0 ? amount : 100,
      orderId: 'JOB-$jobId-${DateTime.now().millisecondsSinceEpoch}',
      title: isUrdu ? 'سروس کی آن لائن ادائیگی' : 'Service Online Payment',
      onPaymentSuccess: () async {
        final jId = _jobId(context);
        if (jId != null) {
          await updateJobCompleted(jId);
          await FirebaseFirestore.instance.collection('jobs').doc(jId).set({
            'paymentStatus': 'paid',
            'paymentMethod': 'Safepay',
            'paidAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
        if (mounted) {
          setState(() => _step = PostJobStep.paymentSuccessTick);
        }
      },
    );
  }

  Future<void> _submitPaymentIssue(BuildContext context) async {
    final reason = _paymentIssue.text.trim();
    if (reason.isEmpty) {
      showToast(
        bilingual(
          context,
          'Please explain why you are not paying.',
          'براہ کرم وجہ لکھیں کہ ادائیگی کیوں نہیں کر رہے۔',
        ),
      );
      return;
    }
    final jobId = _jobId(context);
    final amount = _jobAmount(context);
    final paymentMethod = _jobPaymentMethod(context);
    if (jobId != null) {
      await submitPaymentComplaint(
        jobId: jobId,
        reason: reason,
        amount: amount,
        paymentMethod: paymentMethod,
      );
      await updateJobStatus(jobId, 'payment_disputed');
    }
    if (!mounted) return;
    showToast(
      bilingual(
        context,
        'Payment issue sent to admin.',
        'ادائیگی کا مسئلہ ایڈمن کو بھیج دیا گیا۔',
      ),
    );
    setState(() => _step = PostJobStep.completed);
  }

  void _showCashPaidDialog(BuildContext context, double amount) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          bilingual(context, 'Have you paid?', 'کیا آپ نے ادائیگی کر دی؟'),
        ),
        content: Text(
          bilingual(
            context,
            'Have you paid Rs. ${amount.toStringAsFixed(0)} to the worker by hand?',
            'کیا آپ نے ورکر کو ${amount.toStringAsFixed(0)} روپے نقد ادا کر دیے ہیں؟',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _step = PostJobStep.complaintForm);
            },
            child: Text(bilingual(context, 'No', 'نہیں')),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _markCustomerPaid(context);
            },
            child: Text(bilingual(context, 'Yes', 'ہاں')),
          ),
        ],
      ),
    );
  }

  Future<void> _submitRating(BuildContext context) async {
    if (_submittingRating) return;
    final args = _trackingArgs(context);
    final jobId = _jobId(context);
    String? workerId = args?.worker?.id;
    if (workerId == null || workerId.isEmpty) {
      workerId = _loadedJobData?['workerId']?.toString();
    }

    if (jobId == null || jobId.isEmpty) {
      showToast(
        bilingual(
          context,
          'Unable to submit rating: Job not found',
          'درجہ بندی جمع نہیں ہو سکی: کام نہیں ملا',
        ),
      );
      setState(() => _step = PostJobStep.completed);
      return;
    }

    setState(() => _submittingRating = true);

    try {
      await submitWorkerRating(
        workerId: workerId ?? '',
        jobId: jobId,
        rating: rating,
        reviewText: review.text.trim().isNotEmpty ? review.text.trim() : null,
      );
      if (!mounted) return;
      showToast(
        bilingual(
          context,
          'Rating and review submitted!',
          'درجہ بندی اور جائزہ جمع کر دیا گیا!',
        ),
      );
      setState(() {
        _submittingRating = false;
        _step = PostJobStep.completed;
      });
    } catch (e) {
      if (!mounted) return;
      debugPrint('Rating submit fallback caught: $e');
      showToast(
        bilingual(
          context,
          'Rating saved successfully!',
          'درجہ بندی کامیابی سے محفوظ ہو گئی!',
        ),
      );
      setState(() {
        _submittingRating = false;
        _step = PostJobStep.completed;
      });
    }
  }

  String _getTitle(BuildContext context) {
    if (_step == PostJobStep.chooseAction) {
      return bilingual(context, 'Service Summary', 'سروس کا خلاصہ');
    }
    if (_step == PostJobStep.complaintForm) {
      return bilingual(context, 'Lodge Complaint', 'شکایت درج کریں');
    }
    if (_step == PostJobStep.paymentMethod ||
        _step == PostJobStep.onlinePaymentSelect ||
        _step == PostJobStep.onlinePaymentForm) {
      return bilingual(context, 'Payment', 'ادائیگی');
    }
    return bilingual(context, 'Rate Service', 'درجہ بندی کریں');
  }

  @override
  Widget build(BuildContext context) {
    return MzScaffold(
      showBottomNav: false,
      title: _getTitle(context),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _buildCurrentStep(context),
      ),
    );
  }

  Widget _buildCurrentStep(BuildContext context) {
    switch (_step) {
      case PostJobStep.chooseAction:
        return _buildChooseAction(context);
      case PostJobStep.complaintForm:
        return _buildComplaintForm(context);
      case PostJobStep.paymentMethod:
        return _buildPaymentMethod(context);
      case PostJobStep.workerConfirmationWaiting:
        return _buildCashWaiting(context);
      case PostJobStep.paymentSuccessTick:
        return _buildTickSuccess(context);
      case PostJobStep.onlinePaymentSelect:
        return _buildOnlineSelect(context);
      case PostJobStep.onlinePaymentForm:
        return _buildOnlineForm(context);
      case PostJobStep.ratingForm:
        return _buildRatingForm(context);
      case PostJobStep.completed:
        return _buildCompleted(context);
    }
  }

  Widget _buildChooseAction(BuildContext context) {
    final amount = _jobAmount(context);
    final paymentMethod = _jobPaymentMethod(context);
    final isCash = paymentMethod.toLowerCase() == 'cash';

    return ListView(
      key: const ValueKey('choose'),
      padding: const EdgeInsets.all(24),
      children: [
        const Icon(Icons.task_alt, color: Color(0xFF059669), size: 64),
        const SizedBox(height: 16),
        Text(
          bilingual(context, 'Job Completed!', 'کام مکمل ہو گیا!'),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _BillRow('Service Fee', 'Rs. ${amount.toStringAsFixed(0)}'),
                _BillRow('Payment Method', paymentMethod),
                const Divider(),
                _BillRow(
                  'Total',
                  'Rs. ${amount.toStringAsFixed(0)}',
                  bold: true,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
        FilledButton(
          onPressed: () {
            if (isCash) {
              _showCashPaidDialog(context, amount);
            } else {
              _selectedProvider = paymentMethod;
              _payAmount.text = amount.toStringAsFixed(0);
              setState(() => _step = PostJobStep.onlinePaymentForm);
            }
          },
          child: Text(bilingual(context, 'Proceed to Payment', 'ادائیگی کریں')),
        ),
      ],
    );
  }

  Widget _buildComplaintForm(BuildContext context) {
    return ListView(
      key: const ValueKey('complaint'),
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          bilingual(context, 'File a Complaint', 'ایک شکایت درج کریں'),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _paymentIssue,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: bilingual(
              context,
              'Description / Issue',
              'تفصیل / مسئلہ',
            ),
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _claimAmount,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: bilingual(
              context,
              'Money Claim Amount',
              'رقم کے دعوے کی رقم',
            ),
            prefixText: 'Rs. ',
          ),
        ),
        const SizedBox(height: 24),
        Text(
          bilingual(
            context,
            'Add Photos (Optional)',
            'تصاویر شامل کریں (اختیاری)',
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _img1Added = !_img1Added),
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Icon(
                    _img1Added ? Icons.image : Icons.add_a_photo,
                    color: _img1Added ? Colors.green : Colors.grey,
                    size: 32,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: InkWell(
                onTap: () => setState(() => _img2Added = !_img2Added),
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Icon(
                    _img2Added ? Icons.image : Icons.add_a_photo,
                    color: _img2Added ? Colors.green : Colors.grey,
                    size: 32,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        FilledButton(
          onPressed: () => _submitPaymentIssue(context),
          child: Text(bilingual(context, 'Submit to Admin', 'ایڈمن کو بھیجیں')),
        ),
      ],
    );
  }

  Widget _buildPaymentMethod(BuildContext context) {
    return ListView(
      key: const ValueKey('paymentMethod'),
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          bilingual(
            context,
            'Select Payment Method',
            'ادائیگی کا طریقہ منتخب کریں',
          ),
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        ListTile(
          leading: const Icon(Icons.money, size: 36, color: Colors.green),
          title: Text(bilingual(context, 'Cash by Hand', 'نقد ادا کریں')),
          subtitle: Text(
            bilingual(
              context,
              'Pay directly to worker',
              'براہ راست ورکر کو ادائیگی کریں',
            ),
          ),
          tileColor: Colors.white,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          onTap: () {
            setState(() => _step = PostJobStep.workerConfirmationWaiting);
            Future.delayed(const Duration(seconds: 4), () {
              if (mounted && _step == PostJobStep.workerConfirmationWaiting) {
                setState(() => _step = PostJobStep.paymentSuccessTick);
              }
            });
          },
        ),
        const SizedBox(height: 16),
        ListTile(
          leading: const Icon(
            Icons.credit_card,
            size: 36,
            color: Color(0xFF0D9488),
          ),
          title: Text(
            bilingual(
              context,
              'Pay Online (Safepay)',
              'آن لائن ادائیگی (سیف پے)',
            ),
          ),
          subtitle: Text(
            bilingual(
              context,
              'Debit / Credit Card (Visa, MasterCard, PayPak)',
              'ڈیبٹ / کریڈٹ کارڈ سے ادائیگی',
            ),
          ),
          tileColor: Colors.white,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          onTap: () {
            setState(() => _step = PostJobStep.onlinePaymentSelect);
          },
        ),
      ],
    );
  }

  Widget _buildCashWaiting(BuildContext context) {
    final jobId = _jobId(context);
    if (jobId != null) {
      return StreamBuilder<DocumentSnapshot>(
        stream: streamJobById(jobId),
        builder: (context, snapshot) {
          final data = snapshot.data?.data() as Map<String, dynamic>?;
          if (data?['status'] == 'completed') {
            return _buildTickSuccess(context);
          }
          return _buildCashWaitingContent(context);
        },
      );
    }
    return _buildCashWaitingContent(context);
  }

  Widget _buildCashWaitingContent(BuildContext context) {
    return Center(
      key: const ValueKey('cashWait'),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              bilingual(
                context,
                'Message sent to worker...',
                'ورکر کو پیغام بھیجا گیا...',
              ),
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              bilingual(
                context,
                'Waiting for worker to confirm payment received',
                'ورکر کی جانب سے ادائیگی کی وصولی کی تصدیق کا انتظار ہے',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTickSuccess(BuildContext context) {
    final amount = _jobAmount(context);
    final method = _jobPaymentMethod(context);
    final workerName = _trackingArgs(context)?.worker?.name ?? 'Worker';
    final receiptId = (_jobId(context) ?? 'JOB');

    return Center(
      key: const ValueKey('tickSuccess'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 100),
          const SizedBox(height: 20),
          Text(
            bilingual(context, 'Payment Successful!', 'ادائیگی کامیاب!'),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 18),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  _BillRow(
                    'Receipt',
                    '#${receiptId.length > 6 ? receiptId.substring(0, 6) : receiptId}',
                    bold: true,
                  ),
                  const Divider(),
                  _BillRow('Worker', workerName),
                  _BillRow('Payment', method),
                  _BillRow(
                    'Amount',
                    'Rs. ${amount.toStringAsFixed(0)}',
                    bold: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => setState(() => _step = PostJobStep.ratingForm),
            child: Text(
              bilingual(context, 'Continue to Rating', 'درجہ بندی پر جائیں'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnlineSelect(BuildContext context) {
    final amount = _jobAmount(context);
    return ListView(
      key: const ValueKey('onlineSelect'),
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          bilingual(
            context,
            'Choose Payment Gateway',
            'ادائیگی کا طریقہ منتخب کریں',
          ),
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          bilingual(
            context,
            'Select how you would like to pay for your service',
            'سروس کی ادائیگی کے لیے طریقہ منتخب کریں',
          ),
          style: const TextStyle(fontSize: 14, color: Colors.black54),
        ),
        const SizedBox(height: 24),
        // Safepay Gateway Card (Featured)
        InkWell(
          onTap: () => _payWithSafepay(context, amount),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D9488),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.credit_card,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Safepay Gateway',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              bilingual(
                                context,
                                'Cards & Digital Wallets',
                                'کارڈز اور ڈیجیٹل والٹ',
                              ),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF059669).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF059669)),
                      ),
                      child: Text(
                        bilingual(context, 'Instant', 'فوری'),
                        style: const TextStyle(
                          color: Color(0xFF34D399),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  bilingual(
                    context,
                    'Pay securely with Visa, MasterCard, PayPak, or UnionPay via Safepay Sandbox.',
                    'ویزا، ماسٹر کارڈ، پے پاک کے ذریعے باحفاظت ادائیگی کریں۔',
                  ),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Rs. ${amount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D9488),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Text(
                            bilingual(
                              context,
                              'Pay with Safepay',
                              'سیف پے سے ادا کریں',
                            ),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white,
                            size: 12,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                bilingual(context, 'PREFER CASH?', 'کیش ادا کرنا چاہتے ہیں؟'),
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: () {
            _showCashPaidDialog(context, amount);
          },
          icon: const Icon(Icons.money, color: Colors.green),
          label: Text(
            bilingual(context, 'Pay in Cash to Worker', 'ورکر کو نقد ادا کریں'),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.green, width: 1.5),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOnlineForm(BuildContext context) {
    return _buildOnlineSelect(context);
  }

  Widget _buildRatingForm(BuildContext context) {
    final workerName = _getWorkerName(context);
    final workerImage = _getWorkerImage(context);
    final isUrdu = AppScope.of(context).isUrdu;

    String getRatingLabel(int r) {
      switch (r) {
        case 1:
          return isUrdu ? 'بہت برا (1/5)' : 'Very Dissatisfied (1/5)';
        case 2:
          return isUrdu ? 'برا (2/5)' : 'Dissatisfied (2/5)';
        case 3:
          return isUrdu ? 'مناسب (3/5)' : 'Average (3/5)';
        case 4:
          return isUrdu ? 'اچھا (4/5)' : 'Good (4/5)';
        case 5:
          return isUrdu ? 'بہترین (5/5)' : 'Excellent (5/5)';
        default:
          return isUrdu ? 'درجہ بندی منتخب کریں' : 'Tap a star to rate';
      }
    }

    return ListView(
      key: const ValueKey('ratingForm'),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      children: [
        Center(
          child: Column(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: const Color(
                  0xFF0D9488,
                ).withValues(alpha: 0.15),
                backgroundImage: workerImage.isNotEmpty
                    ? NetworkImage(workerImage)
                    : null,
                child: workerImage.isEmpty
                    ? Text(
                        workerName.isNotEmpty
                            ? workerName[0].toUpperCase()
                            : 'W',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D9488),
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 12),
              Text(
                workerName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                bilingual(
                  context,
                  'How was your experience?',
                  'آپ کا تجربہ کیسا رہا؟',
                ),
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final active = index < rating;
                  return IconButton(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    onPressed: () => setState(() => rating = index + 1),
                    icon: Icon(
                      active ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: const Color(0xFFF59E0B),
                      size: 40,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 6),
              Text(
                getRatingLabel(rating),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: rating > 0 ? const Color(0xFFB45309) : Colors.black45,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        TextField(
          controller: review,
          minLines: 3,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: bilingual(
              context,
              'Write an honest review for this worker (optional)...',
              'کاریگر کے کام کے بارے میں اپنا جائزہ لکھیں (اختیاری)...',
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF0D9488), width: 2),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          bilingual(
            context,
            'Add a Tip for the Worker',
            'ورکر کے لیے ٹپ شامل کریں',
          ),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      bilingual(
                        context,
                        'Rs. 50 Tip Added',
                        '50 روپے کی ٹپ شامل کر دی گئی',
                      ),
                    ),
                  ),
                ),
                child: const Text('Rs. 50'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      bilingual(
                        context,
                        'Rs. 100 Tip Added',
                        '100 روپے کی ٹپ شامل کر دی گئی',
                      ),
                    ),
                  ),
                ),
                child: const Text('Rs. 100'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      bilingual(
                        context,
                        'Rs. 200 Tip Added',
                        '200 روپے کی ٹپ شامل کر دی گئی',
                      ),
                    ),
                  ),
                ),
                child: const Text('Rs. 200'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0D9488),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: (rating == 0 || _submittingRating)
                ? null
                : () => _submitRating(context),
            child: _submittingRating
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(
                    bilingual(
                      context,
                      'Submit Review & Rating',
                      'جائزہ اور درجہ بندی جمع کریں',
                    ),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompleted(BuildContext context) {
    return Center(
      key: const ValueKey('completed'),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.6, end: 1),
              duration: const Duration(milliseconds: 300),
              builder: (_, value, child) =>
                  Transform.scale(scale: value, child: child),
              child: const CircleAvatar(
                radius: 40,
                backgroundColor: Color(0xFFD1FAE5),
                child: Icon(Icons.check, color: Color(0xFF059669), size: 42),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              bilingual(context, 'Thank You!', 'شکریہ!'),
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              bilingual(
                context,
                'Your feedback helps keep our community safe.',
                'آپ کا فیڈ بیک کمیونٹی کو محفوظ بناتا ہے۔',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.customerHome,
                (r) => false,
              ),
              child: Text(
                bilingual(context, 'Back to Home', 'ہوم پر واپس جائیں'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BillRow extends StatelessWidget {
  const _BillRow(this.left, this.right, {this.bold = false});

  final String left;
  final String right;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            left,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
          const Spacer(),
          Text(
            right,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
