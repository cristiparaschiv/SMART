package UI::Card;

use Dancer;
use Data::Dumper;

sub new {
    my $self    = shift;
    my $content = shift;
    my $type    = shift;

    debug Dumper $type;
    my $class = "notice ";
    if ( $type eq "success" ) {
        $class .= "notice-success";
    }
    elsif ( $type eq "error" ) {
        $class .= "notice-danger";
    }
    elsif ( $type eq "warning" ) {
        $class .= "notice-warning";
    }

    return (
        template 'card.tt',
        { class  => $class, content => $content },
        { layout => undef }
    );
}

1;
