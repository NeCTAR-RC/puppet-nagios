class nagios {
  
  package {'nagios-plugins-basic':
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

}
