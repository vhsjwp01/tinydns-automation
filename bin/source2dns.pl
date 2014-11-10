#!/usr/bin/perl
use strict;
use File::Slurp;
use File::Basename;

################################################################################
# CONSTANTS
################################################################################

$ENV{'TERM'}  = "vt100";
$ENV{'PATH'}  = "/bin:/usr/bin:/usr/local/bin:/sbin:/usr/sbin:/usr/local/sbin";

my $SUCCESS      = 0;
my $ERROR        = 1;

my $USAGE        = "$0 < tinydns | dnsmasq | bind >";

################################################################################
# VARIABLES
################################################################################

my $exit_code    = $SUCCESS;
my $err_msg      = "";

my $dns_domain   = "lab.ingram.io";
my $subnet_range = "10.50.3.0/24";

################################################################################
# SUBROUTINES
################################################################################

# NAME: Function f__loccheck
# WHAT: Make sure a passed location is sane
#
sub f__loccheck {
    my $return_code  = $SUCCESS;
    my @arg1            = @{$_[0]};
    my $arg2            = $_[1];

    my $return_value = "false";

    if (( $arg1[0] ne "" ) || ( $arg2 ne "" )) {
        my $max_length = 2;
        my $loc_length = length( $arg2 );

        if ( $loc_length <= $max_length ) {

            foreach my $loc_record ( @arg1 ) {
                my ( $loc_code , $discard ) = split( /:/, $loc_record );
                $loc_code =~ s/^\^//g;

                if ( $arg2 eq $loc_code ) {
                    $return_value = "true";
                }

            }

        }

    }

    return $return_value;
}

#-------------------------------------------------------------------------------

# NAME: Function f__fqdncheck
# WHAT: Make sure a passed hostname is actually an hostname
#
sub f__fqdncheck {
    my $return_code  = $SUCCESS;
    my $arg          = $_[0];

    my $return_value = 0;

    if ( $arg ) {
        my $short_name     =~ s/\.$dns_domain$//g;
        my $hostname_check = 0;
        $hostname_check++ while ( $short_name =~ m/[^a-z0-9\-]/g );

        if (( $short_name ne $arg ) && ( $hostname_check == 0 )) {
            $return_value = 1;
        }

    }

    return $return_value;
}

#-------------------------------------------------------------------------------

# NAME: Function f__ipcheck
# WHAT: Make sure a passed IP address is actually an IP address
#
sub f__ipcheck {
    my $return_code     = $SUCCESS;
    my $arg             = $_[0];

    my $return_value = 0;

    if ( $arg ) {
        my $valid_octets = 4;
        my @octets = split( /\./, $arg );
        my $octet_count = scalar @octets;
        my $has_letters = 0;
        my $has_letters++ while ( $arg =~ m/[a-z]/g );

        if (( $octet_count == $valid_octets ) && ( $has_letters == 0 )) {
            my $counter = 0;

            while ( $counter < $valid_octets ) {

                if (( $counter == 0 ) || ( $counter == 3 )) {

                    if (( $octets[$counter] > 254 ) || ( $octets[$counter] < 1 )) {
                        $return_code++;
                    }

                } else {

                    if (( $octets[$counter] > 254 ) || ( $octets[$counter] < 0 )) {
                        $return_code++;
                    }

                }

                $counter++;
            }

        } else {
            $return_code++;
        }

    } else {
        $return_code++;
    }

    if ( $return_code == $SUCCESS ) {
        $return_value = 1;
    }

    return $return_value;
}

#-------------------------------------------------------------------------------

