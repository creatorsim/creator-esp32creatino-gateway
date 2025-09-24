#!/usr/bin/env python3


#
#  Copyright 2022-2025 Felix Garcia Carballeira, Diego Carmarmas Alonso, Alejandro Calderon Mateos, Elisa Utrilla Arroyo
#
#  This file is part of CREATOR.
#
#  CREATOR is free software: you can redistribute it and/or modify
#  it under the terms of the GNU Lesser General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  CREATOR is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU Lesser General Public License for more details.
#
#  You should have received a copy of the GNU Lesser General Public License
#  along with CREATOR.  If not, see <http://www.gnu.org/licenses/>.
#
#



import re
from flask import Flask, request, jsonify, send_file, Response
from flask_cors import CORS, cross_origin
import subprocess, os, signal, time
import sys
import threading
import select
import logging
import shutil
import glob

BUILD_PATH = './creator' #By default we call the classics ;)
ACTUAL_TARGET = ''
arduino = False

creatino_functions = [
    "initArduino",
    "digitalRead",
    "pinMode",
    "digitalWrite",
    "analogRead",
    "analogReadResolution",
    "analogWrite",
    "map",
    "constrain",
    "abs",
    "max",
    "min",
    "pow",
    "bit",
    "bitClear",
    "bitRead",
    "bitSet",
    "bitWrite",
    "highByte",
    "lowByte",
    "sqrt",
    "sq",
    "cos",
    "sin",
    "tan",
    "attachInterrupt",
    "detachInterrupt",
    "digitalPinToInterrupt",
    "pulseIn",
    "pulseInLong",
    "shiftIn",
    "shiftOut",
    "interrupts",
    "nointerrupts",
    "isDigit",
    "isAlpha",
    "isAlphaNumeric",
    "isAscii",
    "isControl",
    "isPunct",
    "isHexadecimalDigit",
    "isUpperCase",
    "isLowerCase",
    "isPrintable",
    "isGraph",
    "isSpace",
    "isWhiteSpace",
    "delay",
    "delayMicroseconds",
    "randomSeed",
    "random",
    "serial_available",
    "serial_availableForWrite",
    "serial_begin",
    "serial_end",
    "serial_find",
    "serial_findUntil",
    "serial_flush",
    "serial_parseFloat",
    "serial_parseInt",
    "serial_read",
    "serial_readBytes",
    "serial_readBytesUntil",
    "serial_readString",
    "serial_readStringUntil",
    "serial_write",
    "serial_printf"
]

stop_thread = False
# Diccionario para almacenar el proceso
process_holder = {}
#Stopping thread
stop_event = threading.Event()


# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

#  EXIT order
def handle_exit(sig, frame):
    try:
      print("\n🔴 Cleaning gateway...")
      cmd_array = ['idf.py','-C', './creatino','fullclean']
      subprocess.run(cmd_array, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=120)
      cmd_array = ['idf.py','-C', './creator','fullclean']
      subprocess.run(cmd_array, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=120)
      carpeta = './creatino/managed_components'

      # Verificar si la carpeta existe antes de intentar eliminarla
      if os.path.exists(carpeta):
          shutil.rmtree(carpeta)
          print(f"La carpeta '{carpeta}' ha sido eliminada.")
      else:
          print(f"La carpeta '{carpeta}' no existe.")

      print("✅ Closing program...")
      sys.exit(0)
    except Exception as e:
      print(f"ERROR:{e} ")

####----Cleaning functions----
def do_fullclean_request(request):
  try:
    req_data = request.get_json()
    target_device      = req_data['target_port']
    req_data['status'] = ''
    global BUILD_PATH
    BUILD_PATH = './creator'
    error = check_build()
    # flashing steps...
    if error ==0:
      do_cmd_output(req_data, ['idf.py','-C', BUILD_PATH,'fullclean'])
    if error == 0:
       req_data['status'] += 'Full clean done.\n'    
  except Exception as e:
    req_data['status'] += str(e) + '\n'
  return jsonify(req_data)  

