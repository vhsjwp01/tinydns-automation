PROG = bin/source2dns
DEP = records

tinydns : ${DEP}
	${PROG} $@

dnsmasq : ${DEP}
	${PROG} $@

bind    : ${DEP}
	${PROG} $@

#tinydns-test : <dependencies ?? => docker?>
#	<program to run> <arguments>
#
#dnsmasq-test : <dependencies ?? => docker?>
#	<program to run> <arguments>
#
#bind-test : <dependencies ?? => docker?>
#	<program to run> <arguments>
#
