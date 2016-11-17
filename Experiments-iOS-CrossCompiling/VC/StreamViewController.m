/**
 * 最简单的基于FFmpeg的推流器-IOS
 * Simplest FFmpeg IOS Streamer
 *
 * 雷霄骅 Lei Xiaohua
 * leixiaohua1020@126.com
 * 中国传媒大学/数字电视技术
 * Communication University of China / Digital TV Technology
 * http://blog.csdn.net/leixiaohua1020
 *
 * 本程序是IOS平台下的推流器。它可以将本地文件以流媒体的形式推送出去。
 *
 * This software is the simplest streamer in IOS.
 * It can stream local media files to streaming media server.
 */

#import "StreamViewController.h"
#include <libavformat/avformat.h>
#include <libavutil/mathematics.h>
#include <libavutil/time.h>

@interface StreamViewController ()

@end

@implementation StreamViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}




- (IBAction)clickStreamButton:(id)sender {
    [self startStream];
}

//Input AVFormatContext and Output AVFormatContext
AVFormatContext *inputFormatCtx = NULL, *outputFormatCtx = NULL;
AVOutputFormat *outputFormat = NULL;
int ret, i;

-(void) startStream{
    av_register_all();
    avformat_network_init();
    
    //MARK: Input
    char in_filename[500]={0};
    [self getInputStrName: in_filename ];
    
    [self openInput: in_filename]; //TODO: replace with try catch
    int videoindex =
    [self findVideoStremId:in_filename ];//TODO: replace with try catch
    av_dump_format(inputFormatCtx, 0, in_filename, 0);
    
    
    //MARK: Output
    char out_filename[500]={0};
    [self getOutputStrName: out_filename ];
    
    avformat_alloc_output_context2(&outputFormatCtx, NULL, "flv", out_filename); //RTMP
    //avformat_alloc_output_context2(&ofmt_ctx, NULL, "mpegts", out_filename);//UDP
    if (!outputFormatCtx) { ret = AVERROR_UNKNOWN; [NSException raise: @"Could not create output context\n" format: @""];}
    outputFormat = outputFormatCtx->oformat;
    [self setupOutputStreamsTagsAndFlags];
    av_dump_format(outputFormatCtx, 0, out_filename, 1);
    
    [self openOutputURL:out_filename];
    
    
    
    int frame_index=0;
    AVPacket outputPacket;
    int64_t start_time = av_gettime();
    while (1) {
        //Get an AVPacket
        ret = av_read_frame(inputFormatCtx, &outputPacket);
        if (ret < 0) break;
        
        [self fixNoPTSForPacket     :outputPacket   videoindex:videoindex   frame_index:frame_index];
        [self waitForTimeStamp      :outputPacket   videoindex:videoindex   start_time:start_time];
        [self convertPtsDtsFor      :&outputPacket];
        [self logPacket             :outputPacket   videoindex:videoindex   frame_index:frame_index];
        
        //ret = av_write_frame(ofmt_ctx, &pkt);
        ret = av_interleaved_write_frame(outputFormatCtx, &outputPacket);
        if (ret < 0) { printf( "Error muxing packet\n"); break; }
        av_free_packet(&outputPacket);
        
    }
    //写文件尾（Write file trailer）
    av_write_trailer(outputFormatCtx);
    
    
    [self closeInputsAndOutputs];
}


-(void) getInputStrName     : (char *) in_filename{
    char input_str_full[500]={0};
    
    NSString *input_str= [NSString stringWithFormat:@"resource.bundle/%@",self.input.text];
    NSString *input_nsstr=[[[NSBundle mainBundle]resourcePath] stringByAppendingPathComponent:input_str];
    sprintf(input_str_full,"%s",[input_nsstr UTF8String]);
    
    strcpy(in_filename,input_str_full);
    printf("Input Path:%s\n",in_filename);
}
-(void) openInput           : (char *) in_filename {
    if ((ret = avformat_open_input(&inputFormatCtx, in_filename, 0, 0)) < 0) {
        printf( "Could not open input file.");
        [NSException raise: @"Could not open input file." format: @""];
    }
}
-(int) findVideoStremId     : (char *) in_filename   {
    if ((ret = avformat_find_stream_info(inputFormatCtx, 0)) < 0) {
        printf( "Failed to retrieve input stream information");
        [NSException raise: @"Failed to retrieve input stream information" format: @""];
    }
    int videoindex = -1;
    for(i=0; i<inputFormatCtx->nb_streams; i++)
        if(inputFormatCtx->streams[i]->codec->codec_type==AVMEDIA_TYPE_VIDEO){
            videoindex = i;
            break;
        }
    av_dump_format(inputFormatCtx, 0, in_filename, 0);
    NSLog(@"1 %d",videoindex);
    return videoindex;
}

