class nagios::host (
  $parents = 'absent',
  $address = $::ipaddress,
  $nagios_alias = $::fqdn,
  $hostgroups = 'absent',
  $parents = 'absent',
  $use,
){

  @@nagios_host { $::fqdn:
    tag     => $::environment,
    address => $address,
    alias   => $nagios_alias,
    mode    => '0644',
    use     => $use,
  }

  if ($hostgroups != 'absent') {
    Nagios_host[$fqdn] {
      hostgroups => $hostgroups }
  }

  if ($parents != 'absent') {
    Nagios_host[$fqdn] {
      parents => $parents }
  }
}
