onbreak {quit -f}
onerror {quit -f}

vsim -t 1ps -lib xil_defaultlib Read_data512B_buffer_opt

do {wave.do}

view wave
view structure
view signals

do {Read_data512B_buffer.udo}

run -all

quit -force
