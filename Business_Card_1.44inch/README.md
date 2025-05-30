# ePaper Business Card Development Project

### Directory Structure for BC (Business Card) Project

| Directory |	Description |
|-------------|---------------------------------------------------|
| Radian_Src | Code for Full BC Implementation |
| Spartan_Src | Code for Full BC Implementation and Simulation |
| Spartan_IR_UART_Tx_Rx | IR I/O Paths needed for Full BC Impl. |
| | Used for debug and test of IR Tx (Diode) and Rx (Decode) |
| | using two Leo boards, as well as testbench/sim using Vivado |
| Radian_IR_PassThru_Test | Instert Lattice BC with this data pass thru code along |
| | with 2 x Leo setup from above directory sources. |

### Spartan-RPi Board Source Files for Business Card - Full Design

The image drawing control logic for the BC's e-paper was developed using the Leo board first. This was helpful due to the facts that the BC FPGA board had not yet been tested since design and assembly, and the easy access to the control signals sent from the FPGA for probing and data acquisition. The PervasiveDisplays Extension Board Gen2 is specifically made for this reason, as well as having the proper analog driving circuitry for display.

The current state of this code is capable of drawing an image to the 1.44" Aurora Mb Display, where the image data is stored in internal distributed ram during the bit generation process. 

The only differences between the two VHDL sources (Lattice vs Spartan7) are: (1) the Lattice runs at 25 MHz system clock while the Spartan7's system clock is 100 MHz (divided down to 25 MHz in top so rest of VHDL sources are the same, and (2) I/O config files of course differ. Additionally, the image file scripts differ to create Mem source files for the Lattice and COE formatted memory file for the Spartan.  


## Full Project Development Parts List (Including Debug Hardware)

### Adafruit Industries: 
1 x 40-pin FPC to Straight 2x20 IDC Female Socket Header[ID:4905] \
1 x 40-pin 0.5mm pitch FPC Flex Cable with A-B Connections (25cm long)

### Mouser: 
1 x Pervasive Displays Electronic Paper Displays 1.44" EPD, Aurora, B \
1 x EPD Extension board E2144CS021

### Digikey or Mouser: 
1 x JTAG Module: Lattice HW-USBN-2B ACCY USB Download Cable

### ADIUVO: 
1 x Lattice FPGA BC Module \
1 x ADIUVO Spartan-7 board

--------------------

## Project Details

The E-Paper Business Card Project is implemented in VHDL code. At the heart of the  which is largerly a statemachine that covers all steps shown in the following diagram (source: E-paper Display COG Driver Interface Timing for 1.44”,1.9”,2”,2.6” and 2.7” EPD with G2 COG and Aurora Mb Film: PDF Document from PervasiveDisplays Doc. No. 4P018-00):

