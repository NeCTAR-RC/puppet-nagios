#!/usr/bin/perl

use warnings;
use strict;
use NaServer;
use NaElement;
use Getopt::Long;
use POSIX;

##############################################
## DISK HEALTH
##############################################

sub get_disk_info {
	my $nahStorage = shift;
        my $nahDiskIterator = NaElement->new("storage-disk-get-iter");
        my $strActiveTag = "";
        my %hshDiskInfo;

        while(defined($strActiveTag)) {
                if ($strActiveTag ne "") {
                        $nahDiskIterator->child_add_string("tag", $strActiveTag);
                }

                $nahDiskIterator->child_add_string("max-records", 600);
                my $nahResponse = $nahStorage->invoke_elem($nahDiskIterator);
                validate_ontapi_response($nahResponse, "Failed filer health query: ");

                $strActiveTag = $nahResponse->child_get_string("next-tag");

                if ($nahResponse->child_get_string("num-records") == 0) {
                        last;
                }

                foreach my $nahDisk ($nahResponse->child_get("attributes-list")->children_get()) {
			my $strDiskName = $nahDisk->child_get_string("disk-name");
			$hshDiskInfo{$strDiskName}{'home-node'} = $nahDisk->child_get("disk-ownership-info")->child_get_string("home-node-name");
			$hshDiskInfo{$strDiskName}{'current-node'} = $nahDisk->child_get("disk-ownership-info")->child_get_string("owner-node-name");
			if (defined($nahDisk->child_get("disk-raid-info")->child_get("disk-aggregate-info"))) {
				$hshDiskInfo{$strDiskName}{'scrubbing'} = $nahDisk->child_get("disk-raid-info")->child_get("disk-aggregate-info")->child_get_string("is-media-scrubbing");
				$hshDiskInfo{$strDiskName}{'offline'} = $nahDisk->child_get("disk-raid-info")->child_get("disk-aggregate-info")->child_get_string("is-offline");
				$hshDiskInfo{$strDiskName}{'prefailed'} = $nahDisk->child_get("disk-raid-info")->child_get("disk-aggregate-info")->child_get_string("is-prefailed");
				$hshDiskInfo{$strDiskName}{'reconstructing'} = $nahDisk->child_get("disk-raid-info")->child_get("disk-aggregate-info")->child_get_string("is-reconstructing");
			} else {
                        	$hshDiskInfo{$strDiskName}{'scrubbing'} = "false";
                        	$hshDiskInfo{$strDiskName}{'offline'} = "false";
                        	$hshDiskInfo{$strDiskName}{'prefailed'} = "false";
                        	$hshDiskInfo{$strDiskName}{'reconstructing'} = "false";
                	}

			if ($nahDisk->child_get("disk-raid-info")->child_get("disk-outage-info")) {
				$hshDiskInfo{$strDiskName}{'outage'} = $nahDisk->child_get("disk-raid-info")->child_get("disk-outage-info")->child_get_string("reason");
			} else {
				$hshDiskInfo{$strDiskName}{'outage'} = "ok";
			}			
		}
	}

	return \%hshDiskInfo;
}

sub calc_disk_health {
	my $hrefDiskInfo = shift;
        my $intState = 0;
        my $strOutput;

	my @aryFDRWarning = ("bypassed", "label version", "labeled broken", "LUN resized", "missing", "predict failure", "rawsize shrank", "recovering", "sanitizing", "unassigned");
	my @aryFDRCritical = ("bad label", "failed", "init failed", "not responding", "unknown");

	foreach my $strDisk (keys %$hrefDiskInfo) {
		if (defined($hrefDiskInfo->{$strDisk}->{'home-node'}) && defined($hrefDiskInfo->{$strDisk}->{'current-node'})) {
			if ($hrefDiskInfo->{$strDisk}->{'home-node'} ne $hrefDiskInfo->{$strDisk}->{'current-node'}) { 
				my $strNewMessage = $strDisk . " is not on home node and is currently on " . $hrefDiskInfo->{$strDisk}->{'current-node'};
				$strOutput = get_nagios_description($strOutput, $strNewMessage);
				$intState = get_nagios_state($intState, 1);
			}
		}

		if (defined($hrefDiskInfo->{$strDisk}->{'scrubbing'}) && ($hrefDiskInfo->{$strDisk}->{'scrubbing'} eq "true")) {
			my $strNewMessage = $strDisk . " is scrubbing";
                        $strOutput = get_nagios_description($strOutput, $strNewMessage);
                        $intState = get_nagios_state($intState, 1);
		}

		if (defined($hrefDiskInfo->{$strDisk}->{'offline'}) && ($hrefDiskInfo->{$strDisk}->{'offline'} eq "true")) {
			my $strNewMessage = $strDisk . " is offline";
                        $strOutput = get_nagios_description($strOutput, $strNewMessage);
                        $intState = get_nagios_state($intState, 2);
                }

		if (defined($hrefDiskInfo->{$strDisk}->{'prefailed'}) && ($hrefDiskInfo->{$strDisk}->{'prefailed'} eq "true")) {
			my $strNewMessage = $strDisk . " is prefailed";
                        $strOutput = get_nagios_description($strOutput, $strNewMessage);
                        $intState = get_nagios_state($intState, 1);
                }

		if (defined($hrefDiskInfo->{$strDisk}->{'reconstructing'}) && ($hrefDiskInfo->{$strDisk}->{'reconstructing'} eq "true")) {
			my $strNewMessage = $strDisk . " is reconstructing";
                        $strOutput = get_nagios_description($strOutput, $strNewMessage);
                        $intState = get_nagios_state($intState, 1);
                }

		if ($hrefDiskInfo->{$strDisk}->{'outage'} ne "ok") {
			my $strNewMessage = $strDisk . " state is " . $hrefDiskInfo->{$strDisk}->{'outage'};
                        $strOutput = get_nagios_description($strOutput, $strNewMessage);
			
			my $bStateSet = 0;
			foreach my $strEntry (@aryFDRWarning) {
				if ($hrefDiskInfo->{$strDisk}->{'outage'} eq $strEntry) {
					$intState = get_nagios_state($intState, 1);
					$bStateSet = 1;
					last;
				} 
			}

			if (!$bStateSet) {
				foreach my $strEntry (@aryFDRCritical) {
                                	if ($hrefDiskInfo->{$strDisk}->{'outage'} eq $strEntry) {
                                        	$intState = get_nagios_state($intState, 2);
                                	}
                        	}
			}
                }
	}

	if (!(defined($strOutput))) {
                $strOutput = "OK - No problems found";
        }

	return $intState, $strOutput;
}

##############################################
## INTERFACE HEALTH
##############################################

sub get_interface_health {
	my $nahStorage = shift;
        my $nahIntIterator = NaElement->new("net-port-get-iter");
        my $strActiveTag = "";
        my %hshInterfaceInfo;

	while(defined($strActiveTag)) {
                if ($strActiveTag ne "") {
                        $nahIntIterator->child_add_string("tag", $strActiveTag);
                }

                $nahIntIterator->child_add_string("max-records", 100);
                my $nahResponse = $nahStorage->invoke_elem($nahIntIterator);
                validate_ontapi_response($nahResponse, "Failed filer health query: ");

                $strActiveTag = $nahResponse->child_get_string("next-tag");

                if ($nahResponse->child_get_string("num-records") == 0) {
                        last;
                }
		
		foreach my $nahInt ($nahResponse->child_get("attributes-list")->children_get()) {
			my $strName = $nahInt->child_get_string("node") . "/" . $nahInt->child_get_string("port");
			if ($nahInt->child_get_string("is-administrative-up") eq "true") {
				$hshInterfaceInfo{$strName}{'admin-status'} = "up";
			} else {
				$hshInterfaceInfo{$strName}{'admin-status'} = "down";
			}

			$hshInterfaceInfo{$strName}{'link-status'} = $nahInt->child_get_string("link-status");
		}
	}

	$nahIntIterator = NaElement->new("net-interface-get-iter");
        $strActiveTag = "";

	while(defined($strActiveTag)) {
                if ($strActiveTag ne "") {
                        $nahIntIterator->child_add_string("tag", $strActiveTag);
                }

                $nahIntIterator->child_add_string("max-records", 100);
                my $nahResponse = $nahStorage->invoke_elem($nahIntIterator);
                validate_ontapi_response($nahResponse, "Failed filer health query: ");

                $strActiveTag = $nahResponse->child_get_string("next-tag");

                if ($nahResponse->child_get_string("num-records") == 0) {
                        last;
                }

		foreach my $nahInt ($nahResponse->child_get("attributes-list")->children_get()) {
			my $strName = $nahInt->child_get_string("home-node") . "/" . $nahInt->child_get_string("vserver") . $nahInt->child_get_string("interface-name");
			$hshInterfaceInfo{$strName}{'admin-status'} = $nahInt->child_get_string("administrative-status");
			$hshInterfaceInfo{$strName}{'link-status'} = $nahInt->child_get_string("operational-status");
			$hshInterfaceInfo{$strName}{'home-node'} = $nahInt->child_get_string("home-node");
			$hshInterfaceInfo{$strName}{'current-node'} = $nahInt->child_get_string("current-node");
			$hshInterfaceInfo{$strName}{'home-port'} = $nahInt->child_get_string("home-port");
			$hshInterfaceInfo{$strName}{'current-port'} = $nahInt->child_get_string("current-port");
                }
        }

	return \%hshInterfaceInfo;
}

