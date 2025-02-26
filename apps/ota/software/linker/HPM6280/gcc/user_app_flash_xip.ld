/*
 * Copyright (c) 2022-2023 HPMicro
 * SPDX-License-Identifier: BSD-3-Clause
 */

ENTRY(_start)

BOOT_USER_OFFSET = 0x43000;

STACK_SIZE = DEFINED(_stack_size) ? _stack_size : 0x4000;
HEAP_SIZE = DEFINED(_heap_size) ? _heap_size : 0x4000;

MEMORY
{
    XPI0 (rx) : ORIGIN = 0x80000000 + BOOT_USER_OFFSET, LENGTH = _flash_size - BOOT_USER_OFFSET
    ILM (wx) : ORIGIN = 0x00000000, LENGTH = 128K
    DLM (w) : ORIGIN = 0x00080000, LENGTH = 128K
    AXI_SRAM_NONCACHEABLE (wx) : ORIGIN = 0x01080000, LENGTH = 128K
    AXI_SRAM  (wx) : ORIGIN = 0x010A0000, LENGTH = 112K
    SHARE_RAM (w) : ORIGIN = 0x010BC000, LENGTH = 16K
    AHB_SRAM (w) : ORIGIN = 0xF0300000, LENGTH = 32k
}

__app_load_addr__ = ORIGIN(XPI0);


