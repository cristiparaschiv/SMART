package Controller::Stats;

use Dancer;
use Controller::DB;

sub getStats {
	my $self = shift;

	my $dbh = Controller::DB::getDBH;

	my $query = "select * from status";
	my $sth = $dbh->prepare($query);
	$sth->execute();

	my $data = [];
	while (my $row = $sth->fetchrow_hashref()) {
		$row->{last_updated} = localtime($row->{last_updated});
		push @$data, $row;
	}
	$sth->finish;
	$dbh->disconnect;

	return $data;
}

sub addStats {
	#my $self = shift;
	my $data = shift;

	my $dbh = Controller::DB::getDBH;

	my $stats_query = qq^insert into stats values (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)^;
	my $status_query = qq^replace into status values (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)^;
	my $stats_sth = $dbh->prepare($stats_query);
	my $status_sth = $dbh->prepare($status_query);

	foreach my $record (@$data) {
    		if ( !defined $record->{serial} ) { next; }
		eval {
			$stats_sth->execute(
				$record->{serial},
				"/dev/" . $record->{device},
				$record->{name},
				time() + 7200, # ADJUST; server is configured as UTC
				$record->{smart_status},
				$record->{temperature},
				$record->{capacity},
				$record->{powered_on},
				$record->{start_stop},
				$record->{spin_retry},
				$record->{reallocated_sectors},
				$record->{reallocated_events},
				$record->{current_pending_sectors},
				$record->{offline_uncorrectable_sectors},
				$record->{ultradma_crc_errors},
				$record->{seek_error_health},
				$record->{last_test_age}
			);
			$status_sth->execute(
				$record->{serial},
				"/dev/" . $record->{device},
				$record->{name},
				time() + 7200,
				$record->{smart_status},
				$record->{temperature},
				$record->{capacity},
				$record->{powered_on},
				$record->{start_stop},
				$record->{spin_retry},
				$record->{reallocated_sectors},
				$record->{reallocated_events},
				$record->{current_pending_sectors},
				$record->{offline_uncorrectable_sectors},
				$record->{ultradma_crc_errors},
				$record->{seek_error_health},
				$record->{last_test_age}
			);
		};
		if ($@) {
			warning $@;
			return 0;
		}
	}

	$stats_sth->finish;
	$status_sth->finish;

	$dbh->disconnect;
	return 1;
}

1;
