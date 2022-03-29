package FreeScore::Forms::WorldClass::Schedule::Block;

use List::MoreUtils qw( uniq );
use Date::Manip;
use FreeScore::Forms::WorldClass::Schedule;

sub by_priority($$);

# ============================================================
sub by_priority($$) {
# ============================================================
	my $a = shift;
	my $b = shift;

	return 0 ||
		int( @{ $b->{ require }{ nonconcurrent }}) <=> int( @{ $a->{ require }{ nonconcurrent }}) ||
		int( @{ $a->{ require }{ precondition }})  <=> int( @{ $b->{ require }{ precondition }})  ||
		$a->age() <=> $b->age();
		
}

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
	my $self     = shift;
	my $division = shift;
	my $athletes = shift;
	my $round    = shift;
	my $flight   = shift;
	my @id       = ();
	my $forms    = exists $division->{ forms } && defined $division->{ forms } && exists $division->{ forms }{ $round } ? $division->{ forms }{ $round } : 1;
	my $t        = $FreeScore::Forms::WorldClass::Schedule::TIME_PER_FORM * $athletes;

	if( exists $division->{ freestyle }) { $t = $FreeScore::Forms::WorldClass::Schedule::TIME_PER_FREESTYLE_FORM * $athletes; }

	$self->{ athletes }    = $athletes;
	$self->{ division }    = $division->{ name };
	$self->{ description } = $division->{ description };
	$self->{ round }       = $round;
	$self->{ flight }      = $flight || '';
	$self->{ duration }    = $forms ? $forms * $t : ( $round eq 'finals' ? 2 * $t : $t );

	my $key = $self->match(); $key =~ s/\s+/-/g;
	push @id, $division->{ name }, $key, $round, (defined( $flight ) ? $flight : ());
	$self->{ id } = join '|', @id;

	$division->{ blocks } = [ uniq( @{ $division->{ blocks }}, $self->{ id } )];
}

# ============================================================
sub precondition_is_satisfied {
# ============================================================
	my $self  = shift;
	my $other = shift;

	return 0 unless $other->{ day } && $other->{ start } && $other->{ stop }; # Precondition isn't even planned yet
	return 0 if( $self->{ day } < $other->{ day }); # Impossible if the precondition is scheduled for the following day

	my $a   = new Date::Manip::Date( $self->{ start }); die "Bad timestamp '$self->{ start }'" unless $a;
	my $b   = new Date::Manip::Date( $other->{ stop }); die "Bad timestamp '$other->{ stop }'" unless $b;
	my $cmp = $a->cmp( $b );

	return $cmp > 0;
}

# ============================================================
sub is_concurrent {
# ============================================================
	my $self  = shift;
	my $other = shift;

	return 0 unless $other->{ start } && $other->{ stop }; # Other has not yet been planned
	return 0 unless ( $self->{ day } == $other->{ day });  # Different day, no problems here
	
	my $a_start = new Date::Manip::Date( $self->{ start });  die "Bad timestamp '$self->{ start }'"  unless $a_start;
	my $a_stop  = new Date::Manip::Date( $self->{ stop });   die "Bad timestamp '$self->{ stop }'"   unless $a_stop;
	my $b_start = new Date::Manip::Date( $other->{ start }); die "Bad timestamp '$other->{ start }'" unless $b_start;
	my $b_stop  = new Date::Manip::Date( $other->{ stop });  die "Bad timestamp '$other->{ stop }'"  unless $b_stop;

	my $a_while_b = $a_start->cmp( $b_start ) >= 0 && $a_start->cmp( $b_stop ) < 0;
	my $b_while_a = $b_start->cmp( $a_start ) >= 0 && $b_start->cmp( $a_stop ) < 0;

	return $a_while_b || $b_while_a;
}

# ============================================================
sub match {
# ============================================================
	my $self    = shift;
	my $targets = shift;

	my $regex = {
		# ===== EVENT
		freestyle  => { rank => 0, pattern => qr/freestyle/i },

		# ===== GENDERS
		mixed      => { rank => 1, pattern => qr/mixed/i },
		male       => { rank => 1, pattern => qr/\bmale/i },
		female     => { rank => 1, pattern => qr/\bfemale/i },

		# ===== SUBEVENTS
		individual => { rank => 2, pattern => qr/individual/i },
		pair       => { rank => 2, pattern => qr/pair/i },
		team       => { rank => 2, pattern => qr/team/i },

		# ===== AGES
		youth      => { rank => 3, pattern => qr/10-11|youth/i },
		cadet      => { rank => 3, pattern => qr/12-14|cadet/i },
		junior     => { rank => 3, pattern => qr/15-17|12-17|junior/i },
		under17    => { rank => 3, pattern => qr/12-17|under\s*17/i },
		over17     => { rank => 3, pattern => qr/18-99|over\s*17|17\+/i },
		under30    => { rank => 3, pattern => qr/18-30|under\s*30|-30|30-|senior(?!\s*(?:[2-9]\d*|0*1\d+))|senior\s*1/i },
		over30     => { rank => 3, pattern => qr/31-99|over\s*30|30\+/i },
		under40    => { rank => 3, pattern => qr/31-40|under\s*40|-40|40-|senior 2/i },
		under50    => { rank => 3, pattern => qr/41-50|under\s*50|-50|50-/i },
		under60    => { rank => 3, pattern => qr/51-60|under\s*60|-60|60-/i },
		under65    => { rank => 3, pattern => qr/61-65|under\s*65|-65|65-/i },
		over65     => { rank => 3, pattern => qr/66-99|over\s*65|65\+|66\+/i }
	};

	if( ! defined( $targets )) { $targets = [ $self ]; }

	my $lookup = {};
	foreach my $target (@$targets) {
		my $description = [];
		foreach $key (keys %$regex) {
			if( $target->{ description } =~ $regex->{ $key }{ pattern }) {
				push @$description, { text => $key, rank => $regex->{ $key }{ rank }};
			} 
		}
		$description = join ' ', map { $_->{ text } } sort { $a->{ rank } <=> $b->{ rank } } @$description;
		$lookup->{ $description } = $target;
	}
	if( $targets->[ 0 ] == $self ) {
		my $key = (keys %$lookup)[ 0 ];
		return $key;
	} else {
		return $lookup;
	}
}


