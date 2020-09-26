package FreeScore::Forms::WorldClass::RequestManager;
use lib qw( /usr/local/freescore/lib );
use Try::Tiny;
use FreeScore;
use FreeScore::RCS;
use FreeScore::Forms::WorldClass;
use FreeScore::Forms::WorldClass::Schedule;
use FreeScore::Registration::USAT;
use JSON::XS;
use Digest::SHA1 qw( sha1_hex );
use List::Util (qw( first shuffle ));
use List::MoreUtils (qw( first_index ));
use Data::Dumper;
use Data::Structure::Util qw( unbless );
use Clone qw( clone );
use File::Slurp qw( read_file );
use Encode qw( encode );

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
	my $self                    = shift;
	$self->{ _tournament }      = shift;
	$self->{ _ring }            = shift;
	$self->{ _id }              = shift;
	$self->{ _client }          = shift;
	$self->{ _json }            = new JSON::XS();
	$self->{ _watching }        = {};
	$self->{ division }         = {
		athlete_delete          => \&handle_division_athlete_delete,
		athlete_next            => \&handle_division_athlete_next,
		athlete_prev            => \&handle_division_athlete_prev,
		award_penalty           => \&handle_division_award_penalty,
		award_punitive          => \&handle_division_award_punitive,
		clear_judge_score       => \&handle_division_clear_judge_score,
		display                 => \&handle_division_display,
		edit_athletes           => \&handle_division_edit_athletes,
		form_next               => \&handle_division_form_next,
		form_prev               => \&handle_division_form_prev,
		history                 => \&handle_division_history,
		judge_departure         => \&handle_division_judge_departure,
		judge_ping              => \&handle_division_judge_ping,
		judge_query             => \&handle_division_judge_query,
		judge_registration      => \&handle_division_judge_registration,
		navigate                => \&handle_division_navigate,
		pool_close_window       => \&handle_division_pool_close_window,
		pool_judge_registration => \&handle_division_pool_judge_registration,
		pool_judge_ready        => \&handle_division_pool_judge_ready,
		pool_resolve            => \&handle_division_pool_resolve,
		pool_score              => \&handle_division_pool_score,
		read                    => \&handle_division_read,
		restore                 => \&handle_division_restore,
		round_next              => \&handle_division_round_next,
		round_prev              => \&handle_division_round_prev,
		score                   => \&handle_division_score,
		write                   => \&handle_division_write,
	};
	$self->{ ring }             = {
		division_delete         => \&handle_ring_division_delete,
		division_merge          => \&handle_ring_division_merge,
		division_next           => \&handle_ring_division_next,
		division_prev           => \&handle_ring_division_prev,
		division_split          => \&handle_ring_division_split,
		draws_delete            => \&handle_ring_draws_delete,
		draws_write             => \&handle_ring_draws_write,
		read                    => \&handle_ring_read,
		transfer                => \&handle_ring_transfer,
	};
	$self->{ registration }     = {
		archive                 => \&handle_registration_archive,
		import                  => \&handle_registration_import,
		read                    => \&handle_registration_read,
		remove                  => \&handle_registration_remove,
		upload                  => \&handle_registration_upload,
	};
	$self->{ schedule }         = {
		build                   => \&handle_schedule_build,
		check                   => \&handle_schedule_check,
		read                    => \&handle_schedule_read,
		write                   => \&handle_schedule_write,
		remove                  => \&handle_schedule_remove,
	};
}

# ============================================================
sub broadcast_division_response {
# ============================================================
# Broadcasts to ring
# ------------------------------------------------------------
 	my $self      = shift;
	my $request   = shift;
	my $progress  = shift;
	my $clients   = shift;
	my $judges    = shift;
	my $client_id = $self->{ _id };
	my $client    = $self->{ _client };
	my $json      = $self->{ _json };
	my $division  = defined $request->{ divid } ? $progress->find( $request->{ divid } ) : $progress->current();

	print STDERR "  Broadcasting division information to:\n" if $DEBUG;

	foreach my $id (sort keys %$clients) {
		my $user      = $clients->{ $id };
		my $is_judge  = exists $user->{ judge } && defined $user->{ judge };
		my $message   = clone( $is_judge ? $division->get_only( $user->{ judge } ) : $division );
		my $unblessed = unbless( $message ); 
		my $encoded   = $json->canonical->encode( $unblessed );
		my $digest    = sha1_hex( $encoded );

		printf STDERR "    user: %s (%s) message: %s\n", $user->{ role }, substr( $id, 0, 4 ), substr( $digest, 0, 4 ) if $DEBUG;
		$user->{ device }->send( { json => { type => $request->{ type }, action => 'update', digest => $digest, division => $unblessed, request => $request }});
		$self->{ _last_state } = $digest if $client_id eq $id;
	}
	print STDERR "\n" if $DEBUG;
}

# ============================================================
sub broadcast_division_judge_status {
# ============================================================
# Broadcasts to ring
# ------------------------------------------------------------
 	my $self      = shift;
	my $request   = shift;
	my $progress  = shift;
	my $clients   = shift;
	my $judges    = shift;
	my $client_id = $self->{ _id };
	my $client    = $self->{ _client };
	my $json      = $self->{ _json };
	my $division  = defined $request->{ divid } ? $progress->find( $request->{ divid } ) : $progress->current();

	foreach my $id (sort keys %$clients) {
		my $user      = $clients->{ $id };
		my $is_judge  = exists $user->{ judge } && defined $user->{ judge };
		my $message   = clone( $is_judge ? $division->get_only( $user->{ judge } ) : $division );
		my $unblessed = unbless( $message ); 
		my $encoded   = $json->canonical->encode( $unblessed );
		my $digest    = sha1_hex( $encoded );

		$user->{ device }->send( { json => { %$request }});
		$self->{ _last_state } = $digest if $client_id eq $id;
	}
}

# ============================================================
sub broadcast_ring_response {
# ============================================================
# Broadcasts to ring
# ------------------------------------------------------------
 	my $self      = shift;
	my $request   = shift;
	my $progress  = shift;
	my $clients   = shift;
	my $judges    = shift;
	my $client_id = $self->{ _id };
	my $client    = $self->{ _client };
	my $json      = $self->{ _json };
	my $division  = defined $request->{ divid } ? $progress->find( $request->{ divid } ) : $progress->current();

	print STDERR "  Broadcasting ring information to:\n" if $DEBUG;
	foreach my $id (sort keys %$clients) {
		my $user      = $clients->{ $id };
		my $is_judge  = exists $user->{ judge } && defined $user->{ judge };
		my $message   = clone( $is_judge ? $division->get_only( $user->{ judge } ) : $progress );
		my $unblessed = unbless( $message ); 
		my $encoded   = $json->canonical->encode( $unblessed );
		my $digest    = sha1_hex( $encoded );
		my $response  = $is_judge ? { type => 'division', action => 'update', digest => $digest, division => $unblessed, request => $request } : { type => 'ring', action => 'update', digest => $digest, ring => $unblessed, request => $request };

		printf STDERR "    user: %s (%s) message: %s\n", $user->{ role }, substr( $id, 0, 4 ), substr( $digest, 0, 4 ) if $DEBUG;
		$user->{ device }->send( { json => $response });
		$self->{ _last_state } = $digest if $client_id eq $id;
	}
	print STDERR "\n" if $DEBUG;
}

# ============================================================
sub handle {
# ============================================================
	my $self     = shift;
	my $request  = shift;
	my $progress = shift;
	my $clients  = shift;
	my $judges   = shift;
	my $action   = $request->{ action }; $action =~ s/\s+/_/g;
	my $type     = $request->{ type };   $type =~ s/\s+/_/g;

	my $dispatch = $self->{ $type }{ $action } if exists $self->{ $type } && exists $self->{ $type }{ $action };
	return $self->$dispatch( $request, $progress, $clients, $judges ) if defined $dispatch;
	print STDERR "Unknown request $type, $action\n";
}