def do_eraseflash_request(request):
  try:
    req_data = request.get_json()
    target_device      = req_data['target_port']
    req_data['status'] = ''
    global BUILD_PATH
    BUILD_PATH = './creator'
    error = check_build()
    # flashing steps...

    if error == 0:
      error = do_cmd_output(req_data, ['idf.py','-C', BUILD_PATH,'-p',target_device,'erase-flash'])
    if error == 0:
       req_data['status'] += 'Erase flash done. Please, unplug and plug the cable(s) again\n'
         
  except Exception as e:
    req_data['status'] += str(e) + '\n'    

  return jsonify(req_data) 

###---------- Debug Processs------
def check_gdb_connection():
    """ Verifica si gdb está escuchando en el puerto 3333 """
    command = ["lsof", "-i", ":3333"]
    try:
        lsof = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        output, errs = lsof.communicate(timeout=5)  # Reduce el tiempo de espera
        #print("Output: ", output.decode())
        return output.decode()
    except subprocess.TimeoutExpired:
        lsof.kill()
        output, errs = lsof.communicate()

def read_gdbgui_state(req_data):
    global process_holder
    global stop_event
    # Verificar si los procesos existen antes de acceder a ellos
    #openocd = process_holder.get("openocd")
    gdbgui = process_holder.get("gdbgui")
    if gdbgui:
      logging.info(f"PID de gdbgui: {gdbgui.pid}")

    # Si cualquiera de los procesos no está corriendo, salir del bucle
    # if not openocd or not gdbgui:
    #     print("ERROR: Los procesos necesarios no están corriendo.")
    #     stop_event.set()
    
    while not stop_event.is_set():
      # Verificar la conexión a GDB
      output = check_gdb_connection()
      while output is None:
          time.sleep(1)

      output_text = output.decode(errors="ignore")
      if "riscv32-e" not in output_text:
          print(" [ERROR]: Reintentando conexión...")
          if "gdbgui" in process_holder:
            # Matar el proceso específico en process_holder
            process_holder["gdbgui"].kill()  # Solo matar si existe
            process_holder.pop("gdbgui", None)
            kill_all_processes("gdbgui")

          try:
              thread = start_gdbgui(req_data)       
              print("Creado nuevo proceso")
              if 'gdbgui' in process_holder:
                 print(f"PID Nuevo de gdbgui: {process_holder['gdbgui'].pid}")
          except Exception as e:
              logging.error(f"Fallo al crear proceso: {e}")

          time.sleep(5)    
      else:
          print(f"PID Actual: {process_holder['gdbgui'].pid}")
          time.sleep(10)   
   



# def read_openocd_output(req_data):
#     global stop_event
#     """Verifica el estado del proceso"""
#     global process_holder
#     # Verificar si los procesos existen antes de acceder a ellos
#     openocd = process_holder.get("openocd")

#     # Si cualquiera de los procesos no está corriendo, salir del bucle
#     # if not openocd:
#     #     print("ERROR: Los procesos necesarios no están corriendo.")
#     #     return None
#     while True:
#       # Leer stderr
#       error_output = openocd.stderr.readline()
#       if error_output:
#           if "OpenOCD already running" in error_output:
#               pass  # No hacer nada si OpenOCD ya está corriendo
#           elif "Please list all processes to check if OpenOCD is already running" in error_output:
#               logging.warning("OpenOCD se está ejecutando en otro proceso y no se puede conectar(¿Tiene otro servidor abierto?)")
#               openocd.kill()  # Matar proceso openocd
#               process_holder.pop("openocd", None)
#               stop_event.set()    
#               #break  # Salir del bucle si el error es crítico (OpenOCD ya corriendo)
#           elif "Please check the wire connection" in error_output:
#               logging.error("Por favor revise la conexión de cables")  
#               openocd.kill()  # Matar proceso openocd
#               process_holder.pop("openocd", None)
#               stop_event.set()     
#               #break  # Salir del bucle si el error es por un problema de conexión
#           else:
#               logging.error(f"Salida de error desconocido: {error_output.strip()}")
#               openocd.kill()  # Matar proceso openocd
#               process_holder.pop("openocd", None)
#               stop_event.set()     
#               # Salir del bucle si hay un error no reconocido

          
          time.sleep(0.1)  # Pequeño delay para evitar consumo excesivo de CPU


