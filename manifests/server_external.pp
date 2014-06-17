class nagios::server_external (
  $puppetdb_host,
  $puppetdb_port,
  ){

  $nagios_pkgs = [ 'nagios3', 'nagios-images']

  package { $nagios_pkgs:
    ensure => present,
    notify => Exec['nagios_exec_fix', 'nagios_exec_fix1'],
  }

  service { 'nagios3':
    ensure => running,
  }

  file { '/etc/nagios3/nagios.cfg':
    ensure  => file,
    owner   => root,
    group   => root,
    mode    => '0644',
    source  => 'puppet:///modules/nagios/nagios.cfg',
    require => Package['nagios3'],
    notify  => Service['nagios3'],
  }

  file { '/etc/nagios3/naginator.ini':
    ensure  => file,
    owner   => root,
    group   => root,
    mode    => '0755',
    content => template('nagios/naginator.ini.erb'),
  }

  file { '/usr/local/sbin/update-nagios-config':
    ensure  => file,
    owner   => root,
    group   => root,
    mode    => '0755',
    content => template('nagios/update-nagios-config.erb'),
  }

  cron { 'update-nagios-config':
    ensure  => present,
    command => '/usr/local/sbin/update-nagios-config -d',
    user    => 'root',
    minute  => '*/10',
    environment => 'PATH=/bin:/usr/bin:/usr/sbin:/usr/local/bin/',
    require => File['/usr/local/sbin/update-nagios-config'],
  }

  file { '/etc/nagios3/extra.d':
    ensure => directory,
  }

  exec {
    'nagios_exec_fix':
      command => 'dpkg-statoverride --updaten --add nagios www-data 2710 /var/lib/nagios3/rw',
      unless  => 'dpkg-statoverride --list /var/lib/nagios3/rw',
      path    => ['/usr/bin/', '/usr/sbin/'],
      require => Package['nagios3'],
      notify  => Service['nagios3'];
    'nagios_exec_fix1':
      command => 'dpkg-statoverride --update --add nagios nagios 751 /var/lib/nagios3',
      unless  => 'dpkg-statoverride --list /var/lib/nagios3',
      path    => ['/usr/bin/', '/usr/sbin/'],
      require => Package['nagios3'],
      notify  => Service['nagios3'];
  }

  nagios_servicegroup {
    "openstack-endpoints":
      tag => $environment,
      alias => "The user facing endpoints.";
    "message-queues":
      tag => $environment,
      alias => "RabbitMQ and other queues.";
    "databases":
      tag => $environment,
      alias => "Database Servers.";
  }

  nagios::command {
    'http_port':
      command_line => '$USER1$/check_http -p $ARG1$ -H $HOSTADDRESS$ -I $HOSTADDRESS$';
    'https_port':
      command_line => '$USER1$/check_http --ssl -p $ARG1$ -H $HOSTADDRESS$ -I $HOSTADDRESS$';
  }
}