# ============================================================
sub age {
# ============================================================
	my $self    = shift;

	my $regex = {
		youth      => { age => 10, pattern => qr/10-11|youth/i },
		cadet      => { age => 12, pattern => qr/12-14|cadet/i },
		junior     => { age => 15, pattern => qr/15-17|junior/i },
		under17    => { age => 15, pattern => qr/12-17|under\s*17/i },
		under30    => { age => 18, pattern => qr/18-30|under\s*30|-30|30-|senior(?!\s*(?:[2-9]\d*|0*1\d+))|senior\s*1/i },
		over17     => { age => 18, pattern => qr/18-99|over\s*17|17\+|18\+/i },
		over30     => { age => 31, pattern => qr/31-99|over\s*30|30\+/i },
		under40    => { age => 31, pattern => qr/31-40|under\s*40|-40|40-|senior 2/i },
		under50    => { age => 41, pattern => qr/41-50|under\s*50|-50|50-/i },
		under60    => { age => 51, pattern => qr/51-60|under\s*60|-60|60-/i },
		under65    => { age => 61, pattern => qr/61-65|under\s*65|-65|65-/i },
		over65     => { age => 66, pattern => qr/66-99|over\s*65|65\+|66\+/i }
	};
	foreach $key (keys %$regex) {
		return $regex->{ $key }{ age } if( $self->{ description } =~ $regex->{ $key }{ pattern });
	}

	return "under30"; # Default is Senior
}

# ============================================================
sub overtime_for_day {
# ============================================================
	my $self = shift;
	my $day  = shift;

	return 0 unless exists $day->{ stop } && exists $self->{ stop };

	my $day_stop   = new Date::Manip::Date( $day->{ stop });
	my $block_stop = new Date::Manip::Date( $self->{ stop });
	my $overtime   = $block_stop->cmp( $day_stop ) > 0;

	return 1 if( $overtime );
}

# ============================================================
sub overtime_for_ring {
# ============================================================
	my $self = shift;
	my $ring = shift;

	return 0 unless defined $ring;
	return 0 unless exists $ring->{ stop };

	my $ring_stop  = new Date::Manip::Date( $ring->{ stop });
	my $block_stop = new Date::Manip::Date( $self->{ stop });
	my $overtime   = $block_stop->cmp( $ring_stop ) > 0;

	return 1 if( $overtime );
}

# ============================================================
sub preconditions {
# ============================================================
	my $self   = shift;
	my @blocks = @_;

	push @{$self->{ require }{ precondition }}, map { $_->{ id } } @blocks;
}

