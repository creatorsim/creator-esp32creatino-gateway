import json
from elftools.elf.elffile import ELFFile
import subprocess

def parse_elf(elf_file_path):
    instructions_binary = []
    instructions_tag = []
    
    with open(elf_file_path, 'rb') as f:
        elf = ELFFile(f)
        
        # Busca las secciones de símbolos
        symbol_table = elf.get_section_by_name('.symtab')
        
        if symbol_table is None:
            raise ValueError("No se encontró la tabla de símbolos en el archivo ELF.")
        
        # Itera sobre los símbolos
        for symbol in symbol_table.iter_symbols():
            address = hex(symbol['st_value'])
            name = symbol.name
            is_global = symbol['st_info']['bind'] == 'STB_GLOBAL'
            
            # Filtra las direcciones que son multiples de 2 (simulando las direcciones de instrucciones)
            if address.startswith('0x') and int(address, 16) % 2 == 0:
                # Se arma el bloque para instructions_binary
                instructions_binary.append({
                    "Address": address,
                    "Label": name,
                    "loaded": "1000000010000010",  # Valor de ejemplo
                    "globl": is_global
                })
                
                # Se arma el bloque para instructions_tag
                instructions_tag.append({
                    "tag": name,
                    "addr": int(address, 16),
                    "globl": is_global
                })
    
    return {
        "instructions_binary": instructions_binary,
        "instructions_tag": instructions_tag
    }

def save_to_json(data, output_file):
    with open(output_file, 'w') as json_file:
        json.dump(data, json_file, indent=2)

# Ruta del archivo .o
elf_file_path = 'creatino_lib.o'  # Modificar por el nombre de tu archivo .o
output_file = 'creatino.o'  # Nombre del archivo de salida

# Procesa el archivo .o y genera el JSON
# Ejecuta el comando en la terminal
subprocess.run(['riscv64-unknown-elf-as', '-march=rv32imc', '-o', 'creatino_lib.o', 'creatino_lib.s'], check=True)
data = parse_elf(elf_file_path)
save_to_json(data, output_file)
