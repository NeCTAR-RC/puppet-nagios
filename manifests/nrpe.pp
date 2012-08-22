class nagios::nrpe {

  @package {
    'nagios-nrpe-server':
      ensure => present,
      tag    => 'nrpe';
    'nagios-nrpe-plugin':
      ensure => present,
      tag    => 'nrpe';
    'nagios-plugins':
      ensure => present,
      tag    => 'nrpe';
  }

  @service { 'nagios-nrpe-server':
    ensure   => running,
    require  => Package['nagios-nrpe-server'],
    tag      => 'nrpe',
  }

  @file { '/etc/nagios/nrpe.cfg':
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    require => Package['nagios-nrpe-server'],
    notify  => Service['nagios-nrpe-server'],
    content => template('nagios/nrpe.erb'),
    tag     => 'nrpe',
  }

  @file {
    '/usr/local/lib/nagios/':
      ensure  => directory,
      owner   => root,
      group   => root,
      mode    => '0755',
      tag     => 'nrpe';
    '/usr/local/lib/nagios/plugins':
      ensure  => directory,
      owner   => root,
      group   => root,
      mode    => '0755',
      tag     => 'nrpe';
  }
}

define nagios::nrpe::command ($check_command) {

  File <| tag == 'nrpe' |>
  Package <| tag == 'nrpe' |>
  Service <| tag == 'nrpe' |>

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