def check_uart_connection():
    """ Checks UART devices """
    devices = glob.glob('/dev/ttyUSB*')
    logging.debug(f"Found devices: {devices}")
    if "/dev/ttyUSB0" in devices:
        logging.info("Found UART.")
        return 0
    elif devices:
        logging.error("Other UART devices found (Is the name OK?).")
        return 0
    else:
        logging.error("NO UART port found.")
        return 1
    
def check_jtag_connection():
    """ Checks JTAG devices """
    command = ["lsusb"]
    try:
        lsof = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        output, errs = lsof.communicate(timeout=5)  
        if output:
            output_text = output.decode(errors="ignore")
            if "JTAG" in output_text:
                logging.info("JTAG found")
                return True
            else:
                logging.warning("JTAG missing")
                return False
    except subprocess.TimeoutExpired:
        lsof.kill()
        output, errs = lsof.communicate()
    except Exception as e:
        logging.error(f"Error checking JTAG: {e}")
        return None
    return False    
# --- (6.2) Debug processes monitoring functions ---

def check_gdb_connection():
    """ Checks gdb status """
    command = ["lsof", "-i", ":3333"]
    try:
        lsof = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        output, errs = lsof.communicate(timeout=5) 
        logging.debug("GDB connection output: %s", output.decode())
        return output.decode()
    except subprocess.TimeoutExpired:
        lsof.kill()
        output, errs = lsof.communicate()
        logging.error(" GDB:Timeout waiting for GDB connection.")
    except Exception as e:
        logging.error(f"Error checking GDB: {e}")
        return None
    return False

def monitor_openocd_output(req_data, cmd_args, name):
    logfile_path = os.path.join(BUILD_PATH, f"{name}.log")
    try:
        print('A')
        # Ejecutar el comando idf.py con GDB
        global process_holder
        process_holder[name] = subprocess.Popen(
            cmd_args,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )
        if process_holder[name].poll() is None:
            logging.info(f"El proceso {name} sigue corriendo.")
        else:
            logging.info(f"El proceso {name} ha terminado.")
        logging.info(process_holder.keys())
        return process_holder[name]
    except Exception as e:
        logging.error(f"Error executing command {name}: {e}")
        process_holder.pop(name, None)
        return None
    
def kill_all_processes(process_name):
    try:
        if not process_name:
            logging.error("El nombre del proceso no puede estar vacío.")
            return 1

        # Comando para obtener los PIDs de los procesos
        get_pids_cmd = f"ps aux | grep '[{process_name[0]}]{process_name[1:]}' | awk '{{print $2}}'"
        result = subprocess.run(get_pids_cmd, shell=True, capture_output=True, text=True)

        #  PIDs list
        pids = result.stdout.strip().split()
        
        if not pids:
            logging.warning(f"Not processes found '{process_name}'.")
            return 1  # Devuelve 1 para indicar que no se hizo nada

        # Ejecuta kill solo si hay PIDs
        kill_cmd = f"kill -9 {' '.join(pids)}"
        result = subprocess.run(kill_cmd, shell=True, capture_output=True, timeout=120, check=False)

        if result.returncode != 0:
            logging.error(f"Error al intentar matar los procesos {process_name}. Salida: {result.stderr.strip()}")
        else:
            logging.info(f"Todos los procesos '{process_name}' han sido eliminados.")
        
        return result.returncode

    except subprocess.TimeoutExpired as e:
        logging.error(f"El proceso excedió el tiempo de espera: {e}")
        return 1

    except subprocess.CalledProcessError as e:
        logging.error(f"Error al ejecutar el comando: {e}")
        return 1

    except Exception as e:
        logging.error(f"Ocurrió un error inesperado: {e}")
        return 1

    
# (6.3) OpenOCD Function
def start_openocd_thread(req_data):
    target_board       = req_data['target_board']
    route = BUILD_PATH + '/openocd_scripts/openscript_' + target_board + '.cfg'
    logging.info(f"OpenOCD route: {route}")
    try:
        thread = threading.Thread(
            target=monitor_openocd_output,
            args=(req_data, ['openocd', '-f', route], 'openocd'),
            daemon=True
        )
        thread.start()
        logging.debug("Starting OpenOCD thread...")
        return thread
    except Exception as e:
        req_data['status'] += f"Error starting OpenOCD: {str(e)}\n"
        logging.error(f"Error starting OpenOCD: {str(e)}")
        return None
