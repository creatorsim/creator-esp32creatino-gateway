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


extern "C" void serial_begin(int baudrate) {
    Serial.begin(baudrate);
}
extern "C" void serial_end() { 
    Serial.end();   
}

extern "C" int serial_flush() {
    esp_err_t err = uart_wait_tx_done((uart_port_t)CONFIG_ESP_CONSOLE_UART_NUM, timeout_ms);
    if (err == ESP_OK) {
        return 0;
    } else {
        ESP_LOGE("UART", "Error al transmitir datos");
        return 1;
    }
}

extern "C" int serial_find(const char *target) {
    uint8_t data[BUFFER_SIZE];
    int total_read = 0;

    int target_len = strlen(target);
    uint32_t start_time = esp_log_timestamp();

    while (esp_log_timestamp() - start_time < timeout_ms) {
        // Leer datos disponibles
        int len = uart_read_bytes((uart_port_t)CONFIG_ESP_CONSOLE_UART_NUM, data + total_read, BUFFER_SIZE - total_read, 10 / portTICK_PERIOD_MS);
        if (len > 0) {
            total_read += len;

            // Buscar la cadena en los datos leídos
            if (total_read >= target_len && strstr((char *)data, target) != NULL) {
                ESP_LOGI(TAG, "Cadena encontrada: %s", target);
                return 0;
            }

            // Mover los datos no procesados al inicio del búfer (para evitar pérdidas)
            if (total_read > target_len) {
                memmove(data, data + total_read - target_len, target_len);
                total_read = target_len;
            }
        }
    }

    ESP_LOGI(TAG, "Cadena no encontrada dentro del tiempo de espera.");
    return -1;
}

extern "C" bool serial_findUntil(const char *target, char terminator)  {
    uint8_t data[BUFFER_SIZE];
    int total_read = 0;

    int target_len = strlen(target);
    uint32_t start_time = esp_log_timestamp();

    while (esp_log_timestamp() - start_time < timeout_ms) {
        // Leer datos disponibles
        int len = uart_read_bytes((uart_port_t)CONFIG_ESP_CONSOLE_UART_NUM, data + total_read, BUFFER_SIZE - total_read, 10 / portTICK_PERIOD_MS);
        if (len > 0) {
            total_read += len;

            // Buscar la cadena en los datos leídos
            if (total_read >= target_len && strstr((char *)data, target) != NULL) {
                //ESP_LOGI(TAG, "Founded: %s", target);
                return 0;
            }
            for (int i = 0; i < len; i++) {
                if (data[total_read - len + i] == terminator) {
                    //ESP_LOGI(TAG, "Termination founded: %c", terminator);
                    return 1;  // Terminador encontrado, salir
                }
            }

            // Mover los datos no procesados al inicio del búfer (para evitar pérdidas)
            if (total_read > target_len) {
                memmove(data, data + total_read - target_len, target_len);
                total_read = target_len;
            }
        }
    }

    //ESP_LOGI(TAG, "Cadena no encontrada dentro del tiempo de espera.");
    return 1;
}
/*extern "C" int serial_availableForWrite() {
    size_t free_size;
    esp_err_t err = uart_get_tx_buffer_free_size((uart_port_t)CONFIG_ESP_CONSOLE_UART_NUM, &free_size);
    if (err == ESP_OK) {
        printf("Hay sitio para escribir: %d bytes\n", (int)free_size);
        return (int)free_size;
    } else {
        ESP_LOGE("UART", "Error al obtener el tamaño del buffer de transmisión libre");
        return 0;
    }
}*/
extern "C" int serial_availableForWrite() {  
    return (int) Serial.availableForWrite();
}
/*extern "C" int serial_available() {
    size_t rx_bytes;
    uart_get_buffered_data_len((uart_port_t)CONFIG_ESP_CONSOLE_UART_NUM, &rx_bytes); 
    return (int)rx_bytes;

}*/
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

/*
extern "C" int aux_serial_print(char *value) { 
    int result = 0;
    Serial.begin(115200);
    result = Serial.print(value);
    return result;
}
*/
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

/*extern "C" int aux_numero(char *str) { 
    // Iterar sobre cada carácter de la cadena
    while (*str != '\0') {
        printf("Caracter: %c, ASCII: %d\n", *str, *str);
        if (!isdigit(*str)) {  // Si no es un dígito
            printf("No es un número\n");
            return 4;
        }
        else{
            printf("Es un número\n");
            str++;
        }
        
    }

    // Si todos los caracteres son dígitos, es un número decimal
    return 1;
}*/

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
extern "C" int serial_readBytesUntil(char character, char *buffer, int length) {
    size_t result = Serial.readBytesUntil(character, buffer, length);
    vTaskDelay(1);
    return (int)result;

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