# ============================================================
sub handle_division_award_penalty {
# ============================================================
	my $self     = shift;
	my $request  = shift;
	my $progress = shift;
	my $clients  = shift;
	my $judges   = shift;
	my $client   = $self->{ _client };
	my $division = $progress->current();
	my $version  = new FreeScore::RCS();
	my $athlete  = $division->current_athlete();
	my $penalty  = join( ", ", grep { $request->{ penalties }{ $_ } > 0 } sort keys %{ $request->{ penalties }} );
	my $message  = $penalty ? "Award $penalty penalty to $athlete->{ name }\n" : "Clear penalties for $athlete->{ name }\n";

	print STDERR $message if $DEBUG;

	try {
		$version->checkout( $division );
		$division->record_penalties( $request->{ penalties });
		$division->write();
		$version->commit( $division, $message );

		$self->broadcast_division_response( $request, $progress, $clients );
	} catch {
		$client->send( { json => { error => "$_" }});
	}
}

# ============================================================
sub handle_division_award_punitive {
# ============================================================
	my $self     = shift;
	my $request  = shift;
	my $progress = shift;
	my $clients  = shift;
	my $judges   = shift;
	my $client   = $self->{ _client };
	my $division = $progress->current();
	my $version  = new FreeScore::RCS();
	my $athlete  = $division->current_athlete();
	my $decision = $request->{ decision };
	my $message  = "Award punitive decision $decision penalty to $athlete->{ name }\n";

	print STDERR $message if $DEBUG;

	my $pause = { score => 9 };

	try {
		$version->checkout( $division );
		$division->record_decision( $request->{ decision }, $request->{ athlete_id });
		$division->write();
		$version->commit( $division, $message );

		if( $request->{ decision } ne 'clear' ) {
			my $round    = $division->{ round };
			my $form     = $athlete->{ scores }{ $round }{ forms }[ $division->{ form } ];
			my $complete = $athlete->{ scores }{ $round }->form_complete( $division->{ form } );

			# ====== INITIATE AUTOPILOT FROM THE SERVER-SIDE
			print STDERR "Checking to see if we should engage autopilot: " . ($complete ? "Yes.\n" : "Not yet.\n") if $DEBUG;
			my $autopilot = $self->autopilot( $request, $progress, $clients, $judges ) if $complete;
			die $autopilot->{ error } if exists $autopilot->{ error };
		}
		$self->broadcast_division_response( $request, $progress, $clients );

	} catch {
		$client->send( { json => { error => "$_" }});
	}
}

# ============================================================
sub handle_division_athlete_delete {
# ============================================================
	my $self     = shift;
	my $request  = shift;
	my $progress = shift;
	my $clients  = shift;
	my $judges   = shift;
	my $client   = $self->{ _client };
	my $division = $progress->current();
	my $version  = new FreeScore::RCS();
	my $athlete  = $division->current_athlete();
	my $message  = "Deleting $athlete->{ name } from division\n";

	print STDERR $message if $DEBUG;

	try {
		$version->checkout( $division );
		$division->remove_athlete( $request->{ athlete_id } );
		$division->write();
		$version->commit( $division, $message );

		$self->broadcast_division_response( $request, $progress, $clients );
	} catch {
		$client->send( { json => { error => "$_" }});
	}
}

# ============================================================
sub handle_division_athlete_next {
# ============================================================
	my $self     = shift;
	my $request  = shift;
	my $progress = shift;
	my $clients  = shift;
	my $judges   = shift;
	my $client   = $self->{ _client };
	my $division = $progress->current();

	print STDERR "Next athlete.\n" if $DEBUG;

	try {
		$division->autopilot( 'off' );
		$division->next_athlete();
		$division->write();

		$self->broadcast_division_response( $request, $progress, $clients );
	} catch {
		$client->send( { json => { error => "$_" }});
	}
}

# ============================================================
sub handle_division_athlete_prev {
# ============================================================
	my $self     = shift;
	my $request  = shift;
	my $progress = shift;
	my $clients  = shift;
	my $judges   = shift;
	my $client   = $self->{ _client };
	my $division = $progress->current();

	print STDERR "Previous athlete.\n" if $DEBUG;

	try {
		$division->autopilot( 'off' );
		$division->previous_athlete();
		$division->write();

		$self->broadcast_division_response( $request, $progress, $clients );
	} catch {
		$client->send( { json => { error => "$_" }});
	}
}

# ============================================================
sub handle_division_clear_judge_score {
# ============================================================
	my $self     = shift;
	my $request  = shift;
	my $progress = shift;
	my $clients  = shift;
	my $judges   = shift;
	my $client   = $self->{ _client };
	my $division = $progress->current();
	my $version  = new FreeScore::RCS();
	my $athlete  = $division->current_athlete();
	my $jname    = $request->{ judge } == 0 ? 'Referee' : 'Judge ' . $request->{ judge };
	my $message  = "Clearing $jname score for $athlete->{ name }\n";

	print STDERR $message if $DEBUG;

	try {
		$version->checkout( $division );
		$division->clear_score( $request->{ judge } );
		$division->write();
		$version->commit( $division, $message );

		$self->broadcast_division_response( $request, $progress, $clients );
	} catch {
		$client->send( { json => { error => "$_" }});
	}
}

# ============================================================
sub handle_division_display {
# ============================================================
	my $self     = shift;
	my $request  = shift;
	my $progress = shift;
	my $clients  = shift;
	my $judges   = shift;
	my $client   = $self->{ _client };
	my $division = $progress->current();

	print STDERR "Change display.\n" if $DEBUG;

	try {
		$division->autopilot( 'off' );
		if( $division->is_display() ) { $division->score();   } 
		else                          { $division->display(); }
		$division->write();

		$self->broadcast_division_response( $request, $progress, $clients );
	} catch {
		$client->send( { json => { error => "$_" }});
	}
}
# ============================================================
sub handle_division_edit_athletes {
# ============================================================
	my $self     = shift;
	my $request  = shift;
	my $progress = shift;
	my $clients  = shift;
	my $judges   = shift;
	my $client   = $self->{ _client };

	print STDERR "Editing division athletes.\n" if $DEBUG;

	try {
		my $division = $progress->find( $request->{ divid } ) or die "Can't find division " . uc( $request->{ divid }) . " $!";
		$division->edit_athletes( $request->{ athletes }, $request->{ round } );
		$division->write();

		$self->broadcast_division_response( $request, $progress, $clients );
	} catch {
		$client->send( { json => { error => "$_" }});
	}
}

# ============================================================
sub handle_division_form_next {
# ============================================================
	my $self     = shift;
	my $request  = shift;
	my $progress = shift;
	my $clients  = shift;
	my $judges   = shift;
	my $client   = $self->{ _client };
	my $division = $progress->current();

	print STDERR "Next form.\n" if $DEBUG;

	try {
		$division->autopilot( 'off' );
		$division->next_form();
		$division->write();
		$self->broadcast_division_response( $request, $progress, $clients );
	} catch {
		$client->send( { json => { error => "$_" }});
	}
}

# ============================================================
sub handle_division_form_prev {
# ============================================================
	my $self     = shift;
	my $request  = shift;
	my $progress = shift;
	my $clients  = shift;
	my $judges   = shift;
	my $client   = $self->{ _client };
	my $division = $progress->current();

	print STDERR "Previous form.\n" if $DEBUG;

	try {
		$division->autopilot( 'off' );
		$division->previous_form();
		$division->write();
		$self->broadcast_division_response( $request, $progress, $clients );
	} catch {
		$client->send( { json => { error => "$_" }});
	}
}

