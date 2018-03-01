define nagios::contact (
  $email                         = undef,
  $host_notification_commands    = 'notify-host-by-email',
  $host_notification_options     = 'd,r',
  $host_notification_period,
  $service_notification_commands = 'notify-service-by-email',
  $service_notification_options  = 'w,u,c,r',
  $service_notification_period,
) {
  $config_environment = hiera('puppet::config_environment', $::environment)

  if ($email == undef) {
    $contact_email = $name
  } else {
    $contact_email = $email
  }

 nagios_contact {
    $name:
      tag                           => $config_environment,
      alias                         => $name,
      email                         => $contact_email,
      host_notification_commands    => $host_notification_commands,
      host_notification_options     => $host_notification_options,
      host_notification_period      => $host_notification_period,
      service_notification_commands => $service_notification_commands,
      service_notification_options  => $service_notification_options,
      service_notification_period   => $service_notification_period,
 }
}
