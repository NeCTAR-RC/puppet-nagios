# Nagios service group
define nagios::servicegroup (
  $description          = $name,
  $members              = undef,
  $servicegroup_members = undef,
  $notes                = undef,
  $notes_url            = undef,
  $action_url           = undef,
  $register             = undef,
  $use                  = undef,
) {

  include puppet

  @@nagios_servicegroup {
    $name:
      tag                  => $puppet::config_environment,
      alias                => $description,
      members              => $members,
      notes                => $notes,
      notes_url            => $notes_url,
      action_url           => $action_url,
      register             => $register,
      servicegroup_members => $servicegroup_members,
      use                  => $use,
  }
}
