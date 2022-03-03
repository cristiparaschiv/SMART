package SMART;
use Dancer ':syntax';

use Data::Dumper;
use DBI;
use UI::Card;

our $VERSION = '0.1';

get '/' => sub {

    my $driver   = "SQLite";
    my $database = "/var/db/smart.db";
    my $dbuser   = "secret";
    my $dbpass   = "secret";
    my $dsn      = "DBI:$driver:dbname=$database";
    my $dbh;
    eval {
        $dbh = DBI->connect( $dsn, $dbuser, $dbpass, { RaiseError => 1 } ); };
    if ($@) { warning $@; }

    my $query = "select * from status";
    my $sth   = $dbh->prepare($query);
    $sth->execute();
    my @cards = ();
    while ( my $row = $sth->fetchrow_hashref() ) {
        debug Dumper $row;
        $row->{last_updated} = localtime( $row->{last_updated} );
        my $status = $row->{status} eq 'PASSED' ? 'success' : 'error';
        my $statusCardContent = template 'status_card.tt', { data => $row },
          { layout => undef };
        my $card = new UI::Card( $statusCardContent, $status );
        push @cards, $card;
    }

    return template 'index.tt', { cards => \@cards };
};

post '/add' => sub {
    my $data = from_json( request->body );

    debug Dumper $data;

    my $driver   = "SQLite";
    my $database = "/var/db/smart.db";
    my $dbuser   = "secret";
    my $dbpass   = "secret";
    my $dsn      = "DBI:$driver:dbname=$database";
    my $dbh;
    eval {
        $dbh = DBI->connect( $dsn, $dbuser, $dbpass, { RaiseError => 1 } ); };
    if ($@) { warning $@; }
    my $stats_query =
      qq^insert into stats values (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)^;
    my $status_query =
      qq^replace into status values (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)^;
    my $stats_sth  = $dbh->prepare($stats_query);
    my $status_sth = $dbh->prepare($status_query);

    foreach my $record (@$data) {
        if ( !defined $record->{serial} ) { next; }
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
    }

    $stats_sth->finish;
    $status_sth->finish;

    $dbh->disconnect;

    return to_json( { "success" => 1 } );
};

true;