# (6.4) GDBGUI function    
def start_gdbgui(req_data):
    route = os.path.join(BUILD_PATH, 'gdbinit')
    logging.debug(f"GDB route: {route}")
    route = os.path.join(BUILD_PATH, 'gdbinit')
    if os.path.exists(route) and os.path.exists("./gbdscript.gdb"):
        logging.debug(f"GDB route: {route} exists.")
    else:
        logging.error(f"GDB route: {route} does not exist.")
        req_data['status'] += f"GDB route: {route} does not exist.\n"
        return jsonify(req_data)
    req_data['status'] = ''
    if check_uart_connection:
      logging.info("Starting GDBGUI...")
      gdbgui_cmd = ['idf.py', '-C', BUILD_PATH, 'gdbgui', '-x', route, 'monitor']
      time.sleep(5)
      try:
          process_holder['gdbgui'] = subprocess.run(
              gdbgui_cmd,
              stdout=sys.stdout,
              stderr=sys.stderr,
              text=True
          )
          if process_holder['gdbgui'].returncode != -9 and process_holder['gdbgui'].returncode != 0:
              logging.error(f"Command failed with return code {process_holder['gdbgui'].returncode}")

      except subprocess.CalledProcessError as e:
          logging.error("Failed to start GDBGUI: %s", e)
          req_data['status'] += f"Error starting GDBGUI (code {e.returncode}): {e.stderr}\n"
          return None
      except Exception as e:
          logging.error("Unexpected error in GDBGUI: %s", e)
          req_data['status'] += f"Unexpected error starting GDBGUI: {e}\n"
          return None
      
      req_data['status'] += f"Finished debug session: {e}\n"
    else:
      req_data['status'] += f"UART not connected: {e}\n"
    return jsonify(req_data)
          


def kill_all_processes(process_name):
  try:
      if not process_name:
          logging.error("El nombre del proceso no puede estar vacío.")
          return 1

      # Comando para obtener los PIDs de los procesos
      get_pids_cmd = f"ps aux | grep '[{process_name[0]}]{process_name[1:]}' | awk '{{print $2}}'"
      result = subprocess.run(get_pids_cmd, shell=True, capture_output=True, text=True)

        # Si hay más de un proceso, llamar a kill_all_processes
        if int(result.stdout.strip()) > 1:
            print(f"Hay más procesos '{process_name}'.") 
        
        # Construye el comando
        commands = f"ps aux | grep '[{process_name[0]}]{process_name[1:]}' | awk '{{print $2}}' | xargs kill -9"
        
        # Ejecuta el comando
        result = subprocess.run(commands, shell=True, capture_output=True, timeout=120, check=False)  
        # Verifica si hubo algún error en el proceso
        if result.returncode != 0:
            logging.error(f"Error al intentar matar los procesos {process_name}. Salida: {result.stderr.decode()}")        
        else:
            logging.info(f"Todos los procesos {process_name} han sido eliminados.")
        return result.returncode 
    
    except subprocess.TimeoutExpired as e:
        logging.error(f"El proceso excedió el tiempo de espera: {e}")
        return result.returncode 
    
    except subprocess.CalledProcessError as e:
        logging.error(f"Error al ejecutar el comando: {e}")
        return result.returncode 
    
    except Exception as e:
        logging.error(f"Ocurrió un error inesperado: {e}")

def check_jtag_connection():
    """ Verifica si el JTAG está conectado """
    command = ["lsusb"]
    try:
        lsof = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        output, errs = lsof.communicate(timeout=5)  # Reduce el tiempo de espera
        if output:
            output_text = output.decode(errors="ignore")
            if "JTAG" in output_text:
                logging.info("JTAG encontrado en la salida de lsusb.")
                return True
            else:
                logging.warning("No se encontró JTAG en la salida de lsusb.")
                return False
    except subprocess.TimeoutExpired:
        lsof.kill()
        output, errs = lsof.communicate()
    except Exception as e:
        logging.error(f"Error al verificar la conexión JTAG: {e}")
        return None
    return False

