PROG       = bin/source2dns
DEP        = records
TESTPROG   = bin/checkdns
TESTDEP    = tinydns.data
DNSDATACMD = tinydns-data
DNSDATADIR = /etc/ndjbdns
DNSDATA    = data
DHCPDPROG  = bin/source2dhcpd

tinydns : ${DEP}
	${PROG} $@

#dnsmasq : ${DEP}
#       ${PROG} $@
#
#bind    : ${DEP}
#       ${PROG} $@

tinydns-test : ${TESTDEP}
	cp ${TESTDEP} ${DNSDATADIR}
	cd ${DNSDATADIR} && perl -MFile::Slurp -e ';' && perl -MFile::Basename -e ';' && ${DNSDATACMD} ${DNSDATA}
	service dnscache restart
	service tinydns restart
	${TESTPROG} tinydns

dhcpd : ${DEP}
	${DHCPDPROG}

#dnsmasq-test : <dependencies ?? => docker?>
#       <program to run> <arguments>
#
#bind-test : <dependencies ?? => docker?>
#       <program to run> <arguments>
#
