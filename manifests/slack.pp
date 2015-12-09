# Nagios to slack integration
class nagios::slack {

  ensure_packages(['libwww-perl', 'libcrypt-ssleay-perl'])

  $slack_api_domain = hiera('slack_api_domain')
  $slack_api_token = hiera('slack_api_token')

  file { '/usr/local/bin/slack-nagios':
    ensure => file,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
    source => 'puppet:///modules/nagios/slack-nagios',
  }

}
