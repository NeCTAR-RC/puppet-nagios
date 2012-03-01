class nagios {
	
	package { 'nagios-plugins-basic':
		ensure => present,
	}

	user { 'nagios':
		ensure => present,
		gid => 'users',
		groups => 'users',
		shell => '/bin/bash',
		home => '/home/nagios',
		managehome => true,
		before => File['/home/nagios/.ssh'],
	}

	file { '/home/nagios/.ssh':
		ensure => directory,
		require => User['nagios'],
		mode => 0600,
		owner => 'nagios',
		before => File['/home/nagios/.ssh/authorized_keys'],
	}

	file { '/home/nagios/.ssh/authorized_keys':
		ensure => file,
		mode => 600,
		owner => 'nagios',
		require => File['/home/nagios/.ssh'],
		source => 'puppet:///modules/nagios/nagios_authorized_keys',
	}

	file { '/home/nagios/libexec':
		ensure => symlink,
		target => '/usr/lib/nagios/plugins',
		require => [User['nagios'],Package['nagios-plugins-basic']],
	}

}
