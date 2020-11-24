package DBIx::Class::StateMigrations;

use strict;
use warnings;

# ABSTRACT: Schema migrations via checksums instead of versions

our $VERSION = '0.01';

use Moo;
use Types::Standard qw(:all);
use Scalar::Util 'blessed';
use Try::Tiny;

use Path::Class qw/file dir/;
use DBIx::Class::Schema::Diff 1.11;

use DBIx::Class::Schema::Diff::State;
use DBIx::Class::StateMigrations::SchemaState;
use DBIx::Class::StateMigrations::Migration;

has 'migrations_dir', is => 'ro', default => sub { undef };
has 'connected_schema', is => 'ro', required => 1, isa => InstanceOf['DBIx::Class::Schema'];

has 'schema_class', is => 'ro', lazy => 1, init_arg => 1, default => sub {
  my $self = shift;
  blessed $self->connected_schema ? blessed $self->connected_schema : $self->connected_schema
};

has 'loader_options', is => 'ro', default => sub {{
  naming => { ALL => 'v7'},
  use_namespaces => 1,
  use_moose => 0,
  debug => 0,
  qualify_objects => 1
}}, isa => HashRef;


has 'diff_filters', is => 'ro', default => sub {[
  filter_out => 'isa'
]}, isa => ArrayRef;


has 'Migrations', is => 'ro', lazy => 1, default => sub {
  my $self = shift;
  if(my $dir = $self->migrations_dir) {
    my $Dir = dir( $dir )->absolute;
    -d $Dir or die "migrations dir '$dir' not found or is not a directory";
    
    my @migrations = ();
    
    for my $m_dir ($Dir->children) {
      next unless $m_dir->is_dir;
      my $Migration = DBIx::Class::StateMigrations::Migration
        ->new_from_migration_dir($m_dir->absolute->stringify);
      push @migrations, $Migration;
    }
    return \@migrations;
  }
  else {
    return []
  }
}, isa => ArrayRef[InstanceOf['DBIx::Class::StateMigrations::Migration']];


has 'connect_info_args', is => 'ro', lazy => 1, default => sub {
  my $self = shift;
  $self->connected_schema->storage->connect_info
}, isa => Ref;

has 'loaded_schema_class', is => 'ro', lazy => 1, default => sub {
  my $self = shift;
  
  my $schema_class = $self->schema_class || 'ScannedSchmeaForMigration';
  
  my $ref_class = join('_',$schema_class,'RefSchema',String::Random->new->randregex('[a-z0-9A-Z]{5}'));
  
  DBIx::Class::Schema::Loader::make_schema_at(
    $ref_class => $self->loader_options, $self->connect_info_args  
  ) or die "Loading schema failed";

  $ref_class
}, isa => Str;



has 'current_SchemaState', is => 'ro', lazy => 1, default => sub {
  my $self = shift;
  
  my $State = DBIx::Class::Schema::Diff->state(
    schema => $self->loaded_schema_class
  );
  
  DBIx::Class::StateMigrations::SchemaState->new(
    DiffState    => $State,
    diff_filters => $self->diff_filters
  )
}, isa => InstanceOf['DBIx::Class::StateMigrations::SchemaState'];




sub BUILD {
  my $self = shift;
  try{$self->connected_schema->storage->connected} or die join('',
    'Supplied connected_schema "', $self->connected_schema, '" is not connected'
  );
  
  $self->Migrations;
  
}


1;

__END__

=head1 NAME

DBIx::Class::Schema::StateMigrations - Schema migrations via checksums instead of versions

=head1 SYNOPSIS

 use DBIx::Class::Schema::StateMigrations;
 
 ...
 

=head1 DESCRIPTION

This is module serves essentially the same purpose as L<DBIx::Class::DeploymentHandler> except it
uses checksums generated from the actual current state of the schema to identify the current 
"version" and what migration scripts should be ran for that version, rather than relying on a
declatred version number value which is subject to human error.

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