sub calc_interface_health {
	my $hrefInterfaceInfo = shift;
        my $intState = 0;
        my $strOutput;

	foreach my $strInt (keys %$hrefInterfaceInfo) {
		if (!($hrefInterfaceInfo->{$strInt}->{'admin-status'} eq $hrefInterfaceInfo->{$strInt}->{'link-status'})) {
			my $strNewMessage = $strInt . " is " . $hrefInterfaceInfo->{$strInt}->{'link-status'} . " but admin status is " . $hrefInterfaceInfo->{$strInt}->{'admin-status'};
			$strOutput = get_nagios_description($strOutput, $strNewMessage);

			if ($hrefInterfaceInfo->{$strInt}->{'link-status'} eq "down") {
				$intState = get_nagios_state($intState, 2);
			} elsif ($hrefInterfaceInfo->{$strInt}->{'link-status'} eq "up") {
				$intState = get_nagios_state($intState, 1);
			} elsif ($hrefInterfaceInfo->{$strInt}->{'link-status'} eq "unknown") {
				$intState = get_nagios_state($intState, 3);
			} 
		}

		if (defined($hrefInterfaceInfo->{$strInt}->{'home-node'}) && defined($hrefInterfaceInfo->{$strInt}->{'current-node'})) {
			if (!($hrefInterfaceInfo->{$strInt}->{'home-node'} eq $hrefInterfaceInfo->{$strInt}->{'current-node'})) {
				my $strNewMessage = $strInt . " home is " . $hrefInterfaceInfo->{$strInt}->{'home-node'} . " but current node is " . $hrefInterfaceInfo->{$strInt}->{'current-node'};
				$strOutput = get_nagios_description($strOutput, $strNewMessage);
				$intState = get_nagios_state($intState, 1);
			}
		}

		if (defined($hrefInterfaceInfo->{$strInt}->{'home-port'}) && defined($hrefInterfaceInfo->{$strInt}->{'current-port'})) {
                        if (!($hrefInterfaceInfo->{$strInt}->{'home-port'} eq $hrefInterfaceInfo->{$strInt}->{'current-port'})) {
                                my $strNewMessage = $strInt . " home is " . $hrefInterfaceInfo->{$strInt}->{'home-port'} . " but current port is " . $hrefInterfaceInfo->{$strInt}->{'current-port'};
                                $strOutput = get_nagios_description($strOutput, $strNewMessage);
                                $intState = get_nagios_state($intState, 1);
                        }
                }
	}

	if (!(defined($strOutput))) {
                $strOutput = "OK - No problems found";
        }

        return $intState, $strOutput;
}

##############################################
## CLUSTER HEALTH
##############################################

sub get_cluster_health {
	my $nahStorage = shift;
        my $nahClusterIterator = NaElement->new("cluster-peer-health-info-get-iter");
        my $strActiveTag = "";
        my %hshClusterInfo;

	while(defined($strActiveTag)) {
                if ($strActiveTag ne "") {
                        $nahClusterIterator->child_add_string("tag", $strActiveTag);
                }

                $nahClusterIterator->child_add_string("max-records", 100);
                my $nahResponse = $nahStorage->invoke_elem($nahClusterIterator);
                validate_ontapi_response($nahResponse, "Failed filer health query: ");

                $strActiveTag = $nahResponse->child_get_string("next-tag");

                if ($nahResponse->child_get_string("num-records") == 0) {
                        last;
                }

		foreach my $nahNode ($nahResponse->child_get("attributes-list")->children_get()) {
			my $strName = $nahNode->child_get_string("originating-node");
			$hshClusterInfo{$strName}{'destination'} = $nahNode->child_get_string("destination-node");
			$hshClusterInfo{$strName}{'cluster-healthy'} = $nahNode->child_get_string("is-cluster-healthy");
			$hshClusterInfo{$strName}{'destination-available'} = $nahNode->child_get_string("is-destination-node-available");
			$hshClusterInfo{$strName}{'in-quorum'} = $nahNode->child_get_string("is-node-healthy");
		}
	}

	return \%hshClusterInfo;
}

sub calc_cluster_health {
	my $hrefClusterInfo = shift;
        my $intState = 0;
        my $strOutput;

        foreach my $strNode (keys %$hrefClusterInfo) {
		if ($hrefClusterInfo->{$strNode}->{'destination-available'} eq "false") {
			my $strNewMessage = $strNode . "->" . $hrefClusterInfo->{$strNode}->{'destination'} . " destination node is unavailable";
			$strOutput = get_nagios_description($strOutput, $strNewMessage);
                        $intState = get_nagios_state($intState, 2);
		} elsif ($hrefClusterInfo->{$strNode}->{'in-quorum'} eq "false") {
			my $strNewMessage = $strNode . "->" . $hrefClusterInfo->{$strNode}->{'destination'} . " originating node is not in quorum";
                        $strOutput = get_nagios_description($strOutput, $strNewMessage);
                        $intState = get_nagios_state($intState, 2);
                } elsif ($hrefClusterInfo->{$strNode}->{'cluster-healthy'} eq "false") {
			my $strNewMessage = $strNode . "->" . $hrefClusterInfo->{$strNode}->{'destination'} . " cluster peer relationship is unhealthy";
                        $strOutput = get_nagios_description($strOutput, $strNewMessage);
                        $intState = get_nagios_state($intState, 2);
                }
	}

	if (!(defined($strOutput))) {
                $strOutput = "OK - No problems found";
        }

        return $intState, $strOutput;	
}

##############################################
## NETAPP ALARMS
##############################################

