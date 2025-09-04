/*
 * SPDX-FileCopyrightText: 2015-2025 Espressif Systems (Shanghai) CO LTD
 *
 * SPDX-License-Identifier: Apache-2.0
 */

#include "riscv/rvruntime-frames.h"
#include "esp_private/panic_internal.h"
#include "esp_private/panic_reason.h"
#include "hal/wdt_hal.h"
#include "soc/timer_group_struct.h"
#include "soc/timer_group_reg.h"
#include "esp_rom_sys.h"
#include "esp_attr.h" 

void disable_hw_watchdog() {
    // Desactiva el watchdog del Timer Group 1
    TIMERG1.wdtwprotect.val = 0x50D83AA1;
    TIMERG1.wdtconfig0.val = 0;
    TIMERG1.wdtwprotect.val = 0;
}

extern void esp_panic_handler(panic_info_t *info);
volatile bool g_override_ecall = true;

void __real_esp_panic_handler(panic_info_t *info);


void return_from_panic_handler(RvExcFrame *frm) __attribute__((noreturn));

IRAM_ATTR void __wrap_esp_panic_handler(panic_info_t *info)
{
    RvExcFrame *frm = (RvExcFrame *)info->frame;
    if ((frm->mcause == 0x0000000b || frm->mcause == 0x00000008) && g_override_ecall == true) {
        disable_hw_watchdog();
        //printf("ECALL detectado: saltando instrucción\n");
        int cause = frm->a7;
        esp_rom_printf("Causa del panic (a7): %d\n", cause);

        //frm->mepc = frm->ra;
        frm->mepc += 4;
        return_from_panic_handler(frm);
    } else {
        __real_esp_panic_handler(info);
    }
}