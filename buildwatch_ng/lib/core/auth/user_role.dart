/// The two account kinds BuildWatch NG supports.
///
/// The UI currently shows the same screens to both roles, but the role is
/// persisted with the session so features can branch on it later (e.g. only
/// diaspora owners can release payments, only supervisors can submit proof).
enum UserRole {
  diasporaOwner,
  siteSupervisor;

  String get label => switch (this) {
        UserRole.diasporaOwner => 'Diaspora Owner',
        UserRole.siteSupervisor => 'Site Supervisor',
      };

  String get storageValue => name;

  static UserRole fromStorage(String? value) {
    return UserRole.values.firstWhere(
      (r) => r.storageValue == value,
      orElse: () => UserRole.diasporaOwner,
    );
  }
}
