PROG = bin/source2dns
TESTPROG = bin/checkdns
DEP = records

tinydns : ${DEP}
	${PROG} $@

#dnsmasq : ${DEP}
#	${PROG} $@
#
#bind    : ${DEP}
#	${PROG} $@

tinydns-test : ${DEP}
	${TESTPROG} tinydns

#dnsmasq-test : <dependencies ?? => docker?>
#	<program to run> <arguments>
#
#bind-test : <dependencies ?? => docker?>
#	<program to run> <arguments>
#