# NAME: Function f__tinydns
# WHAT: Convert source DNS data to TinyDNS data format
#
sub f__tinydns {
    my $return_code = $SUCCESS;
    my $data_dir    = $_[0];
    my $data_file   = "tinydns.data";

    chdir( $data_dir );
    system( "rm -f \"$data_file\" >/dev/null 2>\&1" );

    print "    Conversion to TinyDNS data format: $data_dir/$data_file\n";

    my $arpa_regex = "";

    my ( $network, $netmask ) = split( /\// , $subnet_range );
    my ( $one, $two, $three, $four ) = split( /\./, $network );

    if ( $four ne "" ) {

        if ( $netmask eq "8" ) {
            $arpa_regex = $one . "\.in-addr.arpa";
        } elsif ( $netmask eq "16" ) {
            $arpa_regex = $two . "." . $one . ".in-addr.arpa";
        } elsif ( $netmask eq "24" ) {
            $arpa_regex = $three . "." . $two . "." . $one . ".in-addr.arpa";
        } else {
            $err_msg    = "Unknown netmask: \"$netmask\"\n";
            $return_code++;
        }

        # Start checking tinyDNS syntax
        if ( $arpa_regex ) {
            my @loc_records        = "";
            my @soa_records        = "";
            my @soa_ns_a_records   = "";
            my @ns_a_records       = "";
            my @mx_records         = "";
            my @a_ptr_records      = "";
            my @a_records          = "";
            my @ptr_records        = "";
            my @cname_records      = "";
            my @ordered_records    = "";
            chomp( my @all_records = read_file( "records" ));

            foreach ( @all_records ) {
                my $this_record = $_;

                if ( $this_record !~ /^#|^.$/ ) {

                    if ( $this_record =~ /^\%/ ) {
                        push( @loc_records, $this_record );
                    } elsif ( $this_record =~ /^Z/ ) {
                        push( @soa_records, $this_record );
                    } elsif ( $this_record =~ /^\./ ) {
                        push( @soa_ns_a_records, $this_record );
                    } elsif ( $this_record =~ /^\&/ ) {
                        push( @ns_a_records, $this_record );
                    } elsif ( $this_record =~ /^\@/ ) {
                        push( @mx_records, $this_record );
                    } elsif ( $this_record =~ /^\=/ ) {
                        push( @a_ptr_records, $this_record );
                    } elsif ( $this_record =~ /^\+/ ) {
                        push( @a_records, $this_record );
                    } elsif ( $this_record =~ /^\^/ ) {
                        push( @ptr_records, $this_record );
                    } elsif ( $this_record =~ /^C/ ) {
                        push( @cname_records, $this_record );
                    } else {
                        print "        WARNING:  Unknown record type: $this_record\n";
                    }

                }

            }

            # Records get processed in this order:
            # % - these are locations
            # Z - these are SOA records
            # . - these are SOA + NS + A records
            # & - these are NS + A records
            # @ - these are MX records
            # = - these are A + PTR records
            # + - these are A records
            # ^ - these are PTR records
            # C - these are CNAME records

            push(@ordered_records, @loc_records);
            push(@ordered_records, @soa_records);
            push(@ordered_records, @soa_ns_a_records);
            push(@ordered_records, @ns_a_records);
            push(@ordered_records, @mx_records);
            push(@ordered_records, @a_ptr_records);
            push(@ordered_records, @a_records);
            push(@ordered_records, @ptr_records);
            push(@ordered_records, @cname_records);

            open( TINYDNS_DATA, ">$data_dir/$data_file" );

            foreach my $record ( @ordered_records ) {

                if ( $record ne "" ) {
                    my @elements        = split(/:/, $record );
                    my $first_character = substr( $elements[0], 0, 1 );
                    my $part_count      = scalar @elements;

                    #print "Record first character: $first_character\n";

                    if ( $first_character eq "%" ) {
                        my $max_parts      = 2;
                        my $min_parts      = 1;
                        my $max_loc_length = 2;
                        my $this_loc       = $elements[0];
                        my $this_loc       =~ s/^$first_character//g;
                        my $loc_length     = length( $this_loc );

                        if ( $loc_length <= $max_loc_length ) {

                            if (( $part_count >= $min_parts ) && ( $part_count <= $max_parts )) {
                                print "        Adding validated record entry: \"$record\"\n";
                                print TINYDNS_DATA "$record\n";
                            } else {
                                print "            ERROR:  Malformed record entry: \"$record\"\n";
                                $return_code++;
                            }

                        } else {
                            print "            ERROR:  Invalid location definition in record entry: \"$record\"\n";
                            $return_code++;
                        }

                    } elsif ( $first_character eq "\." ) {
                        my $is_forward   = 0;
                        my $is_reverse   = 0;
                        my $is_ipaddress = 0;
                        my $max_parts    = 6;
                        my $min_parts    = 3;

                        if (( $part_count >= $min_parts ) && ( $part_count <= $max_parts )) {
                            my $valid_loc = "false";
                            my $this_loc  = $elements[5];

                            # Make sure the optional location code is properly defined if present
                            if ( $this_loc eq "" ) {
                                $valid_loc = "true";
                            } else {
                                $valid_loc = &f__loccheck( \@loc_records, $this_loc );
                            }

                            if ( $valid_loc eq "true" ) {
                                $is_forward = 0;
                                $is_reverse = 0;

                                # This element is either a forward or reverse zone record
                                if ( $elements[0] =~ /\.$dns_domain$/ ) {
                                    $is_forward = 1;
                                }

                                if ( $elements[0] =~ /\.$arpa_regex$/ ) {
                                    $is_reverse = 1;
                                }

                                if (( $is_forward == 1 ) || ( $is_reverse == 1 )) {
                                    $is_ipaddress = &f__ipcheck( $elements[1] );

                                    if ( $is_ipaddress == 1 ) {
                                        print "        Adding validated record entry: \"$record\"\n";
                                        print TINYDNS_DATA "$record\n";
                                    } else {
                                        print "            ERROR:  Invalid IP address in record entry: \"$record\"\n";
                                        $return_code++;
                                    }

                                } else {
                                    print "            ERROR:  Malformed zone definition in record entry: \"$record\"\n";
                                    $return_code++;
                                }

                            } else {
                                print "            ERROR:  Invalid location definition in record entry: \"$record\"\n";
                                $return_code++;
                            }

                        } else {
                            print "            ERROR:  Malformed record entry: \"$record\"\n";
                            $return_code++;
                        }

                    } elsif ( $first_character =~ /[\=,\+]/ ) {
                        my $is_fqdn      = 0;
                        my $is_ipaddress = 0;
                        my $max_parts    = 5;
                        my $min_parts    = 2;

                        if (( $part_count >= $min_parts ) && ( $part_count <= $max_parts )) {
                            my $valid_loc = "false";
                            my $this_loc  = $elements[4];

                            # Make sure the optional location code is properly defined if present
                            if ( $this_loc eq "" ) {
                                $valid_loc = "true";
                            } else {
                                $valid_loc = &f__loccheck( \@loc_records, $this_loc );
                            }

                            if ( $valid_loc eq "true" ) {
                                # Check FQDN validity of element 0
                                my $this_arg = $elements[0]; 
                                $this_arg =~ s/^${first_character}//g;
                                $is_fqdn  = &f__fqdncheck( $this_arg );

                                # Check IP address validity of element 1
                                $is_ipaddress = &f__ipcheck( $elements[1] );

                                if (( $is_fqdn == 1 ) && ( $is_ipaddress == 1 )) {
                                    print "        Adding validated record entry: \"$record\"\n";
                                    print TINYDNS_DATA "$record\n";
                                } else {
                                    print "            ERROR:  Invalid IP address in record entry: \"$record\"\n";
                                    $return_code++;
                                }

                            } else {
                                print "            ERROR:  Invalid location definition in record entry: \"$record\"\n";
                                $return_code++;
                            }

                        } else {
                            print "            ERROR:  Malformed record entry: \"$record\"\n";
                            $return_code++;
                        }
                     
                    } elsif ( $first_character eq "C" ) {
                        my $is_fqdn1  = 0;
                        my $is_fqdn2  = 0;
                        my $max_parts = 5;
                        my $min_parts = 2;

                        if (( $part_count >= $min_parts ) && ( $part_count <= $max_parts )) {
                            my $valid_loc = "false";
                            my $this_loc  = $elements[4];

                            # Make sure the optional location code is properly defined if present
                            if ( $this_loc eq "" ) {
                                $valid_loc = "true";
                            } else {
                                $valid_loc = &f__loccheck( \@loc_records, $this_loc );
                            }

                            if ( $valid_loc eq "true" ) {
                                # Check FQDN validity of element 0
                                my $this_arg = $elements[0];
                                $this_arg =~ s/^${first_character}//g;
                                $is_fqdn1 = &f__fqdncheck( $this_arg );
        
                                # Check FQDN validity of element 1
                                $is_fqdn2 = &f__fqdncheck( $elements[1] );
        
                                if (( $is_fqdn1 == 1 ) && ( $is_fqdn2 == 1 )) {
                                    print "        Adding validated record entry: \"$record\"\n";
                                    print TINYDNS_DATA "$record\n";
                                } else {
                                    print "            ERROR:  Malformed FQDN definitions in record entry: \"$record\"\n";
                                    $return_code++;
                                }

                            } else {
                                print "            ERROR:  Invalid location definitions in record entry: \"$record\"\n";
                                $return_code++;
                            }

                        } else {
                            print "            ERROR:  Malformed record entry: \"$record\"\n";
                            $return_code++;
                        }

                    }

                }

            }

            close( TINYDNS_DATA );
        } else {
            $return_code++;
        }

    } else {
        $return_code++;
    }

    return $return_code;
}

#-------------------------------------------------------------------------------

# NAME: Function f__dnsmasq
# WHAT: Convert source DNS data to DNSMasq data format
#
##f__dnsmasq() {
##    return_code=${SUCCESS}
##    echo "    Conversion to DNSMasq data format"
##
##    return ${return_code}
##}

#-------------------------------------------------------------------------------

# NAME: Function f__bind
# WHAT: Convert source DNS data to BIND data format
#
##f__bind() {
##    return_code=${SUCCESS}
##    echo "    Conversion to BIND conf file format"
##
##    return ${return_code}
##}

#-------------------------------------------------------------------------------

################################################################################
# MAIN
################################################################################

# WHAT: Check our arguments
# WHY:  Operation depends on it
#
if ( $exit_code == $SUCCESS ) {
    my ( $my_name, $bin_dir, $discard ) = fileparse( $0 );
    my $src_dir;

    if ( $bin_dir eq "./" ) {
        $src_dir = "../";
    } else {
        $bin_dir =~ s/\/$//g;
        ( $discard, $src_dir, $discard ) = fileparse( $bin_dir );
    }

    $src_dir =~ s/\/$//g;

    if ( -e "$src_dir/records" ) {
        my $arg;

        foreach $arg ( @ARGV ) {

            if ( $arg eq "tinydns" ) {
                &f__tinydns ( $src_dir );
            } elsif ( $arg eq "dnsmasq" ) {
                &f__dnsmasq;
            } elsif ( $arg eq "bind" ) {
                &f__bind;
            } else {
                $err_msg = "Unknown argument: \"$arg\"\n"; 
                $exit_code++;
            }

            $exit_code += $?;
        }

    } else {
        $err_msg = "Cannot locate file \"records\" in source directory \"$src_dir\"";
        $exit_code = $ERROR;
    }

}

# WHAT: Complain if necessary and exit
# WHY:  Success or failure, we are through!
#
if ( $exit_code != $SUCCESS ) {

    if ( $err_msg ne "" ) {
        print "\n";
        print "    ERROR: $err_msg ... processing halted\n";
        print "\n";
        print "    Usage: $USAGE\n";
        print "\n";
    }

}

exit $exit_code;
