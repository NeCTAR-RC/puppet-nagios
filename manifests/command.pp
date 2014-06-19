define nagios::command (
  $command_line = undef,
  $check_command = undef,
) {

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
      tag          => $environment,
      mode         => '0644',
      command_line => $command,
  }

}
