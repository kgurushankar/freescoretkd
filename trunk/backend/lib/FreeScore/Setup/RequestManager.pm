package FreeScore::Setup::RequestManager;
use lib qw( /usr/local/freescore/lib );
use Try::Tiny;
use FreeScore;
use FreeScore::Repository;
use FreeScore::Tournament;
use JSON::XS;
use Digest::SHA1 qw( sha1_hex );
use List::Util (qw( first ));
use List::MoreUtils (qw( first_index uniq ));
use Data::Dumper;
use Data::Structure::Util qw( unbless );
use Date::Manip;
use Clone qw( clone );

our $DEBUG = 1;

# ============================================================
sub new {
# ============================================================
	my ($class) = map { ref || $_ } shift;
	my $self = bless {}, $class;
	$self->init( @_ );
	return $self;
}

# ============================================================
sub init {
# ============================================================
	my $self               = shift;
	$self->{ _client }     = shift;
	$self->{ _json }       = new JSON::XS();
	$self->{ _watching }   = {};
	$self->{ software }    = {
		connect_to_repo    => \&handle_software_connect_to_repo,
		check_updates      => \&handle_software_check_updates,
		update             => \&handle_software_update
	};
	$self->{ setup }  = {
		read               => \&handle_setup_read,
		write              => \&handle_setup_write,
	};
}

# ============================================================
sub handle {
# ============================================================
 	my $self     = shift;
	my $request  = shift;
	my $setup    = shift;
	my $clients  = shift;
	my $judges   = shift;
	my $action   = $request->{ action }; $action =~ s/\s+/_/g;
	my $type     = $request->{ type };   $type =~ s/\s+/_/g;

	my $dispatch = $self->{ $type }{ $action } if exists $self->{ $type } && exists $self->{ $type }{ $action };
	return $self->$dispatch( $request, $setup, $clients, $judges ) if defined $dispatch;
}

# ============================================================
sub handle_software_check_updates {
# ============================================================
	my $self    = shift;
	my $request = shift;
	my $setup   = shift;
	my $clients = shift;
	my $client  = $self->{ _client };

	try {
		my $repo     = new FreeScore::Repository();
		my $logs     = $repo->log();
		my $hash     = $repo->installed_version();
		my $current  = (grep { $_->{ hash } eq $hash } @$logs)[ 0 ];
		my $latest   = $logs->[ 0 ];

		print STDERR int( @$logs ) . " versions found.\n" if $DEBUG;
		my $update   = ($latest->{ datetime }->cmp( $current->{ datetime })) > 0 ? 1 : 0;
		$_->{ datetime } = $_->{ datetime }->printf( '%a %h %e, %Y, %i:%M %p' ) foreach uniq (@$logs);

		$client->send( { json => { type => $request->{ type }, action => 'updates', available => $update, version => $latest, current => $current, revisions => $logs }});

	} catch {
		$client->send( { json => { error => "$_" }});
	}
}

# ============================================================
sub handle_software_connect_to_repo {
# ============================================================
	my $self    = shift;
	my $request = shift;
	my $setup   = shift;
	my $clients = shift;
	my $client  = $self->{ _client };

	try {
		my $repo = new FreeScore::Repository();
		if( $repo->connect()) {
			$client->send( { json => { type => $request->{ type }, action => 'connect_to_repo', connected => 1 }});
		} else {
			$client->send( { json => { type => $request->{ type }, action => 'connect_to_repo', connected => 0 }});
		}
	} catch {
		$client->send( { json => { error => "$_" }});
	}
}

# ============================================================
sub handle_software_update {
# ============================================================
	my $self    = shift;
	my $request = shift;
	my $setup   = shift;
	my $clients = shift;
	my $client  = $self->{ _client };

	try {
		my $repo = new FreeScore::Repository();
		$repo->install_revision( $request->{ hash });
		$client->send( { json => { type => $request->{ type }, action => 'update', hash => $request->{ hash }, datetime => $request->{ datetime } }});
	} catch {
		$client->send( { json => { error => "$_" }});
	}
}

# ============================================================
sub handle_setup_read {
# ============================================================
	my $self       = shift;
	my $request    = shift;
	my $setup      = shift;
	my $clients    = shift;
	my $client     = $self->{ _client };

	$self->send_setup_response( $request, $setup, $clients );
}

# ============================================================
sub handle_setup_write {
# ============================================================
	my $self       = shift;
	my $request    = shift;
	my $setup      = shift;
	my $clients    = shift;
	my $client     = $self->{ _client };

	if( exists $request->{ edits } ) {
		my $edit = $request->{ edits };
		$setup->update_rings( $edit->{ rings }) if( exists $edit->{ rings });
		$setup->update_wifi(  $edit->{ wifi })  if( exists $edit->{ wifi });
	}
	$setup->write();

	$self->send_setup_response( $request, $setup, $clients );
}

# ============================================================
sub send_setup_response {
# ============================================================
 	my $self       = shift;
	my $request    = shift;
	my $setup      = shift;
	my $clients    = shift;
	my $client     = $self->{ _client };
	my $json       = $self->{ _json };

	my $message    = clone( $setup );
	my $unblessed  = unbless( $message ); 
	my $encoded    = $json->canonical->encode( $unblessed );
	my $digest     = sha1_hex( $encoded );

	$client->send( { json => { type => 'setup', action => 'update', digest => $digest, setup => $unblessed, request => $request }});
	$self->{ _last_state } = $digest;
}

1;
