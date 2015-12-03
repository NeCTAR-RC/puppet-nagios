define nagios::contact (
  $email,
  $pushbullet_api_key            = undef,
  $host_notification_commands    = undef,
  $host_notification_options     = 'd,r',
  $host_notification_period,
  $service_notification_commands = undef,
  $service_notification_options  = 'w,u,c,r',
  $service_notification_period,
) {

  if $host_notification_commands {
    $real_host_notification_commands = $host_notification_commands
  } else {
    if $pushbullet_api_key {
      $real_host_notification_commands = 'notify-host-by-email,notify-host-by-pushbullet'
    } else {
      $real_host_notification_commands = 'notify-host-by-email'
    }
  }

  if $service_notification_commands {
    $real_service_notification_commands = $service_notification_commands
  } else {
    if $pushbullet_api_key {
      $real_service_notification_commands = 'notify-service-by-email,notify-service-by-pushbullet'
    } else {
      $real_service_notification_commands = 'notify-service-by-email'
    }
  }

  nagios_contact {
    $name:
      tag                           => $::environment,
      alias                         => $name,
      email                         => $email,
      pager                         => $pushbullet_api_key,
      host_notification_commands    => $real_host_notification_commands,
      host_notification_options     => $host_notification_options,
      host_notification_period      => $host_notification_period,
      service_notification_commands => $real_service_notification_commands,
      service_notification_options  => $service_notification_options,
      service_notification_period   => $service_notification_period,
  }
}
