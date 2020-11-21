package DBIx::Class::BlockchainMigrations;

use strict;
use warnings;

# ABSTRACT: Schema migrations via checksums instead of versions

our VERSION = '0.01';

use Moo;
use Types::Standard qw(:all);

use Path::Class qw/file dir/;
use DBIx::Class::Schema::Diff;


has 'schema', is => 'ro', isa => InstanceOf['DBIx::Class::Schema'];


has 'Migrations'





1;

__END__

=head1 NAME

DBIx::Class::Schema::BlockchainMigrations - Schema migrations via checksums instead of versions

=head1 SYNOPSIS

 use DBIx::Class::Schema::BlockchainMigrations;
 
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


