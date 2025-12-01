enum UserRole { technician, admin }

class AppUser {
  final String email;
  final String password; // storing plain text for MOCK only
  final UserRole role;
  bool isActive; // This handles the "Disable" logic

  AppUser({
    required this.email,
    required this.password,
    required this.role,
    this.isActive = true, // Active by default
  });
}
