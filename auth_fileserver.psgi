use strict;
use warnings;

use Data::Dumper;
use Plack::App::Directory;
use Plack::Builder;
use Plack::Middleware::Auth::Form;
use Plack::Request;


#
# Request for /private/* checked for auth.
#   If auth-ed, then serve up file or dir listing.
#   Else redirect to /private/login.
# Request for anything else => 404

my $app = sub {
    my $env = shift;

    my $req = Plack::Request->new($env);
    my $path_info = $req->path_info;

    my $res;

    if ( $path_info eq '/private' ) {
        $res = $req->new_response();
        $res->redirect('/private/login');
    }
    elsif ( $path_info eq '/private/login' ) {
        my $inner_app = Plack::Middleware::Auth::Form->new();
    }
    elsif ( $path_info =~ m{ \A /private/ }xms ) {
        $res = $req->new_response();
    }
    else {
        $res = $req->new_response(404); # new Plack::Response
    }


    $res->finalize;
};

__END__

my $auth_app = builder {
    mount '/private' => builder {
        enable 'Session';
        enable 'Auth::Form', authenticator => \&check_pass;
        #$app;
        Plack::App::Directory->new( { root => "private/" } )->to_app;
    },
    ;
};

return $auth_app;

sub check_pass {
    #print STDERR Dumper(\@_);
    1
}
