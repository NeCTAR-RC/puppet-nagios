# Config for generating contact and command resources for
# Nagios/Slack integration
define nagios::slack_site {

  include nagios::slack

  $slack_api_domain = hiera('slack_api_domain')
  $slack_api_token = hiera('slack_api_token')

  nagios_contact { "slack-${name}":
    alias                         => "Slack ${name}",
    tag                           => $::environment,
    host_notification_commands    => "notify-host-by-slack-${name}",
    service_notification_commands => "notify-service-by-slack-${name}",
    host_notification_period      => '24x7',
    service_notification_period   => '24x7',
    host_notification_options     => 'd,r',
    service_notification_options  => 'w,u,c,r'
  }

  nagios_command { "notify-host-by-slack-${name}":
    tag          => $::environment,
    command_line => "/usr/local/bin/slack-nagios --domain ${slack_api_domain} --token ${slack_api_token} -field slack_channel=\"#alerts-${name}\" -field HOSTALIAS=\"\$HOSTNAME\$\" -field HOSTSTATE=\"\$HOSTSTATE\$\" -field HOSTOUTPUT=\"\$HOSTOUTPUT\$\" -field NOTIFICATIONTYPE=\"\$NOTIFICATIONTYPE\$\""
  }

  nagios_command { "notify-service-by-slack-${name}":
    tag          => $::environment,
    command_line => "/usr/local/bin/slack-nagios --domain ${slack_api_domain} --token ${slack_api_token} -field slack_channel=\"#alerts-${name}\" -field HOSTALIAS=\"\$HOSTNAME\$\" -field SERVICEDESC=\"\$SERVICEDESC\$\" -field SERVICESTATE=\"\$SERVICESTATE\$\" -field SERVICEOUTPUT=\"\$SERVICEOUTPUT\$\" -field NOTIFICATIONTYPE=\"\$NOTIFICATIONTYPE\$\""
  }

}
