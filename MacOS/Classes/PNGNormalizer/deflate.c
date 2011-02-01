#include "deflate.h"
#include "zlib.h"

void inflateData(uint8_t *data, uint32_t len, uint8_t *out_data, uint32_t out_len) {
	z_stream strm;
	strm.next_in = data;
	strm.avail_in = len;
	strm.next_out = out_data;
	strm.avail_out = out_len;
	
	strm.zalloc = Z_NULL;
	strm.zfree = Z_NULL;
	strm.opaque = Z_NULL;
	
	inflateInit2(&strm, -8);
	inflate(&strm, Z_SYNC_FLUSH);
	inflateEnd(&strm);	
}

uint32_t deflateData(uint8_t *data, uint32_t len, uint8_t *out_data, uint32_t out_len) {
	z_stream strm;
	strm.next_in = data;
	strm.avail_in = len;
	strm.next_out = out_data;
	strm.avail_out = out_len;
	
	strm.zalloc = Z_NULL;
	strm.zfree = Z_NULL;
	strm.opaque = Z_NULL;
	
	deflateInit(&strm, Z_DEFAULT_COMPRESSION);
	deflate(&strm, Z_FINISH);
	deflateEnd(&strm);
	return out_len - strm.avail_out;
}