# ============================================================
sub handle_division_history {
# ============================================================
	my $self     = shift;
	my $request  = shift;
	my $progress = shift;
	my $clients  = shift;
	my $judges   = shift;
	my $client   = $self->{ _client };
	my $division = $progress->current();
	my $version  = new FreeScore::RCS();

	print STDERR "Request history log\n" if $DEBUG;

	try {
		my @history = $version->history( $division );
		$division->{ history } = [ @history ];
		$self->broadcast_division_response( $request, $progress, $clients );
	} catch {
		$client->send( { json => { error => "$_" }});
	}
}

# ============================================================
sub handle_division_judge_departure {
# ============================================================
	my $self     = shift;
	my $request  = shift;
	my $progress = shift;
	my $clients  = shift;
	my $judges   = shift;
	my $client   = $self->{ _client };
	my $division = $progress->current();

	print STDERR "Requesting judge departure.\n" if $DEBUG;

	my $id = $request->{ cookie }{ id };
	my $i  = first_index { $_->{ id } eq $id; } @$judges;
	$judges->[ $i ] = {} unless $i < 0;
	$client->send( { json => { type => 'division', action => 'judge goodbye' }});
	my $name = $i < 0 ? '' : $i == 0 ? 'Referee' : 'Judge ' . $i;

	print STDERR "Goodbye $name\n" if $DEBUG;
}

# ============================================================
sub handle_division_judge_ping {
# ============================================================
	my $self     = shift;
	my $request  = shift;
	my $progress = shift;
	my $clients  = shift;
	my $judges   = shift;
	my $client   = $self->{ _client };
	my $id       = $self->{ _id };
	my $division = $progress->current();

	my $jid  = substr( $id, 0, 4); # short judge id
	my $name = $i < 0 ? '' : $i == 0 ? 'Referee' : 'Judge ' . $i;
	print STDERR "$name device ($jid) ping.\n" if $DEBUG > 1;

	$self->broadcast_division_judge_status({ type => 'division', action => 'server pong', judge => $request->{ judge }, id => $id }, $progress, $clients );
}

# ============================================================
sub handle_division_judge_query {
# ============================================================
	my $self     = shift;
	my $request  = shift;
	my $progress = shift;
	my $clients  = shift;
	my $judges   = shift;
	my $client   = $self->{ _client };
	my $division = $progress->current();
	my $n        = $division->{ judges };
	my $j        = @$judges;

	# ===== INITIALIZE IF NOT PREVIOUSLY SET
	foreach my $i ( 0 .. ($n - 1)) { $judges->[ $i ] ||= {}; }

	# ===== BUILD UP THE COURT IF NEEDED
	if( $j < $n ) { 
		print STDERR "Have $j judges, building up to $n judges, initializing " . ($n - $j) . " judges\n" if $DEBUG;

	# ===== IF THE NUMBER OF JUDGES HAS BEEN REDUCED, REMOVE THE EXTRA JUDGES
	} elsif( $j > $n ) {
		print STDERR "Reducing from $j to $n judges\n" if $DEBUG;
		splice( @$judges, $n );
	}

	if( $DEBUG ) {
		print STDERR "Requesting judge information for $n judges.\n";
		foreach my $i ( 0 .. ($n - 1)) {
			my $name = $i == 0 ? 'Referee' : 'Judge ' . $i;
			my $judge = $judges->[ $i ];
			printf STDERR "  Found %s (%s)\n", $name, substr( $judge->{ id }, 0, 4 ) if exists $judge->{ id };
		}
	}

	$client->send( { json => { type => 'division', action => 'judges', judges => $judges }} );
}

# ============================================================
sub handle_division_judge_registration {
# ============================================================
	my $self     = shift;
	my $request  = shift;
	my $progress = shift;
	my $clients  = shift;
	my $judges   = shift;
	my $client   = $self->{ _client };
	my $division = $progress->current();
	my $id       = $request->{ id };
	my $num      = $request->{ num };
	my $judge    = $num == 0 ? 'Referee' : 'Judge ' + $num;
	my $sid      = substr( $id, 0, 4 );

	print STDERR "Requesting $judge registration ($id).\n" if $DEBUG;

	# De-register the judge from other positions
	foreach my $i ( 0 .. $#$judges ) {
		my $judge = $judges->[ $i ];
		$judges->[ $i ] = {} if( $judge->{ id } eq $id );
	}
	$judges->[ $num ]{ id } = $id;

	print STDERR "  Broadcasting judge registration information to:\n" if $DEBUG;
	foreach my $id (sort keys %$clients) {
		my $user = $clients->{ $id };

		printf STDERR "    user: %s (%s)\n", $user->{ role }, $id if $DEBUG;
		$user->{ device }->send( { json => { type => $request->{ type }, action => 'judges', judges => $judges }});
	}
	print STDERR "\n" if $DEBUG;

}

# ============================================================
sub handle_division_navigate {
# ============================================================
	my $self     = shift;
	my $request  = shift;
	my $progress = shift;
	my $clients  = shift;
	my $judges   = shift;
	my $client   = $self->{ _client };
	my $division = $progress->current();

	my $target = $request->{ target };
	my $object = $target->{ destination };
	my $i      = undef;
	if   ( exists $target->{ divid }) { $i = $target->{ divid }; }
	elsif( exists $target->{ round }) { $i = $target->{ round }; } 
	else                              { $i = int( $target->{ index }); }

	print STDERR "Navigating to $object $i.\n" if $DEBUG;

	try {
		if( $object =~ /^division$/i ) { 
			$progress->navigate( $i ); 
			$progress->write();
			$division = $progress->current();
			$division->autopilot( 'off' );
			$division->write();
			$self->broadcast_ring_response( $request, $progress, $clients );
		}
		elsif( $object =~ /^(?:athlete|round|form)$/i ) { 
			$division->navigate( $object, $i ); 

			my $roundid  = $division->{ round };
			my $athlete  = $division->current_athlete();
			my $round    = $athlete->{ scores }{ $roundid };
			$division->first_form() if $object =~ /athlete/i && ! $round->form_complete( 0 );

			$division->autopilot( 'off' );
			$division->write();
			$self->broadcast_division_response( $request, $progress, $clients );
		}
	} catch {
		$client->send( { json => { error => "$_" }});
	}
}

# ============================================================
sub handle_division_pool_close_window {
# ============================================================
	my $self     = shift;
	my $request  = shift;
	my $progress = shift;
	my $clients  = shift;
	my $judges   = shift;
	my $client   = $self->{ _client };
	my $division = $progress->current();

	print STDERR "Judge pool scoring window has closed.\n" if $DEBUG;

	my $athlete  = $division->current_athlete();
	my $roundid  = $division->{ round };
	my $form     = $division->{ form };
	my $round    = $athlete->{ scores }{ $roundid };
	my $size     = $request->{ size };
	my $pool     = $round->{ pool };

	try {
		if( $pool ) {
			my ($votes, $scores, $safety) = $pool->votes( $form, 1 );
			$request->{ response } = $votes;
		}

		$self->send_division_response( $request, $progress, $clients );
	} catch {
		$client->send( { json => { error => "$_" }});
	}
}

