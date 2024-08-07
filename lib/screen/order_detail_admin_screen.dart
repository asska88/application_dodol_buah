import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:myapp/module/cart_provider.dart';
import 'package:myapp/module/order_notifer.dart';
import 'package:myapp/screen/order_confirmation_screen.dart';
import 'package:provider/provider.dart';

class OrderDetailAdminScreen extends StatelessWidget {
  final String orderId;

  const OrderDetailAdminScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    Provider.of<CartProvider>(context);
    final orderNotifier = Provider.of<OrderNotifier>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order detail admin'),
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text(
              'Lihat detail',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .doc(orderId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final orderData = snapshot.data!.data() as Map<String, dynamic>;
            final orderItems = orderData['orderItems'];
            final shippingAddress = orderData['shippingAddress'];
            double totalHarga = 0;
            for (var item in orderItems) {
              totalHarga += item['product']['price'] * item['quantity'];
            }
            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    // Agar bisa discroll jika konten panjang
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nomor Transaksi
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Nomor Pesanan', style: GoogleFonts.poppins()),
                            Text(orderData['userId'],
                                style: GoogleFonts.jetBrainsMono()),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Nama Pembeli
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Nama Pembeli', style: GoogleFonts.poppins()),
                            Text(shippingAddress['name'],
                                style: GoogleFonts.jetBrainsMono()),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Tanggal Beli
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('tanggal beli', style: GoogleFonts.poppins()),
                            Text(
                              DateFormat('dd/MM/yyyy').format(
                                  (orderData['orderDate'] as Timestamp)
                                      .toDate()),
                              style: GoogleFonts.jetBrainsMono(),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Detail Produk (dalam Card)
                        Card(
                          child: ListTile(
                            leading: Image.network(
                              orderItems[0]['product']['image'],
                              height: 50,
                              width: 50,
                              fit: BoxFit.contain,
                            ),
                            title: Text(
                              orderItems[0]['product']['name'],
                              style: GoogleFonts.poppins(),
                            ),
                            subtitle: Text(
                              '${orderItems[0]['quantity']}x Rp ${NumberFormat("#,##0", "id_ID").format(orderItems[0]['product']['price'])}',
                              style: GoogleFonts.jetBrainsMono(),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Alamat Pengiriman
                        Text('Jl. ${shippingAddress['street']}',
                            style: GoogleFonts.poppins()),
                        Text(
                          '${shippingAddress['city']}, ${shippingAddress['province']}, ${shippingAddress['postalCode']}',
                          style: GoogleFonts.jetBrainsMono(),
                        ),

                        const SizedBox(height: 32),

                        // Total Harga, Ongkir, dan Penjualan

                        // Tombol Kirim Pesanan
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('total harga ',
                              style: GoogleFonts.poppins(
                                  fontSize: 20, fontWeight: FontWeight.w400)),
                          Text(
                            NumberFormat.currency(
                              locale: 'id_ID',
                              symbol: 'Rp',
                              decimalDigits: 0,
                            ).format(totalHarga),
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.end,
                          ),
                        ],
                      ),
                       Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Metode Pembayaran',
                            style: GoogleFonts.poppins(
                                  fontSize: 20, fontWeight: FontWeight.w400),
                          ),
                          const Text('COD',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    orderNotifier
                        .orderSend(orderId); // Trigger the notification
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            OrderConfirmationScreen(orderId: orderId),
                      ),
                    );
                  },
                  child: const Text(
                    'Kirim pesanan',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
