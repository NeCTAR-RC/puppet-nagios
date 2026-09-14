#Type to create nagios check commands.
#
# @param check_command The command line nrpe runs for this check. Pass a
#   Sensitive value when it embeds credentials: the rendered config file is
#   then also treated as Sensitive, so puppet neither logs nor diffs it.
define nagios::nrpe::command (
  Variant[String, Sensitive[String]] $check_command,
) {
  if $facts['os']['family'] == 'Debian' {
    include apt

    Class['Apt::Update'] -> Package <| tag == 'nrpe' |>
  }
  else {
    Package <| tag == 'nrpe' |>
  }

  File <| tag == 'nrpe' |>
  Service <| tag == 'nrpe' |>

  # Templates cannot render a Sensitive value, so unwrap it for the template
  # and re-wrap the rendered content when the input was Sensitive.
  $command_line = $check_command ? {
    Sensitive => $check_command.unwrap,
    default   => $check_command,
  }

  $content = $check_command ? {
    Sensitive => Sensitive(template('nagios/nrpe_command.erb')),
    default   => template('nagios/nrpe_command.erb'),
  }

  file { "/etc/nagios/nrpe.d/${name}.cfg":
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    require => [Package['nagios-nrpe-server'], File['/etc/nagios/nrpe.d'],],
    notify  => Service['nagios-nrpe-server'],
    content => $content;
  }
}
