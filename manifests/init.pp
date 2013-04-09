class nagios {

}

define nagios::command ($check_command) {
  file { "/etc/nagios3/conf.d/${name}.cfg":
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    notify  => Service['nagios3'],
    content => template('nagios/nagios_command.erb');
  }
}
