use strict;
use warnings;

use Data::Dumper;
use Plack::App::Directory;
use Plack::Builder;
use Plack::Middleware::Auth::Form;

my $auth_app = builder {
    mount '/private' => builder {
        enable 'Session';
        enable 'Auth::Form', authenticator => \&check_pass;
        Plack::App::Directory->new( { root => "private/" } )->to_app;
    },
    ;
};

return $auth_app;

sub check_pass {
    print STDERR Dumper(\@_);
    1
}
