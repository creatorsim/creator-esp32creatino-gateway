#include <stdio.h>
#include <string.h>
#include "sdkconfig.h"
#include "driver/uart.h"
#include "soc/uart_reg.h"
#include "soc/uart_struct.h"
#include <esp_log.h>
#include <esp_timer.h>
#include "io_pin_remap.h"

#define BUFFER_SIZE 1024
#define TAG "SERIAL"

// Configuration header file (e.g., config.h)
#define CONFIG_LOG_MAXIMUM_LEVEL 3 // Example value
#define CONFIG_FREERTOS_HZ 1000 // Example FreeRTOS tick rate
uint32_t timeout_ms = portMAX_DELAY; //By default wait forever
// Define the timeout in milliseconds

//ecall imprimir numeros
extern "C" void ecall_print_int(int option, int value) {
    if (!Serial) {  // Verifica si Serial ya está inicializado
        Serial.begin(115200);
    } 
    Serial.print(value);  // Imprime el valor como número
    vTaskDelay(1);  
}    
            

// ecall de imprimir + exit
extern "C" void ecall_print(int option, void* value) {
    if (!Serial) {  // Verifica si Serial ya está inicializado
        Serial.begin(115200);
    } 
    if (value == nullptr) {  // Verifica si el puntero es nulo
        Serial.println("Error: Puntero nulo.");
        vTaskDelay(1);
        return;
    }

    switch (option) {        
        case 4:
            // print_string
            if (value == nullptr) { 
                Serial.print("Error: Puntero nulo.");
            } else {
                //Serial.println("Es un char!!!");
                Serial.print(static_cast<const char*>(value));
            }
            vTaskDelay(1);
            break;
        
        case 11:
            // print_char
            Serial.print(*static_cast<char*>(value));
            vTaskDelay(1);
            break;

        case 10:
            // exit
            break;            

        default:
            Serial.print("Opción no válida");
            vTaskDelay(1);
            break;
    }
}


// read_int en ecall
extern "C" int ecall_read_int() { 
    if (!Serial) {  // Verifica si Serial ya está inicializado
        Serial.begin(115200);
    }
    char buffer[12];  // Buffer para almacenar los datos
    int bytesRead = 0;
    while (bytesRead < 11) { // Deja espacio para el carácter nulo
        if (Serial.available() > 0) {
            int value = Serial.read(); // Lee un entero
            if (isdigit(value)) {      // Verifica si es un dígito
                buffer[bytesRead] = value;  // Almacena el carácter en el buffer
                Serial.print((char)value); //eco
                bytesRead++;            // Incrementa el número de bytes leídos
            }
            else if (value == '-'){
                buffer[bytesRead++] = value;
                Serial.print(value);
            }
            else if (value == '\n' || value == '\r') {
                buffer[bytesRead] = '\0'; // Termina la cadena
                //Serial.print("\nValue read: ");
                //Serial.println(atoi(buffer));
                return atoi(buffer);
                break;
            }
            vTaskDelay(1);
        }
        vTaskDelay(1); // Pequeño retraso para liberar la CPU
        
    }
    return -1;  // Retorna un valor de error si no hay datos
    
}

// ecall cuando tiene que leer caracteres o cadenas
extern "C" char* ecall_read(int option, char *buffer, int size) {
    if (!Serial) {  // Verifica si Serial ya está inicializado
        Serial.begin(115200);
    }
    //char buffer[size+1];  // Buffer para almacenar los datos
    int bytesRead = 0;
    size++; // Deja espacio para el carácter nulo

    switch (option) {
        case 8: // read_string 
            //Serial.print(bytesRead);
            //Serial.printf("Espacio: %d bytes",size);       
            while (bytesRead < size) { 
                if (Serial.available() > 0) {
                    char c = Serial.read(); // Lee un byte
                    vTaskDelay(1); // Pequeño retraso para liberar la CPU
                    if (c != 0){
                        buffer[bytesRead++] = c; // Almacena el byte                   
                        Serial.print(c); // Eco rápido
                    }
                    // Termina si se detecta un salto de línea
                    if (c == '\n' || c == '\r') {
                        break;
                    }
                }
            }
            buffer[bytesRead] = '\0'; // Termina la cadena
            return buffer;    

        case 12: // read_char (lee un solo carácter)
            //char buffer[2];
            while (bytesRead < 1) { // Deja espacio para el carácter nulo
                if (Serial.available() > 0) {
                    char c = Serial.read(); // Lee un byte
                    if (c != 0){
                        buffer[bytesRead++] = c; // Almacena el byte                   
                        Serial.print(c); // Eco rápido
                        break;
                    }
                    vTaskDelay(1); // Pequeño retraso para liberar la CPU
                }
            }              
            buffer[1] = '\0';  // Convertirlo en cadena válida
            return buffer;
            

        default:
            Serial.println("Opción no válida");
            vTaskDelay(1);
            return nullptr;
    }

    return nullptr; // Retorno seguro en caso de error
}


