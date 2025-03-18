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


from flask import Flask, request, jsonify, send_file, Response
from flask_cors import CORS, cross_origin
import subprocess, os, signal, time
import sys
import threading
import select
import logging

BUILD_PATH = './creator' #By default we call the classics ;)
arduino = False

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
      print("\n🔴 Limpiando directorio de Creatino, espere...")
      cmd_array = ['idf.py','-C', './creatino','fullclean']
      subprocess.run(cmd_array, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=120)
      print("✅ Borrado directorio de build de creatino. Cerrando programa.")
      #cmd_array = ['pkill', 'gdbgui']
      #subprocess.run(cmd_array, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=120)
      sys.exit(0)
    except Exception as e:
      print(f"ERROR:{e} ")

####----Full Clean----
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
        return output
    except subprocess.TimeoutExpired:
        lsof.kill()
        output, errs = lsof.communicate()

def read_gdbgui_state(req_data):
    global process_holder
    global stop_event
    # Verificar si los procesos existen antes de acceder a ellos
    openocd = process_holder.get("openocd")
    gdbgui = process_holder.get("gdbgui")

    # Si cualquiera de los procesos no está corriendo, salir del bucle
    if not openocd or not gdbgui:
        print("ERROR: Los procesos necesarios no están corriendo.")
        stop_event.set()
    
    while True:
      # Verificar la conexión a GDB
      output = check_gdb_connection()
      while output is None:
          time.sleep(1)

      output_text = output.decode(errors="ignore")
      if "riscv32-e" not in output_text:
          print(" [ERROR]: Reintentando conexión...")
          if "gdbgui" in process_holder:
              process_holder["gdbgui"].kill()  # Solo matar si existe
              process_holder.pop("gdbgui", None)

          try:
              start_gdbgui_thread(req_data)
              print("Prueba otra vez...")
          except Exception as e:
              logging.error(f"Fallo al crear proceso: {e}")

          time.sleep(5)    
      else:
          print("Conexión establecida con GDB.")
          break  # Sale del bucle si GDB está activo
   



def read_openocd_output(req_data):
    global stop_event
    """Verifica el estado del proceso"""
    global process_holder
    # Verificar si los procesos existen antes de acceder a ellos
    openocd = process_holder.get("openocd")
    gdbgui = process_holder.get("gdbgui")

    # Si cualquiera de los procesos no está corriendo, salir del bucle
    if not openocd:
        print("ERROR: Los procesos necesarios no están corriendo.")
        return None
    #read_gdbgui_state(req_data)
    while not stop_event.is_set():
      # Leer stderr
      error_output = openocd.stderr.readline()
      if error_output:
          if "OpenOCD already running" in error_output:
              pass  # No hacer nada si OpenOCD ya está corriendo
          elif "Please list all processes to check if OpenOCD is already running" in error_output:
              logging.warning("OpenOCD se está ejecutando en otro proceso y no se puede conectar(¿Tiene otro servidor abierto?)")
              openocd.kill()  # Matar proceso openocd
              process_holder.pop("openocd", None)
              if "gdbgui" in process_holder:  # Verificar si gdbgui está en el holder antes de matarlo
                  gdbgui.kill()  # Matar proceso gdbgui
                  process_holder.pop("gdbgui", None)
              stop_event.set()    
              #break  # Salir del bucle si el error es crítico (OpenOCD ya corriendo)
          elif "Please check the wire connection" in error_output:
              logging.error("Por favor revise la conexión de cables")  
              openocd.kill()  # Matar proceso openocd
              process_holder.pop("openocd", None)
              if "gdbgui" in process_holder:  # Verificar si gdbgui está en el holder antes de matarlo
                  gdbgui.kill()  # Matar proceso gdbgui
                  process_holder.pop("gdbgui", None)
              stop_event.set()     
              #break  # Salir del bucle si el error es por un problema de conexión
          else:
              logging.error(f"Salida de error desconocido: {error_output.strip()}")
              openocd.kill()  # Matar proceso openocd
              process_holder.pop("openocd", None)
              if "gdbgui" in process_holder:  # Verificar si gdbgui está en el holder antes de matarlo
                  gdbgui.kill()  # Matar proceso gdbgui
                  process_holder.pop("gdbgui", None)
              stop_event.set()     
              #break  # Salir del bucle si hay un error no reconocido

          
          time.sleep(0.1)  # Pequeño delay para evitar consumo excesivo de CPU



