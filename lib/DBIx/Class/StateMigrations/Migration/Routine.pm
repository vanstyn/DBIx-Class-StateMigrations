package DBIx::Class::BlockchainMigrations::Migration::Routine;

use strict;
use warnings;

# ABSTRACT: Base class for an individual routine within a migration

our VERSION = '0.01';

use Moo;
use Types::Standard qw(:all);

use Path::Class qw/file dir/;


sub execute { ... }


1;

__END__

=head1 NAME

DBIx::Class::BlockchainMigrations::Migration::Routine - Base class for an individual routine within a migration

=head1 DESCRIPTION

This should be subclassed and used used directly

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


