#import <Foundation/Foundation.h>

#define PNG_HEAD1 0x89504E47
#define PNG_HEAD2 0x0D0A1A0A
#define PNG_IHDR 0x49484452
#define PNG_CgBI 0x43674249
#define PNG_IDAT 0x49444154
#define PNG_IEND 0x49454E44

@interface PNGNormalizer : NSObject {
}

+ (NSData *)dataFromPNGData:(NSData *)d;
+ (NSData *)dataWithContentsOfPNGFile:(NSString *)path;
+ (NSImage *)imageWithContentsOfPNGFile:(NSString *)path;

@end