SECTIONS
{
    .start __app_load_addr__ : {
        . = ALIGN(8);
        KEEP(*(.app_fw_header))
        KEEP(*(.start))
    } > XPI0

    __vector_load_addr__ = ADDR(.start) + SIZEOF(.start);
    .vectors ORIGIN(ILM) : AT(__vector_load_addr__) {
        . = ALIGN(8);
        __vector_ram_start__ = .;
        KEEP(*(.vector_table))
        KEEP(*(.isr_vector))
        KEEP(*(.vector_s_table))
        KEEP(*(.isr_s_vector))
        . = ALIGN(8);
        __vector_ram_end__ = .;
    } > ILM

    .text (__vector_load_addr__ + SIZEOF(.vectors)) : {
        . = ALIGN(8);
        *(.text)
        *(.text*)
        *(.rodata)
        *(.rodata*)
        *(.srodata)
        *(.srodata*)

        *(.hash)
        *(.dyn*)
        *(.gnu*)
        *(.pl*)

        KEEP(*(.eh_frame))
        *(.eh_frame*)

        KEEP (*(.init))
        KEEP (*(.fini))
        . = ALIGN(8);
    } > XPI0

    .rel : {
        KEEP(*(.rel*))
    } > XPI0

    /* section information for usbh class */
    .usbh_class_info : {
        . = ALIGN(8);
        __usbh_class_info_start__ = .;
        KEEP(*(.usbh_class_info))
        __usbh_class_info_end__ = .;
        . = ALIGN(8);
    } > XPI0

    PROVIDE (__etext = .);
    PROVIDE (_etext = .);
    PROVIDE (etext = .);

    __data_load_addr__ = etext;
    .data : AT(__data_load_addr__) {
        . = ALIGN(8);
        __data_start__ = .;
        __global_pointer$ = . + 0x800;
        *(.data)
        *(.data*)
        *(.sdata)
        *(.sdata*)
        *(.tdata)
        *(.tdata*)

        KEEP(*(.jcr))
        KEEP(*(.dynamic))
        KEEP(*(.got*))
        KEEP(*(.got))
        KEEP(*(.gcc_except_table))
        KEEP(*(.gcc_except_table.*))

        . = ALIGN(8);
        PROVIDE(__preinit_array_start = .);
        KEEP(*(.preinit_array))
        PROVIDE(__preinit_array_end = .);

        . = ALIGN(8);
        PROVIDE(__init_array_start = .);
        KEEP(*(SORT_BY_INIT_PRIORITY(.init_array.*)))
        KEEP(*(.init_array))
        PROVIDE(__init_array_end = .);

        . = ALIGN(8);
        PROVIDE(__finit_array_start = .);
        KEEP(*(SORT_BY_INIT_PRIORITY(.finit_array.*)))
        KEEP(*(.finit_array))
        PROVIDE(__finit_array_end = .);

        . = ALIGN(8);
        KEEP(*crtbegin*.o(.ctors))
        KEEP(*(EXCLUDE_FILE (*crtend*.o) .ctors))
        KEEP(*(SORT(.ctors.*)))
        KEEP(*(.ctors))

        . = ALIGN(8);
        KEEP(*crtbegin*.o(.dtors))
        KEEP(*(EXCLUDE_FILE (*crtend*.o) .dtors))
        KEEP(*(SORT(.dtors.*)))
        KEEP(*(.dtors))
        . = ALIGN(8);
        __data_end__ = .;
        PROVIDE (__edata = .);
        PROVIDE (_edata = .);
        PROVIDE (edata = .);
    } > AXI_SRAM

    __fast_load_addr__ = etext + SIZEOF(.data);
    .fast : AT(__fast_load_addr__) {
        . = ALIGN(8);
        PROVIDE(__ramfunc_start__ = .);
        *(.fast)
        . = ALIGN(8);
        PROVIDE(__ramfunc_end__ = .);
    } > ILM

    .bss (NOLOAD) : {
        . = ALIGN(8);
        __bss_start__ = .;
        *(.bss)
        *(.bss*)
        *(.sbss*)
        *(.scommon)
        *(.scommon*)
        *(.dynsbss*)
        *(COMMON)
        . = ALIGN(8);
        _end = .;
        __bss_end__ = .;
    } > AXI_SRAM

    .tbss (NOLOAD) : {
        . = ALIGN(8);
        PROVIDE(__tbss_start__ = .);
        __thread_pointer$ = .;
        *(.tbss)
        *(.tbss.*)
        *(.gnu.linkonce.tb.*)
        *(.tcommon)
        . = ALIGN(8);
        PROVIDE(__tbss_end__ = .);
    } > AXI_SRAM

    __tdata_load_addr__ = etext + SIZEOF(.data) + SIZEOF(.fast);
    .tdata : AT(__tdata_load_addr__) {
        . = ALIGN(8);
        PROVIDE(__tdata_start__ = .);
        *(.tdata)
        *(.tdata.*)
        *(.gnu.linkonce.td.*)
        . = ALIGN(8);
        PROVIDE(__tdata_end__ = .);
    } > AXI_SRAM

    .framebuffer (NOLOAD) : {
        . = ALIGN(8);
        KEEP(*(.framebuffer))
        . = ALIGN(8);
    } > AXI_SRAM

    __noncacheable_init_load_addr__ = etext + SIZEOF(.data) + SIZEOF(.fast) + SIZEOF(.tdata);
    .noncacheable.init : AT(__noncacheable_init_load_addr__) {
        . = ALIGN(8);
        __noncacheable_init_start__ = .;
        KEEP(*(.noncacheable.init))
        __noncacheable_init_end__ = .;
        . = ALIGN(8);
    } > AXI_SRAM_NONCACHEABLE

    .noncacheable.bss (NOLOAD) : {
        . = ALIGN(8);
        KEEP(*(.noncacheable))
        __noncacheable_bss_start__ = .;
        KEEP(*(.noncacheable.bss))
        __noncacheable_bss_end__ = .;
        . = ALIGN(8);
    } > AXI_SRAM_NONCACHEABLE

    .ahb_sram (NOLOAD) : {
        KEEP(*(.ahb_sram))
    } > AHB_SRAM

    .sh_mem (NOLOAD) : {
        KEEP(*(.sh_mem))
    } > SHARE_RAM

    .fast_ram (NOLOAD) : {
        KEEP(*(.fast_ram))
    } > DLM

    .heap (NOLOAD) : {
        . = ALIGN(8);
        __heap_start__ = .;
        . += HEAP_SIZE;
        __heap_end__ = .;
    } > DLM

    .stack (NOLOAD) : {
        . = ALIGN(8);
        __stack_base__ = .;
        . += STACK_SIZE;
        . = ALIGN(8);
        PROVIDE (_stack = .);
        PROVIDE (_stack_safe = .);
    } > DLM

    __fw_size__ = (etext - __app_load_addr__) + SIZEOF(.data) + SIZEOF(.fast) + SIZEOF(.tdata) + SIZEOF(.noncacheable.init);
    __noncacheable_start__ = ORIGIN(AXI_SRAM_NONCACHEABLE);
    __noncacheable_end__ = ORIGIN(AXI_SRAM_NONCACHEABLE) + LENGTH(AXI_SRAM_NONCACHEABLE);
    __share_mem_start__ = ORIGIN(SHARE_RAM);
    __share_mem_end__ = ORIGIN(SHARE_RAM) + LENGTH(SHARE_RAM);

    ASSERT((STACK_SIZE + HEAP_SIZE) <= 128K, "stack and heap total size larger than 128k")
}
