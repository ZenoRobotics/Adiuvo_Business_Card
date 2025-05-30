## Sub-Project Purpose

This subproject of the Business Card project is for solely testing the Lattice BC's onboard IR Tx and IR Rx/Decode circuitry and UART communication methodology. The Lattice code relays IR data from one Lattice BC platform to another can be used standalone.

The 2xSpartan7 boards are also used to interface with tx/rx data display using Thonny and the Pico. The HDL source for this part of the test is identical for each board.

Supplies required:
- Spartan7-RPi ESys Boards x 2
- IR LED
- 470 Ohm Resistor
- IR Receiver Module: Vishay TSOP32538 or similar
- Mini Breadboards x 2
- USB A to USB mini B cables x 4
- Lattice BC (as well as a 3.3v Power source and JTAG module)


## IR Data Tx <=> Rx Test Path 1 

![image](https://github.com/user-attachments/assets/d80cdd42-090a-433d-bfda-2fa3f947fcfb)


## IR Data Tx <=> Rx Test Path 2

![image](https://github.com/user-attachments/assets/230d81a9-3377-43db-b605-c305c8e7f0a2)

The VHDL source code for the system outlined in the diagram above to test the IR channels are in this GitHub repository under:

     Adiuvo_Embed_Ref_Projs > Boards > Custom_Lattice_BC > Projects > Business_Card_1.44inch > IR_TxRx_Testing > Lattice_BC_HDL

and 

     Adiuvo_Embed_Ref_Projs > Boards > Custom_Lattice_BC > Projects > Business_Card_1.44inch > S7_Dev_Brd_HDL

A.K.A. 

     C:/FPGA/Vivado_Projs/IR_Remote_Proj


### microPython code for interfacing to the Spartan7 boards can be found just below under:

      ... > Business_Card_1.44inch > IR_TxRx_Testing > Thonny

On my computer, the microPython code can be found at:

      ... \ADIUVO\Projects\BusinessCard\thonny\Uart-IRDecoder-FPGA-to-Pico-to-Thonny

and

     ... \ADIUVO\Projects\BusinessCard\thonny\Uart-Laptop-to-Pico-to-FPGA-IRDiode
     