sub get_netapp_alarms {
	my $nahStorage = shift;
        my $nahAlarmIterator = NaElement->new("dashboard-alarm-get-iter");
        my $strActiveTag = "";
        my %hshAlarms;

        while(defined($strActiveTag)) {
                if ($strActiveTag ne "") {
                        $nahAlarmIterator->child_add_string("tag", $strActiveTag);
                }

                $nahAlarmIterator->child_add_string("max-records", 100);
                my $nahResponse = $nahStorage->invoke_elem($nahAlarmIterator);
                validate_ontapi_response($nahResponse, "Failed filer health query: ");

                $strActiveTag = $nahResponse->child_get_string("next-tag");

                if ($nahResponse->child_get_string("num-records") == 0) {
                        last;
                }

		foreach my $nahAlarm ($nahResponse->child_get("attributes-list")->children_get()) {
			my $strName = $nahAlarm->child_get_string("node") . "/" . $nahAlarm->child_get_string("object-name") . "/" . $nahAlarm->child_get_string("dashboard-metric-type");
			$hshAlarms{$strName}{'value'} = $nahAlarm->child_get_string("last-value");
			$hshAlarms{$strName}{'state'} = $nahAlarm->child_get_string("state");
		}
        }

	$nahAlarmIterator = NaElement->new("diagnosis-alert-get-iter");
        $strActiveTag = "";

	while(defined($strActiveTag)) {
                if ($strActiveTag ne "") {
                        $nahAlarmIterator->child_add_string("tag", $strActiveTag);
                }

                $nahAlarmIterator->child_add_string("max-records", 100);
                my $nahResponse = $nahStorage->invoke_elem($nahAlarmIterator);
                validate_ontapi_response($nahResponse, "Failed filer health query: ");

                $strActiveTag = $nahResponse->child_get_string("next-tag");

                if ($nahResponse->child_get_string("num-records") == 0) {
                        last;
                }

                foreach my $nahAlarm ($nahResponse->child_get("attributes-list")->children_get()) {
			if (!($nahAlarm->child_get_string("acknowledge") eq "true" || $nahAlarm->child_get_string("suppress") eq "true")) {
				my $strName = $nahAlarm->child_get_string("node") . "/" . $nahAlarm->child_get_string("alerting-resource-name") . "/" . $nahAlarm->child_get_string("subsystem");
				$hshAlarms{$strName}{'value'} = $nahAlarm->child_get_string("probable-cause-description");
				$hshAlarms{$strName}{'state'} = $nahAlarm->child_get_string("perceived-severity");
			}
		}
	}

	return \%hshAlarms;
}

sub calc_netapp_alarm_health {
	my $hrefAlarmsInfo = shift;
        my $intState = 0;
        my $strOutput;

	foreach my $strAlarm (keys %$hrefAlarmsInfo) {
		if ($hrefAlarmsInfo->{$strAlarm}->{'state'} eq "critical") {
			my $strNewMessage = $strAlarm . " " . $hrefAlarmsInfo->{$strAlarm}->{'value'};
			$strOutput = get_nagios_description($strOutput, $strNewMessage);
                        $intState = get_nagios_state($intState, 2);
		} elsif ($hrefAlarmsInfo->{$strAlarm}->{'state'} ne "ok") {
			my $strNewMessage = $strAlarm . " " . $hrefAlarmsInfo->{$strAlarm}->{'value'};
			$strOutput = get_nagios_description($strOutput, $strNewMessage);
                        $intState = get_nagios_state($intState, 1);
		}
	}

	if (!(defined($strOutput))) {
                $strOutput = "OK - No problems found";
        }

        return $intState, $strOutput;
}

##############################################
## DISK SHELF HEALTH
##############################################

## HOPEFULLY UNREQUIRED!!!!

sub get_shelf_hardware {
	my $nahStorage = shift;
        my $nahShelfIterator = NaElement->new("system-node-get-iter");
        my $strActiveTag = "";
        my %hshShelfHardware;

        while(defined($strActiveTag)) {
                if ($strActiveTag ne "") {
                        $nahShelfIterator->child_add_string("tag", $strActiveTag);
                }

                $nahShelfIterator->child_add_string("max-records", 100);
                my $nahResponse = $nahStorage->invoke_elem($nahShelfIterator);
                validate_ontapi_response($nahResponse, "Failed filer health query: ");

                $strActiveTag = $nahResponse->child_get_string("next-tag");

                if ($nahResponse->child_get_string("num-records") == 0) {
                        last;
                }

		foreach my $nahNode ($nahResponse->child_get("attributes-list")->children_get()) {
			my $strNodeName = $nahNode->child_get_string("node");
			
		}
	}
}

sub calc_shelf_hardware_health {

}

##############################################
## FILER HEALTH
##############################################

sub get_filer_hardware { 
	my $nahStorage = shift;
	my $nahFilerIterator = NaElement->new("system-node-get-iter");
        my $strActiveTag = "";
        my %hshFilerHardware;

	while(defined($strActiveTag)) {
                if ($strActiveTag ne "") {
                        $nahFilerIterator->child_add_string("tag", $strActiveTag);
                }

		$nahFilerIterator->child_add_string("max-records", 100);
                my $nahResponse = $nahStorage->invoke_elem($nahFilerIterator);
                validate_ontapi_response($nahResponse, "Failed filer health query: ");

                $strActiveTag = $nahResponse->child_get_string("next-tag");

                if ($nahResponse->child_get_string("num-records") == 0) {
                        last;
                }

		foreach my $nahFilerObj ($nahResponse->child_get("attributes-list")->children_get()) {
			my $strNodeName = $nahFilerObj->child_get_string("node");
			$hshFilerHardware{$strNodeName . "/fan"}{'object'} = "fan";
			$hshFilerHardware{$strNodeName . "/fan"}{'count'} = $nahFilerObj->child_get_string("env-failed-fan-count");
			$hshFilerHardware{$strNodeName . "/fan"}{'message'} = $nahFilerObj->child_get_string("env-failed-fan-message");

			$hshFilerHardware{$strNodeName . "/psu"}{'object'} = "psu";
                        $hshFilerHardware{$strNodeName . "/psu"}{'count'} = $nahFilerObj->child_get_string("env-failed-power-supply-count");
                        $hshFilerHardware{$strNodeName . "/psu"}{'message'} = $nahFilerObj->child_get_string("env-failed-power-supply-message");

			$hshFilerHardware{$strNodeName . "/temp"}{'object'} = "temp";
                        $hshFilerHardware{$strNodeName . "/temp"}{'count'} = $nahFilerObj->child_get_string("env-over-temperature");

			$hshFilerHardware{$strNodeName . "/battery"}{'object'} = "battery";
                        $hshFilerHardware{$strNodeName . "/battery"}{'message'} = $nahFilerObj->child_get_string("nvram-battery-status");
		}
	}

	return \%hshFilerHardware;
}

sub calc_filer_hardware_health {
	my ($hrefFilerInfo, $strWarning, $strCritical) = @_;
        my $intState = 0;
        my $strOutput;
	my (@aryWarning, @aryCritical);

	if (defined($strWarning)) {
                @aryWarning = split(",", $strWarning);
        }

        if (defined($strCritical)) {
                @aryCritical = split(",", $strCritical);
        }

	foreach my $strFilerEntry (keys %$hrefFilerInfo) { 
		if ($hrefFilerInfo->{$strFilerEntry}{'object'} eq "fan") {
			if ($hrefFilerInfo->{$strFilerEntry}{'count'} > 0) {
				my $intStateSet = 2;
				foreach my $strWarnThresh (@aryWarning) {
					if ($strWarnThresh eq $hrefFilerInfo->{$strFilerEntry}{'object'}) {
						$intStateSet = 1;
					}
        			}

        			foreach my $strCritThresh (@aryCritical) {
					if ($strCritThresh eq $hrefFilerInfo->{$strFilerEntry}{'object'}) {
                                                $intStateSet = 2;
                                        }
        			}

				if ($intStateSet > 0) {
					my $strNewMessage = $strFilerEntry . " has " . $hrefFilerInfo->{$strFilerEntry}{'count'} . " failed fans";
                                	$strOutput = get_nagios_description($strOutput, $strNewMessage);
                                	$intState = get_nagios_state($intState, $intStateSet);
				}
			}
		} elsif ($hrefFilerInfo->{$strFilerEntry}{'object'} eq "psu") {
			if ($hrefFilerInfo->{$strFilerEntry}{'count'} > 0) {
				my $intStateSet = 2;
                                foreach my $strWarnThresh (@aryWarning) {
                                        if ($strWarnThresh eq $hrefFilerInfo->{$strFilerEntry}{'object'}) {
                                                $intStateSet = 1;
                                        }
                                }

                                foreach my $strCritThresh (@aryCritical) {
                                        if ($strCritThresh eq $hrefFilerInfo->{$strFilerEntry}{'object'}) {
                                                $intStateSet = 2;
                                        }
                                }

				if ($intStateSet > 0) {	
					my $strNewMessage = $strFilerEntry . " has " . $hrefFilerInfo->{$strFilerEntry}{'count'} . " failed power supplies";
                                	$strOutput = get_nagios_description($strOutput, $strNewMessage);
                                	$intState = get_nagios_state($intState, $intStateSet);
				}
			}
		} elsif ($hrefFilerInfo->{$strFilerEntry}{'object'} eq "temp") {
			if ($hrefFilerInfo->{$strFilerEntry}{'count'} eq "true") {
				my $intStateSet = 1;
                                foreach my $strWarnThresh (@aryWarning) {
                                        if ($strWarnThresh eq $hrefFilerInfo->{$strFilerEntry}{'object'}) {
                                                $intStateSet = 1;
                                        }
                                }

                                foreach my $strCritThresh (@aryCritical) {
                                        if ($strCritThresh eq $hrefFilerInfo->{$strFilerEntry}{'object'}) {
                                                $intStateSet = 2;
                                        }
                                }

				if ($intStateSet > 0) {
					my $strNewMessage = $strFilerEntry . " has breached the filer temperature warning threshold";
                                	$strOutput = get_nagios_description($strOutput, $strNewMessage);
					$intState = get_nagios_state($intState, $intStateSet);
				}
			}
		} elsif ($hrefFilerInfo->{$strFilerEntry}{'object'} eq "battery") {
			if (!($hrefFilerInfo->{$strFilerEntry}{'message'} eq "battery_ok" || $hrefFilerInfo->{$strFilerEntry}{'message'} eq "battery_fully_charged")) {
				my $intStateSet = 1;
				foreach my $strWarnThresh (@aryWarning) {
                                        if ($strWarnThresh eq $hrefFilerInfo->{$strFilerEntry}{'object'}) {
                                                $intStateSet = 1;
                                        }
                                }

                                foreach my $strCritThresh (@aryCritical) {
                                        if ($strCritThresh eq $hrefFilerInfo->{$strFilerEntry}{'object'}) {
                                                $intStateSet = 2;
                                        }
                                }

                                if ($intStateSet > 0) {
                                        my $strNewMessage = $strFilerEntry . " is currently in state " . $hrefFilerInfo->{$strFilerEntry}{'message'};
                                        $strOutput = get_nagios_description($strOutput, $strNewMessage);
                                        $intState = get_nagios_state($intState, $intStateSet);
                                }
			}
		}
	}

	if (!(defined($strOutput))) {
                $strOutput = "OK - No problems found";
        }

        return $intState, $strOutput;
}

