class nagios::server inherits nagios::params {

  $config_environment = hiera('puppet::config_environment', $::environment)

  $nagios_pkgs = [ $nagios_version, 'nagios-images']

  package { $nagios_pkgs:
    ensure => present,
    notify => Exec['nagios_exec_fix', 'nagios_exec_fix1'],
  }

  service { $nagios_version:
    ensure => running,
  }

  file { "/etc/${nagios_version}/nagios.cfg":
    ensure  => file,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template('nagios/nagios.cfg.erb'),
    require => Package['nagios3'],
    notify  => Service['nagios3'],
  }

  file { '/etc/${nagios3}/extra.d':
    ensure => directory,
  }

  exec {
    'nagios_exec_fix':
      command => "dpkg-statoverride --update --add nagios www-data 2710 /var/lib/${nagios_version}/rw",
      unless  => "dpkg-statoverride --list /var/lib/${nagios_version}/rw",
      path    => ['/usr/bin/', '/usr/sbin/'],
      require => Package[$nagios_version],
      notify  => Service[$nagios_version];
    'nagios_exec_fix1':
      command => "dpkg-statoverride --update --add nagios nagios 751 /var/lib/${nagios_version}",
      unless  => "dpkg-statoverride --list /var/lib/${nagios_version}",
      path    => ['/usr/bin/', '/usr/sbin/'],
      require => Package[$nagios_version],
      notify  => Service[$nagios_version];
  }

  nagios_servicegroup {
    "openstack-endpoints":
      tag => $config_environment,
      alias => "The user facing endpoints.";
    "message-queues":
      tag => $config_environment,
      alias => "RabbitMQ and other queues.";
    "databases":
      tag => $config_environment,
      alias => "Database Servers.";
  }

  Nagios_command <<| tag == $config_environment |>>
  Nagios_contactgroup <<| tag == $config_environment |>>
  Nagios_contact <<| tag == $config_environment |>>
  Nagios_hostdependency <<| tag == $config_environment |>>
  Nagios_hostescalation <<| tag == $config_environment |>>
  Nagios_hostextinfo <<| tag == $config_environment |>>
  Nagios_hostgroup <<| tag == $config_environment |>>
  Nagios_host <<| tag == $config_environment |>>
  Nagios_servicedependency <<| tag == $config_environment |>>
  Nagios_serviceescalation <<| tag == $config_environment |>>
  Nagios_servicegroup <<| tag == $config_environment |>>
  Nagios_serviceextinfo <<| tag == $config_environment |>>
  Nagios_service <<| tag == $config_environment |>>
  Nagios_timeperiod <<| tag == $config_environment |>>

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

  Nagios_command <| tag == $config_environment |> {
    require => File['nagios_confd'],
    notify  => Service[$nagios_version],
  }
  Nagios_contact <| tag == $config_environment |> {
    target  => "/etc/${nagios_version}/conf.d/nagios_contact.cfg",
    require => File['nagios_confd'],
    notify  => Service[$nagios_version],
  }
  Nagios_contactgroup <| tag == $config_environment |> {
    target  => "/etc/${nagios_version}/conf.d/nagios_contactgroup.cfg",
    require => File['nagios_confd'],
    notify  => Service[$nagios_version],
  }
  Nagios_host <| tag == $config_environment |> {
    target  => "/etc/${nagios_version}/conf.d/nagios_host.cfg",
    require => File['nagios_confd'],
    notify  => Service[$nagios_version],
  }
  Nagios_hostdependency <| tag == $config_environment |> {
    target => "/etc/${nagios_version}/conf.d/nagios_hostdependency.cfg",
    notify => Service[$nagios_version],
  }
  Nagios_hostescalation <| tag == $config_environment |> {
    target => "/etc/${nagios_version}/conf.d/nagios_hostescalation.cfg",
    notify => Service[$nagios_version],
  }
  Nagios_hostextinfo <| tag == $config_environment |> {
    target  => "/etc/${nagios_version}/conf.d/nagios_hostextinfo.cfg",
    require => File['nagios_confd'],
    notify  => Service[$nagios_version],
  }
  Nagios_hostgroup <| tag == $config_environment |> {
    target  => "/etc/${nagios_version}/conf.d/nagios_hostgroup.cfg",
    require => File['nagios_confd'],
    notify  => Service[$nagios_version],
  }
  Nagios_service <| tag == $config_environment |> {
    target  => "/etc/${nagios_version}/conf.d/nagios_service.cfg",
    require => File['nagios_confd'],
    notify  => Service[$nagios_version],
  }
  Nagios_servicegroup <| tag == $config_environment |> {
    target  => "/etc/${nagios_version}/conf.d/nagios_servicegroup.cfg",
    require => File['nagios_confd'],
    notify  => Service[$nagios_version],
  }
  Nagios_servicedependency <| tag == $config_environment |> {
    target  => "/etc/${nagios_version}/conf.d/nagios_servicedependency.cfg",
    require => File['nagios_confd'],
    notify  => Service[$nagios_version],
  }
  Nagios_serviceescalation <| tag == $config_environment |> {
    target  => "/etc/${nagios_version}/conf.d/nagios_serviceescalation.cfg",
    require => File['nagios_confd'],
    notify  => Service[$nagios_version],
  }
  Nagios_serviceextinfo <| tag == $config_environment |> {
    target  => "/etc/${nagios_version}/conf.d/nagios_serviceextinfo.cfg",
    require => File['nagios_confd'],
    notify  => Service[$nagios_version],
  }
  Nagios_timeperiod <| tag == $config_environment |> {
    target  => "/etc/${nagios_version}/conf.d/nagios_timeperiod.cfg",
    require => File['nagios_confd'],
    notify  => Service[$nagios_version],
  }

