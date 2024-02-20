
## 这个目录主要介绍了 tiny-chat 开发过程
01. [tiny-chat-01](./tiny-chat-01) 实现了一个简单的聊天服务器和客户端，使用了简单的 `codec`
02. [tiny-chat-02](./tiny-chat-02) 使用 `protobuf`
03. [tiny-chat-03](./tiny-chat-03) 使用了应用层 heartbeat，解决主机崩溃 或 网络不可达的问题 或 主机崩溃后重启的问题
04. [tiny-chat-04](./tiny-chat-04) 添加了客户端自动重连的功能
05. [tiny-chat-05](./tiny-chat-05) 处理了客户端 或 服务器端可能收到多条消息的情况
06. [tiny-chat-06](./tiny-chat-06) 添加了服务器对客户端发送消息的确认
07. [tiny-chat-07](./tiny-chat-07) 添加了客户端对服务器发送消息的确认

## 问题：
1. 对于客户端主动向服务器发送消息，可能出现客户端认为发送失败，而服务器实际上已经收到消息的情况
2. 对于服务器主动向客户端发送消息，可能出现服务器认为发送失败，而客户端实际上已经接收消息的情况
3. 对于客户端主动向服务器发送消息，可能出现客户端认为发送失败，重新发送消息，而服务器实际上已经收到多条相同消息的情况
4. 对于服务器主动向客户端发送消息，可能出现服务器认为发送失败，重新发送消息，而客户端实际上已经接收多条相同消息的情况 

### 分析：
由于本项目未使用数据库，当客户端断开重连后，服务器无法确定是否属于同一用户的情况，所以未处理该问题

### 解决：
1. 服务器使用数据库，对每一用户设置一个独一无二的编号
2. 客户端使用账号密码登录
3. 服务器和客户端对收到的数据都返回一个确认
4. 对每一条数据内置一个独一无二的编号
5. 当客户端向服务器发送数据时，**在一定时间内**，如果客户端未收到确认信息，则重新发送该消息，尝试多次以后，如果还未收到确认，则放弃，提示发送失败
6. 服务器端接收消息后，如果该消息编号已经接收过，说明消息重复，丢弃它，无论该编号是否接收过，都返回确认消息

### 说明：
1. 上述方法只解决了问题 3，4，未完全解决问题 1，2
2. **可能**  出现客户端认为发送失败，而服务器实际上已经收到消息的情况 或 服务器认为发送失败，而客户端实际上已经收到消息的情况
3. **不可能** 出现客户端认为发送成功，而服务器实际上未收到消息的情况 或 服务器认为发送成功，而客户端实际上未收到消息的情况

## 问题：
如何保证可靠的交易

### 解决方法：
1. 服务器使用数据库，对每一用户设置一个独一无二的编号
2. 客户端使用账号密码登录
3. 服务器和客户端对收到的数据都返回一个确认
4. 对每一条数据内置一个独一无二的编号

客户端：

1. 客户端向服务器发送交易数据
2. 接收服务器的确认，**在一定时间内**，如果未收到确认信息，则重新发送该交易数据，尝试多次以后，如果还未收到确认，则放弃，提示交易失败
3. 向服务器发送确认消息，表明客户端已经知道服务器得到交易数据了，之后客户端认为服务器将处理交易
4. 接收服务器的处理结果，如果该消息编号已经接收过，说明消息重复，丢弃它
5. 向服务器发送确认消息 

服务器：

1. 接收客户端的交易数据，如果该消息编号已经接收过，说明消息重复，丢弃它
2. 返回确认消息，表明服务器已经知道此交易了
3. 接收客户端的确认，**在一定时间内**，如果未收到确认信息，则重新发送确认消息，尝试多次以后，如果还未收到确认，则转到第5步
4. 开始处理交易, 交易可能失败 也 可能成功
5. 最终将交易结果发给客户端
6. 接收客户端的确认，**在一定时间内**，如果未收到确认信息，则重新发送确认消息，尝试多次以后，如果还未收到确认，则采用其它可靠方式例如：短信发送，确保消息到达

### 参考资源
<https://www.zhihu.com/question/25013499>
