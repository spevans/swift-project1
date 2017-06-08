#include <stdint.h>


struct hd_partition {
  uint8_t active_flag;
  uint8_t start_head;
  uint16_t start_cylsec;
  uint8_t system;
  uint8_t end_head;
  uint16_t end_cylsec;
  uint32_t LBA_start;
  uint32_t part_len;
} __attribute__((__packed__));

