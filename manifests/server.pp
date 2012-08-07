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
    'check_dummy':
      command_line => '$USER1$/check_dummy $ARG1$';
    'check_https_cert':
      command_line => '$USER1$/check_http --ssl -C 20 -H $HOSTADDRESS$ -I $HOSTADDRESS$';
    'check_http_url':
      command_line => '$USER1$/check_http -H $ARG1$ -u $ARG2$';
    'check_http_url_regex':
      command_line => '$USER1$/check_http -H $ARG1$ -u $ARG2$ -e $ARG3$';
    'check_https_url':
      command_line => '$USER1$/check_http --ssl -H $ARG1$ -u $ARG2$';
    'check_https_url_regex':
      command_line => '$USER1$/check_http --ssl -H $ARG1$ -u $ARG2$ -e $ARG3$';
    'check_mysql_db':
      command_line => '$USER1$/check_mysql -H $ARG1$ -P $ARG2$ -u $ARG3$ -p $ARG4$ -d $ARG5$';
    'check_ntp_time':
      command_line => '$USER1$/check_ntp_time -H $HOSTADDRESS$ -w 0.5 -c 1';
    'check_silc':
      command_line => '$USER1$/check_tcp -p 706 -H $ARG1$';
    'check_sobby':
      command_line => '$USER1$/check_tcp -H $ARG1$ -p $ARG2$';

    # from apache module
    'http_port':
      command_line => '$USER1$/check_http -p $ARG1$ -H $HOSTADDRESS$ -I $HOSTADDRESS$';
    'https_port':
      command_line => '$USER1$/check_http --ssl -p $ARG1$ -H $HOSTADDRESS$ -I $HOSTADDRESS$';

    'check_http_port_url_content':
      command_line => '$USER1$/check_http -H $ARG1$ -p $ARG2$ -u $ARG3$ -s $ARG4$';
    'check_https_port_url_content':
      command_line => '$USER1$/check_http --ssl -H $ARG1$ -p $ARG2$ -u $ARG3$ -s $ARG4$';
    'check_http_url_content':
      command_line => '$USER1$/check_http -H $ARG1$ -u $ARG2$ -s $ARG3$';
    'check_https_url_content':
      command_line => '$USER1$/check_http --ssl -H $ARG1$ -u $ARG2$ -s $ARG3$';

    # from bind module
    'check_dig2':
      command_line => '$USER1$/check_dig -H $HOSTADDRESS$ -l $ARG1$ --record_type=$ARG2$';

    # from mysql module
    'check_mysql_health':
      command_line => '$USER1$/check_mysql_health --hostname $ARG1$ --port $ARG2$ --username $ARG3$ --password $ARG4$ --mode $ARG5$ --database $ARG6$';

    # better check_dns
    'check_dns2':
      command_line => '$USER1$/check_dns2 -c $ARG1$ A $ARG2$';

    # dnsbl checking
    'check_dnsbl':
      command_line => '$USER1$/check_dnsbl -H $ARG1$';

  }

}
