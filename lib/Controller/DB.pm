package Controller::DB;

use DBI;

sub getDBH {
	my $self = shift;

	my $driver = "SQLite";
	#my $database = "/var/db/smart.db";
	my $database = "/home/cristi/smart.db";
	my $dbuser = "secret";
	my $dbpass = "secret";
	my $dsn = "DBI:$driver:dbname=$database";
	my $dbh;

	eval {
		$dbh = DBI->connect($dsn, $dbuser, $dbpass, { RaiseError => 1} );
	};
	if ($@) {
		warning $@;
	}

	return $dbh;
}

1;
