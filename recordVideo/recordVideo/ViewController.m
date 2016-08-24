//
//  ViewController.m
//  recordVideo
//
//  Created by allen_Chan on 16/7/22.
//  Copyright © 2016年 Mac. All rights reserved.
//

#import "ViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <AVFoundation/AVFoundation.h>
#import <objc/runtime.h>
#import <CoreAudio/CoreAudioTypes.h>


@interface ViewController ()<UIImagePickerControllerDelegate,UINavigationControllerDelegate,AVAudioRecorderDelegate,AVAudioPlayerDelegate>

@property(nonatomic,strong)NSURL *recordedTmpFile;
@property(nonatomic,strong)UIImagePickerController *picker;
@property (nonatomic, strong) AVPlayer *player;
@property (weak, nonatomic) IBOutlet UIButton *playBtn;
@property (nonatomic, strong) AVAudioPlayer *audioPlayer;
@property (nonatomic, strong) AVAudioRecorder *arecorder;
@property (weak, nonatomic) IBOutlet UIImageView *photo;


@end




@implementation ViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    _picker = [[UIImagePickerController alloc]init];
    _picker.delegate = self;
    _picker.videoQuality = UIImagePickerControllerQualityTypeIFrame1280x720;
    _picker.mediaTypes = @[(NSString *)kUTTypeMovie];
    
    
//    self.audioPlayer;
    
}

- (AVAudioRecorder *)arecorder
{
    
    NSLog(@"asd");
    
    if (!_arecorder) {
        //创建录音文件保存路径
        NSURL *url=[self getSavePath];
        //创建录音格式设置
        NSDictionary *setting=[self getAudioSetting];
        //创建录音机
        NSError *error=nil;
        _arecorder=[[AVAudioRecorder alloc]initWithURL:url settings:setting error:&error];
        _arecorder.delegate=self;
        _arecorder.meteringEnabled=YES;//如果要监控声波则必须设置为YES
        if (error) {
            NSLog(@"创建录音机对象时发生错误，错误信息：%@",error.localizedDescription);
        }
        return _arecorder;
    }
    else
        return _arecorder;
}
/**
 *  取得录音文件存储路径
 *
 *  @return 取得录音文件存储路径
 */
-(NSURL *)getSavePath{
    NSString *urlStr=[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    urlStr=[urlStr stringByAppendingPathComponent:@"myRecord.caf"];
    NSLog(@"file path:%@",urlStr);
    NSURL *url=[NSURL fileURLWithPath:urlStr];
    return url;
}

/**
 *  取得录音文件设置
 *
 *  @return 录音设置
 */
-(NSDictionary *)getAudioSetting{
    NSMutableDictionary *dicM=[NSMutableDictionary dictionary];
    //设置录音格式
    [dicM setObject:@(kAudioFormatLinearPCM) forKey:AVFormatIDKey];
    //设置录音采样率，8000是电话采样率，对于一般录音已经够了
    [dicM setObject:@(8000) forKey:AVSampleRateKey];
    //设置通道,这里采用单声道
    [dicM setObject:@(1) forKey:AVNumberOfChannelsKey];
    //每个采样点位数,分为8、16、24、32
    [dicM setObject:@(8) forKey:AVLinearPCMBitDepthKey];
    //是否使用浮点数采样
    [dicM setObject:@(YES) forKey:AVLinearPCMIsFloatKey];
    //....其他设置等
    return dicM;
}

//开始录音
- (IBAction)recordSounds:(UIButton *)sender
{
    if (sender.selected == YES)
    {
        [_arecorder stop];
        _arecorder = nil;
    }
    else
    {
        [self.arecorder record];
    }
    sender.selected = !sender.selected;
    
}

//懒加载
- (AVAudioPlayer *)audioPlayer
{
    if (!_audioPlayer) {
        NSURL *url=[self getSavePath];
        NSError *error=nil;
        _audioPlayer=[[AVAudioPlayer alloc]initWithContentsOfURL:url error:&error];
        [_audioPlayer prepareToPlay];
        [_audioPlayer play];
        _audioPlayer.delegate = self;
        return _audioPlayer;
    }
    else
        return _audioPlayer;
}

//播放录音
-(IBAction)playSounds:(UIButton *)sender
{
    //判断是否正在播放
    if (sender.selected == NO)
    {
        //播放音频
        [self.audioPlayer play];
    }
    else
    {
        //停止播放音频,并销毁播放器
        [self.audioPlayer stop];
        _audioPlayer = nil;
    }
    //改变按钮状态
    sender.selected = !sender.selected;
}
//播放完毕代理方法
-(void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    //销毁播放器
    player = nil;
    //改变按钮状态
    _playBtn.selected = NO;
}


//视频录制
- (IBAction)record:(id)sender
{
    self.picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    self.picker.cameraCaptureMode = UIImagePickerControllerCameraCaptureModeVideo;
    [self presentViewController:self.picker animated:YES completion:nil];
    
}

//读取本地视频
- (IBAction)show:(id)sender
{
    self.picker.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
    [self presentViewController:self.picker animated:YES completion:nil];
}






- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info
{
    
    NSURL *url = [info objectForKey:UIImagePickerControllerMediaURL];
    NSString *urlStr = [url path];
    if (picker.sourceType == UIImagePickerControllerSourceTypeSavedPhotosAlbum)
    {
        [self video:urlStr didFinishSavingWithError:nil contextInfo:nil];
    }
    else
    {
        if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(urlStr)) {
            UISaveVideoAtPathToSavedPhotosAlbum(urlStr, self, @selector(video:didFinishSavingWithError:contextInfo:), nil);
        }
    }
    
    [picker dismissViewControllerAnimated:YES completion:^{
        
    }];
}

-(void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo{
    if (error) {
        NSLog(@"发生错误");
    }else{
        NSURL *url = [NSURL fileURLWithPath:videoPath];
        _player = [AVPlayer playerWithURL:url];
        AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:_player];
        playerLayer.frame = self.photo.bounds;
        [playerLayer setValue:[NSValue valueWithCGRect:self.photo.bounds] forKey:@"_videoRect"];
        playerLayer.repeatCount = -1;
        NSLog(@"%f",self.photo.bounds.size.width);
        [self.photo.layer addSublayer:playerLayer];
        [_player play];
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
