class nagios::openstack-checks {

  include nova::api::nagios-checks
  include swift::proxy::nagios-checks
  include glance::registry::nagios-checks
  include keystone::nagios-checks
  include glance::nagios-checks

}
