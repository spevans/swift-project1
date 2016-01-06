#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <stdint.h>
#include <fcntl.h>
extern ssize_t read (int __fd, void *__buf, size_t __nbytes) __wur;

typedef struct stat stat_info ;
int stat(const char *pathname, struct stat *buf);

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

