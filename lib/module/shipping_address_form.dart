import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class ShippingAddressForm extends StatefulWidget {
  final Function(Map<String, dynamic>?) onAddressSelected;
  const ShippingAddressForm({super.key, required this.onAddressSelected});

  @override
  ShippingAddressFormState createState() => ShippingAddressFormState();
}

class ShippingAddressFormState extends State<ShippingAddressForm> {
  ShippingAddressFormState get state => this;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _noHpController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _provinceController = TextEditingController();
  final _postalCodeController = TextEditingController();

  Map<String, dynamic>? _existingAddress;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchExistingAddress(); // Fetch existing address on init
  }

  Future<void> _fetchExistingAddress() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final userId = FirebaseAuth.instance.currentUser!.uid;
      final querySnapshot = await firestore
          .collection('users')
          .doc(userId)
          .collection('shippingAddresses')
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        setState(() {
          final doc = querySnapshot.docs.first;
          _existingAddress = doc.data() as Map<String, dynamic>?;
          _existingAddress?['id'] = doc.id;
          _existingAddress = querySnapshot.docs.first.data();
          _streetController.text = _existingAddress?['street'] ?? '';
          _cityController.text = _existingAddress?['city'] ?? '';
          _provinceController.text = _existingAddress?['province'] ?? '';
          _postalCodeController.text = _existingAddress?['postalCode'] ?? '';
        });
      }
    } catch (e) {
      print('Error fetching existing address: $e');
    } finally {
      setState(() {
        _isLoading = false; // Done loading, even if there's an error
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Center(
      child: Column(
        children: [
          if (_existingAddress != null)
            Column(
              children: [
                Text(
                  _existingAddress!['street'],
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w400),
                ),
                // ... (display other address fields)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _existingAddress = null;
                      _nameController.clear();
                      _noHpController.clear();
                      _streetController.clear();
                      _cityController.clear();
                      _provinceController.clear();
                      _postalCodeController.clear();
                    });
                  },
                  child: Text(
                    'Ubah Alamat',
                    style: GoogleFonts.poppins(
                        color: Colors.blueAccent,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.blueAccent,
                        decorationThickness: 2.0),
                  ),
                ),
              ],
            ),
          if (_existingAddress == null)
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration:
                        const InputDecoration(labelText: 'Nama Penerima'),
                    keyboardType: TextInputType.name,
                    textInputAction: TextInputAction.next,
                    validator: (value) =>
                        value!.isEmpty ? 'Nama tidak boleh kosong' : null,
                  ),
                  TextFormField(
                    controller: _noHpController,
                    decoration:
                        const InputDecoration(labelText: 'Nomor Telepon'),
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Nomor telepon tidak boleh kosong';
                      }
                      if (value.length < 10) {
                        return 'Nomor telepon harus terdiri dari 10 angka';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _streetController,
                    decoration: const InputDecoration(labelText: 'Jalan'),
                    textInputAction: TextInputAction.next,
                    validator: (value) =>
                        value!.isEmpty ? 'Jalan harus diisi' : null,
                  ),
                  TextFormField(
                    controller: _cityController,
                    decoration: const InputDecoration(labelText: 'Kota'),
                    textInputAction: TextInputAction.next,
                    validator: (value) =>
                        value!.isEmpty ? 'Kota harus diisi' : null,
                  ),
                  TextFormField(
                    controller: _provinceController,
                    decoration: const InputDecoration(labelText: 'Provinsi'),
                    textInputAction: TextInputAction.next,
                    validator: (value) =>
                        value!.isEmpty ? 'Provinsi harus diisi' : null,
                  ),
                  TextFormField(
                    controller: _postalCodeController,
                    decoration: const InputDecoration(labelText: 'Kode Pos'),
                    textInputAction: TextInputAction.done,
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Kode pos harus diisi';
                      }
                      if (value.length < 5) {
                        // Contoh minimal 5 digit
                        return 'Kode pos harus minimal 5 angka';
                      }
                      return null;
                    },
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        await _submitAddress(); // Tunggu hingga proses penyimpanan selesai

                        if (state.mounted) {
                          ScaffoldMessenger.of(state.context).showSnackBar(
                            const SnackBar(
                                content: Text('Alamat berhasil disimpan')),
                          );
                          widget.onAddressSelected(_existingAddress);
                          // ignore: use_build_context_synchronously
                          Navigator.of(context).pop();
                        }
                      }
                    },
                    child: const Text('Simpan Alamat'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _submitAddress() async {
    if (_formKey.currentState!.validate()) {
      try {
        final firestore = FirebaseFirestore.instance;
        final userId = FirebaseAuth.instance.currentUser!.uid;
        final addressData = {
          'street': _streetController.text,
          'city': _cityController.text,
          'province': _provinceController.text,
          'postalCode': _postalCodeController.text,
        };

        // Determine whether to add a new address or update existing
        if (_existingAddress == null) {
          // Add new address to a subcollection for better organization
          await firestore
              .collection('users')
              .doc(userId)
              .collection('shippingAddresses')
              .add(addressData);
        } else {
          // Update the existing address document
          await firestore
              .collection('users')
              .doc(userId)
              .collection('shippingAddresses')
              .doc(
                  _existingAddress!['id']) // Assuming you store the document ID
              .update(addressData);
        }
        // Notify parent widget of the selected address
        widget.onAddressSelected(addressData); // Use addressData here

        if (state.mounted) {
          ScaffoldMessenger.of(state.context).showSnackBar(
            const SnackBar(content: Text('Alamat berhasil disimpan')),
          );
        }
      } catch (e) {
        print('Error saving address: $e');
      }
    }
  }
}
