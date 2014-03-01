package CSV;

use strict;
use vars qw( $VERSION );
use Carp;
use Util;

$VERSION = 0.1;

sub new
{
	my ( $proto, $params ) = @_;
	my $class = ref($proto) || $proto;
	my $self = {
		debug => $params->{debug},
        file => undef,
		lines => undef,
        csv => undef,
        delimiter => ','
        };
	bless( $self, $class );
    $self->_init($params);
    # Util::print_hash($self, "self");
	$self;
}

sub _msg
{
	my( $self, @msg ) = @_;
	if( $self->{debug} )
	{
        print __PACKAGE__ . " - " . join(' ', @msg) . "\n";
	}
	return 1;
}

sub _new_array
{
    my $self = shift;
    my $array_ref = [];
    return $array_ref;
}

sub _init
{
    my( $self, @args ) = @_;

	$self->_msg( "Processing initialization arguments - begin" );
	for ( keys %{$args[0]} )
	{
        my $key = lc $_;
        my $value = $args[0]->{$_};
        $self->_msg("self->{$key} = $value");
		$self->{$key} =  $value;
	}
	$self->_msg( "Processing initialization arguments - end" );
    $self->{csv} = $self->_new_array();
}

sub _ttt
{
    my ($self, $line) = @_;

    my $delimiter = $self->{delimiter};
    my $first = undef;
    my $second = undef;
    my $regex1 = '^' . quotemeta($delimiter);
    my $regex2 = '(.*?)' . quotemeta($delimiter) . '(.*)';

    # handle double quoted
    if( $line =~ /^(\".*?\")(.*)/ ) {
        $first = $1;
        $second = $2;

        # handle "laksjdf""fjksld"
        #                ^^
        if( defined $second && $second =~ /^\"/ ) {
            my($f) = undef;
            ($f, $second) = $self->_ttt($second);
            $first .= $f;
        }
        if( defined $second ) {
            $second =~ s/$regex1//;
        }
    }
    elsif( $line =~ /$regex2/ ) {
        $first = $1;
        $second = $2;
    }
    else {
        $first = $line;
    }

    return ($first, $second);
}

# parse a line in the csv file and return an array
# of the comma separated components.  handle quotes (")
# as expoected.
sub _parse_line
{
    my ($self, $line) = @_;
    my $remainder;
    my @parsed;
    $self->_msg("processing: $line");
    my ($value, $remainder) = $self->_ttt($line);
    $self->_msg("value: $value, remainder: $remainder");
    push @parsed, $value;
    while($remainder ne "") {
        ($value, $remainder) = $self->_ttt($remainder);
        $self->_msg("value: [$value], remainder: [$remainder]");
        if(!defined $remainder) {
            $self->_msg("NO remainder. *********************** ");
        }
        push @parsed, $value;
    }
#     # ended with a comma ','
#     if(defined $remainder) {
#         push @parsed, "";
#     }
#     else {
#         print "------------------------ what's up doc ----------------------\n";
#     }
    return \@parsed;
}

sub _read_file($)
{
    my($self, $file_name) = @_;
    my @results;
    open(IN_FILE, "<$file_name") || die "Could not open $file_name. $!";
    while(<IN_FILE>)
    {
        chomp;
        $_ =~ s///g;
        push @results, $_;
    }
    close(IN_FILE);
    return \@results;
}

sub parse
{
    my( $self, $params ) = @_;

    # initialize object
    $self->_init( $params );

    # if 'lines' not defined, try to read in from file
    if( ! defined $self->{lines} ) {
        $self->{lines} = $self->_read_file($self->{file});
    }
    return unless $self->{lines};

    # parse all 'lines' & return result
    my $result_ref = $self->{csv};
    my $lines_ref = $self->{lines};
    foreach my $line (@$lines_ref) {
        chomp($line);

        $self->_msg(" the line = <$line>");
        # need to add another ',' at the end so that algorithm works right
        if( $line =~ /,$/ ) {
            $line .= ",";
            $self->_msg("---------------- match eol --------------------");
        }
        $self->_msg(" the line = <$line>\n");
        my $parsed_line_ref = $self->_parse_line($line);
        push @$result_ref, $parsed_line_ref;
    }
    return $self->{csv};
}

sub persist
{
    my($self) = @_;
    my($lines_ref) = $self->{csv};
    my($file_name) = $self->{file};

    open(OUTPUT, ">$file_name") || warn "Could not open $file_name.  $!\n";
    foreach my $row(@$lines_ref) {
        my $count = 0;
        foreach my $col(@$row) {
            if($count!=0) {
                print OUTPUT ",";
            }
            $count++;
            print OUTPUT $col;
        }
        print OUTPUT "\n";
    }
    close(OUTPUT);
}

1;
__END__
