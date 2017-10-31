#Type to create the nagios config to poll nrpe checks.
define nagios::nrpe::service (
  $check_command,
  $check_period          = undef,
  $check_interval        = undef,
  $retry_interval        = undef,
  $max_check_attempts    = undef,
  $notification_interval = undef,
  $notification_period   = undef,
  $notification_options  = undef,
  $contact_groups        = undef,
  $servicegroups         = undef,
  $use                   = hiera('nagios::service::use', 'generic-service'),
  $service_description   = 'absent',
  $nrpe_command          = 'check_nrpe_1arg',
  # DEPRECATED PARAMETERS
  $normal_check_interval = undef,
  $retry_check_interval  = undef,
) {

  include ::nagios::nrpe

  if $normal_check_interval {
    warning('normal_check_interval parameter is deprecated. Please use check_interval instead.')
  }

  if $retry_check_interval {
    warning('retry_check_interval parameter is deprecated. Please use retry_interval instead.')
  }

  # Only add NRPE checks if this host is using NRPE
  if defined(Service[$::nagios::nrpe::nrpe]) {
    nagios::nrpe::command {
      $name:
        check_command => $check_command;
    }

    nagios::service { $name:
      check_command         => "${nrpe_command}!${name}",
      check_period          => $check_period,
      check_interval        => $check_interval,
      normal_check_interval => $normal_check_interval,
      retry_interval        => $retry_interval,
      retry_check_interval  => $retry_check_interval,
      max_check_attempts    => $max_check_attempts,
      notification_interval => $notification_interval,
      notification_period   => $notification_period,
      notification_options  => $notification_options,
      contact_groups        => $contact_groups,
      use                   => $use,
      service_description   => $service_description,
      servicegroups         => $servicegroups,
    }
  }
}
