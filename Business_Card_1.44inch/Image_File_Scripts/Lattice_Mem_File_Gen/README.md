## PervasiveDisplay EPD Display Coordinates

### From the Aurora-MB_COG_Driver_Interface Document

![image](https://github.com/user-attachments/assets/0ca25377-12d4-41b5-bce4-1559f3b5e870)

![image](https://github.com/user-attachments/assets/2d733e41-efa4-4e00-ac1b-e5ff410f459f)

The data extracted from the Adiuvo Logo PNG file is currently accomplished using the Python script in this directory (png_logo_to_lattice_mem_format.py). The PNG logo has the set dimensions: Height = 36, Width = 128. This width is perfect for spanning the 128 dots (two bit pixels) of the 1.44" display. The height for this display is 96 rows, so the script adds 30 rows of white pixels to the top and 33 rows to the bottom of the logo.

Since data for the EPD is written and scanned one row at a time from row 1 to 96, the data written in all of the Python scripts for memory storage is done so in this format. However, the pixel is represented by only 1 bit in memory: 1 = black and 0 = white. This saves memory as a the bit 1 position is currently filled in by the FPGA statemachine after accessing a byte of pixel data from memory:

![image](https://github.com/user-attachments/assets/d69ce3f3-7023-4911-ba90-1b43538aaf38)

This can be done since a the nothing data option is not being used in image storage.

Thus, each byte of data in memory represents 8 pixel values grouped together going from column 1 to 128.





