# Set up the nrpe service to report to servers nagios::hosts.
class nagios::nrpe {

  $nagios_hosts = hiera('nagios::hosts', [])

  $nrpe = $::osfamily ? {
    'RedHat' => 'nrpe',
    'Debian' => 'nagios-nrpe-server',
    default  => 'nagios-nrpe-server',
  }

  $nrpe_user = $::osfamily ? {
    'RedHat' => 'nrpe',
    'Debian' => 'nagios',
    default  => 'nagios',
  }

  $nagios_plugin = $::osfamily ? {
    'RedHat' => 'nagios-plugins',
    'Debian' => 'monitoring-plugins',
    default  => 'monitoring-plugins',
  }

  $nrpe_plugin = $::osfamily ? {
    'RedHat' => 'nagios-plugins-nrpe',
    'Debian' => 'nagios-nrpe-plugin',
    default  => 'nagios-nrpe-plugin',
  }

  $nagios_plugins_contrib = $::osfamily ? {
    'RedHat' => 'nagios-plugins-all',
    'Debian' => 'nagios-plugins-contrib',
    default  => 'nagios-plugins-contrib',
  }

  @package {
    $nrpe :
      ensure => present,
      alias  => 'nagios-nrpe-server',
      tag    => 'nrpe';
    $nrpe_plugin :
      ensure => present,
      alias  => 'nagios-nrpe-plugin',
      tag    => 'nrpe';
    $nagios_plugin :
      ensure => present,
      tag    => 'nrpe';
    $nagios_plugins_contrib :
      ensure => present,
      alias  => 'nagios-plugins-contrib',
      tag    => 'nrpe';
  }

  if ($::osfamily == 'RedHat') and ($::architecture == 'x86_64') {
    @file { '/usr/lib/nagios':
      ensure  => link,
      target  => '/usr/lib64/nagios',
      require => Package['nagios-nrpe-server'],
      tag     => 'nrpe',
    }
  }

  # check if client is running puppet 3
  $puppet3 = (versioncmp($::puppetversion,'4.0.0') < 0)
  if $puppet3 {
    $user_groups = ['users', 'puppet',]
  }
  else {
    $user_groups = ['users',]
  }

  @user { $nrpe_user:
    groups  => $user_groups,
    require => Package['nagios-nrpe-server'],
  }

  User <| title == $nrpe_user |>

  @service { $nrpe :
    ensure  => running,
    enable  => true,
    alias   => 'nagios-nrpe-server',
    require => Package['nagios-nrpe-server'],
    tag     => 'nrpe',
  }

  @file { '/etc/nagios/nrpe.cfg':
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    require => Package['nagios-nrpe-server'],
    notify  => Service['nagios-nrpe-server'],
    content => template('nagios/nrpe.erb'),
    tag     => 'nrpe',
  }

  $plugin_dirs = ['/etc/nagios-plugins', '/etc/nagios-plugins/config',
                  '/etc/nagios', '/etc/nagios/nrpe.d',]

  file { $plugin_dirs:
    ensure => directory,
    mode   => '0755',
    owner  => 'root',
    group  => 'root',
  }

  file { '/etc/nagios-plugins/config/check_nrpe.cfg':
    owner   => root,
    group   => root,
    mode    => '0755',
    source  => 'puppet:///modules/nagios/check_nrpe.cfg',
    require => File[$plugin_dirs],
  }

  @file {
    '/usr/local/lib/nagios/':
      ensure => directory,
      owner  => root,
      group  => root,
      mode   => '0755',
      tag    => 'nrpe';
    '/usr/local/lib/nagios/plugins':
      ensure  => directory,
      owner   => root,
      group   => root,
      mode    => '0755',
      require => File['/usr/local/lib/nagios/'],
      tag     => 'nrpe';
  }
}
