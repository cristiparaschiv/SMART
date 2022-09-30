package SMART;
use Dancer ':syntax';

use Controller::Cards;
use Controller::Stats;

our $VERSION = '0.1';

get '/' => sub {

    my $cards = Controller::Cards::generateCards();

    return template 'index.tt', { cards => $cards };
};

post '/add' => sub {
    my $data = from_json( request->body );

    my $result = Controller::Stats::addStats($data);
    if ($result) {
	return to_json ({"status" => 201, "message" => "success"});
    } else {
	return to_json ({"status" => 500, "message" => "failed to add status"});
    }
};

true;