def monitor_gdb_output(req_data, cmd_args, name):
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
        logging.error(f"Error al ejecutar el comando: {e}")
        process_holder.pop(name, None)  # Eliminar la clave de forma segura si existeS
        return None  # Devolver un código de error en caso de fallo

def start_monitoring_thread(req_data):
    try:
        logging.info(process_holder.keys())
        open_thread = threading.Thread(target=read_openocd_output, args = (req_data,), daemon=True)
        open_thread.start()
        while  not open_thread.is_alive():
          time.sleep(1)
        gdb_thread = threading.Thread(target=read_gdbgui_state, args = (req_data,), daemon=True)
        gdb_thread.start()
        return open_thread
    except Exception as e:
        req_data['status'] += f"Error starting Monitor: {str(e)}\n"
        logging.error(f"Error starting Monitor: {str(e)}")
        return None

def start_openocd_thread(req_data):
    try:
        thread = threading.Thread(
            target=monitor_gdb_output,
            args=(req_data, ['idf.py', '-C', BUILD_PATH, 'openocd'], 'openocd'),
            daemon=True
        )
        thread.start()
        logging.info("Starting OpenOCD thread...")
        return thread
    except Exception as e:
        req_data['status'] += f"Error starting OpenOCD: {str(e)}\n"
        logging.error(f"Error starting OpenOCD: {str(e)}")
        return None

    
def start_gdbgui_thread(req_data):
    try:
        route = BUILD_PATH + '/gdbinit'
        threadGBD = threading.Thread(
            target=monitor_gdb_output,
            args=(req_data, ['idf.py', '-C', BUILD_PATH, 'gdbgui', "-x", route], 'gdbgui'),
            daemon=True
        )
        threadGBD.start()
        return threadGBD
    except Exception as e:
        req_data['status'] += f"Error starting GDBGUI: {str(e)}\n"
        logging.error(f"Error starting GDBGUI: {str(e)}")
        return None    

def kill_all_processes(process_name):
    try:
        commands = f"ps aux | grep '[{process_name[0]}]{process_name[1:]}' | awk '{{print $2}}' | xargs kill -9"
        subprocess.run(commands, shell=True, capture_output=False, timeout=120, check=True)
        logging.info(f"Todos los procesos {process_name} han sido eliminados.")
    except subprocess.CalledProcessError as e:
        logging.error(f"Error al intentar matar los procesos {process_name}: {e}")

def do_debug_request(request):
    try:
        req_data = request.get_json()
        target_device = req_data['target_port']
        req_data['status'] = ''
        
        error = check_build()

        if error == 0:
            if 'openocd' in process_holder:
                logging.info('Killing OpenOCD')
                kill_all_processes("openocd")
                process_holder.pop('openocd', None)

            if 'gdbgui' in process_holder:
                logging.info('Killing GDBGUI')
                kill_all_processes("gdbgui")
                process_holder.pop('gdbgui', None)

            openocd_thread = start_openocd_thread(req_data)
            while openocd_thread is None:
                time.sleep(1)
                openocd_thread = start_openocd_thread(req_data)

            gdbgui_thread = start_gdbgui_thread(req_data)
            while gdbgui_thread is None:
                time.sleep(1)
                gdbgui_thread = start_gdbgui_thread(req_data)

            while not ("gdbgui" in process_holder and "openocd" in process_holder):
                time.sleep(1)
            #---restart monitor
            stop_event = threading.Event()
            logging.info('Starting monitor thread...')
            monitor_thread = start_monitoring_thread(req_data)
            if monitor_thread is None:
                req_data['status'] += "Error starting monitor thread\n"
            print("Monitor thread started")

            #do_cmd(req_data, ['idf.py', '-C', BUILD_PATH,'-p', target_device, 'monitor'])  
        else:
            req_data['status'] += "Build error\n"
            
    except Exception as e:
        req_data['status'] += str(e) + '\n'
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
  statusChecker = req_data.get('state')
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

