package FreeScore::Feats::Division;
use FreeScore;

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
#** @method ( path, name, [ring] )
#   @brief Initializes the division with path, name, and ring information
#*
	my $self = shift;
	my $path = shift;
	my $name = shift;
	my $ring = shift || 'staging';

	$self->{ state }   = 'display';

	$self->{ path } = $path;
	$self->{ ring } = $ring;
	$self->{ name } = $name;
	$self->{ file } = "$self->{ path }/div.$name.txt";
	die "Database Read Error: Can't find division at '$self->{ path }' $!" if( ! -e $self->{ path } );
	$self->read() if( -e $self->{ file } );
}

sub display    { my $self = shift; $self->{ state } = 'display'; }
sub score      { my $self = shift; $self->{ state } = 'score';  }
sub next       { my $self = shift; $self->{ state } = 'score'; $self->{ current } = ($self->{ current } + 1) % int(@{ $self->{ athletes }}); }
sub previous   { my $self = shift; $self->{ state } = 'score'; $self->{ current } = ($self->{ current } - 1) >= 0 ? ($self->{ current } -1) : $#{ $self->{ athletes }}; }

sub is_display { my $self = shift; return $self->{ state } eq 'display'; }
sub is_score   { my $self = shift; return $self->{ state } eq 'score';  }
sub exists     { my $self = shift; return -e $self->{ file }; }

1;
