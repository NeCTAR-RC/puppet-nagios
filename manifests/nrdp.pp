# Set up the Nagios NRDP PHP application
class nagios::nrdp {

  $nrdp_tokens = hiera('nagios::nrdp_tokens', [])

  file { '/var/lib/nagios3/tmp':
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

  file { '/opt/nrdp/config.inc.php':
    content => template('nagios/nrdp-config.inc.php.erb'),
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    require => File['/opt/nrdp'],
  }


  file { '/opt/nrdp/index.php':
    source  => 'puppet:///modules/nagios/nrdp/server/index.php',
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    require => File['/opt/nrdp'],
  }

  file { '/opt/nrdp/includes/utils.inc.php':
    source  => 'puppet:///modules/nagios/nrdp/server/includes/utils.inc.php',
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    require => File['/opt/nrdp/includes'],
  }

  file { '/opt/nrdp/includes/constants.inc.php':
    source  => 'puppet:///modules/nagios/nrdp/server/includes/constants.inc.php',
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    require => File['/opt/nrdp/includes'],
  }

  file { '/opt/nrdp/plugins/nagioscorecmd/nagioscorecmd.inc.php':
    source  => 'puppet:///modules/nagios/nrdp/server/plugins/nagioscorecmd/nagioscorecmd.inc.php',
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    require => File['/opt/nrdp/plugins/nagioscorecmd'],
  }

  file { '/opt/nrdp/plugins/nagioscorepassivecheck/nagioscorepassivecheck.inc.php':
    source  => 'puppet:///modules/nagios/nrdp/server/plugins/nagioscorepassivecheck/nagioscorepassivecheck.inc.php',
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    require => File['/opt/nrdp/plugins/nagioscorepassivecheck'],
  }

  if $::lsbdistcodename == 'precise' {
    file { '/etc/apache2/conf.d/nrdp.conf':
      source => 'puppet:///modules/nagios/nrdp/apache-nrdp.conf.precise',
      mode   => '0644',
      owner  => 'root',
      group  => 'root',
      notify => Service['apache2'],
    }
  }
  else {
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
}
