#FPGA FFT Equalizer

FPGA FFT Equalizer is a basic audio processing tool. It can accept audio signal via Line-in 3,5mm Jack, analyze it, remove frequency bands chosen by the user and send processed signal to headphones or speakers via Line-out 3,5mm Jack. It also visualizes present frequencies on a monitor screen as a bar graph via VGA interface.

Project is implemented in VHDL hardware description language and was designed to be used on Terasic DE2-70 evaluation board equipped with an Altera Cyclone II FPGA core. It uses WM8731 audio controller for accepting and sending audio signals and ADV7123 VGA DAC for generating VGA signal.
Audio analysis and modification is done using FFT algorithm. Time-domain audio signal is transformed into frequency-domain, desired frequencies are muted and then it is transformed back to time-domain with IFFT. Frequency-domain samples are also used to generate visualization.

This project was created as an assignment for Microprocessor Technologies 2 course at AGH University of Science And Technology.
