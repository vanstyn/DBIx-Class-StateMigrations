package DBIx::Class::BlockchainMigrations::Deployment;

use strict;
use warnings;

# ABSTRACT: Actual Deployment handling for all outstanding loaded Migrations

use Moo;
use Types::Standard qw(:all);
use Scalar::Util 'blessed';

use Module::Runtime;
use DBIx::Class::Schema::Loader;
use DBIx::Class::Schema::Diff;
use String::Random;

use RapidApp::Util ':all';

has 'schema', 
  is => 'ro', 
  isa => InstanceOf['DBIx::Class::Schema'],
  required => 1;

has 'schema_class',
  is => 'ro', 
  isa => ClassName,
  lazy => 1,
  default => sub { blessed( (shift)->schema )};

has 'schema_loader_options',
  is => 'ro',
  isa => HashRef,
  default => sub {{}};
  

sub BUILD {
  my $self = shift;
  die "Can supply either 'schema_diff_excludes' or a custom CodeRef in 'get_fingerprint_fn' - but not both"
    if($self->schema_diff_excludes && $self->get_fingerprint_fn);
}



has 'schema_diff_excludes', is => 'ro', isa => Maybe[HashRef[Str]];
  
has 'get_fingerprint_fn',
  is => 'ro',
  isa => Maybe[CodeRef];
  
sub get_current_finderprnt {
  my $self = shift;
  return $self->get_fingerprint_fn($self,@_) if ($self->get_fingerprint_fn);

  
}


sub get_current_schema_Diff {
  my $self = shift;
  
  my $schema_class = $self->schema_class;
  my $ref_class = join('_',$schema_class,'RefSchema',String::Random->new->randregex('[a-z0-9A-Z]{5}'));

  DBIx::Class::Schema::Loader::make_schema_at(
    $ref_class => {
      naming => { ALL => 'v7'},
      use_namespaces => 1,
      use_moose => 1,
      qualify_objects => 1,
      %{$self->schema_loader_options},
    }, $self->schema->storage->connect_info
  );
  
  DBIx::Class::Schema::Diff->new(
    old_schema => $schema_class,
    new_schema => $ref_class
  )
};


has 'Migrations', 
  is => 'ro', 
  isa => HashRef[InstanceOf['DBIx::Class::BlockchainMigrations::Migration']];

sub _run_next_migration {


}

1;

__END__

=head1 NAME

DBIx::Class::Schema::BlockchainMigrations::Migration - individual migration for a single version bump

=head1 SYNOPSIS

 use DBIx::Class::Schema::BlockchainMigrations;
 
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


