package Net::Amazon::EC2::Cssh;

use Moose;

use autodie qw/:all/;
use Cwd;
use File::Spec;
use IO::Socket::SSL;
use Net::Amazon::EC2;
use Safe;
use Text::Template;

use Log::Any qw/$log/;

# Config stuff.
has 'config' => ( is => 'ro', isa => 'HashRef', lazy_build => 1);
has 'config_file' => ( is => 'ro' , isa => 'Str', lazy_build => 1);

# Run options stuff
has 'set' => ( is => 'ro' , isa => 'Maybe[Str]', default => sub{ undef; } );

# Operational stuff.
has 'ec2' => ( is => 'ro', isa => 'Net::Amazon::EC2', lazy_build => 1);


sub _build_config{
    my ($self) = @_;
    return do $self->config_file;
}

sub _build_config_file{
    my ($self) = @_;
    my @candidates = ( File::Spec->catfile( getcwd() , '.ec2cssh.conf' ),
                       File::Spec->catfile( $ENV{HOME} , '.ec2cssh.conf' ),
                       File::Spec->catfile( 'etc' , 'ec2ssh.conf' )
                     );
    foreach my $candidate ( @candidates ){
        if( -r $candidate ){
            $log->info("Found config file '$candidate'");
            return $candidate;
        }
    }
    die "Cannot find any config files amongst ".join(', ' , @candidates )."\n";
}

sub _build_ec2{
    my ($self) = @_;

    # Hack so we never verify Amazon's host. Whilst still keeping HTTPS
    IO::Socket::SSL::set_defaults( SSL_verify_callback => sub{ return 1; } );
    my $ec2 =  Net::Amazon::EC2->new({ %{ $self->config()->{ec2_config} } , ssl => 1 } );
    return $ec2;
}

sub main{
    my ($self) = @_;

    my @hosts;
    $log->info("Listing instances for set='".( $self->set() || 'ALL' )."'");

    my $set_config = {};
    if( $self->set() ){
        $set_config = $self->config()->{ec2_sets}->{$self->set()} || die "No ec2_set '".$self->set()."' defined in config\n";
    }

    my $reservation_infos = $self->ec2->describe_instances( %{ $set_config } ) ;
    foreach my $ri ( @$reservation_infos ){
        my $instances = $ri->instances_set();
        foreach my $instance ( @$instances ){
            if( my $tagset = $instance->tag_set() ){
                foreach my $tag ( @$tagset ){
                    $log->trace("Host has tag: ".$tag->key().':'.( $tag->value() // 'UNDEF' ));
                }
            }
            if( my $host = $instance->dns_name() ){
                $log->debug("Adding host $host");
                push @hosts  , $host;
            }else{
                $log->warn("Instance ".$instance->instance_id()." does not have a dns_name. Skipping");
            }
        }
    }

    $log->info("Got ".scalar( @hosts )." hosts");

    my $tmpl = Text::Template->new( TYPE => 'STRING',
                                    SOURCE => $self->config()->{command} || die "Missing command in config\n"
                                );
    unless( $tmpl->compile() ){
        die "Cannot compile template from '".$self->config()->{command}."' ERROR:".$Text::Template::ERROR."\n";
    }

    my $command = $tmpl->fill_in( SAFE => Safe->new(),
                                  HASH => {
                                      hosts => \@hosts
                                  }
                              );
    $log->info("Will do '".substr($command, 0, 80)."..'");
    if( $log->is_debug() ){
        $log->debug($command);
    }
    my $sys_return = system( $command );
    $log->info("Done (returned $sys_return)");
    return 1;
}

__PACKAGE__->meta->make_immutable();

