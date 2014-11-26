# Set up the nrpe service to report to servers nagios::hosts.
class nagios::nrpe {

  $nagios_hosts = hiera('nagios::hosts', [])

  $nrpe_package = $::osfamily ? {
    RedHat  =>  'nrpe',
    Debian  =>  'nagios-nrpe-server',
    default =>  'nagios-nrpe-server',
  }

  $nrpe_plugin = $::osfamily ? {
    RedHat  =>  'nagios-plugins-nrpe',
    Debian  =>  'nagios-nrpe-plugin',
    default =>  'nagios-nrpe-plugin',
  }

  $nagios_plugins_contrib = $::osfamily ? {
    RedHat  =>  'nagios-plugins-all',
    Debian  =>  'nagios-plugins-contrib',
    default  =>  'nagios-plugins-contrib',
  }

  @package {
    $nrpe_package :
      ensure => present,
      alias  => 'nagios-nrpe-server',
      tag    => 'nrpe';
    $nrpe_plugin :
      ensure => present,
      alias  => 'nagios-nrpe-plugin',
      tag    => 'nrpe';
    'nagios-plugins':
      ensure => present,
      tag    => 'nrpe';
    $nagios_plugins_contrib :
      ensure => present,
      alias  => 'nagios-plugins-contrib',
      tag    => 'nrpe';
  }

  user { 'nagios':
    groups  => ['users', 'puppet'],
    require => Package['nagios-nrpe-server'],
  }

  @service { $nrpe_package :
    ensure  => running,
    require => Package['nagios-nrpe-server'],
    tag     => 'nrpe',
  }

  @file { '/etc/nagios/nrpe.cfg':
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    #require => Package['nagios-nrpe-server'],
    #notify  => Service['nagios-nrpe-server'],
    require => Package[ $nrpe_package ],
    notify  => Service[ $nrpe_package ],
    content => template('nagios/nrpe.erb'),
    tag     => 'nrpe',
  }

  $plugin_dirs = ['/etc/nagios-plugins', '/etc/nagios-plugins/config',
                  '/etc/nagios/nrpe.d',]

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

