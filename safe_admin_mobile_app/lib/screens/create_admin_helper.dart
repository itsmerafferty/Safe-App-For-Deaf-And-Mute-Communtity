import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// One-time setup script to create admin account
/// Run this once to set up your first admin
Future<void> createAdminAccount({
  required String email,
  required String password,
  required String name,
}) async {
  try {
    print('Creating admin account...');
    
    // 1. Create Firebase Auth user
    final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    
    final uid = credential.user!.uid;
    print('Auth user created with UID: $uid');
    
    // 2. Create admin document in Firestore
    await FirebaseFirestore.instance.collection('admins').doc(uid).set({
      'email': email,
      'name': name,
      'role': 'admin',
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    print('✅ Admin account created successfully!');
    print('Email: $email');
    print('UID: $uid');
    print('You can now login with this account.');
    
  } catch (e) {
    print('❌ Error creating admin account: $e');
  }
}

/// Example usage:
/// Call this function once to create your first admin
void main() async {
  // Initialize Firebase first in your app
  // Then call:
  await createAdminAccount(
    email: 'admin@gmail.com',
    password: 'your-secure-password',
    name: 'PDAO Administrator',
  );
}
