define nagios::command (
  $command_line = undef,
  $check_command = undef,
) {

  include puppet
  include nagios::params

  if ($command_line != undef) {
    $command = $command_line
  } else {
    if ($check_command != undef) {
      $command = $check_command
    } else {
      fail("Need to define either check_command or command_line")
    }
  }

  @@nagios_command {
    $name:
      tag          => $puppet::config_environment,
      mode         => '0644',
      target       => "/etc/${nagios::params::nagios_version}/conf.d/${name}.cfg",
      command_line => $command,
  }

}