# ============================================================
sub handle_division_pool_judge_registration {
# ============================================================
	my $self     = shift;
	my $request  = shift;
	my $progress = shift;
	my $clients  = shift;
	my $judges   = shift;
	my $client   = $self->{ _client };
	my $division = $progress->current();
	my $id       = $request->{ id };
	my $num      = $request->{ num };
	my $judge    = $num == 0 ? 'Referee' : 'Judge ' + $num;
	my $sid      = substr( $id, 0, 4 );

	print STDERR "Requesting pool $judge registration ($id).\n" if $DEBUG;

	# De-register the judge from other positions
	foreach my $i ( 0 .. $#$judges ) {
		my $judge = $judges->[ $i ];
		$judges->[ $i ] = {} if( $judge->{ id } eq $id );
	}
	$judges->[ $num ]{ id } = $id;

	print STDERR "  Broadcasting pool judge registration information to:\n" if $DEBUG;
	foreach my $id (sort keys %$clients) {
		my $user = $clients->{ $id };

		printf STDERR "    user: %s (%s)\n", $user->{ role }, $id if $DEBUG;
		$user->{ device }->send( { json => { type => $request->{ type }, action => 'pool judges', judges => $judges }});
	}
	print STDERR "\n" if $DEBUG;

}

# ============================================================
sub handle_division_pool_judge_ready {
# ============================================================
	my $self     = shift;
	my $request  = shift;
	my $progress = shift;
	my $clients  = shift;
	my $judges   = shift;
	my $client   = $self->{ _client };
	my $json     = $self->{ _json };
	my $division = $progress->current();
	my $athlete  = $division->current_athlete();
	my $timers   = exists $division->{ timers } && defined $division->{ timers } ? $json->decode( $division->{ timers }) : { cycle => 2, pause => {} };
	my $jname    = "$request->{ judge }{ fname } $request->{ judge }{ lname }";
	my $message  = "  $jname is ready to score athlete $athlete->{ name }\n";

	print STDERR $message if $DEBUG;

	try {
		my $size     = $request->{ size };          # Required parameter
		my $judge    = $request->{ judge };         # Required parameter
		my $timeout  = $timer->{ pause }{ ready } || $request->{ timeout } || 10;
		my $response = $division->pool_judge_ready( $size, $judge );

		print STDERR "    " . int( @{ $response->{ responded }}) . " out of $size ($response->{ want } wanted)\n" if $DEBUG;

		$division->write();

		$request->{ response } = $response;
		$self->broadcast_division_response( $request, $progress, $clients );

	} catch {
		$client->send( { json => { error => "$_" }});
	}
}

# ============================================================
sub handle_division_pool_resolve {
# ============================================================
	my $self     = shift;
	my $request  = shift;
	my $progress = shift;
	my $clients  = shift;
	my $judges   = shift;
	my $client   = $self->{ _client };
	my $division = $progress->current();
	my $version  = new FreeScore::RCS();
	my $athlete  = $division->current_athlete();

	my $message  = "Manually invoking pool resolution\n";

	print STDERR $message if $DEBUG;

	try {
		my $score = clone( $request->{ score } );
		$version->checkout( $division );

		my $response = $division->resolve_pool();
		$request->{ response } = $response;

		$division->write();
		$version->commit( $division, $message );

		my $round    = $division->{ round };
		my $form     = $athlete->{ scores }{ $round }{ forms }[ $division->{ form } ];
		my $complete = $athlete->{ scores }{ $round }->form_complete( $division->{ form } );

		# ====== INITIATE AUTOPILOT FROM THE SERVER-SIDE
		print STDERR "Checking to see if we should engage autopilot: " . ($complete ? "Yes.\n" : "Not yet.\n") if $DEBUG;
		my $autopilot = $self->autopilot( $request, $progress, $clients, $judges ) if $complete;
		die $autopilot->{ error } if exists $autopilot->{ error };

		$self->broadcast_division_response( $request, $progress, $clients );
	} catch {
		$client->send( { json => { error => "$_" }});
	}
}

# ============================================================
sub handle_division_pool_score {
# ============================================================
	my $self     = shift;
	my $request  = shift;
	my $progress = shift;
	my $clients  = shift;
	my $judges   = shift;
	my $client   = $self->{ _client };
	my $division = $progress->current();
	my $version  = new FreeScore::RCS();
	my $athlete  = $division->current_athlete();
	my $jname    = "$request->{ score }{ judge }{ fname } $request->{ score }{ judge }{ lname }";
	my $message  = "  $jname has scored for $athlete->{ name }\n";

	print STDERR $message if $DEBUG;

	try {
		my $score = clone( $request->{ score } );
		$version->checkout( $division );

		my $response = $division->record_pool_score( $score );
		$request->{ response } = $response;

		$division->write();
		$version->commit( $division, $message );

		# ===== SCORING IS IN PROGRESS; CONFIRM SCORE RECEIVED AND RECORDED
		if( $response->{ status } eq 'in-progress' ) { 
			$self->broadcast_division_response( $request, $progress, $clients );
			return; 

		} elsif( $response->{ status } eq 'fail' ) {
			# ===== A MAJORITY OF POOL JUDGES DISQUALIFY ATHLETE FOR BAD VIDEO
			if( $response->{ solution } eq 'discuss-disqualify' ) {
				print STDERR "  At least one judge has voted to disqualify\n";

			# ===== INSUFFICIENT JUDGES HAVE SCORED
			} elsif( $response->{ solution } eq 'replay' ) {
				print STDERR "  Insufficient judges have scored; rescore the video\n";
			}
			$self->broadcast_division_response( $request, $progress, $clients );
			return;

		} elsif( $response->{ status } eq 'error' ) {
			return;
		}

		my $round    = $division->{ round };
		my $form     = $athlete->{ scores }{ $round }{ forms }[ $division->{ form } ];
		my $complete = $athlete->{ scores }{ $round }->form_complete( $division->{ form } );

		# ====== INITIATE AUTOPILOT FROM THE SERVER-SIDE
		print STDERR "Checking to see if we should engage autopilot: " . ($complete ? "Yes.\n" : "Not yet.\n") if $DEBUG;
		my $autopilot = $self->autopilot( $request, $progress, $clients, $judges ) if $complete;
		die $autopilot->{ error } if exists $autopilot->{ error };

		$self->broadcast_division_response( $request, $progress, $clients );
	} catch {
		$client->send( { json => { error => "$_" }});
	}
}

# ============================================================
sub handle_division_read {
# ============================================================
	my $self     = shift;
	my $request  = shift;
	my $progress = shift;
	my $clients  = shift;
	my $judges   = shift;

	print STDERR "Request division data.\n" if $DEBUG;

	$self->send_division_response( $request, $progress, $clients );
}

# ============================================================
sub handle_division_restore {
# ============================================================
	my $self     = shift;
	my $request  = shift;
	my $progress = shift;
	my $clients  = shift;
	my $judges   = shift;
	my $client   = $self->{ _client };
	my $division = $progress->current();
	my $version  = new FreeScore::RCS();

	print STDERR "Restoring division to version $request->{ version }\n" if $DEBUG;

	try {
		$version->restore( $division, $request->{ version } );
		$division->read();
		$progress->update_division( $division );

		$self->broadcast_division_response( $request, $progress, $clients );
	} catch {
		$client->send( { json => { error => "$_" }});
	}
}

# ============================================================
sub handle_division_round_next {
# ============================================================
	my $self     = shift;
	my $request  = shift;
	my $progress = shift;
	my $clients  = shift;
	my $judges   = shift;
	my $client   = $self->{ _client };
	my $division = $progress->current();

	print STDERR "Next round.\n" if $DEBUG;

	try {
		$division->autopilot( 'off' );
		$division->next_round();
		$division->write();
		$self->broadcast_division_response( $request, $progress, $clients );
	} catch {
		$client->send( { json => { error => "$_" }});
	}
}

