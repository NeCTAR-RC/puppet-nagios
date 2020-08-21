# Set up the Nagios NRDP PHP application
class nagios::nrdp inherits nagios::params {

  # Installed from https://github.com/NagiosEnterprises/nrdp
  # but with one change to the code:
  #
  # +++ nrdp/plugins/nagioscorepassivecheck/nagioscorepassivecheck.inc.php
  # @@ -247,9 +247,9 @@
  # -    $mod_changed = chmod($check_file, 0770);
  # +    $mod_changed = chmod($check_file, 0664);
  #
  # To allow nagios to read the stat files written by Apache without having to
  # mess with the Nagios user groups

  $nrdp_tokens = hiera('nagios::nrdp_tokens', [])

  file { "/var/lib/${nagios_version}/tmp":
    ensure => directory,
    mode   => '0770',
    owner  => 'nagios',
    group  => 'www-data',
  }

  file { [ '/opt/nrdp',
      '/opt/nrdp/includes',
      '/opt/nrdp/plugins',
      '/opt/nrdp/plugins/nagioscorecmd',
      '/opt/nrdp/plugins/nagioscorepassivecheck']:
    ensure => directory,
    mode   => '0755',
    owner  => 'root',
    group  => 'root',
  }
  -> file { '/opt/nrdp/config.inc.php':
    content => template('nagios/nrdp-config.inc.php.erb'),
  }
  -> file {
    '/opt/nrdp/index.php':
      source => 'puppet:///modules/nagios/nrdp/server/index.php';
    '/opt/nrdp/includes/constants.inc.php':
      source => 'puppet:///modules/nagios/nrdp/server/includes/constants.inc.php';
    '/opt/nrdp/includes/jquery-3.2.1.min.js':
      source => 'puppet:///modules/nagios/nrdp/server/includes/jquery-3.2.1.min.js';
    '/opt/nrdp/includes/bootstrap.bundle.min.js':
      source => 'puppet:///modules/nagios/nrdp/server/includes/bootstrap.bundle.min.js';
    '/opt/nrdp/includes/utils.inc.php':
      source => 'puppet:///modules/nagios/nrdp/server/includes/utils.inc.php';
    '/opt/nrdp/includes/bootstrap.min.css':
      source => 'puppet:///modules/nagios/nrdp/server/includes/bootstrap.min.css';
    '/opt/nrdp/plugins/nagioscorecmd/nagioscorecmd.inc.php':
      source => 'puppet:///modules/nagios/nrdp/server/plugins/nagioscorecmd/nagioscorecmd.inc.php';
    '/opt/nrdp/plugins/nagioscorepassivecheck/nagioscorepassivecheck.inc.php':
      source => 'puppet:///modules/nagios/nrdp/server/plugins/nagioscorepassivecheck/nagioscorepassivecheck.inc.php';
  }

  file { '/etc/apache2/conf-available/nrdp.conf':
    source => 'puppet:///modules/nagios/nrdp/apache-nrdp.conf',
    mode   => '0644',
    owner  => 'root',
    group  => 'root',
  }

  if defined(Class['::apacheold']) {
    exec { '/usr/sbin/a2enconf nrdp':
      creates => '/etc/apache2/conf-enabled/nrdp.conf',
      notify  => Service['apache2'],
      require => File['/etc/apache2/conf-available/nrdp.conf'],
    }
  } else {
    ::apache::custom_config {'nrdp':
      source => '/etc/apache2/conf-available/nrdp.conf'
    }
  }
}
