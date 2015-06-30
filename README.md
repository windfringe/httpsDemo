基于AFNetworking的https 单/双向验证demo


#运行

需要把你的客户端p12文件打包到app的bundle里面，同时替换代码中的url和p12文件的名称以及密码才可以运行

你也可以通过修改源代码自定义p12文件的路径

调用方法：

－ (void)bidirectionalAuthentication;

#更新

新添加单向验证方法

需要将服务端的cer文件引入app，文件路径可自行修改

－ (void)serverAuthentication;
