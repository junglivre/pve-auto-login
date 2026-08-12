#!/usr/bin/perl
use strict;
use warnings;

sub raise_perm_exc { die $_[0]; }

sub vncshell {
    my ($param, $user) = @_;
    if (defined($param->{cmd}) && $param->{cmd} ne 'login' && $user ne 'root@pam') {
        raise_perm_exc('user != root@pam');
    }
}

sub spiceshell {
    my ($param, $user) = @_;
    if (defined($param->{cmd}) && $param->{cmd} ne 'login' && $user ne 'root@pam') {
        raise_perm_exc('user != root@pam');
    }
}

1;
