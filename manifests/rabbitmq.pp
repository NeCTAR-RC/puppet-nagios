class nagios::rabbitmq {

  package { 'libnagios-plugin-perl':
    ensure  => 'latest',
    require => Package['nagios-plugins-basic'],
  }

  package { 'libwww-perl':
    ensure => present,
  }

  package { 'libjson-perl':
    ensure => present,
  }

  package { 'liburi-perl':
    ensure => present,
  }

  file { '/usr/lib/nagios/plugins/check_rabbitmq_aliveness':
    ensure  => file,
    owner   => root,
    group   => root,
    mode    => '0755',
    source  => 'puppet:///modules/nagios/rabbitmq/check_rabbitmq_aliveness',
    require => Package['nagios-plugins-basic'],
  }

  file { '/usr/lib/nagios/plugins/check_rabbitmq_objects':
    ensure  => file,
    owner   => root,
    group   => root,
    mode    => '0755',
    source  => 'puppet:///modules/nagios/rabbitmq/check_rabbitmq_objects',
    require => Package['nagios-plugins-basic'],
  }

  file { '/usr/lib/nagios/plugins/check_rabbitmq_overview':
    ensure  => file,
    owner   => root,
    group   => root,
    mode    => '0755',
    source  => 'puppet:///modules/nagios/rabbitmq/check_rabbitmq_overview',
    require => Package['nagios-plugins-basic'],
  }

  file { '/usr/lib/nagios/plugins/check_rabbitmq_queue':
    ensure  => file,
    owner   => root,
    group   => root,
    mode    => '0755',
    source  => 'puppet:///modules/nagios/rabbitmq/check_rabbitmq_queue',
    require => Package['nagios-plugins-basic'],
  }

  file { '/usr/lib/nagios/plugins/check_rabbitmq_server':
    ensure  => file,
    owner   => root,
    group   => root,
    mode    => '0755',
    source  => 'puppet:///modules/nagios/rabbitmq/check_rabbitmq_server',
    require => Package['nagios-plugins-basic'],
  }

}
