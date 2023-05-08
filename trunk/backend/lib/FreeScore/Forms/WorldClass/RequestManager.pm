package FreeScore::Forms::WorldClass::RequestManager;
use lib qw( /usr/local/freescore/lib );
use base FreeScore::RequestManager;
use Try::Tiny;
use FreeScore;
use FreeScore::RCS;
use FreeScore::Forms::WorldClass;
use FreeScore::Forms::WorldClass::Schedule;
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
sub init {
# ============================================================
	my $self               = shift;
	$self->{ _tournament } = shift;
	$self->{ _ring }       = shift;
	$self->{ _id }         = shift;
	$self->{ _client }     = shift;
	$self->{ _json }       = new JSON::XS();
	$self->{ _watching }   = {};
	$self->{ division }    = {
		athlete_delete     => \&handle_division_athlete_delete,
		athlete_next       => \&handle_division_athlete_next,
		athlete_prev       => \&handle_division_athlete_prev,
		award_penalty      => \&handle_division_award_penalty,
		award_punitive     => \&handle_division_award_punitive,
		clear_judge_score  => \&handle_division_clear_judge_score,
		display            => \&handle_division_display,
		edit_athletes      => \&handle_division_edit_athletes,
		form_next          => \&handle_division_form_next,
		form_prev          => \&handle_division_form_prev,
		history            => \&handle_division_history,
		judge_query        => \&handle_division_judge_query,
		navigate           => \&handle_division_navigate,
		read               => \&handle_division_read,
		restore            => \&handle_division_restore,
		round_next         => \&handle_division_round_next,
		round_prev         => \&handle_division_round_prev,
		score              => \&handle_division_score,
		write              => \&handle_division_write,
	};
	$self->{ ring }        = {
		division_delete    => \&handle_ring_division_delete,
		division_merge     => \&handle_ring_division_merge,
		division_next      => \&handle_ring_division_next,
		division_prev      => \&handle_ring_division_prev,
		division_split     => \&handle_ring_division_split,
		read               => \&handle_ring_read,
		transfer           => \&handle_ring_transfer,
	};
	$self->{ tournament } = {
		read               => \&handle_tournament_read,
		draws_delete       => \&handle_tournament_draws_delete,
		draws_write        => \&handle_tournament_draws_write,
	};
	$self->init_client_server();
}