  file { ["/etc/${nagios_version}/conf.d/nagios_contact.cfg",
          "/etc/${nagios_version}/conf.d/nagios_contactgroup.cfg",
          "/etc/${nagios_version}/conf.d/nagios_host.cfg",
          "/etc/${nagios_version}/conf.d/nagios_hostdependency.cfg",
          "/etc/${nagios_version}/conf.d/nagios_hostescalation.cfg",
          "/etc/${nagios_version}/conf.d/nagios_hostextinfo.cfg",
          "/etc/${nagios_version}/conf.d/nagios_hostgroup.cfg",
          "/etc/${nagios_version}/conf.d/nagios_hostgroupescalation.cfg",
          "/etc/${nagios_version}/conf.d/nagios_service.cfg",
          "/etc/${nagios_version}/conf.d/nagios_servicedependency.cfg",
          "/etc/${nagios_version}/conf.d/nagios_serviceescalation.cfg",
          "/etc/${nagios_version}/conf.d/nagios_serviceextinfo.cfg",
          "/etc/${nagios_version}/conf.d/nagios_servicegroup.cfg",
          "/etc/${nagios_version}/conf.d/nagios_timeperiod.cfg"]:
            ensure  => file,
            replace => false,
            notify  => Service[$nagios_version],
            mode    => '0644',
            owner   => root,
            group   => 0;
  }

  file { "/etc/${nagios_version}/conf.d/nagios_command.cfg":
    ensure  => absent,
  }

  file { 'nagios_confd':
    ensure  => directory,
    path    => "/etc/${nagios_version}/conf.d/",
    purge   => true,
    recurse => true,
    force   => true,
    notify  => Service[$nagios_version],
    mode    => '0644',
    owner   => root,
    group   => nagios;
  }

  nagios::command {
    'http_port':
      command_line => '$USER1$/check_http -p $ARG1$ -H $HOSTADDRESS$ -I $HOSTADDRESS$';
    'https_port':
      command_line => '$USER1$/check_http --ssl -p $ARG1$ -H $HOSTADDRESS$ -I $HOSTADDRESS$ -C 60,30';
    'http_port_extra':
      command_line => '$USER1$/check_http -p $ARG1$ -H $HOSTADDRESS$ -I $HOSTADDRESS$ -a \'$ARG2$\' -u \'$ARG3$\' -e \'$ARG4$\'';
    'https_port_extra':
      command_line => '$USER1$/check_http --ssl -p $ARG1$ -H $HOSTADDRESS$ -I $HOSTADDRESS$ -a \'$ARG2$\' -u \'$ARG3$\' -e \'$ARG4$\' -C 60,30';
    'oslo_healthcheck':
      command_line => '$USER1$/check_http -p $ARG1$ -H $HOSTADDRESS$ -I $HOSTADDRESS$  -u \'/healthcheck\' -e \'OK\'';
    'oslo_healthcheck_https':
      command_line => '$USER1$/check_http --ssl -p $ARG1$ -H $HOSTADDRESS$ -I $HOSTADDRESS$  -u \'/healthcheck\' -e \'OK\' -C 60,30';
    'check_ping2':
      command_line => '$USER1$/check_ping -H $ARG1$ -w 5000,100% -c 5000,100% -p 1';
  }
}
