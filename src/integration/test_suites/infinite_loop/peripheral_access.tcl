init

proc compare {x y} {
    puts "'$x' vs. '$y'"

    if {[llength $y] != [llength $y]} {
        puts "length mismatch!"
        return -1
    }

    for {set i 0} {$i < [llength $x]} {incr i} {
        if {[lindex $x $i] != [lindex $y $i]} {
            puts "item $i mismatch!"
            return -1
        }
    }

    return 0
}

# Manually read dmstatus and check if the core is actually held in external
# reset. In the expected state bits anyunavail allrunning anyrunning allhalted 
# and anyhalted should be cleared.
set val [riscv dmi_read 0x11]
puts "dmstatus: $val"

if { ($val & 0x00000F00) != 0 } {
    echo "The core is not held in reset!"
    shutdown error
}

echo "Accessing ECC..."
set golden { 0x63707365 0x38342d33 0x3030312e 0x0 }
set actual [ read_memory 0x10008000 32 4 phys ]
if {[compare $actual $golden] != 0} {
    shutdown error
}

echo "Accessing HMAC..."
set golden { 0x6163686d 0x61327368 0x3030312e 0x0 }
set actual [ read_memory 0x10010000 32 4 phys ]
if {[compare $actual $golden] != 0} {
    shutdown error
}

echo "Accessing SHA512..."
set golden { 0x61327368 0x31322d35 0x3830302e 0x0 }
set actual [ read_memory 0x10020000 32 4 phys ]
if {[compare $actual $golden] != 0} {
    shutdown error
}

echo "Accessing SHA256..."
set golden { 0x61327368 0x35362d32 0x3830312e 0x0 }
set actual [ read_memory 0x10028000 32 4 phys ]
if {[compare $actual $golden] != 0} {
    shutdown error
}

echo "Writing and reading DOE IV..."
set golden { 0xCAFEBABA 0xDEADBEEF 0xD0ED0E00 }
write_memory 0x10000000 32 $golden phys
set actual [ read_memory 0x10000000 32 3 phys ]
if {[compare $actual $golden] != 0} {
    shutdown error
}

# Success
shutdown