# ============================================================
sub handle_division_round_prev {
# ============================================================
	my $self     = shift;
	my $request  = shift;
	my $progress = shift;
	my $clients  = shift;
	my $judges   = shift;
	my $client   = $self->{ _client };
	my $division = $progress->current();

	print STDERR "Previous round.\n" if $DEBUG;

	try {
		$division->autopilot( 'off' );
		$division->previous_round();
		$division->write();
		$self->broadcast_division_response( $request, $progress, $clients );
	} catch {
		$client->send( { json => { error => "$_" }});
	}
}

# ============================================================
sub handle_division_score {
# ============================================================
	my $self     = shift;
	my $request  = shift;
	my $progress = shift;
	my $clients  = shift;
	my $judges   = shift;
	my $client   = $self->{ _client };
	my $division = $progress->current();
	my $version  = new FreeScore::RCS();
	my $athlete  = $division->current_athlete();
	my $jname    = $request->{ cookie }{ judge } == 0 ? 'Referee' : 'Judge ' . $request->{ judge };
	my $message  = "  $jname score for $athlete->{ name }\n";

	print STDERR $message if $DEBUG;

	try {
		my $score = clone( $request->{ score } );
		$version->checkout( $division );
		$division->record_score( $request->{ cookie }{ judge }, $score );
		$division->write();
		$version->commit( $division, $message );

		my $round    = $division->{ round };
		my $form     = $athlete->{ scores }{ $round }{ forms }[ $division->{ form } ];
		my $complete = $athlete->{ scores }{ $round }->form_complete( $division->{ form } );

		# ====== INITIATE AUTOPILOT FROM THE SERVER-SIDE
		print STDERR "Checking to see if we should engage autopilot: " . ($complete ? "Yes.\n" : "Not yet.\n") if $DEBUG;
		my $autopilot = $self->autopilot( $request, $progress, $clients, $judges ) if $complete;
		die $autopilot->{ error } if exists $autopilot->{ error };

		$self->broadcast_division_response( $request, $progress, $clients );
	} catch {
		$client->send( { json => { error => "$_" }});
	}
}

# ============================================================
sub handle_division_write {
# ============================================================
	my $self       = shift;
	my $request    = shift;
	my $progress   = shift;
	my $clients    = shift;
	my $judges     = shift;
	my $client     = $self->{ _client };
	my $tournament = $self->{ _tournament };
	my $ring       = $self->{ _ring };

	print STDERR "Writing division data.\n" if $DEBUG;

	# ===== DIVISION HEADER WHITE LIST
	my $valid = { map { ( $_ => 1 ) } qw( athletes description flight forms judges name ring round ) };

	try {
		my $division = FreeScore::Forms::WorldClass::Division->from_json( $request->{ division } );
		foreach my $key (keys %$division) { delete $division->{ $key } unless exists $valid->{ $key }; }
		if( $ring eq 'staging' ) { $division->{ file } = sprintf( "%s/%s/%s/%s/div.%s.txt",       $FreeScore::PATH, $tournament, $FreeScore::Forms::WorldClass::SUBDIR, $ring, $division->{ name } ); } 
		else                     { $division->{ file } = sprintf( "%s/%s/%s/ring%02d/div.%s.txt", $FreeScore::PATH, $tournament, $FreeScore::Forms::WorldClass::SUBDIR, $ring, $division->{ name } ); }

		my $message   = clone( $division );
		my $unblessed = unbless( $message ); 

		if( -e $division->{ file } && ! exists $request->{ overwrite } ) {
			$client->send( { json => {  type => 'division', action => 'write error', error => "File '$division->{ file }' exists.", division => $unblessed }});

		} else {
			$division->normalize();
			$progress->update_division( $division );
			$division->write();

			# ===== NOTIFY THE CLIENT OF SUCCESSFUL WRITE
			$client->send( { json => {  type => 'division', action => 'write ok', division => $unblessed }});

			# ===== BROADCAST THE UPDATE
			$self->broadcast_ring_response( $request, $progress, $clients );
		}
	} catch {
		$client->send( { json => { error => "$_" }});
	}
}

# ============================================================
sub handle_registration_archive {
# ============================================================
	my $self     = shift;
	my $request  = shift;
	my $progress = shift;
	my $client   = $self->{ _client };

	print STDERR "Archiving previous registration\n" if $DEBUG;
	
	try {
		# ===== MAKE ARCHIVE & CLEAR PREVIOUS VALUES
		my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
		my $archive = sprintf( "archive.%d-%d-%d.%d-%d.tar.gz", ($year + 1900), ($mon + 1), $mday, $hour, $min );

		`cd $path && tar -cvzf $archive forms-grassroots forms-worldclass forms-freestyle sparring-olympic`;
		`cd $path && rm -rf forms-grassroots/*/div*.txt`;
		`cd $path && rm -rf forms-freestyle/*/div*.txt`;
		`cd $path && rm -rf forms-worldclass/*/div*.txt`;
		`cd $path && rm -rf forms-worldclass/schedule.json`;

		$client->send({ json => { request => $request, archive => $archive }});
	} catch {
		$client->send( { json => { error => "$_" }});
	}
}

