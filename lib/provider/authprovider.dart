import 'package:flutter/material.dart';
import 'package:ride_on_driver/model/login_model.dart';
import 'package:ride_on_driver/model/signup_model.dart';
import 'package:ride_on_driver/screens/authentication_screens/login_screen.dart';
import 'package:ride_on_driver/services/authentication_services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ride_on_driver/screens/home_screen.dart';

import '../screens/authentication_screens/mail_sent_screen.dart';
import '../screens/authentication_screens/otp_screen.dart';
import '../screens/onboarding_screens/complete_profiles_screen.dart';
import '../services/driver_services.dart';
import '../services/socket_service.dart';

class AuthProvider with ChangeNotifier {
  bool _signInLoading = false;
  bool get signInLoading => _signInLoading;
  bool _signUpLoading = false;
  bool get signUpLoading => _signUpLoading;
  DriverModel? _driver;
  DriverModel? get driver => _driver;
  SignUpResponse? _driverSignUp;
  SignUpResponse? get driverSignUp => _driverSignUp;
  String? _driverName;
  String? get driverName => _driverName;
  String? _driverEmail;
  String? get driverEmail => _driverEmail;
  String? _driverLastName;
  String? get driverLastName => _driverLastName;
  // String? _driverImage;
  // String? get driverImage => _driverImage;
  String? _error;
  String? get error => _error;
  String? _token;
  String? get token => _token;
  String? _id;
  String? get id => _id;
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  int? _walletBalance;
  int? get walletBalance => _walletBalance;

  final AuthService _authService = AuthService();
  final SocketService _socketService = SocketService();
  final DriverService _driverService = DriverService();
  setError(String message) {
    _error = message;
    notifyListeners();
  }

  setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  //load the token and user name from the storage
  AuthProvider(String? driverName, String? driverLastName, String? driverEmail,
      String? token, int? walletBalance, String? id) {
    _driverName = driverName;
    _driverLastName = driverLastName;
    _driverEmail = driverEmail;
    _token = token;
    _walletBalance = walletBalance;
    _id = id;
  }

  //save the driver information data
  saveDriverData(String driverName, String driverLastName, String driverEmail,
      String token, int walletBalance, String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('driver_name', driverName);
    await prefs.setString('driver_lastname', driverLastName);
    await prefs.setString('driver_email', driverEmail);
    await prefs.setString('auth_token', token);
    await prefs.setInt('wallet_balance', walletBalance);
    await prefs.setString('id', id);
    notifyListeners();
  }

  ///login function
  signIn(BuildContext context, String email, String password) async {
    try {
      print('signing method in provider service');
      _signInLoading = true;
      final responseData = await _authService.signIn(email, password);

      final loginResponse = DriverModel.fromJson(responseData);
      print(responseData);
      if (loginResponse.message == 'success') {
        print('data gotten');
        _driverName = loginResponse.data!.driver!.firstName;
        print(' driver name $_driverName');
        _driverEmail = loginResponse.data!.driver!.email;
        print(_driverEmail);
        _driverLastName = loginResponse.data!.driver!.lastName;
        print(_driverLastName);
        _walletBalance = loginResponse.data!.driver!.walletBalance;
        print('driver wallet balance $_walletBalance');
        _token = loginResponse.data!.token;
        print(_token);
        _id = loginResponse.data!.driver!.id;
        print('driver id $_id');
        // _driverImage = loginResponse.data.userDetails.image;
        // print('driver id $_driverImage');
        /// Initialize the socket with the user token
        _socketService.initSocket(_token!, _id!);

        await saveDriverData(_driverName!, _driverLastName!, _driverEmail!,
            _token!, _walletBalance!, _id!);
        notifyListeners();
        _signInLoading = false;
        //navigate to home page
        if (_driverName != null &&
            _driverLastName != null &&
            _driverEmail != null &&
            _token != null &&
            _walletBalance != null &&
            _id != null) {
          Future.delayed(Duration.zero, () {
            /// Authenticate the socket connection
            _socketService.authenticate();

            /// Start location updates when user logs in
            // _driverService.startLocationUpdates(id!);

            ///start driver status
            // _socketService.driverOnlineStatus(id: _id!, availability: true);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          });
        }
      } else {
        _signInLoading = false;
        notifyListeners();
        print('error');
        setError(responseData['message']);
      }
    } catch (e) {
      _signInLoading = false;
      print('printing the eroor in provide login $e');
      notifyListeners();
    }
  }

  ///SignUp
  signUp(BuildContext context, String firstName, String lastName, String phone,
      String email, String password, String gender, String role) async {
    try {
      print('signing method in provider service');
      _signUpLoading = true;
      final responseData = await _authService.signUp(
          firstName, lastName, phone, email, password, gender, role);
      print('res from signup in provider classa $responseData');
      if (responseData['message'] == 'success') {
        _driverEmail = responseData['data']['newUser']['email'];
        print('this is the driver email on signup $_driverEmail');

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const OTPScreen()),
        );

        _signUpLoading = false;
        notifyListeners();
      } else {
        _signUpLoading = false;
        print('error from sign up ${responseData['message']}');
        setError(responseData['message']);
        notifyListeners();
      }
      _signUpLoading = false;
      notifyListeners();
    } catch (e) {
      _signUpLoading = false;
      print('printing the eroor in provide login $e');
      notifyListeners();
    }
  }

