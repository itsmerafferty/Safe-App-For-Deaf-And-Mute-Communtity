class Validators {
  // Email validation - must end with @gmail.com
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    
    final trimmedValue = value.trim();
    
    // Check if it contains @
    if (!trimmedValue.contains('@')) {
      return 'Please enter a valid email address';
    }
    
    // Check if it ends with @gmail.com
    if (!trimmedValue.toLowerCase().endsWith('@gmail.com')) {
      return 'Email must be a Gmail address (@gmail.com)';
    }
    
    // Check email format
    final emailRegex = RegExp(r'^[a-zA-Z0-9._]+@gmail\.com$');
    if (!emailRegex.hasMatch(trimmedValue.toLowerCase())) {
      return 'Please enter a valid Gmail address';
    }
    
    return null;
  }

  // Phone number validation - must be exactly 11 digits
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    
    // Remove all non-digit characters
    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
    
    if (digitsOnly.length != 11) {
      return 'Phone number must be exactly 11 digits';
    }
    
    // Check if it starts with 09 (Philippine mobile number format)
    if (!digitsOnly.startsWith('09')) {
      return 'Phone number must start with 09';
    }
    
    return null;
  }

  // Password validation
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    
    return null;
  }

  // Confirm password validation
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    
    if (value != password) {
      return 'Passwords do not match';
    }
    
    return null;
  }

  // Name validation
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    
    final trimmedValue = value.trim();
    
    if (trimmedValue.length < 2) {
      return 'Name must be at least 2 characters';
    }
    
    // Check if name contains only letters and spaces
    final nameRegex = RegExp(r'^[a-zA-Z\s]+$');
    if (!nameRegex.hasMatch(trimmedValue)) {
      return 'Name can only contain letters and spaces';
    }
    
    return null;
  }

  // Required field validation
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  // Age validation
  static String? validateAge(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Age is required';
    }
    
    final age = int.tryParse(value);
    if (age == null) {
      return 'Please enter a valid age';
    }
    
    if (age < 1 || age > 120) {
      return 'Please enter a valid age (1-120)';
    }
    
    return null;
  }

  // Height validation (in cm)
  static String? validateHeight(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Height is optional
    }
    
    final height = double.tryParse(value);
    if (height == null) {
      return 'Please enter a valid height';
    }
    
    if (height < 50 || height > 300) {
      return 'Please enter a valid height (50-300 cm)';
    }
    
    return null;
  }

  // Weight validation (in kg)
  static String? validateWeight(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Weight is optional
    }
    
    final weight = double.tryParse(value);
    if (weight == null) {
      return 'Please enter a valid weight';
    }
    
    if (weight < 1 || weight > 500) {
      return 'Please enter a valid weight (1-500 kg)';
    }
    
    return null;
  }

  // Address validation
  static String? validateAddress(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Address is required';
    }
    
    if (value.trim().length < 5) {
      return 'Address must be at least 5 characters';
    }
    
    return null;
  }
}
