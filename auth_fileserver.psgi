use strict;
use warnings;

use Data::Dumper; $Data::Dumper::Sortkeys = 1;
use Digest::Bcrypt;
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

    # Generate the 16-byte salts with something like the following bash
    # one-liner, which uses most printable chars.
    # head -c 500 /dev/urandom | tr -dc "a-zA-Z0-9 !\"£$%^&*()_+-=[]{};\\:@|,./<>?~\`'" | head -c 16 ; echo

    # Calculate the hashed passwords with something like the following perl oneliner.
    # perl -MDigest::Bcrypt -lwe 'my $b = Digest::Bcrypt->new(); $b->cost(10); $b->salt(shift); $b->add(shift); print $b->hexdigest' "THE_SALT" "THE_PASSWORD"
    my %credentials = (
        barry => {
            salt      => q{hNzYJwU>2(3@Kv^k},
            hashed_pw => '484c5f81602a6a0ccda78491dc046ce12ffa0b298e002b',
        },
        sally => {
            salt      => q{E~n[h_D4j7R~@~nL},
            hashed_pw => 'dd205bfdbe7575db02fbeddb973dbe91cf7a047a6c35c7',

        },
    );

    my $stored_credentials = $credentials{$username} or return;

    my $bc = Digest::Bcrypt->new;
    $bc->cost(10); # A higher cost means longer processing time.
    $bc->salt( $stored_credentials->{salt} );
    $bc->add($password);

    my $supplied_hashed_pw = $bc->hexdigest;

    if ( $stored_credentials->{hashed_pw} eq $supplied_hashed_pw ) {
        return {
            user_id  => $username,
            redir_to => "/$private_dir/",
        };
    }

    return;
}
