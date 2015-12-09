class nagios::slack {

  ensure_packages(['libwww-perl', 'libcrypt-ssleay-perl'])

  file { '/usr/local/bin/slack-nagios':
    ensure => file,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
    source => 'puppet:///modules/nagios/slack-nagios',
  }

}
