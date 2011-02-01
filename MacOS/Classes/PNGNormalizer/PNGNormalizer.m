#import <Cocoa/Cocoa.h>

#import "crc32.h"
#import "deflate.h"
#import "PNGNormalizer.h"

uint32 nextUint32(uint8 **head) {
	uint8 *h = *head;
	uint32 result = ntohl(*(uint32 *)h);
	*head += 4;
	return result;
}

uint32 peekUint32(uint8 *head) {
	return ntohl(*(uint32 *)head);
}


@implementation PNGNormalizer

+ (NSData *)dataFromPNGData:(NSData *)d {
	uint8 *bytes = (uint8 *)[d bytes];
	uint8 *head = bytes;
	
	if (nextUint32(&head) != PNG_HEAD1 || nextUint32(&head) != PNG_HEAD2)
		return nil;
	
	if (peekUint32(head + 4) != PNG_CgBI) return d; // no conversion needed
	
	uint32 width = 0, height = 0;
	uint8 *inflated = NULL, *deflated = NULL;
	
	NSMutableData *newpng = [[[NSMutableData alloc] initWithCapacity:d.length] autorelease];
	[newpng appendBytes:bytes length:8]; // grab header
	
	size_t len = [d length];

	
	while (head < bytes + len) {
		uint32 chunk_len = nextUint32(&head);
		uint32 chunk_type = nextUint32(&head);
		uint8 *chunk_data = head;
		head += chunk_len;
		uint32 chunk_crc = nextUint32(&head);
		
		if (chunk_type == PNG_CgBI) continue;
		
		if (chunk_type == PNG_IHDR) {
			uint8 *header = chunk_data;
			width = nextUint32(&header);
			height = nextUint32(&header);
			
		} else if (chunk_type == PNG_IDAT) {
			uint32 out_len = width * height * 4 + height;
			
			if (!inflated) inflated = malloc(out_len);
			inflateData(chunk_data, chunk_len, inflated, out_len);
			
			chunk_crc = 0xFFFFFFFF;
			chunk_crc = updateCRC32Uint32(htonl(chunk_type), chunk_crc);
			
			uint32 i = 0;
			for (uint32 y = 0; y < height; y++) {
				i++;
				
				for (uint32 x = 0; x < width; x++) {
					uint32 tmp = inflated[i];
					inflated[i] = inflated[i + 2];
					inflated[i + 2] = tmp;
					i += 4;
				}
			}
			
			if (!deflated) deflated = malloc(out_len);
			chunk_len = deflateData(inflated, out_len, deflated, out_len);
			chunk_data = deflated;
			
			updateCRC32Bytes(chunk_data, chunk_len, chunk_crc);
			chunk_crc = (chunk_crc + 0x100000000) % 0x100000000;
		}
		
	
		uint32 l = htonl(chunk_len);
		[newpng appendBytes:&l length:4];
		l = htonl(chunk_type);
		[newpng appendBytes:&l length:4];
		[newpng appendBytes:chunk_data length:chunk_len];
		l = htonl(chunk_crc);
		[newpng appendBytes:&l length:4];
		
		if (chunk_type == PNG_IEND) break;
	}
	
	free(inflated);
	free(deflated);
	return newpng;
}

+ (NSData *)dataWithContentsOfPNGFile:(NSString *)path {
	NSData *d = [[[NSData alloc] initWithContentsOfFile:path] autorelease];
	return [self dataFromPNGData:d];
}

+ (NSImage *)imageWithContentsOfPNGFile:(NSString *)path {		
	return [[[NSImage alloc] initWithData:[self dataWithContentsOfPNGFile:path]] autorelease];
}

@end
