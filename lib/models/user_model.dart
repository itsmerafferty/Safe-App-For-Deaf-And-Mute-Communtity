class UserModel {
  final String id;
  final PersonalDetails? personalDetails;
  final MedicalInformation? medicalInformation;
  final List<EmergencyContact>? emergencyContacts;
  final VerificationData? verification;
  final int registrationStep;
  final bool isRegistrationComplete;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.id,
    this.personalDetails,
    this.medicalInformation,
    this.emergencyContacts,
    this.verification,
    required this.registrationStep,
    required this.isRegistrationComplete,
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromFirestore(String id, Map<String, dynamic> data) {
    return UserModel(
      id: id,
      personalDetails:
          data['personalDetails'] != null
              ? PersonalDetails.fromMap(data['personalDetails'])
              : null,
      medicalInformation:
          data['medicalInformation'] != null
              ? MedicalInformation.fromMap(data['medicalInformation'])
              : null,
      emergencyContacts:
          data['emergencyContacts'] != null
              ? (data['emergencyContacts'] as List)
                  .map((contact) => EmergencyContact.fromMap(contact))
                  .toList()
              : null,
      verification:
          data['verification'] != null
              ? VerificationData.fromMap(data['verification'])
              : null,
      registrationStep: data['registrationStep'] ?? 0,
      isRegistrationComplete: data['isRegistrationComplete'] ?? false,
      createdAt: data['createdAt']?.toDate(),
      updatedAt: data['updatedAt']?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'personalDetails': personalDetails?.toMap(),
      'medicalInformation': medicalInformation?.toMap(),
      'emergencyContacts':
          emergencyContacts?.map((contact) => contact.toMap()).toList(),
      'verification': verification?.toMap(),
      'registrationStep': registrationStep,
      'isRegistrationComplete': isRegistrationComplete,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

class PersonalDetails {
  final String fullName;
  final String birthDate;
  final String sex;
  final String email;
  final String mobileNumber;

  PersonalDetails({
    required this.fullName,
    required this.birthDate,
    required this.sex,
    required this.email,
    required this.mobileNumber,
  });

  factory PersonalDetails.fromMap(Map<String, dynamic> map) {
    return PersonalDetails(
      fullName: map['fullName'] ?? '',
      birthDate: map['birthDate'] ?? '',
      sex: map['sex'] ?? '',
      email: map['email'] ?? '',
      mobileNumber: map['mobileNumber'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'birthDate': birthDate,
      'sex': sex,
      'email': email,
      'mobileNumber': mobileNumber,
    };
  }
}

class MedicalInformation {
  final String bloodType;
  final List<String> allergies;
  final List<String> medications;
  final List<String> medicalConditions;
  final String emergencyMedicalInfo;

  MedicalInformation({
    required this.bloodType,
    required this.allergies,
    required this.medications,
    required this.medicalConditions,
    required this.emergencyMedicalInfo,
  });

  factory MedicalInformation.fromMap(Map<String, dynamic> map) {
    return MedicalInformation(
      bloodType: map['bloodType'] ?? '',
      allergies: List<String>.from(map['allergies'] ?? []),
      medications: List<String>.from(map['medications'] ?? []),
      medicalConditions: List<String>.from(map['medicalConditions'] ?? []),
      emergencyMedicalInfo: map['emergencyMedicalInfo'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bloodType': bloodType,
      'allergies': allergies,
      'medications': medications,
      'medicalConditions': medicalConditions,
      'emergencyMedicalInfo': emergencyMedicalInfo,
    };
  }
}

class EmergencyContact {
  final String name;
  final String relationship;
  final String phoneNumber;
  final String email;
  final bool isPrimary;

  EmergencyContact({
    required this.name,
    required this.relationship,
    required this.phoneNumber,
    required this.email,
    required this.isPrimary,
  });

  factory EmergencyContact.fromMap(Map<String, dynamic> map) {
    return EmergencyContact(
      name: map['name'] ?? '',
      relationship: map['relationship'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      email: map['email'] ?? '',
      isPrimary: map['isPrimary'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'relationship': relationship,
      'phoneNumber': phoneNumber,
      'email': email,
      'isPrimary': isPrimary,
    };
  }
}

class VerificationData {
  final bool emailVerified;
  final bool phoneVerified;
  final bool termsAccepted;
  final bool privacyPolicyAccepted;

  VerificationData({
    required this.emailVerified,
    required this.phoneVerified,
    required this.termsAccepted,
    required this.privacyPolicyAccepted,
  });

  factory VerificationData.fromMap(Map<String, dynamic> map) {
    return VerificationData(
      emailVerified: map['emailVerified'] ?? false,
      phoneVerified: map['phoneVerified'] ?? false,
      termsAccepted: map['termsAccepted'] ?? false,
      privacyPolicyAccepted: map['privacyPolicyAccepted'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'emailVerified': emailVerified,
      'phoneVerified': phoneVerified,
      'termsAccepted': termsAccepted,
      'privacyPolicyAccepted': privacyPolicyAccepted,
    };
  }
}
