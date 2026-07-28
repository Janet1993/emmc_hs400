onbreak {quit -f}
onerror {quit -f}

vsim -voptargs="+acc" -t 1ps -L secureip -L fifo_generator_v13_0_1 -L xil_defaultlib -lib xil_defaultlib xil_defaultlib.Read_data512B_buffer

do {wave.do}

view wave
view structure
view signals

do {Read_data512B_buffer.udo}

run -all

quit -force