##############################################
## SNAPMIRROR HEALTH
##############################################

sub get_snapmirror_lag {
	my $nahStorage = shift;
        my $nahSMIterator = NaElement->new("snapmirror-get-iter");
        my $strActiveTag = "";
        my %hshSMHealth;

        while(defined($strActiveTag)) {
                if ($strActiveTag ne "") {
                        $nahSMIterator->child_add_string("tag", $strActiveTag);
                }

                $nahSMIterator->child_add_string("max-records", 100);
                my $nahResponse = $nahStorage->invoke_elem($nahSMIterator);
                validate_ontapi_response($nahResponse, "Failed volume query: ");

                $strActiveTag = $nahResponse->child_get_string("next-tag");

                if ($nahResponse->child_get_string("num-records") == 0) {
                        last;
                }

		foreach my $nahSM ($nahResponse->child_get("attributes-list")->children_get()) {
			if ($nahSM->child_get_string("relationship-control-plane") eq "v2") {
				my $strSMName = $nahSM->child_get_string("destination-location");
                        	$hshSMHealth{$strSMName}{'source'} = $nahSM->child_get_string("destination-location");

				if ($nahSM->child_get_string("is-healthy") eq "false") {
					$hshSMHealth{$strSMName}{'health'} = $nahSM->child_get_string("unhealthy-reason");
				}
				
				if ($nahSM->child_get_string("lag-time")) { 
					$hshSMHealth{$strSMName}{'lag'} = $nahSM->child_get_string("lag-time");
				}
			}
		}
	}

	return \%hshSMHealth;
}

sub calc_snapmirror_health {
        my ($hrefSMInfo, $strWarning, $strCritical) = @_;
        my ($hrefWarnThresholds, $hrefCritThresholds) = snapmirror_threshold_converter($strWarning, $strCritical);
        my $intState = 0;
        my $strOutput;
	
	foreach my $strSM (keys %$hrefSMInfo) {
		if (defined($hrefSMInfo->{$strSM}->{'health'})) {
			my $strNewMessage = $strSM . "->" . $hrefSMInfo->{$strSM}->{'source'} . " is unhealthy: " . $hrefSMInfo->{$strSM}->{'health'};
                        $strOutput = get_nagios_description($strOutput, $strNewMessage);
                        $intState = get_nagios_state($intState, 1);
		}
		
		# Do lag check here
		my $bProcess = 1;
		if (defined($hrefCritThresholds->{'lag-time'}) && defined($hrefSMInfo->{$strSM}->{'lag'})) {
			if ($hrefSMInfo->{$strSM}->{'lag'} > $hrefCritThresholds->{'lag-time'}) {
				my $strFriendlyTime = seconds_to_time($hrefSMInfo->{$strSM}->{'lag'});
				my $strNewMessage = $strSM . "->" . $hrefSMInfo->{$strSM}->{'source'} . " lag time has reached " . $strFriendlyTime;
				$strOutput = get_nagios_description($strOutput, $strNewMessage);
                                $intState = get_nagios_state($intState, 2);
				$bProcess = 0;
			}
		}

		if (defined($hrefWarnThresholds->{'lag-time'}) && defined($hrefSMInfo->{$strSM}->{'lag'}) && $bProcess) {
			if ($hrefSMInfo->{$strSM}->{'lag'} > $hrefWarnThresholds->{'lag-time'}) {
				my $strFriendlyTime = seconds_to_time($hrefSMInfo->{$strSM}->{'lag'});
				my $strNewMessage = $strSM . "->" . $hrefSMInfo->{$strSM}->{'source'} . " lag time has reached " . $strFriendlyTime;
                                $strOutput = get_nagios_description($strOutput, $strNewMessage);
                                $intState = get_nagios_state($intState, 1);
                        }
		}
	}

	if (!(defined($strOutput))) {
                $strOutput = "OK - No problems found";
        }

	return $intState, $strOutput;
}

sub snapmirror_threshold_converter {
	my ($strWarning, $strCritical) = @_;
        my (%hshWarnThresholds, %hshCritThresholds, @aryWarning, @aryCritical, @aryStringsTemp);

        if (defined($strWarning)) {
                @aryWarning = split(",", $strWarning);
        }

        if (defined($strCritical)) {
                @aryCritical = split(",", $strCritical);
        }

        foreach my $strWarnThresh (@aryWarning) {
                if ($strWarnThresh =~ m/^[0-9]*[smhd]$/) {
                        $hshWarnThresholds{'lag-time'} = time_to_seconds($strWarnThresh);
                } elsif ($strWarnThresh =~ m/^[a-zA-Z]*$/) {
                        push(@aryStringsTemp, $strWarnThresh);
                }
        }

        $hshWarnThresholds{'strings'} = [@aryStringsTemp];
        undef(@aryStringsTemp);

	foreach my $strCritThresh (@aryCritical) {
                if ($strCritThresh =~ m/^[0-9]*[smhd]$/) {
                        $hshCritThresholds{'lag-time'} = time_to_seconds($strCritThresh);
                } elsif ($strCritThresh =~ m/^[a-zA-Z]*$/) {
                        push(@aryStringsTemp, $strCritThresh);
                }
        }
	
        $hshCritThresholds{'strings'} = [@aryStringsTemp];
	return \%hshWarnThresholds, \%hshCritThresholds;
}

##############################################
## AGGREGATE SPACE
##############################################

