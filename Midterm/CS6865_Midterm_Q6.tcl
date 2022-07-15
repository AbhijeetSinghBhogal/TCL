#Create a simulator object
set ns [new Simulator]

#Open the nam trace file
set nf [open out.nam w]
$ns namtrace-all $nf

#Define a 'finish' procedure
proc finish {} {
    global ns nf
    $ns flush-trace
    #Close the trace file
    close $nf
    #Execute nam on the trace file
    exec nam out.nam &
    exit 0
}

set n0 [$ns node]
set n1 [$ns node]

$ns duplex-link $n0 $n1 10Mb 10ms DropTail

set tcp0 [new Agent/TCP]
$tcp0 set packetSize_ 500
$tcp0 set window_ 10
$ns attach-agent $n0 $tcp0

set ftp0 [new Application/FTP] 
$ftp0 attach-agent $tcp0

set sink0 [new Agent/TCPSink] 
$ns attach-agent $n1 $sink0

$ns connect $tcp0 $sink0

#Set output file
set f0 [open out0.tr w]

#Define close file proc
proc finish {} {
    global f0
    #Close the output files
    close $f0
    #Call xgraph to display the results
    exec xgraph out0.tr -geometry 800x400 &
    exit 0
}

#Define record file proc
proc record {} {
    global sink0 f0
    #Get an instance of the simulator
    set ns [Simulator instance]
    #Set the time after which the procedure should be called again
    set time 3.5
    #How many bytes have been received by the traffic sinks?
    set bw0 [$sink0 set bytes_]
    #Get the current time
    set now [$ns now]
    #Calculate the bandwidth (in MBit/s) and write it to the files
    puts $f0 "$now [expr $bw0/$time*8/1000000]"
    #Reset the bytes_ values on the traffic sinks
    $sink0 set bytes_ 0
    #Re-schedule the procedure
    $ns at [expr $now+$time] "record"
}

#Schedule events for the FTP agent
$ns at 0.0 "record"
$ns at 10.5 "$ftp0 start"
$ns at 50.5 "$ftp0 stop"

#Call the finish procedure after 60 seconds of simulation time
$ns at 60.0 "finish"

#Run the simulation
$ns run