#Create a simulator object
set ns [new Simulator]

#Initialize the routing protocol 'rtproto' as distance vector routing protocol
$ns rtproto DV

#Set red for the UDP flow
$ns color 1 Red

#Set green for the TCP flow
$ns color 2 Green

#Open the nam trace file
set nf [open out.nam w]
$ns namtrace-all $nf

#Open the output files
set f0 [open out0.tr w]
set f1 [open out1.tr w]

#Define a 'finish' procedure
proc finish {} {
    global ns nf f0 f1
    $ns flush-trace
    #Close the trace file
    close $nf
    #Close the output files
    close $f0
	close $f1
    #Execute nam on the trace file
    exec nam out.nam &
    #Call xgraph to display the results
	exec xgraph out0.tr out1.tr -geometry 800x400 &
    exit 0
}

#Create 6 nodes
set n0 [$ns node]
set n1 [$ns node]
set n2 [$ns node]
set n3 [$ns node]
set n4 [$ns node]
set n5 [$ns node]

#Connect the nodes
$ns duplex-link $n0 $n2 1Mb 10ms DropTail
$ns duplex-link $n1 $n2 1Mb 10ms DropTail
$ns duplex-link $n2 $n3 1Mb 10ms DropTail
$ns duplex-link $n3 $n4 1Mb 10ms DropTail
$ns duplex-link $n3 $n5 1Mb 10ms DropTail

#Create a UDP agent and attach it to node 0
set udp0 [new Agent/UDP]
$ns attach-agent $n0 $udp0

#Create a TCP agent and attach it to node 1
set tcp0 [new Agent/TCP]
$ns attach-agent $n1 $tcp0
$tcp0 set packetSize_ 500
$tcp0 set window_ 1000
$tcp0 set interval_ 0.005

#For setting the colors for the flow ids
$udp0 set class_ 1
$tcp0 set class_ 2

#Create a CBR traffic source and attach it to udp0
set cbr0 [new Application/Traffic/CBR]
$cbr0 set packetSize_ 500
$cbr0 set interval_ 0.005
$cbr0 attach-agent $udp0

#Create a FTP traffic source and attach it to tcp0
set ftp0 [new Application/FTP]
$ftp0 attach-agent $tcp0

#Create a LossMonitor agent (traffic sink) and attach it to node 4
set null0 [new Agent/LossMonitor]
$ns attach-agent $n4 $null0

#Create a TCPSink agent (traffic sink) and attach it to node 5
set null1 [new Agent/TCPSink]
$ns attach-agent $n5 $null1

#Connect the two traffic sources with the two traffic sinks
$ns connect $udp0 $null0
$ns connect $tcp0 $null1

#Define a procedure which periodically records the bandwidth received by the two traffic sinks null0 and null1 and writes it to the two files f0 and f1
proc record {} {
    global null0 null1 f0 f1
    #Get an instance of the simulator
	set ns [Simulator instance]
    #Set the time after which the procedure should be called again
	set time 0.5
    #How many bytes have been received by the traffic sinks?
	set bw0 [$null0 set bytes_]
    set bw1 [$null1 set bytes_]
    #Get the current time
	set now [$ns now]
    #Calculate the bandwidth (in MBit/s) and write it to the files
	puts $f0 "$now [expr $bw0/$time*8/1000000]"
    puts $f1 "$now [expr $bw1/$time*8/1000000]"
    #Reset the bytes_ values on the traffic sinks
	$null0 set bytes_ 0
    $null1 set bytes_ 0
	#Re-schedule the procedure
    $ns at [expr $now+$time] "record"
}

#Start logging the received bandwidth
$ns at 0.0 "record"

#Start the traffic sources
$ns at 5.0 "$cbr0 start"
$ns at 1.0 "$ftp0 start"

#Stop the traffic sources
$ns at 15.0 "$cbr0 stop"
$ns at 15.0 "$ftp0 stop"

#Call the finish procedure after 20 seconds simulation time
$ns at 20.0 "finish"

#Run the simulation
$ns run