sub get_aggregate_space {
        my $nahStorage = shift;
        my $nahAggIterator = NaElement->new("aggr-get-iter");
        my $strActiveTag = "";
        my %hshAggUsage;

        while(defined($strActiveTag)) {
                if ($strActiveTag ne "") {
                        $nahAggIterator->child_add_string("tag", $strActiveTag);
                }

                $nahAggIterator->child_add_string("max-records", 100);
                my $nahResponse = $nahStorage->invoke_elem($nahAggIterator);
                validate_ontapi_response($nahResponse, "Failed volume query: ");

                $strActiveTag = $nahResponse->child_get_string("next-tag");

                if ($nahResponse->child_get_string("num-records") == 0) {
                        last;
                }

                foreach my $nahAgg ($nahResponse->child_get("attributes-list")->children_get()) {

                        my $strAggName = $nahAgg->child_get_string("aggregate-name");
                        my $strAggOwner = $nahAgg->child_get("aggr-ownership-attributes")->child_get_string("home-name");
                        $strAggName = $strAggOwner . "/" . $strAggName;

                        if ($nahAgg->child_get("aggr-raid-attributes")->child_get_string("state") ne "online") {
                                $hshAggUsage{$strAggName}{'state'} = $nahAgg->child_get("aggr-raid-attributes")->child_get_string("state");
                        } else {
                                $hshAggUsage{$strAggName}{'state'} = $nahAgg->child_get("aggr-raid-attributes")->child_get_string("state");
                                $hshAggUsage{$strAggName}{'space-total'} = $nahAgg->child_get("aggr-space-attributes")->child_get_string("size-total");
                                $hshAggUsage{$strAggName}{'space-used'} = $nahAgg->child_get("aggr-space-attributes")->child_get_string("size-used");
                                $hshAggUsage{$strAggName}{'inodes-total'} = $nahAgg->child_get("aggr-inode-attributes")->child_get_string("files-total");
                                $hshAggUsage{$strAggName}{'inodes-used'} = $nahAgg->child_get("aggr-inode-attributes")->child_get_string("files-used");
				$hshAggUsage{$strAggName}{'home-owner'} = $nahAgg->child_get("aggr-ownership-attributes")->child_get_string("home-name");
				$hshAggUsage{$strAggName}{'current-owner'} = $nahAgg->child_get("aggr-ownership-attributes")->child_get_string("owner-name");
                        }
                }
        }

        return \%hshAggUsage;
}

##############################################
## SNAPSHOT SPACE
##############################################

sub get_snap_space {
        my $nahStorage = shift;
        my $nahVolIterator = NaElement->new("volume-get-iter");
        my $strActiveTag = "";
        my %hshVolUsage;

        while(defined($strActiveTag)) {
                if ($strActiveTag ne "") {
                        $nahVolIterator->child_add_string("tag", $strActiveTag);
                }

                $nahVolIterator->child_add_string("max-records", 100);
                my $nahResponse = $nahStorage->invoke_elem($nahVolIterator);
                validate_ontapi_response($nahResponse, "Failed volume query: ");

                $strActiveTag = $nahResponse->child_get_string("next-tag");

                if ($nahResponse->child_get_string("num-records") == 0) {
                        last;
                }

                foreach my $nahVol ($nahResponse->child_get("attributes-list")->children_get()) {

                        my $strVolName = $nahVol->child_get("volume-id-attributes")->child_get_string("name");
                        my $strVolOwner = $nahVol->child_get("volume-id-attributes")->child_get_string("owning-vserver-name");
                        $strVolName = $strVolOwner . "/" . $strVolName;

                        if ($nahVol->child_get("volume-state-attributes")->child_get_string("state") ne "online") {
                                $hshVolUsage{$strVolName}{'state'} = $nahVol->child_get("volume-state-attributes")->child_get_string("state");
                        } else {
                                $hshVolUsage{$strVolName}{'state'} = $nahVol->child_get("volume-state-attributes")->child_get_string("state");
                                $hshVolUsage{$strVolName}{'space-total'} = $nahVol->child_get("volume-space-attributes")->child_get_string("size-available-for-snapshots");
                                $hshVolUsage{$strVolName}{'space-used'} = $nahVol->child_get("volume-space-attributes")->child_get_string("size-used-by-snapshots");
                                $hshVolUsage{$strVolName}{'inodes-total'} = $nahVol->child_get("volume-inode-attributes")->child_get_string("files-total");
                                $hshVolUsage{$strVolName}{'inodes-used'} = $nahVol->child_get("volume-inode-attributes")->child_get_string("files-used");
                        }
                }
        }

        return \%hshVolUsage;
}

##############################################
## VOLUME SPACE
##############################################

sub get_volume_space {
	my $nahStorage = shift;
	my $nahVolIterator = NaElement->new("volume-get-iter");
	my $strActiveTag = "";
	my %hshVolUsage;

	while(defined($strActiveTag)) {
		if ($strActiveTag ne "") {
                        $nahVolIterator->child_add_string("tag", $strActiveTag);
                }
		
		$nahVolIterator->child_add_string("max-records", 100);
		my $nahResponse = $nahStorage->invoke_elem($nahVolIterator);
                validate_ontapi_response($nahResponse, "Failed volume query: ");

		$strActiveTag = $nahResponse->child_get_string("next-tag");

                if ($nahResponse->child_get_string("num-records") == 0) {
                        last;
                }

		foreach my $nahVol ($nahResponse->child_get("attributes-list")->children_get()) {

			my $strVolName = $nahVol->child_get("volume-id-attributes")->child_get_string("name");
			my $strVolOwner = $nahVol->child_get("volume-id-attributes")->child_get_string("owning-vserver-name");
			$strVolName = $strVolOwner . "/" . $strVolName;

			if ($nahVol->child_get("volume-state-attributes")->child_get_string("state") ne "online") {
				$hshVolUsage{$strVolName}{'state'} = $nahVol->child_get("volume-state-attributes")->child_get_string("state");
			} else {
				$hshVolUsage{$strVolName}{'state'} = $nahVol->child_get("volume-state-attributes")->child_get_string("state");
				$hshVolUsage{$strVolName}{'space-total'} = $nahVol->child_get("volume-space-attributes")->child_get_string("size-total");
				$hshVolUsage{$strVolName}{'space-used'} = $nahVol->child_get("volume-space-attributes")->child_get_string("size-used");
                        	$hshVolUsage{$strVolName}{'inodes-total'} = $nahVol->child_get("volume-inode-attributes")->child_get_string("files-total");
                        	$hshVolUsage{$strVolName}{'inodes-used'} = $nahVol->child_get("volume-inode-attributes")->child_get_string("files-used");
			}
		}
	}

	return \%hshVolUsage;
}

##############################################
## SPACE HELPERS
##############################################

sub calc_space_health {
        my ($hrefSpaceInfo, $strWarning, $strCritical) = @_;
        my ($hrefWarnThresholds, $hrefCritThresholds) = space_threshold_converter($strWarning, $strCritical);
        my $intState = 0;
        my $strOutput;
        my $hrefObjectState;

        foreach my $strObj (keys %$hrefSpaceInfo) {
                if ($hrefSpaceInfo->{$strObj}->{'state'} ne "online") {
                        if (defined($hrefCritThresholds->{'strings'}) || defined($hrefWarnThresholds->{'strings'})) {
				my $bObjectRemoved = 0;
				foreach my $strStateThresh (@{$hrefCritThresholds->{'strings'}}) {
					if ($hrefSpaceInfo->{$strObj}->{'state'} eq $strStateThresh) {
						my $strNewMessage = $strObj . " is " . $strStateThresh;
						$strOutput = get_nagios_description($strOutput, $strNewMessage);
                                		$intState = get_nagios_state($intState, 2);
						delete($hrefSpaceInfo->{$strObj});
						$bObjectRemoved = 1;
					}
				}

				if ($bObjectRemoved) {
					next;
				}

				foreach my $strStateThresh (@{$hrefWarnThresholds->{'strings'}}) {
                                        if ($hrefSpaceInfo->{$strObj}->{'state'} eq $strStateThresh) {
                                                my $strNewMessage = $strObj . " is " . $strStateThresh;
                                                $strOutput = get_nagios_description($strOutput, $strNewMessage);
                                                $intState = get_nagios_state($intState, 1);
						delete($hrefSpaceInfo->{$strObj});
                                        }
                                }
                        } elsif ($hrefSpaceInfo->{$strObj}->{'state'} eq "offline") {
                                delete($hrefSpaceInfo->{$strObj});
                        }
                }

		if (defined($hrefSpaceInfo->{$strObj}->{'home-owner'}) && defined($hrefSpaceInfo->{$strObj}->{'current-owner'})) {
			if ($hrefSpaceInfo->{$strObj}->{'home-owner'} ne $hrefSpaceInfo->{$strObj}->{'current-owner'}) {
				if ($hrefCritThresholds->{'owner'}) {
					my $strNewMessage = $strObj . " not on home! Home: " . $hrefSpaceInfo->{$strObj}->{'home-owner'} . " Current: " . $hrefSpaceInfo->{$strObj}->{'current-owner'};
					$strOutput = get_nagios_description($strOutput, $strNewMessage);
                                        $intState = get_nagios_state($intState, 2);
				} elsif ($hrefWarnThresholds->{'owner'}) {
					my $strNewMessage = $strObj . " not on home! Home: " . $hrefSpaceInfo->{$strObj}->{'home-owner'} . " Current: " . $hrefSpaceInfo->{$strObj}->{'current-owner'};
                                        $strOutput = get_nagios_description($strOutput, $strNewMessage);
                                        $intState = get_nagios_state($intState, 1);
				}
			}
		}
        }

        ($intState, $strOutput, $hrefSpaceInfo) = space_threshold_helper($intState, $strOutput, $hrefSpaceInfo, $hrefCritThresholds, 2);
        ($intState, $strOutput, $hrefSpaceInfo) = space_threshold_helper($intState, $strOutput, $hrefSpaceInfo, $hrefWarnThresholds, 1);

        if (!(defined($strOutput))) {
                $strOutput = "OK - No problems found";
        }

        return $intState, $strOutput;
}

