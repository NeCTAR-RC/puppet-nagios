class nagios::params {

  if versioncmp('20.04', $::lsbdistrelease) < 0 {
    $nagios_version = 'nagios3'
    $naginator_package = 'python-external-naginator'
  } else {
    $nagios_version = 'nagios4'
    $naginator_package = 'python3-external-naginator'
  }


}
