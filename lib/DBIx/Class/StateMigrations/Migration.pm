package DBIx::Class::StateMigrations::Migration;

use strict;
use warnings;

# ABSTRACT: individual migration for a single version bump

use Moo;
use Types::Standard qw(:all);

use Scalar::Util 'blessed';
use Path::Class qw( file dir );
require Data::Dump;
require Module::Locate;
require Module::Runtime;

use DBIx::Class::StateMigrations::Migration::Routine::PerlCode;
use DBIx::Class::StateMigrations::Migration::Routine::SQL;

sub BUILD {
  my $self = shift;
  
  my $name = $self->migration_name;
  
  die "invalid migration_name '$name' - can only contain alpha chars and underscore _" 
    unless($name =~ /^[a-zA-Z0-9\_]+$/);
  
  die "At least one trigger_SchemaState required" unless (
    scalar(@{ $self->trigger_SchemaStates }) > 0
  );
}


has 'migration_name', is => 'ro', lazy => 1, default => sub {
  my $self = shift;
  $self->_migration_name_from_classname
    ? $self->_migration_name_from_classname
    : join('_', 'sm', map { $_->fingerprint } @{ $self->trigger_SchemaStates })
}, isa => Str;

has 'trigger_SchemaStates', is => 'ro', required => 1, isa => ArrayRef[
  InstanceOf['DBIx::Class::StateMigrations::SchemaState']
];

has 'DBI_Driver_Name', is => 'ro', required => 1, isa => Str;

has 'completed_SchemaState', is => 'ro', isa => Maybe[
  InstanceOf['DBIx::Class::StateMigrations::SchemaState']
], default => sub { undef };

sub number_routines { scalar(@{ (shift)->Routines }) };

has 'Routines', is => 'ro', required => 1, lazy => 1, default => sub {
  my $self = shift;
  return undef unless ($self->is_migration_class && $self->directory);
  my $Dir = dir( $self->directory, 'routines' )->absolute;
  return undef unless (-d $Dir);
  
  my @routines = ();
  
  for my $File ($Dir->children) {
    next if $File->is_dir;
    next unless (-f $File);
    
    if(my $ext = (reverse split(/\./,$File->basename))[0]) {
      if (lc($ext) eq 'pl') {
        push @routines, DBIx::Class::StateMigrations::Migration::Routine::PerlCode->new(
          file_path => $File->absolute->stringify,
          Migration => $self
        );
      }
      elsif (lc($ext) eq 'sql') {
        push @routines, DBIx::Class::StateMigrations::Migration::Routine::SQL->new(
          file_path => $File->absolute->stringify,
          Migration => $self
        );
      }
    }
  }
  
  return \@routines

}, isa => ArrayRef[InstanceOf['DBIx::Class::StateMigrations::Migration::Routine']];


sub execute_routines {
  my $self = shift;
  my $db = shift;
  my $callback = shift;
  
  die "execute_routines must be supplied connected DBIx::Class::Schema instance argument" 
    unless($db && blessed($db) && $db->isa('DBIx::Class::Schema'));
  
  die "Optional callback must be a CodeRef" if ($callback && (ref($callback)||'') ne 'CODE');
   
  # Empty/no-op Migration:
  return unless ($self->number_routines > 0);
  
  for my $Routine (@{ $self->Routines }) {
    my $ret = $Routine->execute( $db, $self );
    $callback->($Routine,$ret) if $callback;
  }
}

sub matches_SchemaState {
  my ($self, $SchemaState) = @_;
  
  die "check_SchemaState(): Bad argument - not a SchemaState object" unless (
    $SchemaState && blessed($SchemaState)
    && $SchemaState->isa('DBIx::Class::StateMigrations::SchemaState')
  );
  
  for my $SS (@{ $self->trigger_SchemaStates }) {
    return 1 if ($SS->fingerprint eq $SchemaState->fingerprint);
  }

  return 0
}


has 'directory', is => 'ro', lazy => 1, default => sub {
  my $self = shift;
  return undef unless ($self->is_migration_class);
  
  my $pm_path = Module::Locate::locate(blessed $self) or die join('',
    "Failed to locate pm file path for class '",blessed($self),"'"
  );
  
  file( $pm_path )->parent->absolute->stringify
}, isa => Maybe[Str]; 



has 'is_subclass', is => 'ro', lazy => 1, init_arg => undef, default => sub {
  my $self = shift;
  blessed($self) ne 'DBIx::Class::StateMigrations::Migration'
}, isa => Bool;

