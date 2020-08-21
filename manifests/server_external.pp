# Nagios external server
class nagios::server_external (
  $puppetdb_host,
  $puppetdb_port=8081,
  $naginator_timeout=60,
  $use_ssl=true,
  $extra_cfg_dirs=undef,
){

  include ::nagios::nrdp
  include ::stdlib

  $naginator = hiera('nagios::naginator', {})
  $config_environment = hiera('puppet::config_environment', $::environment)

  if versioncmp('20.04', $::lsbdistrelease) < 0 {
    $nagios_version = 'nagios3'
    $naginator_package = 'python-external-naginator'
  } else {
    $nagios_version = 'nagios4'
    $naginator_package = 'python3-external-naginator'
  }

  $nagios_pkgs = [ $nagios_version, 'nagios-images']

  package { $nagios_pkgs:
    ensure => present,
    notify => Exec[ 'nagios_exec_fix', 'nagios_exec_fix1',
                    'nagios_exec_fix_2', 'nagios_exec_fix_3'],
  }

  service { $nagios_version:
    ensure => running,
  }

  package { $naginator_package:
    ensure => present,
  }

  file { "/etc/${nagios_version}/nagios.cfg":
    ensure  => file,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template("nagios/${nagios_version}.cfg.erb"),
    require => Package[$nagios_version],
    notify  => Service[$nagios_version],
  }

  file { "/etc/${nagios_version}/naginator.ini":
    ensure  => file,
    owner   => root,
    group   => root,
    mode    => '0755',
    content => template('nagios/naginator.ini.erb'),
  }

  if $extra_cfg_dirs {
    $dirs = prefix($extra_cfg_dirs, "/etc/${nagios_version}/")
    file {[$dirs]:
      ensure => directory,
      owner  => root,
      group  => root,
      mode   => '0755',
    }
  }

  cron { 'update-nagios-config':
    ensure      => present,
    command     => "/usr/bin/external-naginator --update -c /etc/${nagios_version}/naginator.ini --output-dir /etc/${nagios_version}/conf.d/ --host ${puppetdb_host} --port ${puppetdb_port}",
    user        => 'root',
    minute      => '0',
    environment => 'PATH=/bin:/usr/bin:/usr/sbin:/usr/local/bin/',
    require     => Package[$naginator_package],
  }

  file { "/etc/${nagios_version}/extra.d":
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

    'nagios_exec_fix_2':
      command => "dpkg-statoverride --update --add nagios www-data 770 /var/lib/${nagios_version}/spool",
      unless  => "dpkg-statoverride --list /var/lib/${nagios_version}/spool",
      path    => ['/usr/bin/', '/usr/sbin/'],
      require => Package[$nagios_version],
      notify  => Service[$nagios_version];

    'nagios_exec_fix_3':
      command => "dpkg-statoverride --update --add nagios www-data 770 /var/lib/${nagios_version}/spool/checkresults",
      unless  => "dpkg-statoverride --list /var/lib/${nagios_version}/spool/checkresults",
      path    => ['/usr/bin/', '/usr/sbin/'],
      require => Package[$nagios_version],
      notify  => Service[$nagios_version];
  }

  file { 'nagios_confd':
    ensure  => directory,
    path    => "/etc/${nagios_version}/conf.d/",
    mode    => '0644',
    owner   => root,
    group   => nagios;
  }

  # Legacy groups
  @@nagios_servicegroup {
    'openstack-endpoints':
      tag   => $config_environment,
      alias => 'The user facing endpoints.';
    'message-queues':
      tag   => $config_environment,
      alias => 'RabbitMQ and other queues.';
    'databases':
      tag   => $config_environment,
      alias => 'Database Servers.';
  }

  $servicegroups = hiera('nagios::servicegroups', {})
  create_resources('nagios::servicegroup', $servicegroups)

  nagios::command {
    'http_port':
      command_line => '$USER1$/check_http -p $ARG1$ -H $HOSTADDRESS$ -I $HOSTADDRESS$ -a \'$ARG2$\'';
    'https_port':
      command_line => '$USER1$/check_http --ssl -p $ARG1$ -H $HOSTADDRESS$ -I $HOSTADDRESS$ -a \'$ARG2$\' -C 60,30';
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
