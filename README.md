基于AFNetworking的https 单/双向验证demo


#运行

双向验证：

需要把客户端p12文件打包到app的bundle里面，同时替换代码中的https url和p12文件的名称以及密码

也可以通过修改源代码自定义p12文件的路径

调用方法：

    - (void)bidirectionalAuthentication;

#更新

新添加单向验证方法

需要将服务端的cer文件引入app，文件路径可自行修改

调用方法：

    - (void)serverAuthentication;
