def process_hex_bytes(file_path):
    with open(file_path, 'r') as f:
        hex_string = f.read().replace('0X', '').replace('\n', '').replace(',', '')
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
    return hex_list


if __name__ == "__main__":
    file_path = "data_only.txt"  # Replace with the actual path to your file
    hex_string_array = process_hex_bytes(file_path)
    hex_data_array = hex_string_to_hex_list(hex_string_array)
    hex_data_count = len(hex_data_array)
    value_pair = ''
    true_index = 0
    with open("lattice_bram_image_data.mem", 'w', encoding='ascii') as rev:
       for index, value in enumerate(hex_data_array):
           #rev.write(f"{hex(index)[2:].zfill(3)}   {value}   \n")
           rev.write(f"{value}   \n")
           if index < 20:
                 print(f"{hex(index)[2:].zfill(3)}   {value}   \n")
                 #print("index = ")
                 #print(index)
                 #print("\n")
            
    print(f"End index value = {index}") 