# Adapt assembly file...
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
      data = line.strip().split()
      if (len(data) > 0):
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
        
        elif (data[0] == 'ecall' and BUILD_PATH == './creator'):
          fout.write("#### ecall ####\n")
          fout.write("addi sp, sp, -128\n")
          fout.write("sw x1,  120(sp)\n")
          fout.write("sw x3,  112(sp)\n")
          fout.write("sw x4,  108(sp)\n")
          fout.write("sw x5,  104(sp)\n")
          fout.write("sw x6,  100(sp)\n")
          fout.write("sw x7,  96(sp)\n")
          fout.write("sw x8,  92(sp)\n")
          fout.write("sw x9,  88(sp)\n")
          fout.write("sw x18, 52(sp)\n")
          fout.write("sw x19, 48(sp)\n")
          fout.write("sw x20, 44(sp)\n")
          fout.write("sw x21, 40(sp)\n")
          fout.write("sw x22, 36(sp)\n")
          fout.write("sw x23, 32(sp)\n")
          fout.write("sw x24, 28(sp)\n")
          fout.write("sw x25, 24(sp)\n")
          fout.write("sw x26, 20(sp)\n")
          fout.write("sw x27, 16(sp)\n")
          fout.write("sw x28, 12(sp)\n")
          fout.write("sw x29, 8(sp)\n")
          fout.write("sw x30, 4(sp)\n")
          fout.write("sw x31, 0(sp)\n")

          fout.write("jal _myecall\n")

          fout.write("lw x1,  120(sp)\n")
          fout.write("lw x3,  112(sp)\n")
          fout.write("lw x4,  108(sp)\n")
          fout.write("lw x5,  104(sp)\n")
          fout.write("lw x6,  100(sp)\n")
          fout.write("lw x7,  96(sp)\n")
          fout.write("lw x8,  92(sp)\n")
          fout.write("lw x9,  88(sp)\n")
          fout.write("lw x18, 52(sp)\n")
          fout.write("lw x19, 48(sp)\n")
          fout.write("lw x20, 44(sp)\n")
          fout.write("lw x21, 40(sp)\n")
          fout.write("lw x22, 36(sp)\n")
          fout.write("lw x23, 32(sp)\n")
          fout.write("lw x24, 28(sp)\n")
          fout.write("lw x25, 24(sp)\n")
          fout.write("lw x26, 20(sp)\n")
          fout.write("lw x27, 16(sp)\n")
          fout.write("lw x28, 12(sp)\n")
          fout.write("lw x29, 8(sp)\n")
          fout.write("lw x30, 4(sp)\n")
          fout.write("lw x31, 0(sp)\n")
          fout.write("addi sp, sp, 128\n")
          fout.write("###############\n")
          continue


      fout.write(line)

    # close input + output files
    fin.close()
    fout.close()
    return 0

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

    do_cmd(req_data, ['idf.py', '-C', BUILD_PATH,'-p', target_device, 'monitor']) 

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
    except:
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
    BUILD_PATH = './creator'
    # check arduinoCheck
    error = check_build()

    if 'openocd' in process_holder:
      logging.info('Killing OpenOCD')
      kill_all_processes("openocd")
      process_holder.pop('openocd', None)

    if 'gdbgui' in process_holder:
      logging.info('Killing GDBGUI')
      kill_all_processes("gdbgui")
      process_holder.pop('gdbgui', None)

    # transform th temporal assembly file
    filename= BUILD_PATH + '/main/program.s'
    print("filename to transform in do_flash_request: ", filename)
    error = creator_build('tmp_assembly.s', filename)
    if error != 0:
      req_data['status'] += 'Error adapting assembly file...\n'

    # flashing steps...
    if error == 0 and BUILD_PATH == './creator':
      error = do_cmd_output(req_data, ['idf.py','-C', BUILD_PATH,'fullclean'])
    if error == 0 and BUILD_PATH == './creator':
      error = do_cmd_output(req_data, ['idf.py','-C', BUILD_PATH,'set-target', target_board]) 

    if error == 0:
      error = do_cmd(req_data, ['idf.py','-C', BUILD_PATH,'build'])
    if error == 0:
      error = do_cmd(req_data, ['idf.py','-C', BUILD_PATH, '-p', target_device, 'flash'])

  except Exception as e:
    req_data['status'] += str(e) + '\n'

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
        req_data['status'] += 'Error adapting assembly file...\n'

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

# (3) POST /monitor -> flash
# OJO!!!!!!! Hasta que no se añada el botón de debug, por ahora este es el de debug
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

# (6) POST /fullclean -> clean
@app.route("/fullclean", methods=["POST"])
@cross_origin()
def post_fullclean_flash():
  return do_fullclean_request(request)

# (7) POST /arduinoMode-> cancel
@app.route("/arduinoMode", methods=["POST"])
@cross_origin()
def post_arduino_mode():
  return do_arduino_mode(request)

signal.signal(signal.SIGINT, handle_exit)


# Run
app.run(host='0.0.0.0', port=8080, use_reloader=False, debug=True)