class nagios::nrpe {

  package {
    'nagios-nrpe-server':
      ensure => present;
    'nagios-nrpe-plugin':
      ensure => present;
  }

  service { 'nagios-nrpe-server':
    ensure => running,
  }

  file { '/etc/nagios/nrpe.cfg':
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    require => Package['nagios-nrpe-server'],
    notify  => Service['nagios-nrpe-server'],
    content => template('nagios/nrpe.erb');
  }

}

define nagios::nrpe::command ($check_command)
{
  file { "/etc/nagios/nrpe.d/${name}.cfg":
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    require => Package['nagios-nrpe-server'],
    notify  => Service['nagios-nrpe-server'],
    content => template('nagios/nrpe_command.erb');
  }

}

define nagios::nrpe::service ($check_command) {
  nagios::nrpe::command {
    $name:
      check_command => $check_command;
  }

  nagios::service {
    $name:
      check_command => "check_nrpe_1arg!${name}"
  }
}
