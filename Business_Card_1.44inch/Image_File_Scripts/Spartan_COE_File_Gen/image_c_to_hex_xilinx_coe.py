#Xilinx RAM format
def process_hex_bytes(file_path):
    with open(file_path, 'r') as f:
        hex_string = f.read().replace('0X', '').replace('\n', '')  # Remove spaces and newlines .replace(',', '')
    return hex_string 

def hex_string_to_hex_list(hex_string):
    hex_list = []
    for i in range(0, len(hex_string), 2):
        hex_value = hex_string[i:i+2]
        try:
            decimal_value = int(hex_value, 16)
            hex_value = hex(decimal_value)[2:].zfill(2)
            hex_list.append(hex_value)
        except ValueError:
            print(f"Invalid hex value: {hex_value}")
    return ','.join(hex_list)



if __name__ == "__main__":
    file_path = "data_only.txt"  # Replace with the actual path to your file
    hex_string = process_hex_bytes(file_path)
    #print(hex_string)
    
    
    with open("rev_hex.coe", 'w') as rev:
       rev.write("memory_initialization_radix=16; \n")
       rev.write("memory_initialization_vector= \n")
       rev.write(hex_string)
       rev.write(";")
