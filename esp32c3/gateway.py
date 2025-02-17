#!/usr/bin/env python3


#
#  Copyright 2022-2024 Felix Garcia Carballeira, Diego Carmarmas Alonso, Alejandro Calderon Mateos
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
import threading

BUILD_PATH = './creator' #By default we call the classics ;)

class GDBExceptionError(Exception):
    """Excepción personalizada para errores de GDB."""
    pass

def monitor_gdb_output(req_data, cmd_args):
    try:
        # Ejecutar el comando idf.py con GDB
        process = subprocess.Popen(
            cmd_args,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )
        
        # Leer la salida y error
        stdout, stderr = process.communicate()

        # Verificar si se ha lanzado un error específico
        if "OpenOCD already running" in stderr: #Ya está corriendo
            print("OpenOCD ya está corriendo.")
            pass
        if "terminate called after throwing an instance of 'gdb_exception_error'" in stderr:
            print("Error: GDB lanzó una excepción.")

        # Aquí podrías hacer más verificaciones o procesar la salida
        if stdout:
            print("stdout: "+ stdout)
        if stderr:
            print("stderr: "+stderr)
        
        # Verificar el código de salida del proceso
        return process.returncode  # Verificar si el proceso terminó correctamente

    except GDBExceptionError as gdb_error:
        print(f"GDB Error: {str(gdb_error)}")
        req_data['status'] += f"GDB Error: {str(gdb_error)}\n"
        return False
    except Exception as e:
        print(f"Error inesperado: {str(e)}")
        req_data['status'] += f"Error: {str(e)}\n"
        return False


# (1) Get form values
def do_get_form(request):
  try:
    return send_file('gateway.html')
  except Exception as e:
    return str(e)

def check_build(file_in):
  try:
    # open input + output files
    fin  = open(file_in, "rt")
    data = []
    # for each line in the input file...
    for line in fin:
      data = line.strip().split()
      if (len(data) > 0):
        global BUILD_PATH
        if (data[0] == '#ARDUINO'):
          print("#### ARDUINO ####\n")
          BUILD_PATH = './creatino'
          print("#### CHANGED PATHS ####\n")  
        continue 
    fin.close()
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

        if (data[0] == 'ecall'):
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



def do_cmd(req_data, cmd_array):
    """
    Execute a command and handle the output.
    """
    try:
        # Execute the command normally
        result = subprocess.run(cmd_array, capture_output=False, timeout=120, check=True)    
    except subprocess.CalledProcessError as e:
        print(e)
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
    # check assembly file to see if it is an Arduino program
    error = check_build('tmp_assembly.s')

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


# (3) Run program into the target board
def do_monitor_request(request):
  try:
    req_data = request.get_json()
    target_device      = req_data['target_port']
    req_data['status'] = ''
    error = check_build('tmp_assembly.s')
    if error == 0:
      #error = do_cmd(req_data, ['idf.py', '-C', BUILD_PATH,'-p', target_device, 'monitor'])
      ###-------------------------------------------
      try:
        thread = threading.Thread(
            target=monitor_gdb_output,
            args=(req_data, ['idf.py', '-C', BUILD_PATH, 'openocd']),
            daemon=True
        )
        thread.start()
        print("Starting thread...")

        # Esperar a que OpenOCD realmente arranque
        time.sleep(2)
        print("Verificando OpenOCD...")
        if thread.is_alive():
            print("OpenOCD está corriendo.")
        else:
            print("Error: OpenOCD no se inició correctamente.")
      except Exception as e:
        print("OpenOCD:"+str(e))
        req_data['status'] += str(e) + '\n'

      time.sleep(5)
      try:
        route = BUILD_PATH + '/gdbinit'
        threadGBD = threading.Thread(
            target=monitor_gdb_output,
            args=(req_data, ['idf.py', '-C', BUILD_PATH, 'gdbgui', '-x', route]),
            daemon=True
        )
        threadGBD.start()
        print("Starting thread...")

        # Esperar a que OpenOCD realmente arranque
        time.sleep(2)
        print("Verificando GDB...")
        if threadGBD.is_alive():
            print("GBD está corriendo.")
        else:
            print("Error: GDB no se inició correctamente.")
      except Exception as e:
        print("GDBGUI:"+str(e))
        req_data['status'] += str(e) + '\n'     
      #if error == 0:
        #error = do_cmd(req_data, ['idf.py', '-C', BUILD_PATH,'-p', target_device, 'monitor'])     

  except Exception as e:
    print(e)

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


# Run
app.run(host='0.0.0.0', port=8080, use_reloader=False, debug=True)