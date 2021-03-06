package FusionInventory::Agent::Task::Inventory::Generic::Remote_Mgmt::LiteManager;

use strict;
use warnings;

use parent 'FusionInventory::Agent::Task::Inventory::Module';

use English qw(-no_match_vars);

use FusionInventory::Agent::Tools;

sub isEnabled {
    my (%params) = @_;

    return 0 unless $OSNAME eq 'MSWin32';

    FusionInventory::Agent::Tools::Win32->use();

    my $key = first { getRegistryKey( path => $_ ) } qw(
        HKEY_LOCAL_MACHINE/SYSTEM/LiteManager
        HKEY_LOCAL_MACHINE/SOFTWARE/LiteManager
    );
    return $key && keys(%{$key});
}

sub isEnabledForRemote {
    my (%params) = @_;

    return 0 unless $OSNAME eq 'MSWin32';

    FusionInventory::Agent::Tools::Win32->use();

    my $key = first { getRegistryKey( path => $_ ) } qw(
        HKEY_LOCAL_MACHINE/SYSTEM/LiteManager
        HKEY_LOCAL_MACHINE/SOFTWARE/LiteManager
    );
    return $key && keys(%{$key});
}

sub doInventory {
    my (%params) = @_;

    my $inventory = $params{inventory};
    my $logger    = $params{logger};

    my $liteManagerID = _getID( logger => $logger );

    if ($liteManagerID) {
        $logger->debug('Found LiteManagerID : ' . $liteManagerID) if ($logger);

        $inventory->addEntry(
            section => 'REMOTE_MGMT',
            entry   => {
                ID   => $liteManagerID,
                TYPE => 'litemanager'
            }
        );
    } else {
        $logger->debug('LiteManagerID not found') if ($logger);
    }
}

sub _getID {
    my (%params) = @_;

    return first {
        _findID(
            path => $_,
            %params
        )
    } qw(
        HKEY_LOCAL_MACHINE/SYSTEM/LiteManager
        HKEY_LOCAL_MACHINE/SOFTWARE/LiteManager
    );
}

sub _findID {
    my (%params) = @_;

    FusionInventory::Agent::Tools::Win32->use();

    my $key = getRegistryKey(
        %params,
        wmiopts => { # Only used for remote WMI optimization
            values  => [ 'ID (read only)' ]
        }
    );

    return unless $key && keys(%{$key});

    my $parameters;

    foreach my $sub (grep { m|/$| } keys(%{$key})) {
        next unless $key->{$sub}->{"Server/"};
        next unless $key->{$sub}->{"Server/"}->{"Parameters/"};
        $parameters = $key->{$sub}->{"Server/"}->{"Parameters/"};
        last;
    }

    return unless $parameters;

    return $parameters->{"/ID (read only)"};
}

1;
