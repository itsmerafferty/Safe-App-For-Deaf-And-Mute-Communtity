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
}