sub space_threshold_helper {
	my ($intState, $strOutput, $hrefVolInfo, $hrefThresholds, $intAlertLevel) = @_;

	foreach my $strVol (keys %$hrefVolInfo) {
		my $bMarkedForRemoval = 0;

		if (defined($hrefThresholds->{'space-percent'}) || defined($hrefThresholds->{'space-count'})) {
			my $intUsedPercent = ($hrefVolInfo->{$strVol}->{'space-used'} / $hrefVolInfo->{$strVol}->{'space-total'}) * 100;
                        $intUsedPercent = floor($intUsedPercent + 0.5);
                        my $strReadableUsed = space_to_human_readable($hrefVolInfo->{$strVol}->{'space-used'});
                        my $strReadableTotal = space_to_human_readable($hrefVolInfo->{$strVol}->{'space-total'});
                        my $strNewMessage = $strVol . " - " . $strReadableUsed . "/" . $strReadableTotal . " (" . $intUsedPercent . "%) SPACE USED";
			
			if (defined($hrefThresholds->{'space-percent'}) && defined($hrefThresholds->{'space-count'})) {
				my $intCountInBytes = space_to_bytes($hrefThresholds->{'space-count'});
				my $intCountInPercent = ($intCountInBytes/$hrefVolInfo->{$strVol}->{'space-total'}) * 100;
				$intCountInPercent = floor($intCountInPercent + 0.5);
				my $intPercentInvert = 100 - $hrefThresholds->{'space-percent'};
				
				if ($intCountInPercent < $intPercentInvert) {
					my $intBytesRemaining = $hrefVolInfo->{$strVol}->{'space-total'} - $hrefVolInfo->{$strVol}->{'space-used'};
					if ($intCountInBytes > $intBytesRemaining) {
						$intState = get_nagios_state($intState, $intAlertLevel);
						$strOutput = get_nagios_description($strOutput, $strNewMessage);
						$bMarkedForRemoval = 1;
					}
				} else {
					if ($intUsedPercent >= $hrefThresholds->{'space-percent'}) {
						$intState = get_nagios_state($intState, $intAlertLevel);
                                                $strOutput = get_nagios_description($strOutput, $strNewMessage);
                                                $bMarkedForRemoval = 1;
					}
				}
			} elsif (defined($hrefThresholds->{'space-percent'})) {
				if ($intUsedPercent >= $hrefThresholds->{'space-percent'}) {
                                	$intState = get_nagios_state($intState, $intAlertLevel);
                                        $strOutput = get_nagios_description($strOutput, $strNewMessage);
                                        $bMarkedForRemoval = 1;
                                }
			} elsif (defined($hrefThresholds->{'space-count'})) { 
				my $intCountInBytes = space_to_bytes($hrefThresholds->{'space-count'});
				my $intBytesRemaining = $hrefVolInfo->{$strVol}->{'space-total'} - $hrefVolInfo->{$strVol}->{'space-used'};
				if ($intCountInBytes > $intBytesRemaining) {
                                	$intState = get_nagios_state($intState, $intAlertLevel);
                                        $strOutput = get_nagios_description($strOutput, $strNewMessage);
                                        $bMarkedForRemoval = 1;
                                }
			}
		}

		if (defined($hrefThresholds->{'inodes-percent'}) || defined($hrefThresholds->{'inodes-count'})) {	
			my $intUsedPercent = ($hrefVolInfo->{$strVol}->{'inodes-used'} / $hrefVolInfo->{$strVol}->{'inodes-total'}) * 100;
                                $intUsedPercent = floor($intUsedPercent + 0.5);
                                my $strNewMessage = $strVol . " - " . $hrefVolInfo->{$strVol}->{'inodes-used'} . "/" . $hrefVolInfo->{$strVol}->{'inodes-total'} . " (" . $intUsedPercent . "%) INODES USED";

			if (defined($hrefThresholds->{'inodes-percent'}) && defined($hrefThresholds->{'inodes-count'})) {
				my $intPercentInInodes = $hrefVolInfo->{$strVol}->{'inodes-total'} * ($hrefThresholds->{'inodes-percent'}/100);
				
				if ($hrefThresholds->{'inodes-count'} < $intPercentInInodes) {
					my $intInodesRemaining = $hrefVolInfo->{$strVol}->{'inodes-total'} - $hrefVolInfo->{$strVol}->{'inodes-used'};
					if ($hrefThresholds->{'inodes-count'} > $intInodesRemaining) {
						$intState = get_nagios_state($intState, $intAlertLevel);
                                                $strOutput = get_nagios_description($strOutput, $strNewMessage);
                                                $bMarkedForRemoval = 1;
					}
				} else {
					if ($intUsedPercent >= $hrefThresholds->{'inodes-percent'}) {
						$intState = get_nagios_state($intState, $intAlertLevel);
                                                $strOutput = get_nagios_description($strOutput, $strNewMessage);
                                                $bMarkedForRemoval = 1;
					}
				}
			} elsif (defined($hrefThresholds->{'inodes-percent'})) {
				if ($intUsedPercent >= $hrefThresholds->{'inodes-percent'}) {
                                	$intState = get_nagios_state($intState, $intAlertLevel);
                                        $strOutput = get_nagios_description($strOutput, $strNewMessage);
                                        $bMarkedForRemoval = 1;
                                }
			} elsif (defined($hrefThresholds->{'inodes-count'})) {
				my $intInodesRemaining = $hrefVolInfo->{$strVol}->{'inodes-total'} - $hrefVolInfo->{$strVol}->{'inodes-used'};
                                
				if ($hrefThresholds->{'inodes-count'} > $intInodesRemaining) {
                                	$intState = get_nagios_state($intState, $intAlertLevel);
                                        $strOutput = get_nagios_description($strOutput, $strNewMessage);
                                        $bMarkedForRemoval = 1;
                                }
			}
		}
		
		if ($bMarkedForRemoval) {
			delete($hrefVolInfo->{$strVol});
		}
	}

	return $intState, $strOutput, $hrefVolInfo;
}