def do_debug_request(request):
    global stop_event
    global process_holder
    req_data = {'status': ''}
    try:
        req_data = request.get_json()
        target_device = req_data.get('target_port', None)
        if not target_device:
            req_data['status'] = 'Error: target_port is missing in the request.\n'
            return jsonify(req_data)

        error = check_build()
        if error != 0:
            req_data['status'] += "Build error.\n"
            return jsonify(req_data)
        logging.debug("Delete previous work")
        # Clean previous debug system
        if error == 0:
            if 'openocd' in process_holder:
                logging.debug('Killing OpenOCD')
                kill_all_processes("openocd")
                process_holder.pop('openocd', None)

            # Check if JTAG is connected
            if not check_jtag_connection():
                req_data['status'] += "No JTAG found\n"
                return jsonify(req_data)

            # Start OpenOCD
            logging.info("Starting OpenOCD...")
            openocd_thread = start_openocd_thread(req_data)
            while process_holder.get('openocd') is None:
              time.sleep(1)
              #start_openocd_thread(req_data)

            # Start gdbgui   
            #logging.info("Starting gdbgui")
            error = start_gdbgui(req_data)
            if error != 0:
                req_data['status'] += "Error starting gdbgui\n"
                return jsonify(req_data)   
        else:
            req_data['status'] += "Build error\n"
            
    except Exception as e:
        req_data['status'] += f"Unexpected error: {str(e)}\n"
        logging.error(f"Exception in do_debug_request: {e}")

    return jsonify(req_data)


########----------

# (1) Get form values
def do_get_form(request):
  try:
    return send_file('gateway.html')
  except Exception as e:
    return str(e)

# Change to ArduinoMode
def do_arduino_mode(request):
  req_data = request.get_json()
  statusChecker = req_data.get('arduino_support')
  req_data['status'] = ''
  global arduino
  arduino = not statusChecker
  print(f"Estado checkbox: {arduino} de tipo {type(statusChecker)}")    
  return  req_data
 
def check_build():
  global BUILD_PATH
  try:
    if arduino:
      BUILD_PATH = './creatino'
    else:
      BUILD_PATH = './creator' 
    return 0   
  except Exception as e:
    print("Error adapting assembly file: ", str(e))
    return -1  

class CrFunctionNotAllowed(Exception):
    pass
# Adapt assembly file...
def add_space_after_comma(text):
    return re.sub(r',([^\s])', r', \1', text)

def creator_build(file_in, file_out):
  try:
    # open input + output files
    fin  = open(file_in, "rt")
    fout = open(file_out, "wt")

    # write header
    fout.write(".text\n")
    fout.write(".type main, @function\n")
    fout.write(".globl main\n")

    data = []
    # for each line in the input file...
    for line in fin:
      line = add_space_after_comma(line)
      data = line.strip().split()
      # Creatino replace functions
      if len(data) >= 3 and data[0] == 'jal':
          ra_token = data[1].replace(',', '').strip()
          func_token = data[2].replace(',', '').strip()
          if ra_token == 'ra' and func_token in creatino_functions:
              line = f"jal ra, cr_{func_token}\n"

      if (len(data) > 0):
        if any(token.startswith('cr_') for token in data):
            if BUILD_PATH == './creator':
                raise CrFunctionNotAllowed()
        if (data[0] == 'rdcycle'):
          fout.write("#### rdcycle" + data[1] + "####\n")
          fout.write("addi sp, sp, -8\n")
          fout.write("sw ra, 4(sp)\n")
          fout.write("sw a0, 0(sp)\n")

          fout.write("jal ra, _rdcycle\n")
          fout.write("mv "+ data[1] +", a0\n")

          if data[1] != "a0":
            fout.write("lw a0, 0(sp)\n")
          fout.write("lw ra, 4(sp)\n")
          fout.write("addi sp, sp, 8\n")
          fout.write("####################\n")
          continue

        if (data[0] == 'ecall' and BUILD_PATH == './creatino'):
          fout.write("#### ecall ####\n")
          fout.write("  addi sp, sp, -4\n")
          fout.write("  sw ra, 0(sp)\n")

          fout.write("  jal ra, cr_ecall\n")

          fout.write("  lw ra, 0(sp)\n")
          fout.write("  addi sp, sp, 4\n")
          fout.write("####################\n")
          continue
        
      fout.write(line)

    # close input + output files
    fin.close()
    fout.close()
    return 0

  except CrFunctionNotAllowed:
    print("Error: cr_ functions are not supported in this mode.")
    return 2
  except Exception as e:
    print("Error adapting assembly file: ", str(e))
    return -1
  
