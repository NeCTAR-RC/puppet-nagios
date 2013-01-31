class nagios {

  package {'nagios-plugins-basic':
    ensure => present,
  }

  package {'libipc-run-perl':
    ensure => present,
  }

  user {'nagios':
    ensure     => present,
    gid        => nagios,
    groups     => ['users', 'puppet'],
    shell      => '/bin/false',
    home       => '/var/lib/nagios',
  }
  file {'/home/nagios':
    ensure => absent,
  }
  
  file {'/home/nagios/.ssh':
    ensure  => absent,
  }

  file {'/home/nagios/.ssh/authorized_keys':
    ensure  => absent,
  }

  file {'/home/nagios/libexec':
    ensure  => absent,
  }

  file { '/usr/lib/nagios/plugins/check_md_raid':
    ensure => absent,
  }
  file { '/usr/lib/nagios/plugins/check_memcached.py':
    ensure  => absent,
  }

  file { '/etc/sudoers.d/sudoers_nagios':
    owner   => 'root',
    group   => 'root',
    mode    => 440,
    source  => 'puppet:///modules/nagios/sudoers_nagios',
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

define nagios::command ($check_command)
{
  file { "/etc/nagios3/conf.d/${name}.cfg":
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    notify  => Service['nagios3'],
    content => template('nagios/nagios_command.erb');
  }

}
