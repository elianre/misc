#!/usr/bin/perl

# wrapper for Android adb & aapt, assume adb & Android SDK is installed and device must be rooted with debug mode on
# Don't forget to run adb root to login as root first!

use strict;
no strict "refs";
use warnings;
use Getopt::Long;
use File::Basename;
use Data::Dumper;
use Config;
use File::Spec::Functions;

use FindBin qw($RealBin);
#chdir $RealBin;
$SIG{CHLD} = 'IGNORE'; # in order to no waitpid

my %tools = (
                'adb'    => undef,
                'aapt'   => undef,
            );

my @actions = ("install", "uninstall", "info", "wait", "cmd", "run_app");
my ($device, $serial_num, $action, $params);
my $debug = 0;
my @dummy;
$device = "";
$serial_num = undef;


# you could use your own adb at ANDROID_HOME
if (defined $ENV{ANDROID_HOME}) {
    $tools{adb}  = catfile($ENV{ANDROID_HOME}, "platform-tools", "adb");
    my @files    = glob catfile($ENV{ANDROID_HOME}, "build-tools", "*", "aapt*");
    Die("ERROR: Can't locate aapt at ".catfile($ENV{ANDROID_HOME}, "build-tools", "*", "aapt*")."\n") if $#files == -1;
    $tools{aapt} = $files[0];
} else {
    if ($Config{osname} =~ /MSWin/) {
        $tools{adb} = `where adb`;
        chomp $tools{adb};

        my @files    = glob catfile(dirname(dirname($tools{adb})), "build-tools", "*", "aapt*");
        Die("ERROR: Can't locate aapt at ".catfile(dirname(dirname($tools{adb})), "build-tools", "*", "aapt*")."\n") if $#files == -1;
        $tools{aapt} = $files[0];
    } elsif ($Config{osname} =~ /linux/) {
        $tools{adb} = `which adb`;
        chomp $tools{adb};

        foreach my $p (split(":", $ENV{PATH})) {
            if ($p =~ /(.+android-sdk-.+?)\//) {
                my @files    = glob catfile($1, "build-tools", "*", "aapt*");
                Die("ERROR: Can't locate aapt at ".catfile($1, "build-tools", "*", "aapt*")."\n") if $#files == -1;
                $tools{aapt} = $files[0]; 
            }
        }
    }
}

foreach my $k (keys %tools) {
    die "ERROR: Can't locate '$k'!\n" unless defined $tools{$k} && $tools{$k};
    print "$k : $tools{$k}\n" unless $debug == 0;
}
print "\n\n" unless $debug == 0;

GetOptions(
    'd=s'    =>   \$device,
    'a=s'    =>   \$action,
    'p=s'    =>   \$params,
    'v=s'    =>   \$debug,
);


