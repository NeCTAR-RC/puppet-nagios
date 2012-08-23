
class nagios::check::md_raid {

  nagios::nrpe::service {
    'check_md_raid':
      check_command => '/usr/lib/nagios/plugins/check_md_raid';
  }

  file { '/usr/local/lib/nagios/plugins/check_md_raid':
    ensure  => file,
    owner   => root,
    group   => root,
    mode    => '0755',
    source  => 'puppet:///modules/nagios/check_md_raid',
    require => File['/usr/local/lib/nagios/plugins/'];
  }
}
