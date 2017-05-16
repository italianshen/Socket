//
//  DDUSocketManager.m
//  GCDAsyncSocketDemo
//
//  Created by Danny on 2017/5/16.
//  Copyright © 2017年 Danny. All rights reserved.
//

#import "DDUSocketManager.h"
@interface DDUSocketManager(){
    int       socketID;
    int       MaxConnectedCount;
    int       Connected;
    int       Port;
    int       ClientCount;
    NSString *HostName;
}

@end
@implementation DDUSocketManager

//单例方法
static DDUSocketManager *instance = nil;
+(DDUSocketManager *)shareManager{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

//socket连接
-(void)socketConnectHost{
    self.socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    NSError *err = nil;
    NSString *hostName = @"127.0.0.1";

    UInt16 port = 12345;
    if ([self.socket connectToHost:hostName onPort:port error:&err]) {
        NSLog(@"连接成功");
    }else{
       NSLog(@"连接失败");
    }
    
  //读取
    [_socket readDataWithTimeout:-1 tag:0];
}


//socket执行SSL验证方法
//SSL不通过证书验证
- (void)startWithTLS
{
    NSMutableDictionary *settings = [[NSMutableDictionary alloc] init];
    
    [settings setObject:[NSNumber numberWithBool:YES]
                 forKey:GCDAsyncSocketManuallyEvaluateTrust];
    [_socket startTLS:settings];
}


//断开socket连接
-(void)cutOffSocket{
    self.socket.userData = @1;// 声明是由用户主动切断
    [self.socket disconnect];
}


#pragma mark -  GCDAsyncSocketDelegate
-(void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port{

    _isKilled=NO;
    //    NSLog(@"这是异步返回的连接成功");
    //发送校验实体给服务器端
//    [self performSelector:@selector(certificationSocket) withObject:self afterDelay:1];//发送检验实体给服务器端
    [sock readDataWithTimeout:-1 tag:0];
    //通过定时器不断的发送消息，来检测长连接
    //开启心跳包
    NSTimer *timer=[NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(checkLongConnectByServe) userInfo:nil repeats:NO];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];

}

-(void)socket:(GCDAsyncSocket *)sock didReceiveTrust:(SecTrustRef)trust completionHandler:(void (^)(BOOL))completionHandler{

  //收到信任
    NSLog(@"didReceiveTrust");
    
    //server certificate
    SecCertificateRef serverCertificate = SecTrustGetCertificateAtIndex(trust, 0);
    CFDataRef serverCertificateData = SecCertificateCopyData(serverCertificate);
    
    const UInt8* const serverData = CFDataGetBytePtr(serverCertificateData);
    const CFIndex serverDataSize = CFDataGetLength(serverCertificateData);
    NSData* cert1 = [NSData dataWithBytes:serverData length:(NSUInteger)serverDataSize];
    
    
    //local certificate
    NSString *localCertFilePath = [[NSBundle mainBundle] pathForResource:@"sso" ofType:@"p12"];
    NSData *localCertData = [NSData dataWithContentsOfFile:localCertFilePath];
    CFDataRef myCertData = (__bridge CFDataRef)localCertData;
    
    
    const UInt8* const localData = CFDataGetBytePtr(myCertData);
    const CFIndex localDataSize = CFDataGetLength(myCertData);
    NSData* cert2 = [NSData dataWithBytes:localData length:(NSUInteger)localDataSize];
    if (cert1 == nil || cert2 == nil) {
        NSLog(@"Certificate NULL");
        completionHandler(NO);
        return;
    }
    
    
    BOOL equal = [cert1 isEqualToData:cert2];

    NSLog(@"equal ===>%d",equal);
    completionHandler(YES);

}

-(void)socketDidSecure:(GCDAsyncSocket *)sock {
    NSLog(@"socketDidSecure");
}


//当一个socket已经把数据读入内存中时被调用。如果发生错误则不被调用
-(void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    
    NSDictionary *result = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
    NSLog(@"====>socketResult:%@",result);
    //有可能是字符串
    NSString *message =[[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"message ===>%@",message);
    
    if ([self.managerDelegate respondsToSelector:@selector(socketManagerDidRecieveMessage:)]) {
        [self.managerDelegate socketManagerDidRecieveMessage:message];
    }
    
    if (result.allKeys.count > 3)
    {
        NSLog(@"socketResult:%@",result);
    }
    [sock readDataWithTimeout:-1 tag:0];
}


//发生错误 socket将要断开连接
-(void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
    NSLog(@"onSocket:%p willDisconnectWithError:%@", sock, err);
    
    //    NSLog(@"socket断开连接 %ld",sock.userData);
    if (sock.userData == GCDSocketOfflineByServer &&!_isKilled) {
        // 服务器掉线，重连
        [self socketConnectHost];
    }

}




-(void)checkLongConnectByServe{
    //向服务器发送固定的消息，来检测长连接
    NSString *longConnect = @"connect is here";
    NSLog(@"\n");
    NSData *data = [longConnect dataUsingEncoding:NSUTF8StringEncoding];
    [self.socket writeData:data withTimeout:0 tag:0];
}



@end
