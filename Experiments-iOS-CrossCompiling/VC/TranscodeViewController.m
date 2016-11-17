//
//  TranscodeViewController.m
//  TestFFMpeg
//
//  Created by Apple on 16/6/21.
//  Copyright © 2016年 tuyaohui. All rights reserved.
//

#import "TranscodeViewController.h"
#import "ffmpeg.h"

@interface TranscodeViewController ()

@end

@implementation TranscodeViewController


- (IBAction)transcodeAction:(id)sender {

    NSString *soucePath = [[NSBundle mainBundle]pathForResource:@"small" ofType: @"mp4"];
    NSString *targetPath  = [NSString stringWithFormat:@"%@/Documents/out.avi",NSHomeDirectory()];
    
    NSLog(@"%@",targetPath);
    
    NSString *commond = [NSString stringWithFormat:@"ffmpeg -i %@ -b:v 400k -s 600x600 %@",soucePath,targetPath];
    self.content.text = commond;
    
    NSArray *argv_array = [commond componentsSeparatedByString:@" "];
    int argc = (int)argv_array.count;
    char **argv = malloc(sizeof(char)*1024);
    //把我们写的命令转成c的字符串数组
    for (int i = 0; i < argc; i++) {
        argv[i] = (char *)malloc(sizeof(char)*1024);
        strcpy(argv[i], [[argv_array objectAtIndex:i] UTF8String]);
        
    }
    
    ffmpeg_main(argc, argv);
    
    for(int i=0;i<argc;i++)
        free(argv[i]);
    free(argv);
    
}


@end
