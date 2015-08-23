use strict;
use warnings;
package Net::Amazon::EC2::Cssh;

use Moose;
use Data::Dumper;
use Cwd;
use File::Spec;
use IO::Socket::SSL;
use Net::Amazon::EC2;

use Log::Any qw/$log/;

has 'config' => ( is => 'ro', isa => 'HashRef', lazy_build => 1);
has 'config_file' => ( is => 'ro' , isa => 'Str', lazy_build => 1);

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
    my $instances = $self->ec2->describe_instances();
    foreach my $instance ( @$instances ){
        $log->info(Dumper($instance));
    }
}

__PACKAGE__->meta->make_immutable();

