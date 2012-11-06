# XXX (russell) I have decided that using this class is a bad idea
# because it prevents overiding the host groups in the sub classes.
# This also means that a nagios host class can be added to the base
# class which prevents breakage when there is no host defined for a
# service.

class nagios::target (
  $parents = 'absent',
  $address = $::ipaddress_public,
  $nagios_alias = $::hostname,
  $hostgroups = 'absent'
){
  @@nagios_host { $fqdn:
    address => $address,
    alias   => $nagios_alias,
    use     => 'generic-host',
  }

  if ($parents != 'absent') {
    Nagios_host[$fqdn] {
      parents => $parents }
  }

  if ($hostgroups != 'absent') {
    Nagios_host[$fqdn] {
      hostgroups => $hostgroups }
  }

}