-(void) getOutputStrName    : (char *) out_filename{
    char output_str_full[500]={0};
    
    sprintf(output_str_full,"%s",[self.output.text UTF8String]);
    
    strcpy(out_filename,output_str_full);
    printf("Output Path:%s\n",out_filename);
}
-(void) setupOutputStreamsTagsAndFlags{
    
    outputFormat = outputFormatCtx->oformat;
    for (i = 0; i < inputFormatCtx->nb_streams; i++) {
        
        AVStream *in_stream = inputFormatCtx->streams[i];
        
        AVStream *out_stream = avformat_new_stream(outputFormatCtx, in_stream->codec->codec);
        if (!out_stream) {
            printf( "Failed allocating output stream\n");
            ret = AVERROR_UNKNOWN;
            [NSException raise: @"Failed allocating output stream\n" format: @""];
        }
        
        ret = avcodec_copy_context(out_stream->codec, in_stream->codec);
        if (ret < 0) {
            printf( "Failed to copy context from input to output stream codec context\n");
            [NSException raise: @"Failed to copy context from input to output stream codec context\n" format: @""];
        }
        
        out_stream->codec->codec_tag = 0;
        if (outputFormatCtx->oformat->flags & AVFMT_GLOBALHEADER)
            out_stream->codec->flags |= CODEC_FLAG_GLOBAL_HEADER;
    }
}
-(void) openOutputURL       : (char *) out_filename  {
    //Open output URL
    if (!(outputFormat->flags & AVFMT_NOFILE)) {
        ret = avio_open(&outputFormatCtx->pb, out_filename, AVIO_FLAG_WRITE);
        if (ret < 0) {
            printf( "Could not open output URL '%s'", out_filename);
            [NSException raise: @"Could not open output URL\n" format: @""];
        }
    }
    
    ret = avformat_write_header(outputFormatCtx, NULL);
    if (ret < 0) {
        printf( "Error occurred when opening output URL\n");
        [NSException raise: @"Error occurred when opening output URL\n" format: @""];
    }
}

-(void) fixNoPTSForPacket   : (AVPacket) outputPacket      videoindex: (int) videoindex     frame_index: (int) frame_index {
    //FIX：No PTS (Example: Raw H.264)
    //Simple Write PTS
    if(outputPacket.pts==AV_NOPTS_VALUE){
        //Write PTS
        AVRational time_base1=inputFormatCtx->streams[videoindex]->time_base;
        //Duration between 2 frames (us)
        int64_t calc_duration=(double)AV_TIME_BASE/av_q2d(inputFormatCtx->streams[videoindex]->r_frame_rate);
        //Parameters
        outputPacket.pts=(double)(frame_index*calc_duration)/(double)(av_q2d(time_base1)*AV_TIME_BASE);
        outputPacket.dts=outputPacket.pts;
        outputPacket.duration=(double)calc_duration/(double)(av_q2d(time_base1)*AV_TIME_BASE);
    }
}
-(void) logPacket           : (AVPacket) outputPacket      videoindex: (int) videoindex     frame_index: (int) frame_index {
    NSString *s = @"";
    for (int i = 0; i < 10; i ++) {
        NSString* myNewString = [NSString stringWithFormat:@" %3d ", outputPacket.data[i]];
        s = [s stringByAppendingString:myNewString];
    }
    NSLog(@"%@",s);
    
    //Print to Screen
    if(outputPacket.stream_index==videoindex){
        printf("Send %8d video frames to output URL\n",frame_index);
        frame_index++;
    }
}
-(void) waitForTimeStamp    : (AVPacket) outputPacket      videoindex: (int) videoindex     start_time: (int64_t) start_time {
    //Important:Delay
    if(outputPacket.stream_index==videoindex){
        AVRational time_base=inputFormatCtx->streams[videoindex]->time_base;
        AVRational time_base_q={1,AV_TIME_BASE};
        int64_t pts_time = av_rescale_q(outputPacket.dts, time_base, time_base_q);
        int64_t now_time = av_gettime() - start_time;
        if (pts_time > now_time)
            av_usleep(pts_time - now_time);
        
    }
}
-(void) convertPtsDtsFor    : (AVPacket *) outputPacket{
    AVStream *in_stream, *out_stream;
    in_stream  = inputFormatCtx->streams[outputPacket->stream_index];
    out_stream = outputFormatCtx->streams[outputPacket->stream_index];
    /* copy packet */
    //Convert PTS/DTS
    outputPacket->pts = av_rescale_q_rnd(outputPacket->pts, in_stream->time_base, out_stream->time_base, (AV_ROUND_NEAR_INF|AV_ROUND_PASS_MINMAX));
    outputPacket->dts = av_rescale_q_rnd(outputPacket->dts, in_stream->time_base, out_stream->time_base, (AV_ROUND_NEAR_INF|AV_ROUND_PASS_MINMAX));
    outputPacket->duration = av_rescale_q(outputPacket->duration, in_stream->time_base, out_stream->time_base);
    outputPacket->pos = -1;
}

-(void) closeInputsAndOutputs{
    avformat_close_input(&inputFormatCtx);
    /* close output */
    if (outputFormatCtx && !(outputFormat->flags & AVFMT_NOFILE))
        avio_close(outputFormatCtx->pb);
    avformat_free_context(outputFormatCtx);
    if (ret < 0 && ret != AVERROR_EOF) {
        printf( "Error occurred.\n");
        return;
    }
    return;
}
@end