# (3) Run program into the target board
def do_monitor_request(request):
  try:
    req_data = request.get_json()
    target_device      = req_data['target_port']
    req_data['status'] = ''
    check_build()
    stop_event.set() # Detener el hilo de monitoreo

    if 'openocd' in process_holder:
      logging.debug('Killing OpenOCD')
      kill_all_processes("openocd")
      process_holder.pop('openocd', None)

    if 'gdbgui' in process_holder:
      logging.debug('Killing GDBGUI')
      kill_all_processes("gdbgui")
      process_holder.pop('gdbgui', None)

    error = check_uart_connection()
    if error != 0:
      raise Exception("No UART port found") 
    
    
    build_dir = BUILD_PATH + '/build'
    logging.info(f"Checking for build directory: {build_dir}")
    if not os.listdir(build_dir):
      raise Exception("No build found. Please, build the program first.") 
    logging.info("Build directory is not empty, proceeding with monitor...")
     

    error = do_cmd(req_data, ['idf.py', '-C', BUILD_PATH,'-p', target_device, 'monitor']) 
    if error == 0:
      req_data['status'] += 'Monitoring program success.\n'  

  except Exception as e:
    req_data['status'] += str(e) + '\n'

  return jsonify(req_data)  

def do_cmd(req_data, cmd_array):
    """
    Execute a command and handle the output.
    """
    try:
        # Execute the command normally
        result = subprocess.run(cmd_array, capture_output=False, timeout=120, check=True)  
    except Exception as e:
      pass

    if result.stdout != None:
      req_data['status'] += result.stdout.decode('utf-8') + '\n'
    if result.returncode != None:
      req_data['error']   = result.returncode

    return req_data['error']


def do_cmd_output(req_data, cmd_array):
  try:
    result = subprocess.run(cmd_array, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=120)
  except:
    pass

  if result.stdout != None:
    req_data['status'] += result.stdout.decode('utf-8') + '\n'
  if result.returncode != None:
    req_data['error']   = result.returncode
    

  return req_data['error']


