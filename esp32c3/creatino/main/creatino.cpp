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

extern "C" void ecall_print(int option, void* value) { 
    Serial.begin(115200);

    if (Serial.available()){
        switch (option)
        {
            case 1:
                // print_int
                if (value) Serial.print(*static_cast<int*>(value));
                break;
            
            case 4:
                // print_string
                if (value) Serial.print(static_cast<const char*>(value));
                break;
            
            case 11:
                // print_char
                if (value) Serial.print(*static_cast<char*>(value));
                break;

            case 10:
                // exit
                return;            

            default:
                Serial.println("Opción no válida");
                break;
        }
    }
}

extern "C" void ecall_read(int option, void* value, int size = 0) { 
    Serial.begin(115200);

    if (Serial.available()) {
        switch (option)
        {
            case 5:
                // read int (devuelve el valor leído)
                {
                    int readValue = Serial.parseInt(SKIP_WHITESPACE);
                    if (value) {
                        *static_cast<int*>(value) = readValue;  // Asignar el valor leído a la variable apuntada por 'value'
                    }
                }
                break;

            case 8:
                // read_string  
                {
                    if (size > 0) {
                        char readString[size];
                        Serial.readBytesUntil('\n', readString, size+1);  // Leer hasta salto de línea
                        if (value) {
                            strcpy(static_cast<char*>(value), readString);  // Copiar la cadena leída al puntero 'value'
                        }
                    }
                }   
                break;

            case 12:
                // read_char (lee un solo carácter)
                {
                    char readChar;
                    Serial.readBytesUntil('\n', &readChar, 1);  // Leer un solo carácter
                    if (value) {
                        *static_cast<char*>(value) = readChar;  // Asignar el carácter leído a la variable apuntada por 'value'
                    }
                }
                break;         

            default:
                Serial.println("Opción no válida");
                break;
        }
    }
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
    bool result = Serial.findUntil(target, terminator);
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