has 'is_migration_class', is => 'ro', lazy => 1, init_arg => undef, default => sub {
  my $self = shift;
  my $name = $self->_migration_name_from_classname;
  defined $name && $name eq $self->migration_name 
}, isa => Bool;


has '_migration_name_from_classname', is => 'ro', init_arg => undef, lazy => 1, default => sub {
  my $self = shift;
  return undef unless ($self->is_subclass);
  my $class = blessed($self);
  my ($junk,$name) = split(/Migration\_/,$class,2);
  $name
}, isa => Maybe[Str];


sub new_from_migration_dir {
  my $self = shift;
  my $dir = shift or die "dir not supplied";
  
  my $Dir = dir( $dir )->absolute;
  -d $Dir or die "'$dir' does not exist or is not a directory";
  
  my $pm_file;
  for my $File ($Dir->children) {
    next if $File->is_dir;
    next unless (-f $File);
    my $ext = (reverse split(/\./,$File->basename))[0];
    next unless ($ext && lc($ext) eq 'pm');
    
    die "Error - multiple pm files found in directory '$dir'" if ($pm_file);
    
    $pm_file = $File->absolute;
  }
  
  die "No Migration pm file found in directory '$dir'" unless ($pm_file);
  die "Invalid Migration pm file '$pm_file' - must start with 'Migration_'" 
    unless ($pm_file->basename =~ /^Migration_/);
    
  my $mclass = $pm_file->basename;
  $mclass =~ s/\.pm$//i;
  
  die "Not loading $pm_file - class named '$mclass' already loaded!" if (Module::Locate::locate($mclass));
  
  eval "use lib '$Dir'";
  Module::Runtime::require_module($mclass);
  
  die "Error loading $pm_file - '$mclass' still not loaded after require" unless (Module::Locate::locate($mclass));
  
  my $Migration = $mclass->new;
  
  die "Error loading new $mclass object instance - not a valid Migration class" unless (
    blessed($Migration) && $Migration->isa('DBIx::Class::StateMigrations::Migration')
  );
  
  die "New $mclass object instance returns false for ->is_migration_class" unless (
    $Migration->is_migration_class
  );
  
  return $Migration
}



sub as_subclass_pm_code {
  my $self = shift;
  
  my @embed_attrs = qw(DBI_Driver_Name completed_SchemaState trigger_SchemaStates);
  
  my $classname = join('_','Migration',$self->migration_name);
  
  my @pm_file_lines = (
    'package ',
    '   ' . $classname . ';','',
    'use strict;',
    'use warnings;','',
    'use Moo;',
    'extends "DBIx::Class::StateMigrations::Migration";',
    '',
    $self->__generate_inline_pm_code_lines_for_attrs(@embed_attrs),
    '1',''
  );

  return join("\n",@pm_file_lines);
}


sub __generate_inline_pm_code_lines_for_attrs {
  my ($self, @attrs) = @_;
  scalar(@attrs) > 0 or die "no attrs supplied";
  
  my @lines = ();
  
  for my $attr (@attrs) {

    $self->can($attr) or die "No such attr '$attr'";
    
    my $val = $self->$attr;
    
    if(ref($val)) {
      push @lines, join('',"has '+",$attr,q~', default => sub { ~,$self->_Dump($val),q~ };~),'';
    }
    else {
      $val = defined $val ? "'$val'" : 'undef';
      push @lines, join('',"has '+",$attr,q~', default => sub { ~,$val,q~ };~),'';
    }
  }

  @lines
}



sub write_subclass_pm_file {
  my $self = shift;
  my $dir = shift or die "dir not supplied";
  
  my $Dir = dir( $dir )->absolute;
  
  -d $Dir or die "'$dir' does not exist or is not a directory";
  
  my $pm_file = file( $Dir, 'Migration_' . $self->migration_name . '.pm' );
  
  -f $pm_file and die "write_subclass_pm_file(): pm file '$pm_file' already exists";
  
  $pm_file->spew( $self->as_subclass_pm_code );
  
  
  my $NewMigration = $self->new_from_migration_dir( "$Dir" );
  
  die "Loading newly creted migration class failure - not the same migration_name" unless (
    $self->migration_name eq $NewMigration->migration_name
  );
  
  return 1;
}


sub _Dump {
  my $self = shift;
  my $obj = shift;
  
  require Data::Dump;
  local $Data::Dump::INDENT = '  ';
  
  return Data::Dump::dump($obj);
}



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


