class WorkerSignupData {
  final String name;
  final String email;
  final String password;
  final String phone;
  final String? profilePicUrl;
  final String? cnicNumber;
  final String idFrontUrl;
  final String idBackUrl;
  final String? certificationUrl;
  final List<String>? certificates;

  WorkerSignupData({
    required this.name,
    required this.email,
    required this.password,
    required this.phone,
    this.profilePicUrl,
    this.cnicNumber,
    required this.idFrontUrl,
    required this.idBackUrl,
    this.certificationUrl,
    this.certificates,
  });
}

class ServicesSetupArguments {
  final int categoryIndex;
  final WorkerSignupData? signupData;

  ServicesSetupArguments({required this.categoryIndex, this.signupData});
}
