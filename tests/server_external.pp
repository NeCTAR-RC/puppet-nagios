#usage: run puppet apply with --noop
include stdlib

class {'nagios::server_external':
  puppetdb_host => 'localhost',
  extra_dirs    => ['test1','test2'],
}
