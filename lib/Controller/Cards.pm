package Controller::Cards;

use Dancer;
use UI::Card;
use Controller::Stats;

sub generateCards {
	my $self = shift;

	my $data = Controller::Stats::getStats();
	my @cards = ();
	foreach (@$data) {
		my $row = $_;
		my $status = $row->{status} eq 'PASSED' ? 'success' : 'error';
		my $statusCardContent = template 'status_card.tt', { data => $row }, {layout => undef };
		my $card = new UI::Card($statusCardContent, $status);
		push @cards, $card;
	}

	return \@cards;
}

1;
