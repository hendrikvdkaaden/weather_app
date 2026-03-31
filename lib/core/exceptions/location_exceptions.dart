class LocationServiceDisabledException implements Exception {
  const LocationServiceDisabledException();

  @override
  String toString() => 'LocationServiceDisabledException: GPS is uitgeschakeld op dit apparaat.';
}

class LocationPermissionDeniedException implements Exception {
  const LocationPermissionDeniedException();

  @override
  String toString() => 'LocationPermissionDeniedException: Locatietoegang is geweigerd.';
}

class LocationPermissionPermanentlyDeniedException implements Exception {
  const LocationPermissionPermanentlyDeniedException();

  @override
  String toString() =>
      'LocationPermissionPermanentlyDeniedException: Locatietoegang is permanent geweigerd. Open de app-instellingen om dit te wijzigen.';
}