# (2) Flasing assembly program into target board
def do_flash_request(request):
  try:
    req_data = request.get_json()
    target_device      = req_data['target_port']
    target_board       = req_data['target_board']
    asm_code           = req_data['assembly']
    req_data['status'] = ''

    # create temporal assembly file
    text_file = open("tmp_assembly.s", "w")
    ret = text_file.write(asm_code)
    text_file.close()
    global BUILD_PATH
    global stop_event
    global ACTUAL_TARGET
    BUILD_PATH = './creator'
    # check arduinoCheck
    error = check_build()

    if 'openocd' in process_holder:
      logging.debug('Killing OpenOCD')
      kill_all_processes("openocd")
      process_holder.pop('openocd', None)

    if 'gdbgui' in process_holder:
      logging.debug('Killing GDBGUI')
      kill_all_processes("gdbgui")
      process_holder.pop('gdbgui', None)

    stop_event.set() # Detener el hilo de monitoreo  

    # transform th temporal assembly file
    filename= BUILD_PATH + '/main/program.s'
    logging.debug("filename to transform in do_flash_request: ", filename)
    error = creator_build('tmp_assembly.s', filename)
    if error == 2:
      logging.info("cr_ functions are not supported in this mode.")
      raise Exception("cr_ functions are not supported in this mode.")
    elif error != 0:
      raise Exception

    # flashing steps...
    if error == 0 :
      error = check_uart_connection()
    if error != 0:
      req_data['status'] += 'No UART port found.\n'
      raise  Exception("No UART port found")
     
    if error == 0 and BUILD_PATH == './creator':
      error = do_cmd(req_data, ['idf.py','-C', BUILD_PATH,'fullclean'])
    # if error == 0 and BUILD_PATH == './creatino' and ACTUAL_TARGET != target_board:
    if error == 0 and ACTUAL_TARGET != target_board:
        # print("ACTUAL_TARGET: ", ACTUAL_TARGET)
        print(f"File path: {BUILD_PATH}/sdkconfig")
        sdkconfig_path = os.path.join(BUILD_PATH, "sdkconfig")
        # 1. Crear/actualizar sdkconfig.defaults con la frecuencia correcta
        defaults_path = os.path.join(BUILD_PATH, "sdkconfig.defaults")
        if target_board == 'esp32c3':
          with open(defaults_path, "w") as f:
              f.write(
                  "CONFIG_FREERTOS_HZ=1000\n"
                  "# CONFIG_ESP_SYSTEM_MEMPROT_FEATURE is not set\n"
                  "# CONFIG_ESP_SYSTEM_MEMPROT_FEATURE_LOCK is not set\n"
              )
        elif target_board == 'esp32c6': 
          with open(defaults_path, "w") as f:
              f.write(
                  "CONFIG_FREERTOS_HZ=1000\n"
                  "# CONFIG_ESP_SYSTEM_PMP_IDRAM_SPLIT is not set\n"
              )     
        
        # 2. If previous sdkconfig exists, check if mem protection is disabled (for debug purposes)
        if os.path.exists(sdkconfig_path):
          if target_board == 'esp32c3':
            #CONFIG_FREERTOS_HZ=1000
            do_cmd(req_data, [
                'sed', '-i',
                r'/^CONFIG_FREERTOS_HZ=/c\CONFIG_FREERTOS_HZ=1000',
                sdkconfig_path
            ])
            # Memory Protection
            do_cmd(req_data, [
                'sed', '-i',
                r'/^CONFIG_ESP_SYSTEM_MEMPROT_FEATURE=/c\# CONFIG_ESP_SYSTEM_MEMPROT_FEATURE is not set',
                sdkconfig_path
            ])
            # Memory protection lock
            do_cmd(req_data, [
                'sed', '-i',
                r'/^CONFIG_ESP_SYSTEM_MEMPROT_FEATURE_LOCK=/c\# CONFIG_ESP_SYSTEM_MEMPROT_FEATURE_LOCK is not set',
                sdkconfig_path
            ])
          elif target_board == 'esp32c6':
            #CONFIG_FREERTOS_HZ=1000
            do_cmd(req_data, [
                'sed', '-i',
                r'/^CONFIG_FREERTOS_HZ=/c\CONFIG_FREERTOS_HZ=1000',
                sdkconfig_path
            ])
            # PMP IDRAM split
            do_cmd(req_data, [
                'sed', '-i',
                r'/^CONFIG_ESP_SYSTEM_PMP_IDRAM_SPLIT=/c\# CONFIG_ESP_SYSTEM_PMP_IDRAM_SPLIT is not set',
                sdkconfig_path
            ])  
          
        # 3. Ahora sí, ejecutar set-target
        error = do_cmd(req_data, ['idf.py', '-C', BUILD_PATH, 'set-target', target_board])
        if error != 0:
            raise Exception("No se pudo establecer el target")
        ACTUAL_TARGET = target_board 
        
    if error == 0:
      error = do_cmd(req_data, ['idf.py','-C', BUILD_PATH,'build'])
    if error == 0:
      error = do_cmd(req_data, ['idf.py','-C', BUILD_PATH, '-p', target_device, 'flash'])
    if error == 0:
          req_data['status'] += 'Flash completed successfully.\n'  

  except Exception as e:
    req_data['status'] += str(e) + '\n'
    print("Error in do_flash_request: ", str(e))

  return jsonify(req_data)

