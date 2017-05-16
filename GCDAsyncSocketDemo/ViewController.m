//
//  ViewController.m
//  GCDAsyncSocketDemo
//
//  Created by Danny on 2017/5/16.
//  Copyright © 2017年 Danny. All rights reserved.
//

#import "ViewController.h"
#import "DDUSocketManager.h"
@interface ViewController ()<UITableViewDataSource,UITableViewDelegate,UITextFieldDelegate,GCDAsyncSocketDelegate>

@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) UITextField *textField;

@property (nonatomic, strong) NSMutableArray *dataSource;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    DDUSocketManager *manager =[DDUSocketManager shareManager];
    manager.managerDelegate = self;
    //建立tcp连接
    manager.socket.userData = @1;
    [manager cutOffSocket];
    //确保断开连接后在连接
    manager.socket.userData = @0;
    [manager socketConnectHost];
    
    //初始化一个tableView 和一个输入框
    
    self.tableView =[[UITableView alloc]initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height - 44) style:UITableViewStylePlain];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.rowHeight = 44;
    self.tableView.tableFooterView =[[UIView alloc]init];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"UITableViewCell"];
    [self.view addSubview:self.tableView];
    
    self.textField =[[UITextField alloc]initWithFrame:CGRectMake(15, [UIScreen mainScreen].bounds.size.height - 44, [UIScreen mainScreen].bounds.size.width - 30, 44)];
    self.textField.backgroundColor =[UIColor cyanColor];
    self.textField.delegate = self;
    
    [self.view addSubview:self.textField];
    
}


-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{

    DDUSocketManager *manager =[DDUSocketManager shareManager];
    NSInteger random = arc4random() + 100;
    NSString *longConnect = [NSString stringWithFormat:@"这是我发送的消息消息 %ld",random];
    NSData *data = [longConnect dataUsingEncoding:NSUTF8StringEncoding];
    [manager.socket writeData:data withTimeout:0 tag:0];

}


#pragma mark - 

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{

    return self.dataSource.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell =[tableView dequeueReusableCellWithIdentifier:@"UITableViewCell"];
    cell.textLabel.text = self.dataSource[indexPath.row];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}


#pragma mark -  return key按下
-(BOOL)textFieldShouldReturn:(UITextField *)textField{
    [self.textField resignFirstResponder];
    
    DDUSocketManager *manager =[DDUSocketManager shareManager];

    NSString *longConnect = [NSString stringWithFormat:@"%@\n",textField.text];
    NSData *data = [longConnect dataUsingEncoding:NSUTF8StringEncoding];
    [manager.socket writeData:data withTimeout:0 tag:0];
    
    [self.dataSource addObject:textField.text];
    [self.tableView reloadData];
    //清空文本框
    self.textField.text = @"";
    
    //滚动到最后一行
    [self scrollToLastPath];
    

    return YES;
}

#pragma mark - socket代理

-(void)socketManagerDidRecieveMessage:(NSString *)message{

    [self.dataSource addObject:message];
    [self.tableView reloadData];
    
    //滚动到最后一行
    [self scrollToLastPath];
}


-(void)scrollToLastPath{
    NSInteger count= self.dataSource.count;
    NSIndexPath *lastPath =[NSIndexPath indexPathForRow:count-1 inSection:0];
    [self.tableView scrollToRowAtIndexPath:lastPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];

}



-(NSMutableArray *)dataSource{
    if (_dataSource == nil) {
        _dataSource =[NSMutableArray array];
    }
    return _dataSource;
}


@end
