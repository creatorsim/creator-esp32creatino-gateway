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


extern "C" int __attribute__((aligned(4))) serial_begin(int baudrate) {
    esp_err_t err = uart_set_baudrate((uart_port_t)CONFIG_ESP_CONSOLE_UART_NUM, (uint32_t)baudrate);
    if (err == ESP_OK) {
        return 0;
    } else {
        ESP_LOGE("UART", "Error al inicializar");
        return 1;
    }
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

extern "C" int serial_findUntil(const char *target, char terminator)  {
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
    uint32_t tx_fifo_size = 128;  
    uint32_t tx_fifo_count = UART0.status.txfifo_cnt;  
    uint32_t tx_fifo_free = tx_fifo_size - tx_fifo_count;  
    return (int) tx_fifo_free;
}
extern "C" int serial_available() {
    size_t rx_bytes;
    uart_get_buffered_data_len((uart_port_t)CONFIG_ESP_CONSOLE_UART_NUM, &rx_bytes); 
    return (int)rx_bytes;

}
extern "C" int serial_peek() { 
    int data = Serial.peek();
    return data;  // Devuelve la cantidad de bytes escritos
}
extern "C" int serial_write(const uint8_t *val, int len) { //Obligo al usuario a pasar el elemento y la longitud
    size_t bytes = uart_write_bytes((uart_port_t)CONFIG_ESP_CONSOLE_UART_NUM, val, len);
    return (int)bytes;  // Devuelve la cantidad de bytes escritos
}
extern "C" long aux_map(long value,long fromLow,long fromHigh,long toLow,long toHigh) { 
    long result = map(value, fromLow, fromHigh, toLow, toHigh);
    return result; 
}

extern "C" int aux_constrain(int valueToConstrain, int lowerEnd, int UpperEnd) { 
    int result = constrain(valueToConstrain, lowerEnd, UpperEnd);
    return result;
}

extern "C" int aux_serial_print(char *value) { 
    int result = 0;
    if (Serial.available() > 0) {
        result = Serial.print(value);
    }
    return result;
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

extern "C" int serial_setTimeout(int timeout) {
    size_t rx_bytes;
    esp_err_t err = uart_set_rx_timeout((uart_port_t)CONFIG_ESP_CONSOLE_UART_NUM, (const uint8_t) timeout); 
    if (err == ESP_OK) {
        timeout_ms = timeout;
        return 0;
    } else {
        ESP_LOGE("UART", "Error al poner un timeout");
        return 1;
    }

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