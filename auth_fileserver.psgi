use strict;
use warnings;

use Data::Dumper;
use Plack::App::Directory;
use Plack::Builder;
use Plack::Middleware::Auth::Form;

#
# Request for /private/* checked for auth.
#   If auth-ed, then serve up file or dir listing.
#   Else redirect to /private/login.
# Request for anything else => 404

my $app = sub {
    my $env = shift;

    my $session = $env->{'psgix.session'};

    print STDERR Dumper($session);

    return [1,2,3];
};

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
