class nagios {

  file { '/etc/sudoers.d/sudoers_nagios':
    owner   => 'root',
    group   => 'root',
    mode    => 440,
    source  => 'puppet:///modules/nagios/sudoers_nagios',
    require => Package['nagios-plugins'],
  }

  if $virtual == "physical" {
    package {'libipc-run-perl':
      ensure => present,
    }

    file { '/usr/lib/nagios/plugins/check_ipmi_sensor.pl':
      ensure  => file,
      owner   => root,
      group   => root,
      mode    => '0755',
      source  => 'puppet:///modules/nagios/check_ipmi_sensor.pl',
      require => Package['nagios-plugins','libipc-run-perl'],
    }
  }

}

define nagios::command ($check_command) {
  file { "/etc/nagios3/conf.d/${name}.cfg":
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    notify  => Service['nagios3'],
    content => template('nagios/nagios_command.erb');
  }

}
