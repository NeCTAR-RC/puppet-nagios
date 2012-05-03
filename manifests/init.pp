class nagios {
  
  package {'nagios-plugins-basic':
    ensure => present,
  }

   package {'libipc-run-perl':
    ensure => present,
  }
 
  user {'nagios':
    ensure     => present,
    gid        => 'users',
    groups     => ['users', 'puppet'],
    shell      => '/bin/bash',
    home       => '/home/nagios',
    managehome => true,
  }
  
  file {'/home/nagios/.ssh':
    ensure  => directory,
    owner   => nagios,
    mode    => '0600',
    require => User['nagios'],
  }
  
  file {'/home/nagios/.ssh/authorized_keys':
    ensure  => file,
    owner   => nagios,
    mode    => '0600',
    source  => 'puppet:///modules/nagios/nagios_authorized_keys',
    require => File['/home/nagios/.ssh'],
  }
  
  file {'/home/nagios/libexec':
    ensure  => symlink,
    target  => '/usr/lib/nagios/plugins',
    require => [ User['nagios'],
                 Package['nagios-plugins-basic']],
  }

  file { '/usr/lib/nagios/plugins/check_memcached.py':
    ensure  => file,
    owner   => root,
    group   => root,
    mode    => '0755',
    source  => 'puppet:///modules/nagios/check_memcached.py',
    require => Package['nagios-plugins-basic'],
  }

  file { '/etc/sudoers.d/sudoers_nagios':
    owner   => 'root',
    group   => 'root',
    mode    => 440,
    source  => 'puppet:///nagios/sudoers_nagios',
    require => Package['nagios-plugins-basic'],
  }


  if $virtual == "physical" {
    file { '/usr/lib/nagios/plugins/check_ipmi_sensor.pl':
      ensure  => file,
      owner   => root,
      group   => root,
      mode    => '0755',
      source  => 'puppet:///modules/nagios/check_ipmi_sensor.pl',
      require => Package['nagios-plugins-basic','libipc-run-perl'],
    }
  }

  
}