extern "C" void serial_begin(int baudrate) {
    Serial.begin(baudrate);
}
extern "C" void serial_end() { 
    Serial.end();   
}

extern "C" void serial_flush() {
    Serial.flush();
}

extern "C" bool serial_find(const char *target) {
    bool result = Serial.find(target);
    vTaskDelay(1);
    return result;
}

extern "C" bool serial_findUntil(const char *target, const char *terminator)  {
    static char buffer[1024]; 
    int len = Serial.readBytesUntil(*terminator, buffer, sizeof(buffer) - 1);
    buffer[len] = '\0'; 

    bool result = (strstr(buffer, target) != nullptr);
    vTaskDelay(1);
    return result;
}

extern "C" int serial_availableForWrite() {  
    return (int) Serial.availableForWrite();
}

extern "C" int serial_available() {
    int result = Serial.available();
    return result;

}
extern "C" int serial_peek() { 
    int data = Serial.peek();
    return data;  // Devuelve la cantidad de bytes escritos
}
extern "C" int serial_write(const uint8_t *val, int len) { //Obligo al usuario a pasar el elemento y la longitud
    int result = Serial.write(val, len);
    return result;  // Devuelve la cantidad de bytes escritos
}
extern "C" long aux_map(long value,long fromLow,long fromHigh,long toLow,long toHigh) { 
    long result = map(value, fromLow, fromHigh, toLow, toHigh);
    return result; 
}

extern "C" int aux_constrain(int valueToConstrain, int lowerEnd, int UpperEnd) { 
    int result = constrain(valueToConstrain, lowerEnd, UpperEnd);
    return result;
}

extern "C" int aux_serial_printf(const char *format, ...) { 
    //printf(format);
    char buffer[128];  // Buffer para almacenar la cadena formateada
    va_list args;
    va_start(args, format);
    vsnprintf(buffer, sizeof(buffer), format, args);  // Formatear texto
    va_end(args);
    //printf(buffer);  // Enviar el mensaje formateado a Serial
    size_t result = Serial.print(buffer);

    return result ;  // Enviar el mensaje formateado a Serial
}


extern "C" void aux_printchar(void *value) { 
    Serial.begin(115200);
    Serial.print((char*)value);
}

extern "C" void serial_setTimeout(int timeout) {
    Serial.setTimeout(timeout);

}
extern "C" int serial_read() {
    size_t result = Serial.read();
    vTaskDelay(1);
    return (int)result;

}
extern "C" int serial_readBytes(char *buffer, int length) {
    size_t result = Serial.readBytes(buffer, length);
    vTaskDelay(1);
    return (int)result;

}
extern "C" long serial_parseInt(LookaheadMode lookahead = LookaheadMode::SKIP_ALL, char ignore = '\0') {
    long result = Serial.parseInt(lookahead, ignore);
    vTaskDelay(1);
    return result;
}

extern "C" int serial_readBytesUntil(char character, char *buffer, int length) {
    size_t result = Serial.readBytesUntil(character, buffer, length);
    vTaskDelay(1);
    return (int)result;

}
extern "C" const char* serial_readString() {
    static char input[100];  // Buffer estático
    int len = Serial.readBytes(input, sizeof(input) - 1);  // Lee los datos disponibles
    if (len < 0) {
        // Error en la lectura
        return "";
    }
    input[len] = '\0';  // Asegúrate de que la cadena termine con '\0'
    printf("Recibido: %s\n", input);
    vTaskDelay(3);
    return input;
}

extern "C" int cr_micros() {
    return (int)esp_timer_get_time();
}
extern "C" int cr_millis() {
    return (int)esp_timer_get_time()/ 1000ULL;
}
extern "C" int cr_digitalPinToGPIONumber(int pin) {
    return (int)digitalPinToGPIONumber((int8_t)pin);
}