#Type to create nagios check commands.
define nagios::nrpe::command ($check_command) {

  if $::osfamily == 'Debian' {
    Class['Apt::Update'] -> Package <| tag == 'nrpe' |>
  }
  else {
    Package <| tag == 'nrpe' |>
  }

  File <| tag == 'nrpe' |>
  Service <| tag == 'nrpe' |>

  file { "/etc/nagios/nrpe.d/${name}.cfg":
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    require => [Package['nagios-nrpe-server'], File['/etc/nagios/nrpe.d'], ],
    notify  => Service['nagios-nrpe-server'],
    content => template('nagios/nrpe_command.erb');
  }

}
