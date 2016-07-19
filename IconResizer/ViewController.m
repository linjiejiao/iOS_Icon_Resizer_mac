//
//  ViewController.m
//  IconResizer
//
//  Created by liangjiajian on 16/7/18.
//  Copyright © 2016年 cn.ljj. All rights reserved.
//

#import "ViewController.h"
@interface ViewController()
@property (weak) IBOutlet NSTextField *pathTextField;
@property (strong, nonatomic) NSDictionary *contentsJson;
@property (unsafe_unretained) IBOutlet NSTextView *outputInfoText;

@end

@implementation ViewController
#pragma mark actions
- (IBAction)openBtnClicked:(NSButton *)sender {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSURL *url = [self getFielUrl];
        if(url){
            _pathTextField.stringValue = [url path];
        }else{
            [self addStringInfo:@"No File Selected!"];
        }
    });
}

- (IBAction)resizeBtnClicked:(NSButton *)sender {
    NSString *sourse = _pathTextField.stringValue;
    [self scalesImage:sourse toSizes:self.contentsJson];
}

#pragma mark orride
- (void)viewDidLoad {
    [super viewDidLoad];
    [self parseSezes];
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
}

#pragma mark private methods
-(NSURL *)getFielUrl {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    NSArray* fileTypes = [[NSArray alloc] initWithObjects:@"png", @"jpg", @"bmp", nil];
    [panel setMessage:@"Select A Image"];
    [panel setPrompt:@"OK"];
    [panel setCanChooseDirectories:NO];
    [panel setCanCreateDirectories:NO];
    [panel setCanChooseFiles:YES];
    [panel setAllowsMultipleSelection:NO];
    [panel setAllowedFileTypes:fileTypes];
    // sync call
    NSInteger result = [panel runModal];
    if (result ==NSFileHandlingPanelOKButton) {
        NSArray *selectFileUrls = [panel URLs] ;
        for (int i=0; i<selectFileUrls.count; i++) {
            NSURL *url = [selectFileUrls objectAtIndex:i];
            if(url){
                return url;
            }
        }
    }
    return nil;
}

- (void)scalesImage:(NSString*)imgPath toSizes:(NSDictionary*)dic{
    if(!imgPath || imgPath.length <= 0){
        [self addStringInfo:[NSString stringWithFormat:@"scalesImage failed! imgPath=%@", imgPath]];
        return;
    }
    NSString *outputDir = [imgPath substringToIndex:imgPath.length - 4];
    NSString *fileName = [[outputDir pathComponents] lastObject];
    if(!fileName || fileName.length <= 0){
        fileName = @"untitle";
    }
    BOOL isDir;
    BOOL dirExit = [[NSFileManager defaultManager] fileExistsAtPath:outputDir isDirectory:&isDir];
    if(!dirExit || !isDir){
        NSError *err;
        [[NSFileManager defaultManager] createDirectoryAtPath:outputDir withIntermediateDirectories:YES attributes:nil error:&err];
        if (err) {
            [self addStringInfo:[NSString stringWithFormat:@"scalesImage failed, create dir failed err=%@", err]];
            return;
        }
    }
    NSArray *images = [dic objectForKey:@"images"];
    for(int i=0; i<images.count; i++){
        NSDictionary *image = images[i];
        NSString *newName = [NSString stringWithFormat:@"%@-%d.png", fileName, i];
        [image setValue:newName forKey:@"filename"];
        NSString *output = [NSString stringWithFormat:@"%@/%@",outputDir, newName];
        NSString *sizeString = [image objectForKey:@"size"];
        NSRange rang = [sizeString rangeOfString:@"x"];
        float width = [[sizeString substringToIndex:rang.location] floatValue];
        float height = [[sizeString substringFromIndex:rang.location + rang.length] floatValue];
        NSSize nsSize = NSMakeSize(width, height);
        [self scalesImageAtPath:imgPath outputPath:output outputSize:nsSize];
        [self addStringInfo:output];
    }
    NSString *sontentPath = [NSString stringWithFormat:@"%@/Contents.json", outputDir];
    [dic writeToFile:sontentPath atomically:YES];
    [self addStringInfo:sontentPath];
}

- (BOOL)scalesImageAtPath:(NSString *)sourcePath outputPath:(NSString*)optPath outputSize:(NSSize)optSize {
    NSImage *image = [[NSImage alloc]initWithContentsOfFile:sourcePath];
    [image setSize:optSize];
    NSImage *newImag = [image copy];
    [newImag lockFocus];
    NSBitmapImageRep *bits = [[NSBitmapImageRep alloc]initWithFocusedViewRect:NSMakeRect(0, 0, optSize.width, optSize.height)];
    [newImag unlockFocus];
    NSDictionary *imageProps = [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:1.0] forKey:NSImageCompressionFactor];
    NSData *imageData = [bits representationUsingType:NSPNGFileType properties:imageProps];
    return [imageData writeToFile:optPath atomically:YES];
}

- (void)parseSezes {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"Contents" ofType:@"json"];
    NSData * data = [[NSFileManager defaultManager] contentsAtPath:path];
    NSError *error;
    self.contentsJson = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
}

- (void)addStringInfo:(NSString*)string {
    NSString *origin = self.outputInfoText.string;
    if(!origin){
        origin = string;
    }else{
        origin = [NSString stringWithFormat:@"%@\n%@", string, origin];
    }
    self.outputInfoText.string = origin;
}

@end