# (4) Flasing assembly program into target board
def do_job_request(request):
  try:
    req_data = request.get_json()
    target_device      = req_data['target_port']
    target_board       = req_data['target_board']
    asm_code           = req_data['assembly']
    req_data['status'] = ''

    # create temporal assembly file
    text_file = open("tmp_assembly.s", "w")
    ret = text_file.write(asm_code)
    text_file.close()
    error = check_build('tmp_assembly.s')
    # transform th temporal assembly file
    filename= BUILD_PATH + '/main/program.s'
    print("filename to transform in do_job_request: ", filename)
    error = creator_build('tmp_assembly.s', filename)
    if error != 0:
        raise Exception("Error adapting assembly file...")

    # flashing steps...
    if error == 0 and BUILD_PATH == './creator':
      error = do_cmd_output(req_data, ['idf.py',  'fullclean'])
    """if error == 0 and BUILD_PATH = './creator':
      error = do_cmd_output(req_data, ['idf.py',  'set-target', target_board])""" 

    if error == 0:
      error = do_cmd(req_data, ['idf.py','-C', BUILD_PATH,'build'])
    if error == 0:
      error = do_cmd(req_data, ['idf.py','-C', BUILD_PATH, '-p', target_device, 'flash'])

    if error == 0:
      error = do_cmd_output(req_data, ['./gateway_monitor.sh', target_device, '50'])
      error = do_cmd_output(req_data, ['cat', 'monitor_output.txt'])
      error = do_cmd_output(req_data, ['rm', 'monitor_output.txt'])

  except Exception as e:
    req_data['status'] += str(e) + '\n'

  return jsonify(req_data)


# (5) Stop flashing
def do_stop_flash_request(request):
  try:
    req_data = request.get_json()
    req_data['status'] = ''
    #Cleaning creatino 
    error = do_cmd_output(req_data, ['idf.py','-C', './creatino','fullclean'])
    if error == 0:
      do_cmd(req_data, ['pkill',  'idf.py'])

  except Exception as e:
    req_data['status'] += str(e) + '\n'

  return jsonify(req_data)

def do_stop_monitor_request(request):
  try:
    req_data = request.get_json()
    req_data['status'] = ''
    print("Killing Monitor")
    error = kill_all_processes("idf.py")
    if error == 0:
      req_data['status'] += 'Process stopped\n' 
    

  except Exception as e:
    req_data['status'] += str(e) + '\n'

  return jsonify(req_data)



# Setup flask and cors:
app  = Flask(__name__)
cors = CORS(app)
app.config['CORS_HEADERS'] = 'Content-Type'

# (1) GET / -> send gateway.html
@app.route("/", methods=["GET"])
@cross_origin()
def get_form():
  return do_get_form(request)

# (2) POST /flash -> flash
@app.route("/flash", methods=["POST"])
@cross_origin()
def post_flash():
  try:
    shutil.rmtree('build')
  except Exception as e:
    pass

  return do_flash_request(request)

# (3) POST /debug -> debug
@app.route("/debug", methods=["POST"])
@cross_origin()
def post_debug():
  return do_debug_request(request)

@app.route("/monitor", methods=["POST"])
@cross_origin()
def post_monitor():
  return do_monitor_request(request)

# (4) POST /job -> flash + monitor
@app.route("/job", methods=["POST"])
@cross_origin()
def post_job():
  return do_job_request(request)

# (5) POST /stop -> cancel
@app.route("/stop", methods=["POST"])
@cross_origin()
def post_stop_flash():
  return do_stop_flash_request(request)

@app.route("/stopmonitor", methods=["POST"])
@cross_origin()
def post_stop_monitor():
  return do_stop_monitor_request(request)

# (6) POST /fullclean -> clean
@app.route("/fullclean", methods=["POST"])
@cross_origin()
def post_fullclean_flash():
  return do_fullclean_request(request)

# (6) POST /fullclean -> clean
@app.route("/eraseflash", methods=["POST"])
@cross_origin()
def post_erase_flash():
  return do_eraseflash_request(request)

# (7) POST /arduinoMode-> cancel
@app.route("/arduinoMode", methods=["POST"])
@cross_origin()
def post_arduino_mode():
  return do_arduino_mode(request)

#signal.signal(signal.SIGINT, handle_exit)


# Run
app.run(host='0.0.0.0', port=8080, use_reloader=False, debug=True)