  ///sending of otp
  sendOtp(BuildContext context, int otp) async {
    _signUpLoading = true;
    final responseData = await _authService.sendOtp(otp);
    try {
      if (responseData['message'] == 'success') {
        _signUpLoading = false;
        notifyListeners();
        // navigate to otp page
        Future.delayed(Duration.zero, () {
          // Navigator.pushReplacement(
          //   context,
          //   MaterialPageRoute(builder: (context) => const LoginScreen()),
          // );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const CompleteProfileScreen()),
          );
        });
      } else {
        _signUpLoading = false;
        notifyListeners();
        setError(responseData['message']);
      }
    } catch (e) {
      _signUpLoading = false;
      print('printing the eroor in provide login $e');
      notifyListeners();
    }
  }

  ///resend of otp
  Future<void> getOtp(
    BuildContext context,
    String email,
  ) async {
    try {
      final otpResponseData = await _authService.getOtp(email);
      print('res from resend otp in provider $otpResponseData');
      if (otpResponseData['message'] == 'success') {
        print('res from resend work n resend occured');
        // Navigate to another screen
        Future.delayed(Duration.zero, () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const OTPScreen()),
          );
        });
      } else {
        setError(otpResponseData['message']);
      }
    } catch (error) {
      setError('An error occurred. Please try again later.');
    }
  }

  ///forgot password
  forgotPassword(BuildContext context, String email) async {
    try {
      final responseData = await _authService.forgetPassword(email);

      if (responseData['message'] == 'success') {
        // navigate to mail screen page
        Future.delayed(Duration.zero, () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MailSentScreen()),
          );
        });
      } else {
        setError(responseData['message']);
      }
    } catch (error) {
      setError('An error occurred. Please try again later.');
    }
  }

  ///reset password
  resetPassword(BuildContext context, String otp, String newPassword) async {
    try {
      final responseData = await _authService.resetPassword(otp, newPassword);
      if (responseData['message'] == 'success') {
        // navigate to login page
        Future.delayed(Duration.zero, () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        });
      } else {
        setError(responseData['message']);
      }
    } catch (error) {
      setError('An error occurred. Please try again later.');
    }
  }

  ///logout
  logout(BuildContext context) async {
    // Disconnect the socket
    _socketService.disconnectSocket();

    // Stop location updates when user logs out
    _driverService.stopLocationUpdates();

    final SharedPreferences sharedPreferences =
        await SharedPreferences.getInstance();
    await sharedPreferences.clear();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );

    notifyListeners();
  }
}
