//
//  DDUSocketManager.h
//  GCDAsyncSocketDemo
//
//  Created by Danny on 2017/5/16.
//  Copyright © 2017年 Danny. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GCDAsyncSocket.h"

enum{
    GCDSocketOfflineByServer,// 服务器掉线，默认为0
    GCDSocketOfflineByUser,  // 用户主动cut
};


@protocol DDUSocketManagerDelegate <NSObject>

-(void)socketManagerDidRecieveMessage:(NSString *)message;

@end



@interface DDUSocketManager : NSObject<GCDAsyncSocketDelegate>

@property (nonatomic, strong) GCDAsyncSocket *socket;//socket

//单例方法
+(DDUSocketManager *)shareManager;

//socket连接
-(void)socketConnectHost;

//断开socket连接
-(void)cutOffSocket;

//账号在其它地方登陆
@property (nonatomic, assign) BOOL isKilled;


@property (nonatomic, weak) id<DDUSocketManagerDelegate> managerDelegate;



@end