![image](https://github.com/user-attachments/assets/c1574b56-f662-4fc5-aed8-915cae9781d2)

Each section listed in the flow chart has its own set of control sequences that needs to be implemented as outlined in the PervasiveDisplay Doc. No. 4P018-00. We won't rehash what is already written in this document, but will instead describe the general methodology we used to accomplish the set of control requirements, as well as some subtleties to be aware of.

An equally important part of getting the display to function as you wish is creating the correctly formatted data you wish to display! We will spend some time explaining how we went about accomplishing our current capability, as well as describe other display creation methodologies you may wish to pursue. 

## Vivado Generated Top Level Schematic of the BC as of Present (March 5, 2025)

![image](https://github.com/user-attachments/assets/9d96451f-85ea-4424-8016-7df9c25a77df)


## JTAG Programmer

The JTAG Module listed above is connected to the BC board as follows:

![image](https://github.com/user-attachments/assets/4242a07f-5653-4f3e-bc2c-84fbeadbf3aa)

## Board Power

Currently, the BC board is supplied with 3.3v from an Arduino Uno to the board's battery cell terminals.

## Implementing an IR UART Tx/Rx Communication Protocol

### Standard UART Data Packet Format vs IR Method

#### UART - RP2040 <=> Spartan7 On Board Connection

<img src= "https://github.com/user-attachments/assets/74b826db-2ce2-4f91-a9ed-cc0d75de8bf9" width="450" height="250">

#### IR Tx Adapted Format of IR diode modulated 1's and 0's to Rx Data Packet Format Produced at the IR Receiver Module

<img src= "https://github.com/user-attachments/assets/ed6462eb-b116-4479-8e93-c5d5cdb409d3" width="450" height="250">

# [For Hackster.io Article]

## Project Overview
### Title: FPGA Based E-Paper Business Card

This article covers the design and test methodologies followed, along with the debug tools used, to create and test an FPGA based e-Paper display driver on a new board design. The business card (BC) platform is at center in this article and is designed and built by ADIUVO Engineering.

So, let's dive into the world of low power e-paper and an FPGA design to control it!

#### Things

The hardware components used in this project are: 

Mouser: \
1 x Pervasive Displays Electronic Paper Displays 1.44" EPD, Aurora, B  \
1 x EPD Extension board E2144CS021 (optional)

Digikey or Mouser:  \
1 x JTAG Module: Lattice HW-USBN-2B ACCY USB Download Cable 

ADIUVO: \
1 x Lattice CrossLink-NX-33U FPGA BC Module 


#### The software programs used include:
•	Lattice Radiant Software (IDE for the Lattice FPGA) \
•	Image2Lcd Software to Initial Convert Image Files to C Files \
•	Python Image Data Conversion to Lattice Ram data format.

### Introduction
#### First, what exactly is e-paper? 

E-paper, also known as electronic ink (e-ink) or electrophoretic display (EPD), is a display technology that mimics the look and feel of traditional printed paper. It uses tiny capsules filled with fluid containing charged particles to create images. These particles move in response to an electric field, making the display appear to change color, typically between black and white.

#### Electrical Connections 
E-paper displays require external, analog circuitry to supply the proper voltages for the display. The following schematic of a reference circuit for the 1.44 inch EPD comes from the E-paper Display COG Driver Interface Timing document, which can be found included in the project's github repository or online under the www.pervasivedisplays.com website. We will be refering to it quite a bit, so keep it handy!

![image](https://github.com/user-attachments/assets/fc191c37-9168-4e32-9f7f-93a1df3017dd)

**Figure x:** 1.44 inch EPD Reference Circuit


#### Driving Waveform Control Logic

For any e-paper display to work, the controlling processor must perform a series of register configurations within defined time frames without failure. Hence, they are nothing like TFT's :) The registers that are being configured in the display are for powerup, display options/functions, and power down. An SPI or quasi-SPI communication interface is used for these data transfers from the controlling hardware, such as an MCU or FPGA, to the e-paper. 

What is meant by quasi-SPI format is that there are some subtle, but very important differences one must be aware of to successfully communicate with the G2 COG driver. The details of which are in the E-paper Display COG Driver Interface Timing document, but are easy to misinterpret or bypass all together. So, I will spend a little time below in the Approach section pointing out possible gotchas with example waveforms acquired from the ADIUVO BC.

It should also be noted that some e-papers can be purchased with a driver board, such as the Waveshare e-Paper (G) 1.02" to 2.36". That e-paper can also display red, yellow, black, and white colors. 

### Approach

#### ADIUVO Custom-made BC FPGA board

The ADIUVO Engineering custom-made business card processing board is designed to operate on very low power. At the heart of the board is the Lattice CrossLink-NX-33U FPGA used for the e-paper controller design. The board's interface to the e-paper is made up of analog circuits that generate the correct voltage levels needed to power the e-paper display. 

The FPGA design's functionality is used for controlling the e-paper display through all its essential phases which include powerup, display manipulations of stored image data, and power down. Display manipulations include image inversion, display updates (e.g., a clock or temperature display) and display clearing. A single 3.3v coin battery runs the full BC board system (FPGA, display, and other circuitry)!

The Lattice Radiant FPGA Design Suite Software was used for the BC's FPGA design. You can download a free version of Radiant from the Lattice Semiconductor website: https://www.latticesemi.com/latticeradiant. 

#### SPI Serial Communication Protocol

The G2 COG driver (e-paper driver) expects SPI Mode 0 for communications and can operate up to 20 MHz. Mode 0 is the most popular mode for SPI communications. It is defined as data being sampled at the leading rising edge of the clock. Thus, the SPI FPGA HDL module was designed for this mode.    

The SPI's chip select active low (CS_n) is used somewhat differently for the COG driver, however. The CS_n is used to indicate the start/end of a command header + command index packet and the start/end of trailing data header + 1 or more 8-bit data words packet. The waveform below shows what the COG driver expects to understand the data it is receiving. 

![image](https://github.com/user-attachments/assets/5dfd4ec1-5a21-412d-a30a-767f5daa6456)

**Figure x:** G2 COG driver SPI Signal Format


#### State Machine Details

#### Image Formatting

Preparing an image for display requires that it has proper dimensions and data format. This part of the process is a bit of an artform of its own. Typically, you want an aesthetically pleasing representation of the image you wish to display. However, to do so, you will be working with reduced, proportional dimensions, as well as the correct pixel data formatting for your e-paper.  We sill step through the phases that were used for this project, along with critiquing the results obtained. 






