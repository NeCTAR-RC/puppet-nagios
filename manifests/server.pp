class nagios::server {

  package {'nagios3':
    ensure => present,
    notify => Exec['nagios_exec_fix', 'nagios_exec_fix1'],
  }

  service {'nagios3':
    ensure => running,
  }

  file {'/etc/nagios3/nagios.cfg':
    ensure  => file,
    owner   => root,
    group   => root,
    mode    => '0644',
    source  => 'puppet:///modules/nagios/nagios.cfg',
    require => Package['nagios3'],
    notify  => Service['nagios3'],
  }

  exec {
    'nagios_exec_fix':
      command => 'dpkg-statoverride --update --add nagios www-data 2710 /var/lib/nagios3/rw',
      unless  => 'dpkg-statoverride --list /var/lib/nagios3/rw',
      path    => '/usr/sbin/',
      require => Package['nagios3'],
      notify  => Service['nagios3'];
    'nagios_exec_fix1':
      command => 'dpkg-statoverride --update --add nagios nagios 751 /var/lib/nagios3',
      unless  => 'dpkg-statoverride --list /var/lib/nagios3',
      path    => '/usr/sbin/',
      require => Package['nagios3'],
      notify  => Service['nagios3'];
  }

  Nagios_command <<||>>
  Nagios_contactgroup <<||>>
  Nagios_contact <<||>>
  Nagios_hostdependency <<||>>
  Nagios_hostescalation <<||>>
  Nagios_hostextinfo <<||>>
  Nagios_hostgroup <<||>>
  Nagios_host <<||>>
  Nagios_servicedependency <<||>>
  Nagios_serviceescalation <<||>>
  Nagios_servicegroup <<||>>
  Nagios_serviceextinfo <<||>>
  Nagios_service <<||>>
  Nagios_timeperiod <<||>>

  resources {
    [ 'nagios_command',
      'nagios_contactgroup',
      'nagios_contact',
      'nagios_hostdependency',
      'nagios_hostescalation',
      'nagios_hostextinfo',
      'nagios_hostgroup',
      'nagios_host',
      'nagios_servicedependency',
      'nagios_serviceescalation',
      'nagios_servicegroup',
      'nagios_serviceextinfo',
      'nagios_service',
      'nagios_timeperiod']:
        purge => true;
  }

  Nagios_command <| tag == $environment |> {
    target  => '/etc/nagios3/conf.d/nagios_command.cfg',
    require => File['nagios_confd'],
    notify  => Service['nagios3'],
  }
  Nagios_contact <| tag == $environment |> {
    target  => '/etc/nagios3/conf.d/nagios_contact.cfg',
    require => File['nagios_confd'],
    notify  => Service['nagios3'],
  }
  Nagios_contactgroup <| tag == $environment |> {
    target  => '/etc/nagios3/conf.d/nagios_contactgroup.cfg',
    require => File['nagios_confd'],
    notify  => Service['nagios3'],
  }
  Nagios_host <| tag == $environment |> {
    target  => '/etc/nagios3/conf.d/nagios_host.cfg',
    require => File['nagios_confd'],
    notify  => Service['nagios3'],
  }
  Nagios_hostdependency <| tag == $environment |> {
    target => '/etc/nagios3/conf.d/nagios_hostdependency.cfg',
    notify => Service['nagios3'],
  }
  Nagios_hostescalation <| tag == $environment |> {
    target => '/etc/nagios3/conf.d/nagios_hostescalation.cfg',
    notify => Service['nagios3'],
  }
  Nagios_hostextinfo <| tag == $environment |> {
    target  => '/etc/nagios3/conf.d/nagios_hostextinfo.cfg',
    require => File['nagios_confd'],
    notify  => Service['nagios3'],
  }
  Nagios_hostgroup <| tag == $environment |> {
    target  => '/etc/nagios3/conf.d/nagios_hostgroup.cfg',
    require => File['nagios_confd'],
    notify  => Service['nagios3'],
  }
  Nagios_service <| tag == $environment |> {
    target  => '/etc/nagios3/conf.d/nagios_service.cfg',
    require => File['nagios_confd'],
    notify  => Service['nagios3'],
  }
  Nagios_servicegroup <| tag == $environment |> {
    target  => '/etc/nagios3/conf.d/nagios_servicegroup.cfg',
    require => File['nagios_confd'],
    notify  => Service['nagios3'],
  }
  Nagios_servicedependency <| tag == $environment |> {
    target  => '/etc/nagios3/conf.d/nagios_servicedependency.cfg',
    require => File['nagios_confd'],
    notify  => Service['nagios3'],
  }
  Nagios_serviceescalation <| tag == $environment |> {
    target  => '/etc/nagios3/conf.d/nagios_serviceescalation.cfg',
    require => File['nagios_confd'],
    notify  => Service['nagios3'],
  }
  Nagios_serviceextinfo <| tag == $environment |> {
    target  => '/etc/nagios3/conf.d/nagios_serviceextinfo.cfg',
    require => File['nagios_confd'],
    notify  => Service['nagios3'],
  }
  Nagios_timeperiod <| tag == $environment |> {
    target  => '/etc/nagios3/conf.d/nagios_timeperiod.cfg',
    require => File['nagios_confd'],
    notify  => Service['nagios3'],
  }

  file { ['/etc/nagios3/conf.d/nagios_command.cfg',
          '/etc/nagios3/conf.d/nagios_contact.cfg',
          '/etc/nagios3/conf.d/nagios_contactgroup.cfg',
          '/etc/nagios3/conf.d/nagios_host.cfg',
          '/etc/nagios3/conf.d/nagios_hostdependency.cfg',
          '/etc/nagios3/conf.d/nagios_hostescalation.cfg',
          '/etc/nagios3/conf.d/nagios_hostextinfo.cfg',
          '/etc/nagios3/conf.d/nagios_hostgroup.cfg',
          '/etc/nagios3/conf.d/nagios_hostgroupescalation.cfg',
          '/etc/nagios3/conf.d/nagios_service.cfg',
          '/etc/nagios3/conf.d/nagios_servicedependency.cfg',
          '/etc/nagios3/conf.d/nagios_serviceescalation.cfg',
          '/etc/nagios3/conf.d/nagios_serviceextinfo.cfg',
          '/etc/nagios3/conf.d/nagios_servicegroup.cfg',
          '/etc/nagios3/conf.d/nagios_timeperiod.cfg']:
            ensure  => file,
            replace => false,
            notify  => Service['nagios3'],
            mode    => '0644',
            owner   => root,
            group   => 0;
  }

  file { 'nagios_confd':
    ensure  => directory,
    path    => '/etc/nagios3/conf.d/',
    purge   => true,
    recurse => true,
    force   => true,
    notify  => Service['nagios3'],
    mode    => '0750',
    owner   => root,
    group   => nagios;
  }

  nagios_command {
    'http_port':
      tag          => $environment,
      command_line => '$USER1$/check_http -p $ARG1$ -H $HOSTADDRESS$ -I $HOSTADDRESS$';
    'https_port':
      tag          => $environment,
      command_line => '$USER1$/check_http --ssl -p $ARG1$ -H $HOSTADDRESS$ -I $HOSTADDRESS$';
  }
}
