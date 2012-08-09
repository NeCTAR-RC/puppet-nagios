class nagios::server {

  package {'nagios3':
    ensure => present,
  }

  service {'nagios3':
    ensure => running,
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

  Nagios_command <||> {
    target  => '/etc/nagios3/conf.d/nagios_command.cfg',
    require => File['nagios_confd'],
    notify  => Service['nagios3'],
  }
  Nagios_contact <||> {
    target  => '/etc/nagios3/conf.d/nagios_contact.cfg',
    require => File['nagios_confd'],
    notify  => Service['nagios3'],
  }
  Nagios_contactgroup <||> {
    target  => '/etc/nagios3/conf.d/nagios_contactgroup.cfg',
    require => File['nagios_confd'],
    notify  => Service['nagios3'],
  }
  Nagios_host <||> {
    target  => '/etc/nagios3/conf.d/nagios_host.cfg',
    require => File['nagios_confd'],
    notify  => Service['nagios3'],
  }
  Nagios_hostdependency <||> {
    target => '/etc/nagios3/conf.d/nagios_hostdependency.cfg',
    notify => Service['nagios3'],
  }
  Nagios_hostescalation <||> {
    target => '/etc/nagios3/conf.d/nagios_hostescalation.cfg',
    notify => Service['nagios3'],
  }
  Nagios_hostextinfo <||> {
    target  => '/etc/nagios3/conf.d/nagios_hostextinfo.cfg',
    require => File['nagios_confd'],
    notify  => Service['nagios3'],
  }
  Nagios_hostgroup <||> {
    target  => '/etc/nagios3/conf.d/nagios_hostgroup.cfg',
    require => File['nagios_confd'],
    notify  => Service['nagios3'],
  }
  Nagios_service <||> {
    target  => '/etc/nagios3/conf.d/nagios_service.cfg',
    require => File['nagios_confd'],
    notify  => Service['nagios3'],
  }
  Nagios_servicegroup <||> {
    target  => '/etc/nagios3/conf.d/nagios_servicegroup.cfg',
    require => File['nagios_confd'],
    notify  => Service['nagios3'],
  }
  Nagios_servicedependency <||> {
    target  => '/etc/nagios3/conf.d/nagios_servicedependency.cfg',
    require => File['nagios_confd'],
    notify  => Service['nagios3'],
  }
  Nagios_serviceescalation <||> {
    target  => '/etc/nagios3/conf.d/nagios_serviceescalation.cfg',
    require => File['nagios_confd'],
    notify  => Service['nagios3'],
  }
  Nagios_serviceextinfo <||> {
    target  => '/etc/nagios3/conf.d/nagios_serviceextinfo.cfg',
    require => File['nagios_confd'],
    notify  => Service['nagios3'],
  }
  Nagios_timeperiod <||> {
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
      command_line => '$USER1$/check_http -p $ARG1$ -H $HOSTADDRESS$ -I $HOSTADDRESS$';
    'https_port':
      command_line => '$USER1$/check_http --ssl -p $ARG1$ -H $HOSTADDRESS$ -I $HOSTADDRESS$';
  }
}
