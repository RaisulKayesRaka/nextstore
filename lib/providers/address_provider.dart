import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/models/address_model.dart';

class AddressProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<AddressModel> _addresses = [];
  bool _isLoading = false;

  List<AddressModel> get addresses => _addresses;
  bool get isLoading => _isLoading;

  void setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  Future<void> fetchAddresses(String userId) async {
    setLoading(true);
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('addresses')
          .get();
      _addresses = snapshot.docs
          .map((doc) => AddressModel.fromMap(doc.data(), doc.id))
          .toList();
      _addresses.sort((a, b) => b.isDefault ? 1 : -1);
    } catch (e) {
      debugPrint("Error fetching addresses: $e");
    }
    setLoading(false);
  }

  Future<bool> addAddress(String userId, AddressModel address) async {
    try {
      if (address.isDefault) {
        await _removeOtherDefaults(userId);
      } else if (_addresses.isEmpty) {
        address = address.copyWith(isDefault: true);
      }

      final docRef = await _firestore
          .collection('users')
          .doc(userId)
          .collection('addresses')
          .add(address.toMap());
      final newAddress = AddressModel(
        id: docRef.id,
        name: address.name,
        phone: address.phone,
        details: address.details,
        isDefault: address.isDefault,
      );

      if (newAddress.isDefault) {
        _addresses.insert(0, newAddress);
      } else {
        _addresses.add(newAddress);
      }
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateAddress(String userId, AddressModel address) async {
    try {
      if (address.isDefault) {
        await _removeOtherDefaults(userId);
      }
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('addresses')
          .doc(address.id)
          .update(address.toMap());
      await fetchAddresses(userId);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteAddress(String userId, String addressId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('addresses')
          .doc(addressId)
          .delete();
      _addresses.removeWhere((a) => a.id == addressId);
      if (_addresses.isNotEmpty && !_addresses.any((a) => a.isDefault)) {
        await updateAddress(userId, _addresses.first.copyWith(isDefault: true));
      }
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> _removeOtherDefaults(String userId) async {
    final batch = _firestore.batch();
    for (var addr in _addresses) {
      if (addr.isDefault) {
        batch.update(
          _firestore
              .collection('users')
              .doc(userId)
              .collection('addresses')
              .doc(addr.id),
          {'isDefault': false},
        );
      }
    }
    await batch.commit();
  }
}
