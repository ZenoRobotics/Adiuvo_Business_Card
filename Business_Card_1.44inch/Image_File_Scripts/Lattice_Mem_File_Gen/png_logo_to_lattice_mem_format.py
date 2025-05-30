import matplotlib.pyplot as plt
from PIL import Image 

# Import an image from directory: 
input_image = Image.open("logo_png.png") 
  
# Extracting pixel map: 
pixel_map = input_image.load() 
  
# Extracting the width and height  
# of the image: 
width, height = input_image.size

rows, cols = height, width  # 96x128
bw_image = []  # Will become the 2D image array in 96 x 128 EDP display format
pix_val = 0

print(f"Height = {height}, Width = {width} \n")

BW_THRESH = 240  # Constant
bit_cnt = 0 
byte_sum = 0
total_byte_cnt = 0

with open("lattice_bram_image_data.mem", 'w', encoding='ascii') as rev:
    #white filler top rows 30x
    value = format(byte_sum, 'x')[2:].zfill(2)
    for fill_indx in range (30*16):
        rev.write(f"{value}   \n")
        total_byte_cnt = total_byte_cnt + 1

    # logo byte data
    for row_indx in range (height): 
        row_arr = []
        bit_cnt = 0
        byte_sum = 0
        for col_indx in range(width): 
        
            # getting the RGB pixel value. 
            r, g, b, p = input_image.getpixel((col_indx, row_indx)) 
          
            # Apply formula of grayscale
            # For ADIUVO Logo, Colors are Shades of Blue and Grey
            grayscale = (0.2*r + 0.3*g + 0.5*b)

            if grayscale >= BW_THRESH:
                pix_val = 1
            else:
                pix_val = 0
            
            row_arr.append(pix_val) # Used for matplot
            byte_sum = byte_sum + (pix_val * (2**(7-bit_cnt)))

            if bit_cnt == 7:
                #convert byte_sum to hex
                hex_number_no_prefix = '{:02x}'.format(byte_sum)
                #print byte formated without leading x to .mem file
                print(f'{hex_number_no_prefix}\n')
                rev.write(f"{hex_number_no_prefix}   \n")
                total_byte_cnt = total_byte_cnt + 1
                bit_cnt = 0 
                byte_sum = 0
            else:
                bit_cnt += 1
            
            #print(f"{grayscale}")
  
        
        bw_image.append(row_arr)
        #print('\n')

    #white filler bottom rows 30x
        byte_sum = 0
    value = format(byte_sum, 'x')[2:].zfill(2)
    for fill_indx in range (33*16):
        rev.write(f"{value}   \n")
        total_byte_cnt = total_byte_cnt + 1

print(f'Total byte count = {total_byte_cnt}\n')
plt.imshow(bw_image,cmap='gray')
plt.show()