sub get_devices {
    my ($filter) = @_;

    my %devices = ();
    for my $l (split("\n", `$tools{adb} devices`)) {
        if ($l =~ /^(\w+)\s+device\s*$/) {
            my $s = $1;

            my $name = `$tools{adb} -s $s shell getprop ro.product.model`;
            chomp $name;
            if ($name =~ /([\w\-_`~!@#\$\%\^&*()_+\-=\[\]\{\}\\\|;':",.\<\> \t]+)\s*$/) {
                $name = $1;
            }
            $devices{"$name"} = $s;

            if (defined $filter && ($s eq $filter || $name =~ /$filter/)) {
                return $name, $s;
            }
        }
    }

    return %devices;
}

sub Die {
    print @_;
    die;
}


sub check_device {
    if (defined $ENV{ANDROID_SERIAL}) {
        $serial_num = $ENV{ANDROID_SERIAL};
        return;
    }
    unless ($device ) {
        my %temp = get_devices();
        my $num = keys(%temp) + 0;
        if ($num != 0) {
            Die("ERROR: Found more than 1 android device: ".join(", ", keys(%temp))."!\n") if $num > 1;
            ($device, @dummy)  = %temp;
            $serial_num = $temp{$device};
        }
    } else {
        my %temp = get_devices();
        my $match = "";
        my $all = "";
        for my $k (keys %temp) {
            $all .= "    $k    $temp{$k}\n";
            if ($k =~ /$device/ || $temp{$k} =~ /$device/) {
                $match = $k;
                last;
            }
        }

        if ($match eq "") {
            print "WARN: Can't find device like '$device'. Existed device:\n".$all,"\n";
        } else {
            $device = $match;
            $serial_num = $temp{$device};
        }
    }
}


if ($action) {
    my $match = 0;
    $match = $_ eq $action? 1:$match foreach @actions;

    Die("ERROR: Action '$action' is not supported! Valid option [-a ".join('|', @actions)."]\n") unless $match;
} else {
    Die("ERROR: No action specified!\n");
}

check_device();
print "Device: $device Serial number: $serial_num\n" if defined $serial_num;

print "\n";
&$action();


sub execute {
    my ($cmd, $timeout) = @_;
    print "$cmd\n";
    if(defined $timeout) {
        my $pid = fork();
        if ($pid == 0) { #child
            exec($cmd);
            exit;
        } else { #parent
            my $done = 0;
            for (my $i = 0; $i < $timeout; $i++) {
                my $res = kill 0, $pid;
                unless ($res) {
                    $done = 1;
                    last
                }
                sleep 1;
            }

            kill 9, $pid;
        }
    } else {
        system($cmd);
    }
}


sub wait {
    my $timeout = 60;
    $timeout = int($params) if defined $params;
    print "Max wait time: $timeout\n";
    while ( not defined $serial_num && $timeout > 0) {
        check_device();
        sleep 10;
        print "Wait 10 seconds...\n\n";
        $timeout -= 10;
        last if $timeout < 0;
    }

    if (defined  $serial_num) {
        print "Found device $device: $serial_num\n";
    } else {
        Die("ERROR: No target android device found!\n");
    }
}

sub install {
    Die("ERROR: No android device found!\n")  unless defined $serial_num;
    Die("ERROR: Please specify valid APK file by '-p APK'.\n") unless defined $params && -f $params;

    print "Start to install $params to $device...\n";
    #execute("$tools{adb} -s $serial_num shell mount -o remount rw /");
    #execute("$tools{adb} -s $serial_num remount");
    #execute("$tools{adb} -s $serial_num push $params /mnt/shell");
    #execute("$tools{adb} -s $serial_num shell pm install /mnt/shell/".basename($params), 10);
    execute("$tools{adb} -s $serial_num install $params", 10);
}


sub uninstall {
    Die("ERROR: No android device found!\n") unless defined $serial_num;
    Die("ERROR: Please specify package name or APK file by '-p [PACKAGE|APK]'.\n") unless defined $params;
    my $pkg_name;
    if ($params =~ /\.apk$/i) {
        Die("ERROR: Can't find APK file '$params'!\n") unless -f $params;

        my $cmd = "$tools{aapt} list -a $params";
        my $pkg_info = `$cmd`;
        if ($pkg_info =~ /package="([^"]+)"/) {
            $pkg_name = $1;
        } else {
            Die("ERROR: No package name found by: $cmd\n".$pkg_info."\n");
        }
    } else {
        $pkg_name = $params;
    }

    print "Start to uninstall package $pkg_name...\n";
    execute("$tools{adb} -s $serial_num uninstall $pkg_name");
}


sub info {
    Die("ERROR: No android device found!\n") unless defined $serial_num;
    if (defined $params && -f $params) {
        print "Show info for APK '$params'\n";
        execute("$tools{aapt} list -a $params");
    } else {
        print "Show info for $device...\n";
        execute("$tools{adb} -s $serial_num shell getprop");
    }
}


sub run_app_by_apk {
    Die("ERROR: No android device found!\n") unless defined $serial_num;
    if (defined $params && -f $params) {
        my $cmd = "$tools{aapt} dump badging $params";
        my $pkg_info = `$cmd`;
        my ($pkg_name, $activity);
        if ($pkg_info =~ /package: name='([^']+)'.+launchable-activity:.+?label='([^']+)'/s) {
            $pkg_name = $1;
            $activity = $2;

            execute("$tools{adb} -s $serial_num shell am start -n $pkg_name/.$activity");
        } else {
            Die("ERROR: No package name found by: $cmd\n".$pkg_info."\n");
        }
    } else {
        Die("ERROR: Please specify valid APK file by '-p APK'\n");
    }
}

sub run_app {
    Die("ERROR: No android device found!\n") unless defined $serial_num;
    if (defined $params) { # params must be 4 element list joined by "," (side effect: get problem when app command line argument contains ",")
        my ($pkg, $activity, $output, $argv, $stime) = split ",", $params;
        $stime ||= 3;
        $output ||= "dummy.txt";

        my $rm = "rm -rf $output";
        $rm = "" if $output eq "dummy.txt";
        my $cmd = <<EOF
am force-stop $pkg
logcat -c
rm -f /sdcard/stdout.txt
$rm
logcat > /sdcard/stdout.txt &
am start -n $pkg/$activity $argv
sleep $stime
kill \`ps logcat | grep -o "root *[0-9]*" | grep -o "[0-9][0-9]*"\`
am force-stop $pkg
EOF
;
        execute("$tools{adb} -s $serial_num shell '$cmd'");
    } else {
        Die("ERROR: Params is not specified!\n");
    }
}


sub cmd {
    Die("ERROR: No android device found!\n") unless defined $serial_num;
    if (defined $params) {
        print "Execute command on device $device: '$params'...\n";
        execute("$tools{adb} -s $serial_num $params");
        print "\n";
    } else {
        Die("ERROR: No command to execute!\n");
    }
}
