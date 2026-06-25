class WorkerSignupData {
  final String name;
  final String email;
  final String password;
  final String phone;
  final String idFrontUrl;
  final String idBackUrl;
  final String policeCertUrl;
  final String? certificationUrl;

  WorkerSignupData({
    required this.name,
    required this.email,
    required this.password,
    required this.phone,
    required this.idFrontUrl,
    required this.idBackUrl,
    required this.policeCertUrl,
    this.certificationUrl,
  });
}

class ServicesSetupArguments {
  final int categoryIndex;
  final WorkerSignupData? signupData;

  ServicesSetupArguments({required this.categoryIndex, this.signupData});
}