# ============================================================
sub handle_registration_import {
# ============================================================
	my $self     = shift;
	my $request  = shift;
	my $progress = shift;
	my $client   = $self->{ _client };

	print STDERR "Importing USAT Registration information\n" if $DEBUG;
	
	my @path = split /\//, $progress->{ path }; @path = splice @path, 0, int( @path ) - 2;
	my $path = join '/', @path;
	return if( ! -e "$path/registration.female.txt" || ! -e "$path/registration.male.txt" );

	my $draws = $progress->{ draws };

	# ===== IMPORT
	try {
		my $settings     = $request->{ settings };
		my $female       = read_file( "$path/registration.female.txt" );
		my $male         = read_file( "$path/registration.male.txt" );
		my $registration = new FreeScore::Registration::USAT( $female, $male );
		my $divisions    = $registration->worldclass_poomsae( $settings );
		my $copy         = clone( $request ); delete $copy->{ data };

		foreach my $subevent (keys %$divisions) {
			foreach my $key (keys %{$divisions->{ $subevent }}) {
				my $divid                      = FreeScore::Registration::USAT::divid( $subevent, $key );
				my $athletes                   = $divisions->{ $subevent }{ $key };
				my ($description, $draw)       = FreeScore::Registration::USAT::description( $subevent, $key );
				my $forms                      = assign_draws( $draws, $draw ) if $draws;
				my $round                      = 'prelim'; if( @$athletes <= 8 ) { $round = 'finals'; } elsif( @$athletes < 20 ) { $round = 'semfin'; }
				my $division                   = $progress->create_division( $divid ); 
				$division->{ athletes }        = [ shuffle map { { name => join( " ", map { ucfirst } split /\s+/, $_->{ first }) . ' ' . uc( $_->{ last }), info => { state => $_->{ state }} }} @$athletes ];
				$division->{ current }         = 0;
				$division->{ description }     = $description;
				$division->{ form }            = 0;
				$division->{ forms }           = $draws ? $forms : { prelim => [ 'Open' ], semfin => [ 'Open' ], finals => [ 'Open', 'Open' ]};
				$division->{ judges }          = 5;
				$division->{ order }{ $round } = [ 0 .. $#$athletes ];
				$division->{ round }           = $round;

				print STDERR "  $divid: $description\n" if $DEBUG;
				$division->write();
			}
		}
		$client->send({ json => { request => $copy, result => 'success' }});
	} catch {
		$client->send( { json => { error => "$_", result => 'failure' }});
	}
}

# ============================================================
sub handle_registration_upload {
# ============================================================
	my $self     = shift;
	my $request  = shift;
	my $progress = shift;
	my $client   = $self->{ _client };

	print STDERR "Uploading USAT Registration $request->{ target } information\n" if $DEBUG;
	
	my $target = $request->{ target } =~ /^(?:male|female|usat)$/ ? $request->{ target } : undef;
	return unless defined $target;

	my @path = split /\//, $progress->{ path }; @path = splice @path, 0, int( @path ) - 2;
	my $path = join '/', @path;

	open FILE, ">$path/registration.$target.txt" or die $!;
	print FILE encode( 'UTF-8', $request->{ data });
	close FILE;

	try {
		$client->send({ json => { type => 'registration', action => 'read', result => "$target division file received" }});

	} catch {
		print STDERR "Error: $_\n";
		$client->send( { json => { error => "$_" }});
	}
	my $file = {
		female => "$path/registration.female.txt",
		male   => "$path/registration.male.txt",
		usat   => "$path/registration.usat.txt"
	};
	return unless(( -e $file->{ female } && -e $file->{ male } ) || -e $file->{ usat });

	try {
		my $registration = undef;
		if( -e $file->{ usat }) {
			my $usat      = read_file( $file->{ usat });
			$registration = new FreeScore::Registration::USAT( $usat );

		} elsif( -e $file->{ female } && -e $file->{ male }) {
			my $female    = read_file( $file->{ female });
			my $male      = read_file( $file->{ male });
			$registration = new FreeScore::Registration::USAT( $female, $male );
		}
		return unless $registration;

		my $divisions    = $registration->worldclass_poomsae();
		my $copy         = clone( $request ); delete $copy->{ data };

		$client->send({ json => { request => $copy, divisions => $divisions }});
	} catch {
		$client->send( { json => { error => "$_" }});
	}
}

# ============================================================
sub handle_registration_read {
# ============================================================
	my $self     = shift;
	my $request  = shift;
	my $progress = shift;
	my $client   = $self->{ _client };

	print STDERR "Reading USAT Registration information\n" if $DEBUG;
	
	my @path = split /\//, $progress->{ path }; @path = splice @path, 0, int( @path ) - 2;
	my $path = join '/', @path;

	try {
		my $female    = "$path/registration.female.txt";
		my $male      = "$path/registration.male.txt";
		my $usat      = "$path/registration.usat.txt";
		my $copy      = clone( $request );
		my @divisions = ();
		if( -e $usat ) {
			$usat   = read_file( $usat );
			my $registration = new FreeScore::Registration::USAT( $usat );
			my $poomsae      = $registration->worldclass_poomsae();
			@divisions       = ( divisions => $poomsae );
			$copy->{ action } = 'upload';

			$female = \0;
			$male   = \0;
			$usat   = \1;

		} 
		elsif( -e $male && -e $female ) {
			$female = read_file( $female );
			$male   = read_file( $male );
			my $registration = new FreeScore::Registration::USAT( $female, $male );
			my $poomsae      = $registration->worldclass_poomsae();
			@divisions       = ( divisions => $poomsae );
			$copy->{ action } = 'upload';

			$female = \1;
			$male   = \1;
			$usat   = \0;
		} 
		elsif( -e $male   ) { $female = \0; $male = \1; $usat = \0; }
		elsif( -e $female ) { $female = \1; $male = \0; $usat = \0; }
		else                { $female = \0; $male = \0; $usat = \0; }
		$client->send({ json => { request => $copy, male => $male, female => $female, usat => $usat, @divisions }});
	} catch {
		$client->send( { json => { error => "$_" }});
	}
}

# ============================================================
sub handle_registration_remove {
# ============================================================
	my $self     = shift;
	my $request  = shift;
	my $progress = shift;
	my $client   = $self->{ _client };

	print STDERR "Removing USAT Registration information\n" if $DEBUG;
	
	my $path = "$progress->{ path }/../..";
	my @path = split /\//, $progress->{ path }; @path = splice @path, 0, int( @path ) - 2;
	return if( ! -e "$path/registration.female.txt" || ! -e "$path/registration.male.txt" );

	try {
		my $female = "$path/registration.female.txt";
		my $male   = "$path/registration.male.txt";
		my $copy   = clone( $request );

		unlink $female;
		unlink $male;
		$copy->{ action } = 'remove';

		my $result = -e $female || -e $male ? 'failed' : 'success';

		$client->send({ json => { request => $copy, type => 'registration', action => 'remove', result => $result }});
	} catch {
		$client->send( { json => { error => "$_" }});
	}
}

# ============================================================
sub handle_ring_division_delete {
# ============================================================
	my $self     = shift;
	my $request  = shift;
	my $progress = shift;
	my $clients  = shift;
	my $judges   = shift;
	my $client   = $self->{ _client };

	print STDERR "Deleting division $request->{ divid }.\n" if $DEBUG;

	try {
		$progress->delete_division( $request->{ divid });
		$progress->write();
		$self->broadcast_ring_response( $request, $progress, $clients );
	} catch {
		$client->send( { json => { error => "$_" }});
	}
}

# ============================================================
sub handle_ring_division_merge {
# ============================================================
	my $self     = shift;
	my $request  = shift;
	my $progress = shift;
	my $clients  = shift;
	my $judges   = shift;
	my $client   = $self->{ _client };

	print STDERR "Merging flights for division $request->{ name }.\n" if $DEBUG;

	try {
		$progress->merge_division( $request->{ name });
		$progress->write();
		$self->broadcast_ring_response( $request, $progress, $clients );
	} catch {
		$client->send( { json => { error => "$_" }});
	}
}

# ============================================================
sub handle_ring_division_next {
# ============================================================
	my $self     = shift;
	my $request  = shift;
	my $progress = shift;
	my $clients  = shift;
	my $judges   = shift;
	my $client   = $self->{ _client };

	print STDERR "Next division.\n" if $DEBUG;

	try {
		$progress->next();
		$progress->write();
		$self->broadcast_ring_response( $request, $progress, $clients );
	} catch {
		$client->send( { json => { error => "$_" }});
	}
}

# ============================================================
sub handle_ring_division_prev {
# ============================================================
	my $self     = shift;
	my $request  = shift;
	my $progress = shift;
	my $clients  = shift;
	my $judges   = shift;
	my $client   = $self->{ _client };

	print STDERR "Previous division.\n" if $DEBUG;

	try {
		$progress->previous();
		$progress->write();
		$self->broadcast_ring_response( $request, $progress, $clients );
	} catch {
		$client->send( { json => { error => "$_" }});
	}
}

# ============================================================
sub handle_ring_division_split {
# ============================================================
	my $self     = shift;
	my $request  = shift;
	my $progress = shift;
	my $clients  = shift;
	my $judges   = shift;
	my $client   = $self->{ _client };
	my $divid    = $request->{ name };
	my $flights  = $request->{ flights };

	print STDERR "Splitting division $divid into $flights flights.\n" if $DEBUG;

	try {
		$progress->split_division( $divid, $flights );
		$progress->write();
		$self->broadcast_ring_response( $request, $progress, $clients );
	} catch {
		$client->send( { json => { error => "$_" }});
	}
}

# ============================================================
sub handle_ring_read {
# ============================================================
	my $self     = shift;
	my $request  = shift;
	my $progress = shift;
	my $clients  = shift;
	my $judges   = shift;
	my $ring     = $request->{ ring } eq 'staging' ? 'Staging' : sprintf( "Ring %02d", $request->{ ring } );

	print STDERR "Request $ring data.\n" if $DEBUG;

	$self->send_ring_response( $request, $progress, $clients );
}

# ============================================================
sub send_division_response {
# ============================================================
 	my $self      = shift;
	my $request   = shift;
	my $progress  = shift;
	my $clients   = shift;
	my $judges    = shift;
	my $id        = $self->{ _id };
	my $client    = $self->{ _client };
	my $json      = $self->{ _json };
	my $division  = defined $request->{ divid } ? $progress->find( $request->{ divid } ) : $progress->current();
	my $unblessed = undef;
	my $is_judge  = exists $request->{ cookie }{ judge } && defined $request->{ cookie }{ judge } && $request->{ cookie }{ judge } ne '' && int( $request->{ cookie }{ judge } ) >= 0;
	my $judge     = $is_judge ? int($request->{ cookie }{ judge }) : undef;
	my $role      = exists $request->{ cookie }{ role } ? $request->{ cookie }{ role } : 'client';

	my $message   = clone( $is_judge ? $division->get_only( $judge ) : $division );
	my $unblessed = unbless( $message ); 
	my $encoded   = $json->canonical->encode( $unblessed );
	my $digest    = sha1_hex( $encoded );

	my $jname     = [ qw( R 1 2 3 4 5 6 ) ];

	print STDERR "  Sending division response to " . ($is_judge ? $judge == 0 ? "Referee" : "Judge $judge" : $role) . "\n" if $DEBUG;
	printf STDERR "    user: %s (%s) message: %s\n", $role, substr( $id, 0, 4 ), substr( $digest, 0, 4 ) if $DEBUG;

	$client->send( { json => { type => $request->{ type }, action => 'update', digest => $digest, division => $unblessed, request => $request }});
	$self->{ _last_state } = $digest;
}

# ============================================================
sub send_ring_response {
# ============================================================
 	my $self      = shift;
	my $request   = shift;
	my $progress  = shift;
	my $clients   = shift;
	my $judges    = shift;
	my $id        = $self->{ _id };
	my $client    = $self->{ _client };
	my $json      = $self->{ _json };
	my $unblessed = undef;
	my $is_judge  = exists $request->{ cookie }{ judge } && int( $request->{ cookie }{ judge } ) >= 0;
	my $judge     = $is_judge ? int( $request->{ cookie }{ judge }) : undef;
	my $role      = exists $request->{ cookie }{ role } ? $request->{ cookie }{ role } : 'client';

	my $message   = clone( $progress );
	my $unblessed = unbless( $message ); 
	my $encoded   = $json->canonical->encode( $unblessed );
	my $digest    = sha1_hex( $encoded );

	my $jname     = [ qw( R 1 2 3 4 5 6 ) ];
	print STDERR "  Sending ring response to " . ($is_judge ? "Judge " . $jname->[ $judge ] : $role) . "\n" if $DEBUG;
	printf STDERR "    user: %s (%s) message: %s\n", substr( $id, 0, 4 ), $role, substr( $digest, 0, 4 ) if $DEBUG;

	$client->send( { json => { type => $request->{ type }, action => 'update', digest => $digest, ring => $unblessed, request => $request }});
	$self->{ _last_state } = $digest;
}

# ============================================================
sub handle_ring_transfer {
# ============================================================
	my $self     = shift;
	my $request  = shift;
	my $progress = shift;
	my $clients  = shift;
	my $judges   = shift;
	my $client   = $self->{ _client };
	my $divid    = $request->{ name };
	my $transfer = $request->{ transfer };

	my $destination = $transfer eq 'staging' ? $transfer : sprintf( "Ring %d", $transfer );
	print STDERR "Transfer division $divid to $destination.\n" if $DEBUG;

	try {
		$progress->transfer( $divid, $transfer );

		$self->broadcast_ring_response( $request, $progress, $clients );
	} catch {
		$client->send( { json => { error => "$_" }});
	}
}

# ============================================================
sub handle_ring_draws_delete {
# ============================================================
	my $self     = shift;
	my $request  = shift;
	my $progress = shift;
	my $clients  = shift;
	my $judges   = shift;
	my $client   = $self->{ _client };

	print STDERR "Deleting draws in database.\n" if $DEBUG;

	try {
		$progress->delete_draws();

		$self->broadcast_ring_response( $request, $progress, $clients );
	} catch {
		$client->send( { json => { error => "$_" }});
	}
}
# ============================================================
sub handle_ring_draws_write {
# ============================================================
	my $self     = shift;
	my $request  = shift;
	my $progress = shift;
	my $clients  = shift;
	my $judges   = shift;
	my $client   = $self->{ _client };
	my $draws    = $request->{ draws };

	print STDERR "Writing draws to database.\n" if $DEBUG;

	try {
		$progress->write_draws( $draws );

		$self->broadcast_ring_response( $request, $progress, $clients );
	} catch {
		$client->send( { json => { error => "$_" }});
	}
}

# ============================================================
sub handle_schedule_build {
# ============================================================
	my $self     = shift;
	my $request  = shift;
	my $progress = shift;
	my $json     = $self->{ _json };
	my $client   = $self->{ _client };

	print STDERR "Building schedule... " if $DEBUG;
	
	my $copy       = clone( $request );
	my $path       = "$progress->{ path }/..";
	my $file       = "$path/schedule.json";
	my $tournament = $request->{ tournament };
	my $all        = new FreeScore::Forms::WorldClass( $tournament );

	$divisions = unbless( $all->{ divisions } );
	try {
		unless( -e $file ) {
			$client->send( { json => { error => "Schedule file '$file' does not exist" }});
			return;
		}

		my $schedule = new FreeScore::Forms::WorldClass::Schedule( $file );
		my $build = $schedule->build();
		$schedule->write();

		my $schedule_data = $schedule->data();

		if( $build->{ ok }) {
			$client->send({ json => { type => $request->{ type }, action => $request->{ action }, request => $copy, results => 'ok', schedule => $schedule_data, divisions => $divisions, warnings => $build->{ warnings }}});
			print STDERR "OK\n" if $DEBUG && $build->{ ok };
		} else {
			$client->send({ json => { type => $request->{ type }, action => $request->{ action }, request => $copy, results => 'failed', schedule => $schedule_data, errors => $build->{ errors }, warnings => $build->{ warnings }}});
			print STDERR "failed\n" if $DEBUG;
		}
	} catch {
		$client->send( { json => { error => "$_" }});
	}
}

# ============================================================
sub handle_schedule_check {
# ============================================================
	my $self     = shift;
	my $request  = shift;
	my $progress = shift;
	my $json     = $self->{ _json };
	my $client   = $self->{ _client };

	print STDERR "Checking schedule... " if $DEBUG;
	
	my $copy       = clone( $request );
	my $path       = "$progress->{ path }/..";
	my $file       = "$path/schedule.json";
	my $schedule   = undef;
	my $tournament = $request->{ tournament };
	my $all        = new FreeScore::Forms::WorldClass( $tournament );
	my $build      = { ok => 0 };
	my $check      = { ok => 0 };

	$divisions = unbless( $all->{ divisions } );
	try {
		unless( -e $file ) {
			$client->send( { json => { error => "Schedule file '$file' does not exist" }});
			return;
		}

		$schedule = new FreeScore::Forms::WorldClass::Schedule( $file );
		$check    = $schedule->check();

		if( $check->{ ok }) {
			$client->send({ json => { type => $request->{ type }, action => $request->{ action }, request => $copy, results => 'ok', schedule => $schedule->data(), divisions => $divisions, warnings => $check->{ warnings }}});
			print STDERR "OK\n" if $DEBUG && $check->{ ok };
		} else {
			my $error  = @{ $check->{ errors }} ? $check->{ errors }[ 0 ] : undef;
			my $reason = $error ? $error->{ cause }{ reason } : $check->{ results };
			$client->send({ json => { type => $request->{ type }, action => $request->{ action }, request => $copy, results => 'failed', schedule => $schedule->data(), errors => $check->{ errors }, warnings => $check->{ warnings }}});
			print STDERR "$reason\n" if $DEBUG;
		}
	} catch {
		$client->send( { json => { error => "$_" }});
	}
}

# ============================================================
sub handle_schedule_read {
# ============================================================
	my $self     = shift;
	my $request  = shift;
	my $progress = shift;
	my $json     = $self->{ _json };
	my $client   = $self->{ _client };

	print STDERR "Reading schedule information\n" if $DEBUG;
	
	my $copy       = clone( $request );
	my $path       = "$progress->{ path }/..";
	my $file       = "$path/schedule.json";
	my $schedule   = undef;
	my $tournament = $request->{ tournament };
	my $all        = new FreeScore::Forms::WorldClass( $tournament );

	$divisions = unbless( $all->{ divisions } );
	try {
		if( -e $file ) {
			$schedule = new FreeScore::Forms::WorldClass::Schedule( $file );
			$client->send({ json => { type => $request->{ type }, action => $request->{ action }, request => $copy, schedule => $schedule->data(), divisions => $divisions }});
		} else {
			$client->send({ json => { type => $request->{ type }, action => $request->{ action }, request => $copy, divisions => $divisions }});
		}
	} catch {
		$client->send( { json => { error => "$_" }});
	}
}

# ============================================================
sub handle_schedule_remove {
# ============================================================
	my $self     = shift;
	my $request  = shift;
	my $progress = shift;
	my $client   = $self->{ _client };

	print STDERR "Removing schedule information\n" if $DEBUG;
	
	my $path = "$progress->{ path }/..";
	try {
		unlink( "$path/schedule.json" );
		$client->send({ json => { request => $copy, result => 'success' }});
	} catch {
		$client->send( { json => { error => "$_" }});
	}
}

# ============================================================
sub handle_schedule_write {
# ============================================================
	my $self     = shift;
	my $request  = shift;
	my $progress = shift;
	my $client   = $self->{ _client };
	my $json     = $self->{ _json };

	print STDERR "Writing schedule information\n" if $DEBUG;
	
	my $path       = "$progress->{ path }/..";
	my $file       = "$path/schedule.json";
	my $schedule   = $request->{ schedule };
	my $tournament = $request->{ tournament };
	my $all        = new FreeScore::Forms::WorldClass( $tournament );

	# ===== DO NOT CACHE DIVISION INFORMATION; RETRIEVE IT FRESH FROM THE DB EVERY TIME
	$divisions = unbless( $all->{ divisions } );
	$schedule  = bless $schedule, 'FreeScore::Forms::WorldClass::Schedule';

	$schedule->clear() if( $request->{ clear });

	try {
		$schedule->write( $file );
		$client->send( { json => {  type => 'schedule', schedule => $schedule->data(), divisions => $divisions, action => 'write', result => 'ok' }});
	} catch {
		$client->send( { json => { error => "$_" }});
	}
}

# ============================================================
sub assign_draws {
# ============================================================
	my $draws = shift;
	my $draw  = shift;

	my $event   = $draw->{ event };
	my $gender  = $draw->{ gender };
	my $age     = $draw->{ age };
	my $default = { prelim => [ 'Open' ], semfin => [ 'Open' ], finals => [ 'Open', 'Open' ]};
	
	return $default unless exists $draws->{ $event };
	my $forms = $draws->{ $event };

	if   ( exists $forms->{ $gender }) { $forms = $forms->{ $gender }; }
	elsif( exists $forms->{ c }      ) { $forms = $forms->{ c };       }
	else { return $default; }

	return $default unless exists $forms->{ $age };
	return $forms->{ $age };
}

# ============================================================
sub autopilot {
# ============================================================
#** @method( request, progress, clients, judges )
#   @brief Automatically advances to the next form/athlete/round/division
#   Called when judges finish scoring an athlete's form 
#*

	my $self     = shift;
	my $request  = shift;
	my $progress = shift;
	my $clients  = shift;
	my $judges   = shift;
	my $division = $progress->current();
	my $json     = $self->{ _json };
	my $timers   = exists $division->{ timers } && defined $division->{ timers } ? $json->decode( $division->{ timers }) : { cycle => 2 };
	my $cycle    = $timers->{ cycle };

	# ===== DISALLOW REDUNDANT AUTOPILOT REQUESTS
	if( my $locked = $division->autopilot() ) { print STDERR "Autopilot already engaged.\n" if $DEBUG; return { warning => 'Autopilot is already engaged.' }; }

	# ===== PREVENT ECHOING LAST REQUEST
	$request = { action => 'engage autopilot', type => 'division' };

	# ===== ENGAGE AUTOPILOT
	try {
		print STDERR "Engaging autopilot.\n" if $DEBUG;
		$division->autopilot( 'on' );
		$division->write();
	} catch {
		return { error => $_ };
	};

	my $pause    = $timers->{ pause } if exists $timers->{ pause } && defined $timers->{ pause };
	my $round    = $division->{ round };
	my $order    = $division->{ order }{ $round };
	my $forms    = $division->{ forms }{ $round };
	my $pending  = $division->{ pending }{ $round };
	my $athlete  = $division->current_athlete();
	my $score    = $athlete->{ scores }{ $round };
	my $punitive = $score ? $score->any_punitive_decision() : 0;
	my $j        = first_index { $_ == $division->{ current } } @$order;
 
	# Default pauses
	$pause->{ score }       ||= 9;
	$pause->{ leaderboard } ||= 12;
	$pause->{ brief }       ||= 1;

	my $last = {
		athlete => (int( @$pending ) == 0),
		form    => ($division->{ form }    == int( @$forms ) - 1) || $punitive,
		round   => ($division->{ round } eq 'finals' || $division->{ round } eq 'ro2'),
		cycle   => (!(($j + 1) % $cycle)),
	};

	# ===== AUTOPILOT BEHAVIOR
	# Autopilot behavior comprises the two afforementioned actions in
	# serial, with delays between.
	my $delay = new Mojo::IOLoop::Delay();
	$delay->steps(
		sub { # Display the athlete's score for 9 seconds
			my $delay = shift;
			Mojo::IOLoop->timer( $pause->{ score } => $delay->begin );
		},
		sub { 
			my $delay = shift;

			die "Disengaging autopilot\n" unless $division->autopilot();

			# Display the leaderboard for 12 seconds every $cycle athlete, or last athlete
			if( $last->{ form } && ( $last->{ cycle } || $last->{ athlete } )) { 
				print STDERR "Showing leaderboard.\n" if $DEBUG;
				$division->display() unless $division->is_display(); 
				$division->write(); 
				Mojo::IOLoop->timer( $pause->{ leaderboard } => $delay->begin );
				$self->broadcast_division_response( $request, $progress, $clients, $judges );

			# Otherwise keep displaying the score for another second
			} else {
				Mojo::IOLoop->timer( $pause->{ brief } => $delay->begin );
			}
		},
		sub { # Advance to the next form/athlete/round
			my $delay = shift;

			die "Disengaging autopilot\n" unless $division->autopilot();
			print STDERR "Advancing the division to next item.\n" if $DEBUG;

			my $go_next = {
				round   =>   $last->{ form } &&   $last->{ athlete } && ! $last->{ round },
				athlete =>   $last->{ form } && ! $last->{ athlete },
				form    => ! $last->{ form }
			};

			if    ( $go_next->{ round }   ) { $division->next_round(); $division->first_form(); }
			elsif ( $go_next->{ athlete } ) { $division->next_available_athlete(); }
			elsif ( $go_next->{ form }    ) { $division->next_form(); }
			$division->autopilot( 'off' ); # Finished. Disengage autopilot for now.
			$division->write();

			$self->broadcast_division_response( $request, $progress, $clients, $judges );
		},
	)->catch( sub {
		my $delay = shift;
		my $error = shift;

	})->wait();
}

1;
