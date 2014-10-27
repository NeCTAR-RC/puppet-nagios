class nagios::server_external (
  $puppetdb_host,
  $puppetdb_port=8081,
  $naginator_timeout=60,
  $use_ssl=true,
  ){

  $naginator = hiera('nagios::naginator', {})

  $nagios_pkgs = [ 'nagios3', 'nagios-images']

  package { $nagios_pkgs:
    ensure => present,
    notify => Exec['nagios_exec_fix', 'nagios_exec_fix1'],
  }

  service { 'nagios3':
    ensure => running,
  }

  package { ['python-externalnaginator']:
    ensure => absent,
  }

  package { ['python-external-naginator']:
    ensure => present,
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
    ensure  => absent,
  }

  cron { 'update-nagios-config':
    ensure  => present,
    command => "/usr/bin/external-naginator --update -c /etc/nagios3/naginator.ini --output-dir /etc/nagios3/conf.d/ --host ${puppetdb_host} --port ${puppetdb_port}",
    user    => 'root',
    minute  => '0',
    environment => 'PATH=/bin:/usr/bin:/usr/sbin:/usr/local/bin/',
    require => Package['python-external-naginator'],
  }

  file { '/etc/nagios3/extra.d':
    ensure => directory,
  }

  exec {
    'nagios_exec_fix':
      command => 'dpkg-statoverride --update --add nagios www-data 2710 /var/lib/nagios3/rw',
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

  file { 'nagios_confd':
    ensure  => directory,
    path    => '/etc/nagios3/conf.d/',
    mode    => '0644',
    owner   => root,
    group   => nagios;
  }

  @@nagios_servicegroup {
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
      command_line => '$USER1$/check_http -p $ARG1$ -H $HOSTADDRESS$ -I $HOSTADDRESS$ -a \'$ARG2$\'';
    'https_port':
      command_line => '$USER1$/check_http --ssl -p $ARG1$ -H $HOSTADDRESS$ -I $HOSTADDRESS$';
  }
}
