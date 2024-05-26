class nagios::host (
  $parents = 'absent',
  $address = $::ipaddress,
  $nagios_alias = $::fqdn,
  $hostgroups = 'absent',
  $use = 'generic-host',
){

  include puppet

  @@nagios_host { $::fqdn:
    tag     => $puppet::config_environment,
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
