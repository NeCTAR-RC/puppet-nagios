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

  file { '/usr/local/lib/nagios/plugins/check_netapp_ontapi':
    ensure => absent,
  }

  file { 'check_netapp_ontap':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    path    => '/usr/local/lib/nagios/plugins/check_netapp_ontap',
    source  => 'puppet:///modules/nagios/check_netapp_ontap.pl',
    require => File['/usr/local/lib/nagios'],
  }

  nagios::command { 'check_netapp_ontap':
    check_command => 'perl /usr/local/lib/nagios/plugins/check_netapp_ontap -H \'$ARG1$\' -u \'$ARG2$\' -p \'$ARG3$\' -o \'$ARG4$\'',
    require       => File['check_netapp_ontap'],
  }

  nagios::command { 'check_netapp_ontap_exclude':
    check_command => 'perl /usr/local/lib/nagios/plugins/check_netapp_ontap -H \'$ARG1$\' -u \'$ARG2$\' -p \'$ARG3$\' -o \'$ARG4$\' -m exclude,\'$ARG5$\'',
    require       => File['check_netapp_ontap'],
  }

  $host = hiera('netapp::host')

  @@nagios_host { $host:
    use     => hiera('nagios::host::use', 'generic-host'),
    target  => '/etc/nagios3/conf.d/nagios_host.cfg',
    tag     => $environment,
    require => File['nagios_confd'],
    notify  => Service['nagios3'],
  }

  nagios::checks::netapp::host { $host:
    require => Nagios::Command['check_netapp_ontap'],
  }
}

define nagios::checks::netapp::host {

  $user = hiera('netapp::user')
  $password = hiera('netapp::password')

  nagios::service { "${name}_aggregate":
    host_name           => $name,
    check_command       => "check_netapp_ontap!$name!$user!$password!aggregate_health",
    service_description => 'aggregate_health',
  }
  nagios::service { "${name}_snapmirror":
    host_name           => $name,
    check_command       => "check_netapp_ontap!$name!$user!$password!snapmirror_health",
    service_description => 'snapmirror_health',
  }
  nagios::service { "${name}_snapshot":
    host_name           => $name,
    check_command       => "check_netapp_ontap!$name!$user!$password!snapshot_health",
    service_description => 'snapshot_health',
  }
  nagios::service { "${name}_filer_hardware":
    host_name           => $name,
    check_command       => "check_netapp_ontap!$name!$user!$password!filer_hardware_health",
    service_description => 'filer_hardware_health',
  }
  nagios::service { "${name}_interface":
    host_name           => $name,
    check_command       => "check_netapp_ontap!$name!$user!$password!interface_health",
    service_description => 'interface_health',
  }
  nagios::service { "${name}_port":
    host_name           => $name,
    check_command       => "check_netapp_ontap!$name!$user!$password!port_health",
    service_description => 'port_health',
  }
  nagios::service { "${name}_alarms":
    host_name           => $name,
    check_command       => "check_netapp_ontap_exclude!$name!$user!$password!netapp_alarms!aggr_root",
    service_description => 'netapp_alarms',
  }
  nagios::service { "${name}_cluster":
    host_name           => $name,
    check_command       => "check_netapp_ontap!$name!$user!$password!cluster_health",
    service_description => 'cluster_health',
  }
  nagios::service { "${name}_disk":
    host_name           => $name,
    check_command       => "check_netapp_ontap!$name!$user!$password!disk_health",
    service_description => 'disk_health',
  }
  nagios::service { "${name}_volume":
    host_name           => $name,
    check_command       => "check_netapp_ontap!$name!$user!$password!volume_health",
    service_description => 'volume_health',
  }

}
