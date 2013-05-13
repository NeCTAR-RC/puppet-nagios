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

  user { 'nagios':
    groups  => ['users', 'puppet'],
    require => Package['nagios-nrpe-server'],
  }

  @service { 'nagios-nrpe-server':
    ensure  => running,
    require => Package['nagios-nrpe-server'],
    tag     => 'nrpe',
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

  $plugin_dirs = ['/etc/nagios-plugins', '/etc/nagios-plugins/config']

  file { $plugin_dirs:
    ensure  => directory,
    mode    => '0755',
    owner   => 'root',
    group   => 'root',
  }

  file{ '/etc/nagios-plugins/config/check_nrpe.cfg':
    owner   => root,
    group   => root,
    mode    => '0755',
    source  => 'puppet:///modules/nagios/check_nrpe.cfg',
    require => File[$plugin_dirs],
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
      require => File['/usr/local/lib/nagios/'],
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

define nagios::nrpe::service (
  $check_command,
  $check_period = '',
  $normal_check_interval = '',
  $retry_check_interval = '',
  $max_check_attempts = '',
  $notification_interval = '',
  $notification_period = '',
  $notification_options = '',
  $contact_groups = '',
  $servicegroups = '',
  $use = 'generic-service',
  $service_description = 'absent',
  $nrpe_command = 'check_nrpe_1arg',
  ) {
  nagios::nrpe::command {
    $name:
      check_command => $check_command;
  }

  nagios::service {
    $name:
      check_command         => "${nrpe_command}!${name}",
      check_period          => $check_period,
      normal_check_interval => $normal_check_interval,
      retry_check_interval  => $retry_check_interval,
      max_check_attempts    => $max_check_attempts,
      notification_interval => $notification_interval,
      notification_period   => $notification_period,
      notification_options  => $notification_options,
      contact_groups        => $contact_groups,
      use                   => $use,
      service_description   => $service_description,
      servicegroups         => $servicegroups,
  }
}