sub space_threshold_converter {
        my ($strWarning, $strCritical) = @_;
        my (%hshWarnThresholds, %hshCritThresholds, @aryWarning, @aryCritical, @aryStringsTemp);

	if (defined($strWarning)) {
		@aryWarning = split(",", $strWarning);
	}

	if (defined($strCritical)) {
		@aryCritical = split(",", $strCritical);
	}

	$hshWarnThresholds{'owner'} = 0;
	$hshCritThresholds{'owner'} = 0;

        foreach my $strWarnThresh (@aryWarning) {
                if ($strWarnThresh =~ m/^[0-9]*\%$/) {
                        $hshWarnThresholds{'space-percent'} = $strWarnThresh;
			$hshWarnThresholds{'space-percent'} =~ s/%//;
                } elsif ($strWarnThresh =~ m/^([0-9]*)([KMGT]?B)/) {
                        $hshWarnThresholds{'space-count'} = $strWarnThresh;		
		} elsif ($strWarnThresh =~ m/^[0-9]*\%i$/) {
                        $hshWarnThresholds{'inodes-percent'} = $strWarnThresh;
			$hshWarnThresholds{'inodes-percent'} =~ s/\%i//;
		} elsif ($strWarnThresh =~ m/^[0-9]*$/) {
                        $hshWarnThresholds{'inodes-count'} = $strWarnThresh;
		} elsif ($strWarnThresh =~ m/^owner$/) {
			$hshWarnThresholds{'owner'} = 1;
		} elsif ($strWarnThresh =~ m/^[a-zA-Z]*$/) {
			push(@aryStringsTemp, $strWarnThresh);
                }
        }

	$hshWarnThresholds{'strings'} = [@aryStringsTemp];
	undef(@aryStringsTemp);

        foreach my $strCritThresh (@aryCritical) {
                if ($strCritThresh =~ m/^[0-9]*\%$/) {
                        $hshCritThresholds{'space-percent'} = $strCritThresh;
			$hshCritThresholds{'space-percent'} =~ s/%//;
                } elsif ($strCritThresh =~ m/^([0-9]*)([KMGT]?B)/) {
                        $hshCritThresholds{'space-count'} = $strCritThresh;
		} elsif ($strCritThresh =~ m/^[0-9]*\%i$/) {
                        $hshCritThresholds{'inodes-percent'} = $strCritThresh;
			$hshCritThresholds{'inodes-percent'} =~ s/\%i//;
		} elsif ($strCritThresh =~ m/^[0-9]*$/) {
                        $hshCritThresholds{'inodes-count'} = $strCritThresh;
		} elsif ($strCritThresh =~ m/^owner$/) {
			$hshCritThresholds{'owner'} = 1;
		} elsif ($strCritThresh =~ m/^[a-zA-Z]*$/) {
			push(@aryStringsTemp, $strCritThresh);
                }
        }

	$hshCritThresholds{'strings'} = [@aryStringsTemp];
        return \%hshWarnThresholds, \%hshCritThresholds;
}

sub space_to_bytes {
        my $strInput = shift;
        $strInput =~ m/([0-9]*)([KMGT]?B)/;
        my $intValue = $1;
        my $strMagnitude = $2;

        if ($strMagnitude eq "KB") {
                $intValue = $intValue * 1024;
        } elsif ($strMagnitude eq "MB") {
                $intValue = $intValue * (1024 ** 2);
        } elsif ($strMagnitude eq "GB") {
                $intValue = $intValue * (1024 ** 3);
        } elsif ($strMagnitude eq "TB") {
                $intValue = $intValue * (1024 ** 4);
        } else {
                print "No magnitude (B, KB, MB, GB, TB) defined, unable to finish!\n";
                exit 3;
        }

        return $intValue;
}

sub space_to_human_readable {
	my $intValue = shift;

        my @aryStrings = ("B","KB","MB","GB","TB");
        my $intCount = 0;

        while (($intValue > 1024) && ($intCount < 4)) {
                $intValue = $intValue / 1024;
                $intCount = $intCount + 1;
        }

        my $strRoundedNumber = sprintf("%0.2f", $intValue) . $aryStrings[$intCount];

        return $strRoundedNumber;
}

##############################################
## HELPERS
##############################################

sub help {
        my $strVersion = "v0.4 b110314";
        print "\ncheck_netapp_ontapi version: $strVersion\n";
        print "By John Murphy <john.murphy\@roshamboot.org>, GNU GPL License\n";
        print "\nUsage: ./check_netapp_ontapi.pl -H <hostname> -u <username> -p <password> -o <option> [ -w <warning_thresh> -c <critical_thresh> -m <include|exclude,pattern1,pattern2,etc> ]\n\n";
        print <<EOL;
--hostname, -H
        Hostname or address of the cluster administrative interface.
--user, -u
        Username of a Netapp Ontapi enabled user.
--password, -p
        Password for the netapp Ontapi enabled user.
--option, -o
        The name of the option you want to check. See the option and threshold list at the bottom of this help text.
--warning, -w
        A custom warning threshold value. See the option and threshold list at the bottom of this help text.
--critical, -c
        A custom warning threshold value. See the option and threshold list at the bottom of this help text.
--modifier, -m
        This modifier is used to set an inclusive or exclusive filter on what you want to monitor.
--help, -h
        Display this help text.

===OPTION LIST===
volume_health
	desc: Check the space and inode health of a vServer volume. If space % and space in *B are both defined the smaller value of the two will be used when deciding if the volume is in a warning or critical state. This allows you to better accomodate large volume monitoring.
	thresh: space % used, space in *B (i.e MB) remaining, inode count remaining, inode % used (Usage example: 80%i), "offline" keyword

aggregate_health
        desc: Check the space and inode health of a cluster aggregate. If space % and space in *B are both defined the smaller value of the two will be used when deciding if the volume is in a warning or critical state. This allows you to better accomodate large aggregate monitoring.
        thresh: space % used, space in *B (i.e MB) remaining, inode count remaining, inode % used (Usage example: 80%i), "offline" keyword, "is-home" keyword

snapshot_health
        desc: Check the space and inode health of a vServer snapshot. If space % and space in *B are both defined the smaller value of the two will be used when deciding if the volume is in a warning or critical state. This allows you to better accomodate large snapshot monitoring.
        thresh: space % used, space in *B (i.e MB) remaining, inode count remaining, inode % used (Usage example: 80%i), "offline" keyword

snapmirror_health
        desc: Check the lag time and health flag of the snapmirror relationships.
        thresh: snapmirror lag time (valid intervals are s, m, h, d).

filer_hardware_health
        desc: Check the environment hardware health of the filers (fan, psu, temperature, battery).
        thresh: component name (fan, psu, temperature, battery). There is no default alert level they MUST be defined.

interface_health
        desc: Check that a LIF is in the correctly configured state and that it is on its home node and port. Additionally checks the state of a physical port.
        thresh: N/A not customizable.

netapp_alarms
        desc: Check for Netapp console alarms.
        thresh: N/A not customizable.

cluster_health
        desc: Check the cluster disks for failure or other potentially undesirable states. 
        thresh: N/A not customizable. 

disk_health
        desc: Check the health of the disks in the cluster.
        thresh: Not customizable yet.

* For keyword thresholds, if you want to ignore alerts for that particular keyword you set it at the same threshold that the alert defaults to.

EOL
        exit 3;
}

sub time_to_seconds {
	my $strInput = shift;
	$strInput =~ m/([0-9]*)([smhd])/;
        my $intValue = $1;
        my $strMagnitude = $2;

	if ($strMagnitude eq "s") {
		# Do nothing
	} elsif ($strMagnitude eq "m") {
		$intValue = $intValue * 60;
	} elsif ($strMagnitude eq "h") {
		$intValue = $intValue * (60 ** 2);
	} elsif ($strMagnitude eq "d") {
		$intValue = ($intValue * 24) * (60 ** 2);
	} else {
		print "No time valid time string (s, m, h, d) defined, unable to finish!\n";
		exit 3;
	}

	return int($intValue);
}

sub seconds_to_time {
	my $intSecondsIn = shift;
        my $intDays = int($intSecondsIn / 86400);
        $intSecondsIn = $intSecondsIn - ($intDays * 86400);
        my $intHours = int($intSecondsIn / 3600);
        $intSecondsIn = $intSecondsIn - ($intHours * 3600);
        my $intMinutes = int($intSecondsIn / 60);
        my $intSeconds = $intSecondsIn % 60;

        my $strDays = $intDays < 1 ? "" : $intDays . "d ";
        my $strHours = $intHours < 1 ? "" : $intHours . "h ";
        my $strMinutes = $intMinutes < 1 ? "" : $intMinutes . "m ";
        my $strSeconds = $intSeconds . "s";
        my $strTime = $strDays . $strHours . $strMinutes . $strSeconds;

        return $strTime;
}

