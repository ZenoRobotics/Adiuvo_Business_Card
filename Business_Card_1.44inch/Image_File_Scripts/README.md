## Image2Lcd Software to Initial Convert Image Files to C Files

Link for software: https://www.e-paper-display.com/download_detail/downloadsId=625.html

The steps followed to create image files, such as JPG, bin, bmp, or others (limited) is presented here.

### Creating Image Hex File

Creating a hex file that represents a monochrome image is currently accomplished with the help of the Image2Lcd program found in the link above. Pixel values need to be in the proper scan order so that the image can be correctly reproduced by the BC. The first step is to capture an image that will very closely fit the dimensions of the e-paper display.

For the 1.44" PD Aurora e-paper display (EPD) there are 96 rows and 126 columns of pixels (called dots: 1 dot/pixel = 2 bits). The three options for a dot are black, white, and nothing (no change).

Example: Batman Image Captured Using Snipping Tool

![image](https://github.com/user-attachments/assets/97e8343e-a465-4b5b-9f33-aace5fad7c82)


The Image2Lcd program above will create a hex file of 1 bit per pixel (black or white). 
