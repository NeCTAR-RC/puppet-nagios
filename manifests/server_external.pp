# Nagios external server
class nagios::server_external (
  $puppetdb_host,
  $puppetdb_port=8081,
  $naginator_timeout=60,
  $use_ssl=true,
  $extra_cfg_dirs=undef,
  $use_authentication=0,
  $default_user=undef,
  $authorized_users=['nagiosadmin'],
  $retention_update_interval=1,
  $enable_notifications=1,
  $manage_cgi=false,
  Hash $nagios_command = {},
) inherits nagios::params {

  include puppet
  include nagios::nrdp
  include stdlib

  $naginator = hiera('nagios::naginator', {})
  $config_environment = $puppet::config_environment

  $nagios_pkgs = [ $nagios::params::nagios_version, 'nagios-images']

  package { $nagios_pkgs:
    ensure => present,
    notify => Exec[ 'nagios_exec_fix', 'nagios_exec_fix1',
                    'nagios_exec_fix_2', 'nagios_exec_fix_3'],
  }

  service { $nagios::params::nagios_version:
    ensure => running,
  }

  package { $nagios::params::naginator_package:
    ensure => present,
  }

  file { "/etc/${nagios::params::nagios_version}/nagios.cfg":
    ensure  => file,
    owner   => root,
    group   => root,
    mode    => '0644',
    content => template("nagios/${nagios::params::nagios_version}.cfg.erb"),
    require => Package[$nagios::params::nagios_version],
    notify  => Service[$nagios::params::nagios_version],
  }

  if $manage_cgi and $nagios::params::nagios_version == 'nagios4' {
    file { "/etc/${nagios::params::nagios_version}/cgi.cfg":
      ensure  => file,
      owner   => root,
      group   => root,
      mode    => '0644',
      content => template('nagios/cgi.cfg.erb')
    }
  }

  file {"/etc/${nagios::params::nagios_version}/objects":
    ensure => directory,
    owner  => root,
    group  => root,
    mode   => '0775',
  }

  file {"/etc/${nagios::params::nagios_version}/objects/commands.cfg":
    ensure  => file,
    owner   => root,
    group   => root,
    mode    => '0664',
    content => template('nagios/commands.cfg.erb'),
  }

  # External naginator is hard coded to look here
  file { "/etc/${nagios::params::nagios_version}/commands.cfg":
    ensure  => link,
    target  => "/etc/${nagios::params::nagios_version}/objects/commands.cfg",
    require => Package[$nagios::params::nagios_version],
    notify  => Service[$nagios::params::nagios_version],
  }

  file { "/etc/${nagios::params::nagios_version}/naginator.ini":
    ensure  => file,
    owner   => root,
    group   => root,
    mode    => '0755',
    content => template('nagios/naginator.ini.erb'),
  }

  if $extra_cfg_dirs {
    $dirs = prefix($extra_cfg_dirs, "/etc/${nagios::params::nagios_version}/")
    file {[$dirs]:
      ensure => directory,
      owner  => root,
      group  => root,
      mode   => '0755',
    }
  }

  cron { 'update-nagios-config':
    ensure      => present,
    command     => "/usr/bin/external-naginator --update -c /etc/${nagios::params::nagios_version}/naginator.ini --output-dir /etc/${nagios::params::nagios_version}/conf.d/ --host ${puppetdb_host} --port ${puppetdb_port}",
    user        => 'root',
    minute      => '0',
    environment => 'PATH=/bin:/usr/bin:/usr/sbin:/usr/local/bin/',
    require     => Package[$nagios::params::naginator_package],
  }

  file { "/etc/${nagios::params::nagios_version}/extra.d":
    ensure => directory,
  }

  exec {
    'nagios_exec_fix':
      command => "dpkg-statoverride --update --add nagios www-data 2710 /var/lib/${nagios::params::nagios_version}/rw",
      unless  => "dpkg-statoverride --list /var/lib/${nagios::params::nagios_version}/rw",
      path    => ['/usr/bin/', '/usr/sbin/'],
      require => Package[$nagios::params::nagios_version],
      notify  => Service[$nagios::params::nagios_version];

    'nagios_exec_fix1':
      command => "dpkg-statoverride --update --add nagios nagios 751 /var/lib/${nagios::params::nagios_version}",
      unless  => "dpkg-statoverride --list /var/lib/${nagios::params::nagios_version}",
      path    => ['/usr/bin/', '/usr/sbin/'],
      require => Package[$nagios::params::nagios_version],
      notify  => Service[$nagios::params::nagios_version];

    'nagios_exec_fix_2':
      command => "dpkg-statoverride --update --add nagios www-data 770 /var/lib/${nagios::params::nagios_version}/spool",
      unless  => "dpkg-statoverride --list /var/lib/${nagios::params::nagios_version}/spool",
      path    => ['/usr/bin/', '/usr/sbin/'],
      require => Package[$nagios::params::nagios_version],
      notify  => Service[$nagios::params::nagios_version];

    'nagios_exec_fix_3':
      command => "dpkg-statoverride --update --add nagios www-data 770 /var/lib/${nagios::params::nagios_version}/spool/checkresults",
      unless  => "dpkg-statoverride --list /var/lib/${nagios::params::nagios_version}/spool/checkresults",
      path    => ['/usr/bin/', '/usr/sbin/'],
      require => Package[$nagios::params::nagios_version],
      notify  => Service[$nagios::params::nagios_version];
  }

  file { 'nagios_confd':
    ensure => directory,
    path   => "/etc/${nagios::params::nagios_version}/conf.d/",
    mode   => '0644',
    owner  => root,
    group  => nagios;
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

  $nagios_command_default = {
    'http_port' => {
      'command_line' => '$USER1$/check_http -p $ARG1$ -H $HOSTADDRESS$ -I $HOSTADDRESS$ -a \'$ARG2$\''
    },
    'https_port' => {
      'command_line' => '$USER1$/check_http --ssl -p $ARG1$ -H $HOSTADDRESS$ -I $HOSTADDRESS$ -a \'$ARG2$\' -C 60,30'
    },
    'http_port_extra' => {
      'command_line' => '$USER1$/check_http -p $ARG1$ -H $HOSTADDRESS$ -I $HOSTADDRESS$ -a \'$ARG2$\' -u \'$ARG3$\' -e \'$ARG4$\''
    },
    'https_port_extra' => {
      'command_line' => '$USER1$/check_http --ssl -p $ARG1$ -H $HOSTADDRESS$ -I $HOSTADDRESS$ -a \'$ARG2$\' -u \'$ARG3$\' -e \'$ARG4$\' -C 60,30'
    },
    'oslo_healthcheck' => {
      'command_line' => '$USER1$/check_http -p $ARG1$ -H $HOSTADDRESS$ -I $HOSTADDRESS$  -u \'/healthcheck\' -e \'OK\''
    },
    'oslo_healthcheck_https' => {
      'command_line' => '$USER1$/check_http --ssl -p $ARG1$ -H $HOSTADDRESS$ -I $HOSTADDRESS$  -u \'/healthcheck\' -e \'OK\' -C 60,30'
    },
    'check_ping2' => {
      'command_line' => '$USER1$/check_ping -H $ARG1$ -w 5000,100% -c 5000,100% -p 1'
    },
  }

  $nagios_command_real = merge($nagios_command_default, $nagios_command)
  create_resources('nagios::command', $nagios_command_real)

}
