class nagios::checks::iostat {

  include nagios

  package { 'sysstat':
    ensure => present;
  }

  file { '/usr/local/lib/nagios/plugins/check_iostat':
    ensure => file,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
    source => 'puppet:///modules/nagios/check_iostat',
  }

  nagios::nrpe::service { 'check_iostat':
    check_command => '/usr/local/lib/nagios/plugins/check_iostat -d vdb -c 2,75,2 -w 1,60,1';
  }
}

class nagios::checks::netapp {

  include nagios

  package { [ 'libwww-perl', 'libxml-perl' ]:
    ensure => installed,
  }

  file { '/usr/local/lib/site_perl':
    source  => 'puppet:///modules/nagios/netapp',
    recurse => true,
  }

  file { 'check_netapp_ontapi':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    path    => '/usr/local/lib/nagios/plugins/check_netapp_ontapi',
    source  => 'puppet:///modules/nagios/check_netapp_ontapi.pl',
    require => File['/usr/local/lib/nagios'],
  }

  nagios::command { 'check_netapp_ontapi':
    check_command => 'perl /usr/local/lib/nagios/plugins/check_netapp_ontapi -H \'$ARG1$\' -u \'$ARG2$\' -p \'$ARG3$\' -o \'$ARG4$\'',
    require       => File['check_netapp_ontapi'],
  }

  $host = hiera('netapp::host')
  nagios::checks::netapp::host { $host: }
}

define nagios::checks::netapp::host {

  $user = hiera('netapp::user')
  $password = hiera('netapp::password')

  nagios::service { "${name}_aggregate":
    check_command => "check_netapp_ontapi!$name!$user!$password!aggregate_health"
  }
  nagios::service { "${name}_snapmirror":
    check_command => "check_netapp_ontapi!$name!$user!$password!snapmirror_health"
  }
  nagios::service { "${name}_filer_hardware":
    check_command => "check_netapp_ontapi!$name!$user!$password!filer_hardware_health"
  }
  nagios::service { "${name}_interface":
    check_command => "check_netapp_ontapi!$name!$user!$password!interface_health"
  }
  nagios::service { "${name}_alarms":
    check_command => "check_netapp_ontapi!$name!$user!$password!netapp_alarms"
  }
  nagios::service { "${name}_cluster":
    check_command => "check_netapp_ontapi!$name!$user!$password!cluster_health"
  }
  nagios::service { "${name}_disk":
    check_command => "check_netapp_ontapi!$name!$user!$password!disk_health"
  }
}
