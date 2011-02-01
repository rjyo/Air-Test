#ifndef DEFLATE__H
#define DEFLATE__H
#include <stdint.h>

void inflateData(uint8_t *data, uint32_t len, uint8_t *out_data, uint32_t out_len);
uint32_t deflateData(uint8_t *data, uint32_t len, uint8_t *out_data, uint32_t out_len);

#endif