sub get_nagios_description {
	my ($strOutput, $strNewMessage) = @_; 
	if (!(defined($strOutput))) {
		$strOutput = $strNewMessage;
	} else { 
		$strOutput .= ", " . $strNewMessage;
	}

	return $strOutput;
}

sub get_nagios_state {
	my ($intState, $intNewState) = @_;
	if ($intNewState > $intState) {
		$intState = $intNewState;
	}

	return $intState;
}

sub validate_ontapi_response {
        my ($nahResponse, $strMessage) = @_;

        if (ref($nahResponse) eq "NaElement" && $nahResponse->results_errno != 0) {
                my $strResponse = $nahResponse->results_reason();
                print $strMessage . $strResponse . "\n";
                exit 3;
        } elsif ($nahResponse->results_status() eq "failed") {
                my $strResponse = $nahResponse->results_reason();
                print $strResponse . "\n";
                exit 3;
        } else {
                return;
        }
}

sub filter_object {
	my ($hrefObjectsToFilter, $strModifier) = @_;
	my @aryModifier = split(",",$strModifier);	
	my $strProcType = shift @aryModifier;

	if ($strProcType eq "exclude") {
		foreach my $strObject (keys %$hrefObjectsToFilter) { 
			foreach my $strFilter (@aryModifier) {
				if ($strObject =~ m/$strFilter/) {
					delete($hrefObjectsToFilter->{$strObject});
				}
			}
		}
	} elsif ($strProcType eq "include") {
		foreach my $strObject (keys %$hrefObjectsToFilter) {
			my $bRemove = 1;

                        foreach my $strFilter (@aryModifier) {
                                if ($strObject =~ m/$strFilter/) {
					$bRemove = 0;
                                }
                        }

			if ($bRemove) {
				delete($hrefObjectsToFilter->{$strObject});
			}
                }
	} else {
		print "Unable to determine modifier type, should be either include or exclude... skipping filtering step.\n";
		exit 3;
	}

	return $hrefObjectsToFilter;
}

##############################################
##
## BEGIN MAIN
##
##############################################

my ($strHost, $strUser, $strPassword, $strOption, $strWarning, $strCritical, $strModifier);

GetOptions("H=s" => \$strHost,                                  "hostname=s" => \$strHost,
           "u=s" => \$strUser,                                  "user=s" => \$strUser,
           "p=s" => \$strPassword,                              "password=s" => \$strPassword,
	   "o=s" => \$strOption,                                "option=s" => \$strOption,
	   "w=s" => \$strWarning,            			"warning=s" => \$strWarning,
           "c=s" => \$strCritical,            			"critical=s" => \$strCritical,
	   "m=s" => \$strModifier, 				"modifier=s" => \$strModifier);

if (!($strHost || $strUser || $strPassword || $strOption)) {
	print "A required option is not set!\n";
        help();
}

$strOption = lc($strOption);

my $nahStorage = NaServer->new($strHost, 1, 15);
$nahStorage->set_style("LOGIN");
$nahStorage->set_admin_user($strUser, $strPassword);
$nahStorage->set_transport_type("HTTP");
my $nahResponse = $nahStorage->invoke("system-get-version");
validate_ontapi_response($nahResponse, "Failed test query: ");

if (!($nahResponse->child_get_string("is-clustered"))) {
        print "This plugin only works for Cluster-Mode your filers are running in 7-Mode.\n";
        exit 3;
}

my ($intState, $strOutput);

if ($strOption eq "volume_health") {
	# * COMPLETE % TESTED
	# Space used, Inode used, offline
	my $hrefVolInfo = get_volume_space($nahStorage);

	if (defined($strModifier)) {
		$hrefVolInfo = filter_object($hrefVolInfo, $strModifier);
	}

	($intState, $strOutput) = calc_space_health($hrefVolInfo, $strWarning, $strCritical);
} elsif ($strOption eq "aggregate_health") {
	# * COMPLETE % TESTED
	# Space used, Inodes used, offline, is-home
	my $hrefAggInfo = get_aggregate_space($nahStorage);

	if (defined($strModifier)) {
                $hrefAggInfo = filter_object($hrefAggInfo, $strModifier);
        }

	($intState, $strOutput) = calc_space_health($hrefAggInfo, $strWarning, $strCritical);
} elsif ($strOption eq "snapshot_health") {
	# * COMPLETE % TESTED
	# Space used, Inode used, offline
	my $hrefSnapInfo = get_snap_space($nahStorage);

        if (defined($strModifier)) {
                $hrefSnapInfo = filter_object($hrefSnapInfo, $strModifier);
        }

        ($intState, $strOutput) = calc_space_health($hrefSnapInfo, $strWarning, $strCritical);
} elsif ($strOption eq "snapmirror_health") {
	# * COMPLETE % TESTED
	# Snapmirror lag time, health
	my $hrefSMInfo = get_snapmirror_lag($nahStorage);
	
	if (defined($strModifier)) {
                $hrefSMInfo = filter_object($hrefSMInfo, $strModifier);
        }

	($intState, $strOutput) = calc_snapmirror_health($hrefSMInfo, $strWarning, $strCritical);
} elsif ($strOption eq "filer_hardware_health") {
	# * COMPLETE
	# Filer fan failure, Filer power supply failure, Filer temperature health, Filer battery failure

	my $hrefFilerHWInfo = get_filer_hardware($nahStorage);
	
	if (defined($strModifier)) {
                $hrefFilerHWInfo = filter_object($hrefFilerHWInfo, $strModifier);
        }

	($intState, $strOutput) = calc_filer_hardware_health($hrefFilerHWInfo, $strWarning, $strCritical);
} elsif ($strOption eq "shelf_hardware_health") {
	# HOPEFULLY NO LONGER REQUIRED. TESTING REQUIRED!
        # Disk shelf power supply failure
        # Disk shelf fan failure
        # Disk shelf temperature health
        # Disk shelf voltage senseor health

	my $hrefShelfHWInfo = get_shelf_hardware($nahStorage);

        if (defined($strModifier)) {
                $hrefShelfHWInfo = filter_object($hrefShelfHWInfo, $strModifier);
        }

        ($intState, $strOutput) = calc_shelf_hardware_health($hrefShelfHWInfo, $strWarning, $strCritical);
} elsif ($strOption eq "interface_health") {
	# * COMPLETE
	# LIF status, LIF is on home node, LIF on home port, Port status

	my $hrefInterfaceInfo = get_interface_health($nahStorage);

        if (defined($strModifier)) {
                $hrefInterfaceInfo = filter_object($hrefInterfaceInfo, $strModifier);
        }

        ($intState, $strOutput) = calc_interface_health($hrefInterfaceInfo, $strWarning, $strCritical);
} elsif ($strOption eq "netapp_alarms") {
	# * COMPLETE
	# Diagnostic and dashboard alarms
	
	my $hrefAlarmInfo = get_netapp_alarms($nahStorage);

        if (defined($strModifier)) {
                $hrefAlarmInfo = filter_object($hrefAlarmInfo, $strModifier);
        }

        ($intState, $strOutput) = calc_netapp_alarm_health($hrefAlarmInfo, $strWarning, $strCritical);
} elsif ($strOption eq "cluster_health") {
	# * COMPLETE 
	# Cluster health

	my $hrefClusterInfo = get_cluster_health($nahStorage);

        if (defined($strModifier)) {
                $hrefClusterInfo = filter_object($hrefClusterInfo, $strModifier);
        }

        ($intState, $strOutput) = calc_cluster_health($hrefClusterInfo, $strWarning, $strCritical);
} elsif ($strOption eq "disk_health") {
	# * COMPLETE
	# Disk health -wc ????

	my $hrefDiskInfo = get_disk_info($nahStorage);

        if (defined($strModifier)) {
                $hrefDiskInfo = filter_object($hrefDiskInfo, $strModifier);
        }

        ($intState, $strOutput) = calc_disk_health($hrefDiskInfo, $strWarning, $strCritical);
}

## FUTURE STUFF----
# DISK IO, DE-DUPE LAG

$strOutput .= "\n";
print $strOutput;
exit $intState; 
