class nagios::checks::iostat {

  package { 'sysstat':
    ensure => present;
  }

  file{ '/usr/local/lib/nagios/plugins/check_iostat':
    ensure => file,
    owner  => root,
    group  => root,
    mode   => '0755',
    source => 'puppet:///modules/nagios/check_iostat',
  }

  nagios::nrpe::service { 'check_iostat':
    check_command => '/usr/local/lib/nagios/plugins/check_iostat -d vdb -c 2,75,2 -w 1,60,1';
  }
}

