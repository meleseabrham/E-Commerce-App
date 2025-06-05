import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> initializeFirebase() async {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyCUj3kbkCNI0p7oTe1zTuhfhhjU39OVHho",
        authDomain: "mehalgebeya-dcdfc.firebaseapp.com",
        projectId: "mehalgebeya-dcdfc",
        storageBucket: "mehalgebeya-dcdfc.firebasestorage.app",
        messagingSenderId: "326390551953",
        appId: "1:326390551953:web:b871300033631bc6ecb630",
        measurementId: "G-3T39KTSQT0"
      ),
    );
  }

  // Create or Update User Document
  static Future<void> createOrUpdateUserDocument(User user) async {
    final userDoc = _firestore.collection('users').doc(user.uid);
    final docSnapshot = await userDoc.get();

    if (!docSnapshot.exists) {
      // Create new user document
      await userDoc.set({
        'userId': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
        'photoURL': user.photoURL,
      });
    } else {
      // Update last login
      await userDoc.update({
        'lastLogin': FieldValue.serverTimestamp(),
        'email': user.email, // Update email in case it changed
        'displayName': user.displayName, // Update display name in case it changed
        'photoURL': user.photoURL, // Update photo URL in case it changed
      });
    }
  }

  // Email/Password Sign Up
  static Future<UserCredential?> signUpWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (userCredential.user != null) {
        await createOrUpdateUserDocument(userCredential.user!);
      }
      
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Email/Password Sign In
  static Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (userCredential.user != null) {
        await createOrUpdateUserDocument(userCredential.user!);
      }
      
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Google Sign In
  static Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      
      if (userCredential.user != null) {
        await createOrUpdateUserDocument(userCredential.user!);
      }
      
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Sign Out
  static Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // Password Reset
  static Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Get Current User
  static User? get currentUser => _auth.currentUser;

  // Get Current User Profile
  static Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    if (_auth.currentUser == null) return null;
    
    try {
      final doc = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .get();
      
      if (doc.exists) {
        return {
          'email': _auth.currentUser!.email,
          ...doc.data() ?? {},
        };
      } else {
        // Create default profile if it doesn't exist
        final defaultProfile = {
          'fullName': _auth.currentUser!.displayName ?? 'User',
          'email': _auth.currentUser!.email ?? '',
          'phone': '',
          'dateOfBirth': '',
        };
        await _firestore
            .collection('users')
            .doc(_auth.currentUser!.uid)
            .set(defaultProfile);
        return defaultProfile;
      }
    } catch (e) {
      throw 'Failed to get user profile: $e';
    }
  }

  // Update User Profile
  static Future<void> updateUserProfile(String userId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(userId).update(data);
      
      // If name is being updated, also update Auth display name
      if (data.containsKey('fullName')) {
        await _auth.currentUser?.updateDisplayName(data['fullName']);
      }
    } catch (e) {
      throw 'Failed to update profile: $e';
    }
  }

  // Change Password
  static Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      if (_auth.currentUser == null || _auth.currentUser!.email == null) {
        throw 'User not logged in';
      }

      // Verify current password by reauthenticating
      final credential = EmailAuthProvider.credential(
        email: _auth.currentUser!.email!,
        password: currentPassword,
      );

      await _auth.currentUser!.reauthenticateWithCredential(credential);
      
      // If reauthentication successful, update password
      await _auth.currentUser!.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'wrong-password':
          throw 'Current password is incorrect';
        case 'weak-password':
          throw 'New password is too weak';
        default:
          throw 'Failed to change password: ${e.message}';
      }
    } catch (e) {
      throw 'Failed to change password: $e';
    }
  }

  // Error Handler
  static String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'invalid-email':
        return 'The email address is badly formatted.';
      default:
        return 'An error occurred password are not correct. Please try again.';
    }
  }

  static Future<void> updateUserLastLogin(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'lastLogin': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> createOrder(Map<String, dynamic> order) async {
    try {
      if (_auth.currentUser == null) {
        throw 'User must be logged in to create an order';
      }

      final orderData = {
        ...order,
        'createdAt': FieldValue.serverTimestamp(),
        'userId': _auth.currentUser!.uid,
      };

      await _firestore.collection('orders').doc(order['id']).set(orderData);
    } catch (e) {
      throw 'Failed to create order: $e';
    }
  }

  static Stream<QuerySnapshot> getUserOrders() {
    if (_auth.currentUser == null) {
      throw 'User must be logged in to view orders';
    }

    return _firestore
        .collection('orders')
        .where('userId', isEqualTo: _auth.currentUser!.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  static Future<void> cancelOrder(String orderId) async {
    try {
      if (_auth.currentUser == null) {
        throw 'User must be logged in to cancel an order';
      }

      // First verify that this order belongs to the current user
      final orderDoc = await _firestore
          .collection('orders')
          .doc(orderId)
          .get();

      if (!orderDoc.exists) {
        throw 'Order not found';
      }

      final orderData = orderDoc.data() as Map<String, dynamic>;
      if (orderData['userId'] != _auth.currentUser!.uid) {
        throw 'Not authorized to cancel this order';
      }

      if (orderData['status'] == 'cancelled') {
        throw 'Order is already cancelled';
      }

      if (orderData['status'] != 'pending') {
        throw 'Only pending orders can be cancelled';
      }

      await _firestore.collection('orders').doc(orderId).update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
        'updatedBy': _auth.currentUser!.uid,
      });
    } catch (e) {
      if (e is FirebaseException && e.code == 'permission-denied') {
        throw 'You do not have permission to cancel this order';
      }
      throw 'Failed to cancel order: $e';
    }
  }

  static Stream<List<Product>> getProducts() {
    return _firestore.collection('products').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Product.fromMap({
        'id': doc.id,
        ...doc.data(),
      })).toList();
    });
  }

  static Future<void> deleteOrder(String orderId) async {
    try {
      if (_auth.currentUser == null) {
        throw 'User must be logged in to delete an order';
      }

      // First verify that this order belongs to the current user
      final orderDoc = await _firestore
          .collection('orders')
          .doc(orderId)
          .get();

      if (!orderDoc.exists) {
        throw 'Order not found';
      }

      final orderData = orderDoc.data() as Map<String, dynamic>;
      if (orderData['userId'] != _auth.currentUser!.uid) {
        throw 'Not authorized to delete this order';
      }

      await _firestore.collection('orders').doc(orderId).delete();
    } catch (e) {
      if (e is FirebaseException && e.code == 'permission-denied') {
        throw 'You do not have permission to delete this order';
      }
      throw 'Failed to delete order: $e';
    }
  }
} 