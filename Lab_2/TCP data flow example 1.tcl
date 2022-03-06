#Create a simulator object
set ns [new Simulator]

#Initialize the routing protocol 'rtproto' as distance vector routing protocol
$ns rtproto DV

#Open a trace file for the routing information data
set tf [open out.tr w]
$ns trace-all $tf

#Open the nam trace file for the nam trace data
set nf [open out.nam w]
$ns namtrace-all $nf

#Define a 'finish' procedure
proc finish {} {
        global ns nf tf
        $ns flush-trace
	#Close both the trace files
        close $nf
        close $tf
	#Execute nam on the trace file
        exec nam out.nam &
        exit 0
}

#Create two nodes
set n0 [$ns node]
set n1 [$ns node]

#Create a duplex link between the nodes
$ns duplex-link $n0 $n1 1Mb 10ms DropTail

#Create a TCP agent and attach it to node n0
set tcp0 [new Agent/TCP]
$tcp0 set packetSize_ 500
$tcp0 set window_ 1
$ns attach-agent $n0 $tcp0

# Create a FTP traffic source and attach it to tcp0
set ftp0 [new Application/FTP]
$ftp0 attach-agent $tcp0

#Create a TCPSink agent (a traffic sink) and attach it to node n1
set sink0 [new Agent/TCPSink]
$ns attach-agent $n1 $sink0

#Connect the traffic source with the traffic sink
$ns connect $tcp0 $sink0  

#Schedule events for the FTP agent
$ns at 0.5 "$ftp0 start"
$ns at 4.5 "$ftp0 stop"

#Call the finish procedure after 5 seconds of simulation time
$ns at 5.0 "finish"

#Run the simulation
$ns run