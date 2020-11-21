package DBIx::Class::StateMigrations::Migration;

use strict;
use warnings;

# ABSTRACT: individual migration for a single version bump

our VERSION = '0.01';

use Moo;
use Types::Standard qw(:all);
use String::Random;

use DBIx::Class::Schema::Diff 1.10_01;


has 'schema_class', is => 'ro', lazy => 1, isa => ClassName;

has 'connect_info_args', is => 'ro', lazy => 1, isa => Ref;


has 'connected_schema', is => 'ro', lazy => 1, default => sub {
  my $self = shift;

}, isa => ClassName;



has 'dbh', is => 'ro', lazy => 1, default => sub {
  my $self shift;
  $self->connected_schema->storage->dbh
}, isa => InstanceOf['DBI::db'];


has 'Driver', is => 'ro', lazy => 1, default => sub {
  my $self shift;
  $self->dbh->{Driver}{Name}
}, isa => Str;


has 'State',
  is => 'ro', lazy => 1,
  isa => Maybe[InstanceOf['DBIx::Class::Schema::Diff::State']],
  default => sub { 
    my $self = shift;
    DBIx::Class::Schema::Diff->state( schema => $ref_class )
  }
);
  

has 'fingerprint', is => 'ro', lazy => 1, default => sub {
  my $self = shift;
  die __PACKAGE__ . ' must supply either a checksum "fingerprint" or "State"' unless ($self->State);
  $self->State->fingerprint
}, isa => Str;


has 'loader_options', is => 'ro', default => sub {{
  naming => { ALL => 'v7'},
  use_namespaces => 1,
  use_moose => 0,
  debug => 0,
  qualify_objects => 1
}}, isa => HashRef;


has 'loaded_schema_class', is => 'ro', lazy => 1, sub {
  my $self = shift;
  
  my $schema_class = $self->schema_class || 'ScannedSchmeaForMigration';
  
  my $ref_class = join('_',$schema_class,'RefSchema',String::Random->new->randregex('[a-z0-9A-Z]{5}'));
  
  DBIx::Class::Schema::Loader::make_schema_at(
    $ref_class => $self->loader_options, $self->connect_info_args  
  ) or die "Loading schema failed";

  $ref_class
  
}, isa => Str;





1;

__END__

=head1 NAME

DBIx::Class::Schema::StateMigrations::Migration - individual migration for a single version bump

=head1 SYNOPSIS

 use DBIx::Class::Schema::StateMigrations;
 
 ...
 

=head1 DESCRIPTION



=head1 CONFIGURATION


=head1 METHODS


=head1 SEE ALSO

=over

=item * 

L<DBIx::Class>

=item *

L<DBIx::Class::DeploymentHandler>

=item * 

L<DBIx::Class::Migrations>

=item * 

L<DBIx::Class::Schema::Versioned>

=back


=head1 AUTHOR

Henry Van Styn <vanstyn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by IntelliTree Solutions llc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


