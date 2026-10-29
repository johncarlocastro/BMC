import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'seed_products.dart';

class AdminMain extends StatefulWidget {
  const AdminMain({super.key});

  @override
  State<AdminMain> createState() => _AdminMainState();
}

class _AdminMainState extends State<AdminMain> {
  bool _uploading = false;

  void _openOrders() {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const AdminOrdersPage()));
  }

  Future<void> _uploadProducts() async {
    if (_uploading) return;

    setState(() => _uploading = true);

    try {
      if (FirebaseAuth.instance.currentUser == null) {
        throw Exception('Mag-login muna sa admin account bago mag-upload.');
      }

      await SeedProducts.uploadProducts();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Matagumpay na na-upload ang 10 products!'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Hindi na-upload: $e')));
    } finally {
      if (mounted) {
        setState(() => _uploading = false);
      }
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    const orange = Color(0xFFE86B35);

    return Scaffold(
      appBar: AppBar(
        title: const Text('D.C FOODHUB Admin'),
        backgroundColor: orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: _signOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.cloud_upload_outlined,
                      color: orange,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _openOrders,
                        icon: const Icon(Icons.receipt_long_outlined),
                        label: const Text('View Live Orders'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Upload Food Products',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'I-upload ang 10 food products mula sa '
                      'seed_products.dart papunta sa Firestore '
                      'products collection.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _uploading ? null : _uploadProducts,
                        icon: _uploading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.upload),
                        label: Text(
                          _uploading
                              ? 'Uploading...'
                              : 'Upload Products to Firebase',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Siguraduhing naka-sign in ang tamang '
                      'admin account bago mag-upload.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AdminOrdersPage extends StatelessWidget {
  const AdminOrdersPage({super.key});

  String _peso(num amount) => '₱${amount.toStringAsFixed(2)}';

  String _dateText(dynamic value) {
    if (value is Timestamp) {
      return value.toDate().toLocal().toString().substring(0, 16);
    }
    return 'Saving...';
  }

  void _showOrderDetails(
    BuildContext context,
    String orderId,
    Map<String, dynamic> data,
  ) {
    final customer = data['customer'] is Map
        ? Map<String, dynamic>.from(data['customer'] as Map)
        : <String, dynamic>{};
    final rawItems = data['items'];
    final items = rawItems is List
        ? rawItems
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList()
        : <Map<String, dynamic>>[];
    final total = (data['totalAmount'] as num?) ?? 0;
    final paymentStatus = data['paymentStatus']?.toString() ?? 'PENDING';
    final orderStatus = data['orderStatus']?.toString() ?? 'RECEIVED';
    final paymentMethod =
        data['paymentChannel']?.toString() ??
        data['paymentMethod']?.toString() ??
        'Not available yet';

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Order Details'),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SelectableText('Order ID: $orderId'),
                const SizedBox(height: 6),
                Text('Date: ${_dateText(data['createdAt'])}'),
                Text('Order status: $orderStatus'),
                Text('Payment status: $paymentStatus'),
                Text('Payment method: $paymentMethod'),
                const Divider(height: 24),
                const Text(
                  'Customer',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('Name: ${customer['name'] ?? 'Not provided'}'),
                Text('Phone: ${customer['phone'] ?? 'Not provided'}'),
                Text('Address: ${customer['address'] ?? 'Not provided'}'),
                if (data['notes']?.toString().trim().isNotEmpty ?? false)
                  Text('Notes: ${data['notes']}'),
                const Divider(height: 24),
                const Text(
                  'Items',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...items.map((item) {
                  final name = item['name']?.toString() ?? 'Food item';
                  final quantity = (item['quantity'] as num?)?.toInt() ?? 0;
                  final price = (item['price'] as num?) ?? 0;
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '$name × $quantity — ${_peso(price * quantity)}',
                    ),
                  );
                }),
                const Divider(height: 24),
                Text(
                  'Total: ${_peso(total)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Orders'),
        backgroundColor: const Color(0xFFFFFBF5),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('orders').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Hindi ma-load ang orders. Tiyaking admin account '
                  'ang naka-sign in at may admin read permission ang rules.\n\n'
                  '${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFE86B35)),
            );
          }

          final orders = snapshot.data?.docs.toList() ?? [];
          orders.sort((a, b) {
            final aDate = a.data()['createdAt'] as Timestamp?;
            final bDate = b.data()['createdAt'] as Timestamp?;
            return (bDate?.millisecondsSinceEpoch ?? 0).compareTo(
              aDate?.millisecondsSinceEpoch ?? 0,
            );
          });

          if (orders.isEmpty) {
            return const Center(child: Text('No orders yet.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              final data = order.data();
              final customer = data['customer'] is Map
                  ? Map<String, dynamic>.from(data['customer'] as Map)
                  : <String, dynamic>{};
              final total = (data['totalAmount'] as num?) ?? 0;
              final paymentStatus =
                  data['paymentStatus']?.toString() ?? 'PENDING';
              final orderStatus = data['orderStatus']?.toString() ?? 'RECEIVED';
              final paymentMethod =
                  data['paymentChannel']?.toString() ??
                  data['paymentMethod']?.toString() ??
                  'Not available yet';

              return Card(
                color: Colors.white,
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectableText(
                        'Order ID: ${order.id}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text('Date: ${_dateText(data['createdAt'])}'),
                      Text(
                        'Customer: ${customer['name'] ?? 'Not provided'}'
                        ' • ${customer['phone'] ?? 'No phone'}',
                      ),
                      Text('Total: ${_peso(total)}'),
                      Text('Payment: $paymentMethod • $paymentStatus'),
                      Text('Order status: $orderStatus'),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () =>
                              _showOrderDetails(context, order.id, data),
                          icon: const Icon(Icons.visibility_outlined),
                          label: const Text('View Details'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
