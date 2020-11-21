package DBIx::Class::BlockchainMigrations::Migration::Routine::DDL;

use strict;
use warnings;

# ABSTRACT: Raw DDL routine

our VERSION = '0.01';

use Moo;
use Types::Standard qw(:all);

use Path::Class qw/file dir/;
use SQL::SplitStatement;

has 'Migration', 
  is => 'ro', 
  isa => InstanceOf['DBIx::Class::BlockchainMigrations::Migration']
  required => 1;



has 'raw_ddl', is => 'ro', isa => Maybe[Str], default => sub { undef };

has 'statements', is => 'ro', isa => ArrayRef[Str], lazy => 1, default => sub {
  my $self = shift;
  my $raw_ddl = $self->raw_ddl or die "must supply either raw_ddl or a list of DDL statements.";
  
  my @stmts = SQL::SplitStatement->new->split($raw_ddl);
  
  \@stmts
};

sub execute {


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


