# == Define: nagios::service
#
#  The Nagios type service. This resource type is autogenerated using the
#  model developed in Naginator, and all of the Nagios types are generated
#  using the same code and the same library.
#
#  This type generates Nagios configuration statements in Nagios-parseable
#  configuration files. By default, the statements will be added to
#  /etc/nagios/nagios_service.cfg, but you can send them to a different file
#  by setting their target attribute.
#
#  You can purge Nagios resources using the resources type, but only in the
#  default file locations. This is an architectural limitation.
#
define nagios::service (
  $ensure                       = present,
  $host_name                    = $facts['networking']['fqdn'],
  $mode                         = '0644',
  $action_url                   = undef,
  $active_checks_enabled        = undef,
  $business_impact              = undef,
  $check_freshness              = undef,
  $check_interval               = undef,
  $check_period                 = undef,
  $contact_groups               = undef,
  $contacts                     = undef,
  $display_name                 = undef,
  $event_handler                = undef,
  $event_handler_enabled        = undef,
  $failure_prediction_enabled   = undef,
  $first_notification_delay     = undef,
  $flap_detection_enabled       = undef,
  $flap_detection_options       = undef,
  $freshness_threshold          = undef,
  $high_flap_threshold          = undef,
  $hostgroup_name               = undef,
  $icon_image                   = undef,
  $icon_image_alt               = undef,
  $initial_state                = undef,
  $is_volatile                  = undef,
  $low_flap_threshold           = undef,
  $max_check_attempts           = undef,
  $notes                        = undef,
  $notes_url                    = undef,
  $notification_interval        = undef,
  $notification_options         = undef,
  $notification_period          = undef,
  $notifications_enabled        = undef,
  $obsess_over_service          = undef,
  $parallelize_check            = undef,
  $passive_checks_enabled       = undef,
  $poller_tag                   = undef,
  $process_perf_data            = undef,
  $register                     = undef,
  $retain_nonstatus_information = undef,
  $retain_status_information    = undef,
  $retry_interval               = undef,
  $service_description          = undef,
  $servicegroups                = undef,
  $stalking_options             = undef,
  $target                       = undef,
  $use                          = hiera('nagios::service::use', 'generic-service'),
  $check_command,
  # DEPRECATED PARAMETERS
  $normal_check_interval        = undef,
  $retry_check_interval         = undef,
) {

  include puppet
  include nagios::params

  if $normal_check_interval {
    warning('normal_check_interval parameter is deprecated. Please use check_interval instead.')
  }

  if $retry_check_interval {
    warning('retry_check_interval parameter is deprecated. Please use retry_interval instead.')
  }

  $_service_description = $service_description ? {
    undef    => $name,
    'absent' => $name,
    default  => $service_description
  }

  @@nagios_service { "${facts['networking']['fqdn']}_${name}":
    ensure                       => $ensure,
    action_url                   => $action_url,
    active_checks_enabled        => $active_checks_enabled,
    business_impact              => $business_impact,
    check_command                => $check_command,
    check_freshness              => $check_freshness,
    check_interval               => $check_interval,
    check_period                 => $check_period,
    contact_groups               => $contact_groups,
    contacts                     => $contacts,
    display_name                 => $display_name,
    event_handler                => $event_handler,
    event_handler_enabled        => $event_handler_enabled,
    failure_prediction_enabled   => $failure_prediction_enabled,
    first_notification_delay     => $first_notification_delay,
    flap_detection_enabled       => $flap_detection_enabled,
    flap_detection_options       => $flap_detection_options,
    freshness_threshold          => $freshness_threshold,
    high_flap_threshold          => $high_flap_threshold,
    host_name                    => $host_name,
    hostgroup_name               => $hostgroup_name,
    icon_image                   => $icon_image,
    icon_image_alt               => $icon_image_alt,
    initial_state                => $initial_state,
    is_volatile                  => $is_volatile,
    low_flap_threshold           => $low_flap_threshold,
    max_check_attempts           => $max_check_attempts,
    mode                         => $mode,
    normal_check_interval        => $normal_check_interval,
    notes                        => $notes,
    notes_url                    => $notes_url,
    notification_interval        => $notification_interval,
    notification_options         => $notification_options,
    notification_period          => $notification_period,
    notifications_enabled        => $notifications_enabled,
    obsess_over_service          => $obsess_over_service,
    parallelize_check            => $parallelize_check,
    passive_checks_enabled       => $passive_checks_enabled,
    poller_tag                   => $poller_tag,
    process_perf_data            => $process_perf_data,
    register                     => $register,
    retain_nonstatus_information => $retain_nonstatus_information,
    retain_status_information    => $retain_status_information,
    retry_check_interval         => $retry_check_interval,
    retry_interval               => $retry_interval,
    servicegroups                => $servicegroups,
    stalking_options             => $stalking_options,
    target                       => $target,
    use                          => $use,
    tag                          => $puppet::config_environment,
    notify                       => Service[$nagios::params::nagios_version],
    service_description          => $_service_description,
  }
}
