use strict;
use warnings;

use Data::Dumper; $Data::Dumper::Sortkeys = 1;
use Plack::App::Directory;
use Plack::Builder;
use Plack::Middleware::Auth::Form;
use Plack::Session::Store::File;

# TODO: SSL support

# Required behaviour:
# /             => 404
# /public       => Browseable by anyone. 
# /private      => Needs login.

# Store session data here - create if necessary.
my $session_dir = './psgi_sessions';
mkdir $session_dir unless -d $session_dir;

my $public_dir  = 'public';
my $private_dir = 'private';

my $app = builder {

    # Serve up $public_dir to anyone.
    mount "/$public_dir" => builder { 
        Plack::App::Directory->new( { root => $public_dir } )->to_app; 
    };

    # Handle auth and fileserving for $private_dir
    mount "/$private_dir" => builder {
        enable "Session", 
            state => 'Cookie', 
            store => Plack::Session::Store::File->new(
                dir => $session_dir,
            );

        enable 'Auth::Form', authenticator => \&check_credentials;

        enable sub {
            my $app = shift;
            return sub {
                my $env = shift;
                if ($env->{'psgix.session'}{user_id}) {
                    # Logged in - serve up dir/file.
                    return $app->($env);
                }
                else {
                    # Redirect to login page.
                    return [ 302, [ Location => "/$private_dir/login" ], [''] ];
                }
            }
        };

        Plack::App::Directory->new( { root => $private_dir } )->to_app;
    };

    # Anything else will cause a 404
};

sub check_credentials {
    my ( $username, $password, $env ) = @_;

    if ( $username eq 'barry' && $password eq 'qwerty123' ) {
        return {
            user_id  => $username,
            redir_to => "/$private_dir/",
        };
    }

    return;
}
