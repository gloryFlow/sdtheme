//
//  DFPushKitManager.m
//  Views
//
//  Created by 250 on 2019/5/13.
//

#import "DFPushKitManager.h"
#import <PushKit/PushKit.h>
#import <UserNotifications/UserNotifications.h>
#import "DFBDSpeech.h"

@interface DFPushKitManager () <PKPushRegistryDelegate> {
    UILocalNotification *callNotification;
    UNNotificationRequest *request;//ios 10
}

@property (nonatomic, strong) NSString *token;

@end

@implementation DFPushKitManager

+ (instancetype)sharedInstance {
    
    static DFPushKitManager *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[DFPushKitManager alloc] init];
    });
    
    return _sharedInstance;
}

- (void)registerPushKit {
    PKPushRegistry *pushRegistry = [[PKPushRegistry alloc] initWithQueue:dispatch_get_main_queue()];
    pushRegistry.delegate = self;
    pushRegistry.desiredPushTypes = [NSSet setWithObject:PKPushTypeVoIP];
    //ios10注册本地通知
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 10.0) {
        [self registerUserNotificationCenter];
    }
}

- (void)registerUserNotificationCenter {
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 10.0) {
        //iOS10特有
        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        // 必须写代理，不然无法监听通知的接收与点击
        [center requestAuthorizationWithOptions:(UNAuthorizationOptionAlert | UNAuthorizationOptionBadge | UNAuthorizationOptionSound) completionHandler:^(BOOL granted, NSError * _Nullable error) {
            if (granted) {
                // 点击允许
                DebugLog(@"注册成功");
                [center getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
                    DebugLog(@"%@", settings);
                }];
            } else {
                // 点击不允许
                DebugLog(@"注册失败");
            }
        }];
    }
}

#pragma mark -pushkitDelegate
- (void)pushRegistry:(PKPushRegistry *)registry didUpdatePushCredentials:(PKPushCredentials *)credentials forType:(NSString *)type{
    if([credentials.token length] == 0) {
        NSLog(@"voip token NULL");
        return;
    }
    //应用启动获取token，并上传服务器
    self.token = [[[[credentials.token description] stringByReplacingOccurrencesOfString:@"<"withString:@""]
              stringByReplacingOccurrencesOfString:@">" withString:@""]
             stringByReplacingOccurrencesOfString:@" " withString:@""];
    //token上传服务器
    //[self uploadToken];
    DebugLog(@"token:%@",self.token);
}

- (void)pushRegistry:(PKPushRegistry *)registry didReceiveIncomingPushWithPayload:(PKPushPayload *)payload forType:(NSString *)type{
    BOOL isCalling = false;
    switch ([UIApplication sharedApplication].applicationState) {
        case UIApplicationStateActive: {
            isCalling = false;
        }
            break;
        case UIApplicationStateInactive: {
            isCalling = false;
        }
            break;
        case UIApplicationStateBackground: {
            isCalling = true;
        }
            break;
        default:
            isCalling = true;
            break;
    }
    
    if (isCalling){
        //本地通知，实现响铃效果
        [self onReceiverPushCall];
    }
    
    [[DFBDSpeech sharedInstance] speechSynthesizer:payload.dictionaryPayload completion:^{
        DebugLog(@"播放语音");
    }];
}

#pragma mark - 处理后续操作
/**
 当APP收到呼叫、处于后台时调用、用来处理通知栏类型和铃声。
 */
- (void)onReceiverPushCall:(NSDictionary *)userInfo {
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 10.0) {
        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
        content.body = [NSString localizedUserNotificationStringForKey:@"收到一条消息" arguments:nil];
        UNNotificationSound *customSound = [UNNotificationSound defaultSound];
        content.sound = customSound;
        UNTimeIntervalNotificationTrigger* trigger = [UNTimeIntervalNotificationTrigger
                                                      triggerWithTimeInterval:1 repeats:NO];
        request = [UNNotificationRequest requestWithIdentifier:@"Voip_Push"
                                                       content:content trigger:trigger];
        [center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
            
        }];
    }else {
        
        callNotification = [[UILocalNotification alloc] init];
        callNotification.alertBody = [NSString
                                      stringWithFormat:@"收到一条消息"];
        
        callNotification.soundName = @"default";
        [[UIApplication sharedApplication]
         presentLocalNotificationNow:callNotification];
        
    }
    
}

- (void)onCancelPushCall {
    //取消通知栏
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 10.0) {
        NSMutableArray *arraylist = [[NSMutableArray alloc]init];
        [arraylist addObject:@"Voip_Push"];
        [[UNUserNotificationCenter currentNotificationCenter] removeDeliveredNotificationsWithIdentifiers:arraylist];
    }else {
        [[UIApplication sharedApplication] cancelLocalNotification:callNotification];
    }
    
}

@end