# ============================================================
sub handle_division_award_penalty {
# ============================================================
	my $self     = shift;
	my $request  = shift;
	my $progress = shift;
	my $group    = shift;
	my $client   = $self->{ _client };
	my $division = $progress->current();
	my $version  = new FreeScore::RCS();
	my $i        = $division->{ current };
	my $athlete  = $division->{ athletes }[ $i ];
	my $penalty  = join( ", ", grep { $request->{ penalties }{ $_ } > 0 } sort keys %{ $request->{ penalties }} );
	my $message  = $penalty ? "Award $penalty penalty to $athlete->{ name }\n" : "Clear penalties for $athlete->{ name }\n";

	print STDERR $message if $DEBUG;

	try {
		$version->checkout( $division );
		$division->record_penalties( $request->{ penalties });
		$division->write();
		$version->commit( $division, $message );

		$self->broadcast_updated_division( $request, $progress, $group );
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
	my $group    = shift;
	my $client   = $self->{ _client };
	my $division = $progress->current();
	my $version  = new FreeScore::RCS();
	my $i        = $request->{ athlete_id };
	my $athlete  = $division->{ athletes }[ $i ];
	my $decision = $request->{ decision };
	my $message  = "Award punitive decision $decision penalty to $athlete->{ name }\n";

	print STDERR $message if $DEBUG;

	try {
		$version->checkout( $division);
		$division->record_decision( $request->{ decision }, $request->{ athlete_id });
		$division->next_available_athlete() unless $request->{ decision } eq 'clear';
		$division->write();
		$version->commit( $division, $message );

		$self->broadcast_updated_division( $request, $progress, $group );
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
	my $group    = shift;
	my $client   = $self->{ _client };
	my $division = $progress->current();
	my $version  = new FreeScore::RCS();
	my $i        = $division->{ current };
	my $athlete  = $division->{ athletes }[ $i ];
	my $message  = "Deleting $athlete->{ name } from division\n";

	print STDERR $message if $DEBUG;

	try {
		$version->checkout( $division );
		$division->remove_athlete( $request->{ athlete_id } );
		$division->write();
		$version->commit( $division, $message );

		$self->broadcast_updated_division( $request, $progress, $group );
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
	my $group    = shift;
	my $client   = $self->{ _client };
	my $division = $progress->current();

	print STDERR "Next athlete.\n" if $DEBUG;

	try {
		$division->autopilot( 'off' );
		$division->next_athlete();
		$division->write();

		$self->broadcast_updated_division( $request, $progress, $group );
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
	my $group    = shift;
	my $client   = $self->{ _client };
	my $division = $progress->current();

	print STDERR "Previous athlete.\n" if $DEBUG;

	try {
		$division->autopilot( 'off' );
		$division->previous_athlete();
		$division->write();

		$self->broadcast_updated_division( $request, $progress, $group );
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
	my $group    = shift;
	my $client   = $self->{ _client };
	my $division = $progress->current();
	my $version  = new FreeScore::RCS();
	my $i        = $division->{ current };
	my $athlete  = $division->{ athletes }[ $i ];
	my $jname    = $request->{ judge } == 0 ? 'Referee' : 'Judge ' . $request->{ judge };
	my $message  = "Clearing $jname score for $athlete->{ name }\n";

	print STDERR $message if $DEBUG;

	try {
		$version->checkout( $division );
		$division->clear_score( $request->{ judge } );
		$division->write();
		$version->commit( $division, $message );

		$self->broadcast_updated_division( $request, $progress, $group );
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
	my $group    = shift;
	my $client   = $self->{ _client };
	my $division = $progress->current();

	print STDERR "Change display.\n" if $DEBUG;

	try {
		$division->autopilot( 'off' );
		if( $division->is_display() ) { $division->score();   } 
		else                          { $division->display(); }
		$division->write();

		$self->broadcast_updated_division( $request, $progress, $group );
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
	my $group    = shift;
	my $client   = $self->{ _client };

	print STDERR "Editing division athletes.\n" if $DEBUG;

	try {
		my $division = $progress->find( $request->{ divid } ) or die "Can't find division " . uc( $request->{ divid }) . " $!";
		$division->edit_athletes( $request->{ athletes }, $request->{ round } );
		$division->write();

		$self->broadcast_updated_division( $request, $progress, $group );
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
	my $group    = shift;
	my $client   = $self->{ _client };
	my $division = $progress->current();

	print STDERR "Next form.\n" if $DEBUG;

	try {
		$division->autopilot( 'off' );
		$division->next_form();
		$division->write();
		$self->broadcast_updated_division( $request, $progress, $group );
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
	my $group    = shift;
	my $client   = $self->{ _client };
	my $division = $progress->current();

	print STDERR "Previous form.\n" if $DEBUG;

	try {
		$division->autopilot( 'off' );
		$division->previous_form();
		$division->write();
		$self->broadcast_updated_division( $request, $progress, $group );
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
	my $group    = shift;
	my $client   = $self->{ _client };
	my $division = $progress->current();
	my $version  = new FreeScore::RCS();

	print STDERR "Request history log\n" if $DEBUG;

	try {
		my @history = $version->history( $division );
		$division->{ history } = [ @history ];
		$self->broadcast_updated_division( $request, $progress, $group );
	} catch {
		$client->send( { json => { error => "$_" }});
	}
}

# ============================================================
sub handle_division_judge_query {
# ============================================================
	my $self       = shift;
	my $request    = shift;
	my $progress   = shift;
	my $group      = shift;
	my $division   = $progress->current();
	my $n          = $division->{ judges };
	my $judges     = [];

	foreach my $i ( 0 .. $n - 1 ) {
		my $name = $i == 0 ? 'Referee' : "Judge $i";
		$judges[ $i ] = { cid => undef, jid => $i, name => $name };
	}

	foreach my $judge ($group->judges()) {
		my $jid  = $judge->jid();
		next if $jid >= $n;
		my $name = $jid == 0 ? 'Referee' : "Judge $jid";
		$judges[ $jid ] = { cid => $judge->cid(), jid => $judge->jid(), name => $name };
	}

	$client->send( { json => { type => 'division', action => 'judges', judges => $judges }} );
}

# ============================================================
sub handle_division_navigate {
# ============================================================
	my $self     = shift;
	my $request  = shift;
	my $progress = shift;
	my $group    = shift;
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
			$self->broadcast_updated_ring( $request, $progress, $group );
		}
		elsif( $object =~ /^(?:athlete|round|form)$/i ) { 
			$division->navigate( $object, $i ); 
			$division->autopilot( 'off' );
			$division->write();
			$self->broadcast_updated_division( $request, $progress, $group );
		}
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
	my $group    = shift;

	print STDERR "Request division data.\n" if $DEBUG;

	$self->send_division_response( $request, $progress, $group );
}

# ============================================================
sub handle_division_restore {
# ============================================================
	my $self     = shift;
	my $request  = shift;
	my $progress = shift;
	my $group    = shift;
	my $client   = $self->{ _client };
	my $division = $progress->current();
	my $version  = new FreeScore::RCS();

	print STDERR "Restoring division to version $request->{ version }\n" if $DEBUG;

	try {
		$version->restore( $division, $request->{ version } );
		$division->read();
		$progress->update_division( $division );

		$self->broadcast_updated_division( $request, $progress, $group );
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
	my $group    = shift;
	my $client   = $self->{ _client };
	my $division = $progress->current();

	print STDERR "Next round.\n" if $DEBUG;

	try {
		$division->autopilot( 'off' );
		$division->next_round();
		$division->write();
		$self->broadcast_updated_division( $request, $progress, $group );
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
	my $group    = shift;
	my $client   = $self->{ _client };
	my $division = $progress->current();

	print STDERR "Previous round.\n" if $DEBUG;

	try {
		$division->autopilot( 'off' );
		$division->previous_round();
		$division->write();
		$self->broadcast_updated_division( $request, $progress, $group );
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
	my $group    = shift;
	my $client   = $self->{ _client };
	my $division = $progress->current();
	my $version  = new FreeScore::RCS();
	my $i        = $division->{ current };
	my $athlete  = $division->{ athletes }[ $i ];
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
		my $athlete  = $division->{ athletes }[ $division->{ current } ];
		my $form     = $athlete->{ scores }{ $round }{ forms }[ $division->{ form } ];
		my $complete = $athlete->{ scores }{ $round }->form_complete( $division->{ form } );

		# ====== INITIATE AUTOPILOT FROM THE SERVER-SIDE
		print STDERR "Checking to see if we should engage autopilot: " . ($complete ? "Yes.\n" : "Not yet.\n") if $DEBUG;
		my $autopilot = $self->autopilot( $request, $progress, $group ) if $complete;
		die $autopilot->{ error } if exists $autopilot->{ error };

		$self->broadcast_updated_division( $request, $progress, $group );
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
	my $group      = shift;
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
			$self->broadcast_updated_ring( $request, $progress, $group );
		}
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
	my $group    = shift;
	my $client   = $self->{ _client };

	print STDERR "Deleting division $request->{ divid }.\n" if $DEBUG;

	try {
		$progress->delete_division( $request->{ divid });
		$progress->write();
		$self->broadcast_updated_ring( $request, $progress, $group );
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
	my $group    = shift;
	my $client   = $self->{ _client };

	print STDERR "Merging flights for division $request->{ name }.\n" if $DEBUG;

	try {
		$progress->merge_division( $request->{ name });
		$progress->write();
		$self->broadcast_updated_ring( $request, $progress, $group );
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
	my $group    = shift;
	my $client   = $self->{ _client };

	print STDERR "Next division.\n" if $DEBUG;

	try {
		$progress->next();
		$progress->write();
		$self->broadcast_updated_ring( $request, $progress, $group );
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
	my $group    = shift;
	my $client   = $self->{ _client };

	print STDERR "Previous division.\n" if $DEBUG;

	try {
		$progress->previous();
		$progress->write();
		$self->broadcast_updated_ring( $request, $progress, $group );
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
	my $group    = shift;
	my $client   = $self->{ _client };
	my $divid    = $request->{ name };
	my $flights  = $request->{ flights };

	print STDERR "Splitting division $divid into $flights flights.\n" if $DEBUG;

	try {
		$progress->split_division( $divid, $flights );
		$progress->write();
		$self->broadcast_updated_ring( $request, $progress, $group );
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
	my $group    = shift;
	my $ring     = $request->{ ring } eq 'staging' ? 'Staging' : sprintf( "Ring %02d", $request->{ ring } );

	print STDERR "Request $ring data.\n" if $DEBUG;

	$self->send_ring_response( $request, $progress, $group );
}

# ============================================================
sub send_division_response {
# ============================================================
 	my $self      = shift;
	my $request   = shift;
	my $progress  = shift;
	my $group     = shift;
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
	my $group     = shift;
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
	my $group    = shift;
	my $client   = $self->{ _client };
	my $divid    = $request->{ name };
	my $transfer = $request->{ transfer };

	my $destination = $transfer eq 'staging' ? $transfer : sprintf( "Ring %d", $transfer );
	print STDERR "Transfer division $divid to $destination.\n" if $DEBUG;

	try {
		$progress->transfer( $divid, $transfer );

		$self->broadcast_updated_ring( $request, $progress, $group );
	} catch {
		$client->send( { json => { error => "$_" }});
	}
}

# ============================================================
sub handle_tournament_draws_delete {
# ============================================================
	my $self     = shift;
	my $request  = shift;
	my $progress = shift;
	my $group    = shift;
	my $client   = $self->{ _client };

	print STDERR "Deleting draws in database.\n" if $DEBUG;

	try {
		$progress->delete_draws();

		$self->broadcast_updated_ring( $request, $progress, $group );
	} catch {
		$client->send( { json => { error => "$_" }});
	}
}

# ============================================================
sub handle_tournament_read {
# ============================================================
	my $self     = shift;
	my $request  = shift;
	my $progress = shift;
	my $json     = $self->{ _json };
	my $client   = $self->{ _client };

	print STDERR "Reading all ring information\n" if $DEBUG;
	
	my $copy       = clone( $request );
	my $tournament = $request->{ tournament };
	my $all        = new FreeScore::Forms::WorldClass( $tournament );

	$divisions = unbless( $all->{ divisions } );
	try {
		$client->send({ json => { type => $request->{ type }, action => $request->{ action }, request => $copy, divisions => $divisions }});
	} catch {
		$client->send( { json => { error => "$_" }});
	}
}

# ============================================================
sub handle_tournament_draws_write {
# ============================================================
	my $self     = shift;
	my $request  = shift;
	my $progress = shift;
	my $group    = shift;
	my $client   = $self->{ _client };
	my $draws    = $request->{ draws };

	print STDERR "Writing draws to database.\n" if $DEBUG;

	try {
		$progress->write_draws( $draws );

		$self->broadcast_updated_ring( $request, $progress, $group );
	} catch {
		$client->send( { json => { error => "$_" }});
	}
}

# ============================================================
sub autopilot {
# ============================================================
#** @method( request, progress, group )
#   @brief Automatically advances to the next form/athlete/round/division
#   Called when judges finish scoring an athlete's form 
#*

	my $self     = shift;
	my $request  = shift;
	my $progress = shift;
	my $group    = shift;
	my $division = $progress->current();
	my $cycle    = $division->{ autodisplay } || 2;

	request->{ type } = 'autopilot';

	# ===== DISALLOW REDUNDANT AUTOPILOT REQUESTS
	# if( $division->autopilot() ) { print STDERR "Autopilot already engaged.\n" if $DEBUG; return { warning => 'Autopilot is already engaged.' }; }

	# ===== ENGAGE AUTOPILOT
	try {
		print STDERR "Engaging autopilot.\n" if $DEBUG;
		$division->autopilot( 'on' );
		$division->write();
	} catch {
		return { error => $_ };
	};

	my $pause = { score => 9, leaderboard => 12, brief => 1 };
	my $round = $division->{ round };
	my $order = $division->{ order }{ $round };
	my $forms = $division->{ forms }{ $round };
	my $j     = first_index { $_ == $division->{ current } } @$order;

	my $last = {
		athlete => ($division->{ current } == $order->[ -1 ]),
		form    => ($division->{ form }    == int( @$forms ) - 1),
		round   => ($division->{ round } eq 'finals' || $division->{ round } eq 'ro2'),
		cycle   => (!(($j + 1) % $cycle)),
	};

	# ===== AUTOPILOT BEHAVIOR
	# Autopilot behavior comprises the two afforementioned actions in
	# serial, with delays between.
	my $delay = new Mojo::IOLoop::Delay();
	my $show = {
		score => sub { # Display the athlete's score for 9 seconds
			my $delay = shift;
			Mojo::IOLoop->timer( $pause->{ score } => $delay->begin );
			$request->{ action } = 'scoreboard';
			$self->broadcast_updated_division( $request, $progress, $group );
		},
		leaderboard => sub { 
			my $delay = shift;

			die "Disengaging autopilot\n" unless $division->autopilot();

			# Display the leaderboard for 12 seconds every $cycle athlete, or last athlete
			if( $last->{ form } && ( $last->{ cycle } || $last->{ athlete } )) { 
				print STDERR "Showing leaderboard.\n" if $DEBUG;
				$division->display() unless $division->is_display(); 
				$division->write(); 
				Mojo::IOLoop->timer( $pause->{ leaderboard } => $delay->begin );
				$request->{ action } = 'leaderboard';
				$self->broadcast_updated_division( $request, $progress, $group );

			# Otherwise keep displaying the score for another second
			} else {
				Mojo::IOLoop->timer( $pause->{ brief } => $delay->begin );
			}
		},
		next => sub { # Advance to the next form/athlete/round
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

			$request->{ action } = 'next';
			$self->broadcast_updated_division( $request, $progress, $group );
		}
	};
	my @steps = ( $show->{ score }, $show->{ leaderboard }, $show->{ next });
	$delay->steps( @steps )->catch( sub {} )->wait();
}

1;
