//
//  DFPushKitManager.h
//  Views
//
//  Created by 250 on 2019/5/13.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DFPushKitManager : NSObject

+ (instancetype)sharedInstance;

- (void)registerPushKit;

- (void)onReceiverPushCall;

- (void)onCancelPushCall;

@end

NS_ASSUME_NONNULL_END
