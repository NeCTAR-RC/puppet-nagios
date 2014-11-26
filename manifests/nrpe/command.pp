#Type to create nagios check commands.
define nagios::nrpe::command ($check_command) {

  File <| tag == 'nrpe' |>
  Package <| tag == 'nrpe' |>
  Service <| tag == 'nrpe' |>

  file { "/etc/nagios/nrpe.d/${name}.cfg":
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    require => [ Package[ 'nagios-nrpe-server' ], File['/etc/nagios/nrpe.d'], ],
    notify  => Service[ 'nagios-nrpe-server' ],
    content => template('nagios/nrpe_command.erb');
  }

}
