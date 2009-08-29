package LJ::Console::Command::Set;

use strict;
use base qw(LJ::Console::Command);
use Carp qw(croak);

sub cmd { "set" }

sub desc { "Set the value of a userprop." }

sub args_desc { [
                 'community' => "Optional; community to set property for, if you're a maintainer.",
                 'propname' => "Property name to set.",
                 'value' => "Value to set property to.",
                 ] }

sub usage { '[ "for" <community> ] <propname> <value>' }

sub can_execute { 1 }

sub execute {
    my ($self, @args) = @_;

    return $self->error("This command takes either two or four arguments. Consult the reference.")
        unless scalar(@args) == 2 || scalar(@args) == 4;

    my $remote = LJ::get_remote();
    my $journal = $remote;   # may be overridden later

    if (scalar(@args) == 4) {
        # sanity check
        my $for = shift @args;
        return $self->error("First argument must be 'for'")
            unless $for eq "for";

        my $name = shift @args;
        $journal = LJ::load_user($name);

        return $self->error("Invalid account: $name")
            unless $journal;
        return $self->error("You are not permitted to change this journal's settings.")
            unless LJ::can_manage( $remote, $journal ) || ( $remote && $remote->has_priv( "siteadmin", "propedit" ) );
    }

    my ($key, $value) = @args;
    return $self->error("Unknown property '$key'")
        unless ref $LJ::SETTER{$key} eq "CODE";

    my $errmsg;
    my $rv = $LJ::SETTER{$key}->($journal, $key, $value, \$errmsg);
    return $self->error("Error setting property: $errmsg")
        unless $rv;

    return $self->print("User property '$key' set to '$value' for " . $journal->user);
}

1;
