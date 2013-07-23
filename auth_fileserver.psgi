use strict;
use warnings;

use Data::Dumper; $Data::Dumper::Sortkeys = 1;
use Plack::App::Directory;
use Plack::Builder;
use Plack::Middleware::Auth::Form;
use Plack::Request;
use Plack::Session::Store::File;


#
# Request for /private/* checked for auth.
#   If auth-ed, then serve up file or dir listing.
#   Else redirect to /private/login.
# Request for anything else => 404

my $app = builder {
    enable "Session", state => 'Cookie', store => 'File';
    enable 'Auth::Form', authenticator => \&check_pass;

    enable sub {
        my $app = shift;
        return sub {
           my $env = shift;
           if ($env->{'psgix.session'}{user_id}) {
               return $app->($env);
           }
           elsif ( $env->{PATH_INFO} =~ m{^/log(in|out)$}xms ) {
               return $app->($env);
           }

           return [ 302, [ Location => '/login' ], [""] ];
        }
    };

    Plack::App::Directory->new( { root => 'private' } )->to_app;
};

sub check_pass {
    my ($username, $password, $env) = @_;

    if ( $username eq 'barry' && $password eq 'qwerty123' ) {
        return 1;
    }

    return;
}