# ============================================================
sub nonconcurrences {
# ============================================================
# This is the master list of block concurrency conflicts
# ------------------------------------------------------------
	my $self      = shift;
	my $divisions = shift;

	my $key       = $self->match();
	my $lookup    = $self->match( $divisions );

	my $nonconcurrencies = {
		"male individual youth"               => [ "pair youth", "male team youth" ],
		"female individual youth"             => [ "pair youth", "female team youth" ],
		"male team youth"                     => [ "pair youth", "male individual youth" ],
		"female team youth"                   => [ "pair youth", "female individual youth" ],
		"pair youth"                          => [ "male individual youth", "female individual youth", "male team youth", "female team youth" ],
		"freestyle male individual under17"   => [ "male individual cadet", "pair cadet", "male team cadet", "male individual junior", "pair junior", "male team junior", "freestyle pair under17", "freestyle mixed team under17" ],
		"freestyle female individual under17" => [ "female individual cadet", "pair cadet", "female team cadet", "female individual junior", "pair junior", "female team junior", "freestyle pair under17", "freestyle mixed team under17" ],
		"freestyle pair under17"              => [ "male individual cadet", "female individual cadet", "pair cadet", "male team cadet", "female team cadet", "male individual junior", "female individual junior", "pair junior", "male team junior", "female team junior", "freestyle male individual under17", "freestyle female individual under17", "freestyle mixed team under17" ],
		"freestyle mixed team under17"        => [ "male individual cadet", "female individual cadet", "pair cadet", "male team cadet", "female team cadet", "male individual junior", "female individual junior", "pair junior", "male team junior", "female team junior", "freestyle male individual under17", "freestyle female individual under17", "freestyle pair under17" ],
		"male individual cadet"               => [ "pair cadet", "male team cadet", "freestyle male individual junior", "freestyle pair junior", "freestyle mixed team under17" ],
		"female individual cadet"             => [ "pair cadet", "female team cadet", "freestyle female individual junior", "freestyle pair junior", "freestyle mixed team under17" ],
		"male team cadet"                     => [ "pair cadet", "male individual cadet", "freestyle male individual junior", "freestyle pair junior", "freestyle mixed team under17" ],
		"female team cadet"                   => [ "pair cadet", "female individual cadet", "freestyle female individual junior", "freestyle pair junior", "freestyle mixed team under17" ],
		"pair cadet"                          => [ "male individual cadet", "female individual cadet", "male team cadet", "female team cadet", "freestyle male individual junior", "freestyle female individual junior", "freestyle pair junior", "freestyle mixed team under17" ],
		"male individual junior"              => [ "pair junior", "male team junior", "freestyle male individual junior", "freestyle pair junior", "freestyle mixed team under17" ],
		"female individual junior"            => [ "pair junior", "female team junior", "freestyle female individual junior", "freestyle pair junior", "freestyle mixed team under17" ],
		"male team junior"                    => [ "pair junior", "male individual junior", "freestyle male individual junior", "freestyle pair junior", "freestyle mixed team under17" ],
		"female team junior"                  => [ "pair junior", "female individual junior", "freestyle female individual junior", "freestyle pair junior", "freestyle mixed team under17" ],
		"pair junior"                         => [ "male individual junior", "female individual junior", "male team junior", "female team junior", "freestyle male individual junior", "freestyle female individual junior", "freestyle pair junior", "freestyle mixed team under17" ],
		"freestyle male individual over17"    => [ "male individual under30", "pair under30", "male team under30", "male individual under40", "pair over30", "male team over30", "freestyle pair over17", "freestyle mixed team over17" ],
		"freestyle female individual over17"  => [ "female individual under30", "pair under30", "female team under30", "female individual under40", "pair over30", "female team over30", "freestyle pair over17", "freestyle mixed team over17" ],
		"freestyle pair over17"               => [ "male individual under30", "female individual under30", "pair under30", "male team under30", "female team under30", "male individual under40", "female individual under40", "pair over30", "male team over30", "female team over30", "freestyle male individual over17", "freestyle female individual over17", "freestyle mixed team over17" ],
		"freestyle mixed team over17"         => [ "male individual under30", "female individual under30", "pair under30", "male team under30", "female team under30", "male individual under40", "female individual under40", "pair over30", "male team over30", "female team over30", "freestyle male individual over17", "freestyle female individual over17", "freestyle pair over17" ],
		"male individual under30"             => [ "pair under30", "male team under30" ],
		"female individual under30"           => [ "pair under30", "female team under30" ],
		"male team under30"                   => [ "pair under30", "male individual under30" ],
		"female team under30"                 => [ "pair under30", "female individual under30" ],
		"pair under30"                        => [ "male individual under30", "female individual under30", "male team under30", "female team under30" ],
		"male individual under40"             => [ "pair over30", "male team over30" ],
		"female individual under40"           => [ "pair over30", "female team over30" ],
		"male team over30"                    => [ "pair over30", "male individual under40", "male individual under50", "male individual under60", "male individual under70", "male individual over65" ],
		"female team over30"                  => [ "pair over30", "female individual under40", "female individual under50", "female individual under60", "female individual under70", "female individual over65" ],
		"pair over30"                         => [ "male individual under40", "female individual under40", "male individual under50", "female individual under50", "male individual under60", "female individual under60", "male individual under70", "female individual under70", "male individual over65", "female individual over65", "male team over30", "female team over30" ],
		"male individual under50"             => [ "pair over30", "male team over30" ],
		"female individual under50"           => [ "pair over30", "female team over30" ],
		"male individual under60"             => [ "pair over30", "male team over30" ],
		"female individual under60"           => [ "pair over30", "female team over30" ],
		"male individual under70"             => [ "pair over30", "male team over30" ],
		"female individual under70"           => [ "pair over30", "female team over30" ],
		"male individual over65"              => [ "pair over30", "male team over30" ],
		"female individual over65"            => [ "pair over30", "female team over30" ]
	};

	my $nonconcurrents = $nonconcurrencies->{ $key };
	foreach my $nonconcurrent (@$nonconcurrents) {
		my $division = $lookup->{ $nonconcurrent };
		push @{$self->{ require }{ nonconcurrent }}, @{$division->{ blocks }};
	}
}

1;
