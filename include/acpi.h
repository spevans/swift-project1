/*
 * include/acpi.h
 *
 * Created by Simon Evans on 16/12/2015.
 * Copyright © 2015, 2016 Simon Evans. All rights reserved.
 *
 * Definitions of ACPI headers and tables
 *
 */

#ifndef __ACPI_H__
#define __ACPI_H__

#include <stdint.h>


struct rsdp1_header {
        char signature[8];
        uint8_t checksum;
        char oem_id[6];
        uint8_t revision;
        uint32_t rsdt_addr;
} __attribute__((packed));


struct rsdp2_header {
        struct rsdp1_header rsdp1;
        uint32_t length;
        uint64_t xsdt_addr;
        uint8_t checksum;
        uint8_t reserved[3];
} __attribute__((packed));



// System description table header
struct acpi_sdt_header {
        char signature[4];
        uint32_t length;
        uint8_t revision;
        uint8_t checksum;
        char oem_id[6];
        char oem_table_id[8];
        uint32_t oem_revision;
        char creator_id[4];
        uint32_t creator_rev;
} __attribute__((packed));


// Fixed ACPI description table
struct acpi_facp_table {
        struct acpi_sdt_header header;
        uint32_t firmware_ctrl; // 32bit address
        uint32_t dsdt;          // 32bit address
        uint8_t reserved1;
        uint8_t preferred_pm_profile;
        uint16_t sci_int;
        uint32_t smi_cmd;
        uint8_t acpi_enable;
        uint8_t acpi_disable;
        uint8_t s4bios_req;
        uint8_t pstate_cnt;
        uint32_t pm1a_evt_blk;
        uint32_t pm1b_evt_blk;
        uint32_t pm1a_cnt_blk;
        uint32_t pm1b_cnt_blk;
        uint32_t pm2_cnt_blk;
        uint32_t pm_tml_blk;
        uint32_t gpe0_blk;
        uint32_t gpe1_blk;
        uint8_t pm1_evt_len;
        uint8_t pm1_cnt_len;
        uint8_t pm2_cnt_len;
        uint8_t pm_tmr_len;
        uint8_t gpe0_blk_len;
        uint8_t gpe1_blk_len;
        uint8_t gpe1_base;
        uint8_t cst_cnt;
        uint16_t p_lvl2_lat;
        uint16_t p_lvl3_lat;
        uint16_t flush_size;
        uint16_t flush_stride;
        uint8_t duty_offset;
        uint8_t day_alrm;
        uint8_t mon_alrm;
        uint8_t century;
        uint16_t iapc_boot_arch;
        uint8_t reserved2;
        uint32_t feature_flags;
        uint8_t reset_reg[12];
        uint8_t reset_value;
        uint16_t arm_boot_arch;
        uint8_t fadt_minor_version;
        uint64_t x_firmware_ctrl;
        uint64_t x_dsdt;
        uint8_t x_pm1a_evt_blk[12];
        uint8_t x_pm1b_evt_blk[12];
        uint8_t x_pm1a_cnt_blk[12];
        uint8_t x_pm1b_cnt_blk[12];
        uint8_t x_pm2_cnt_blk[12];
        uint8_t x_pm_tmr_blk[12];
        uint8_t x_gpe0_blk[12];
        uint8_t x_gpe1_blk[12];
        uint8_t sleep_control_reg[12];
        uint8_t sleep_status_reg[12];
        uint8_t hypervisor_vendor_id[8];
} __attribute__((packed));

#endif  // __ACPI_H__
