---
title: spring_boot_1
date: 2017-10-22 18:58:49
tags:
---

### 介绍最简答的spring-boot使用方式

* 从spring网站下载使用的工程
* 访问地址http://start.spring.io 
* 选择 maven, java 和 spring boot最新的版本
* Group, Artifact 填写你需要的信息
* 点击'Switch to full version'
* 勾选Web web 选项
* 然后点击Generate Porject，这时候浏览器会将生成好的文件，打包下载到本地。



<!-- more -->



将打包下来的文件解压到本地，并使用jave ide工具导入工程.
(本文使用的是idea社区版本, 只需在idea的初始界面，选择open file，选中压缩包里的pom文件即可。 idea会按照工程方式加载此工程)


* 利用终端，进入到程序所在目录， 运行 'mvn clean install -DskipTests', 可用来编译下载的工程

* 在idea中，运行 main方法， 则有一下输出
```
  .   ____          _            __ _ _
 /\\ / ___'_ __ _ _(_)_ __  __ _ \ \ \ \
( ( )\___ | '_ | '_| | '_ \/ _` | \ \ \ \
 \\/  ___)| |_)| | | | | || (_| |  ) ) ) )
  '  |____| .__|_| |_|_| |_\__, | / / / /
 =========|_|==============|___/=/_/_/_/
 :: Spring Boot ::        (v1.5.8.RELEASE)

2017-10-22 19:26:37.923  INFO 9913 --- [           main] c.e.F.FirstspringbootApplication         : Starting FirstspringbootApplication on www.sn.10086.cn with PID 9913 (/Users/eharry/Documents/code/spring.example/FirstspringbootApplication/target/classes started by eharry in /Users/eharry/Documents/code/spring.example/FirstspringbootApplication)
2017-10-22 19:26:37.931  INFO 9913 --- [           main] c.e.F.FirstspringbootApplication         : No active profile set, falling back to default profiles: default
2017-10-22 19:26:38.122  INFO 9913 --- [           main] ationConfigEmbeddedWebApplicationContext : Refreshing org.springframework.boot.context.embedded.AnnotationConfigEmbeddedWebApplicationContext@6cc7b4de: startup date [Sun Oct 22 19:26:38 CST 2017]; root of context hierarchy
2017-10-22 19:26:40.644  INFO 9913 --- [           main] s.b.c.e.t.TomcatEmbeddedServletContainer : Tomcat initialized with port(s): 8080 (http)
2017-10-22 19:26:40.664  INFO 9913 --- [           main] o.apache.catalina.core.StandardService   : Starting service [Tomcat]
2017-10-22 19:26:40.665  INFO 9913 --- [           main] org.apache.catalina.core.StandardEngine  : Starting Servlet Engine: Apache Tomcat/8.5.23
2017-10-22 19:26:40.830  INFO 9913 --- [ost-startStop-1] o.a.c.c.C.[Tomcat].[localhost].[/]       : Initializing Spring embedded WebApplicationContext
2017-10-22 19:26:40.831  INFO 9913 --- [ost-startStop-1] o.s.web.context.ContextLoader            : Root WebApplicationContext: initialization completed in 2718 ms
2017-10-22 19:26:41.018  INFO 9913 --- [ost-startStop-1] o.s.b.w.servlet.ServletRegistrationBean  : Mapping servlet: 'dispatcherServlet' to [/]
2017-10-22 19:26:41.023  INFO 9913 --- [ost-startStop-1] o.s.b.w.servlet.FilterRegistrationBean   : Mapping filter: 'characterEncodingFilter' to: [/*]
2017-10-22 19:26:41.024  INFO 9913 --- [ost-startStop-1] o.s.b.w.servlet.FilterRegistrationBean   : Mapping filter: 'hiddenHttpMethodFilter' to: [/*]
2017-10-22 19:26:41.024  INFO 9913 --- [ost-startStop-1] o.s.b.w.servlet.FilterRegistrationBean   : Mapping filter: 'httpPutFormContentFilter' to: [/*]
2017-10-22 19:26:41.024  INFO 9913 --- [ost-startStop-1] o.s.b.w.servlet.FilterRegistrationBean   : Mapping filter: 'requestContextFilter' to: [/*]
2017-10-22 19:26:41.444  INFO 9913 --- [           main] s.w.s.m.m.a.RequestMappingHandlerAdapter : Looking for @ControllerAdvice: org.springframework.boot.context.embedded.AnnotationConfigEmbeddedWebApplicationContext@6cc7b4de: startup date [Sun Oct 22 19:26:38 CST 2017]; root of context hierarchy
2017-10-22 19:26:41.534  INFO 9913 --- [           main] s.w.s.m.m.a.RequestMappingHandlerMapping : Mapped "{[/error]}" onto public org.springframework.http.ResponseEntity<java.util.Map<java.lang.String, java.lang.Object>> org.springframework.boot.autoconfigure.web.BasicErrorController.error(javax.servlet.http.HttpServletRequest)
2017-10-22 19:26:41.535  INFO 9913 --- [           main] s.w.s.m.m.a.RequestMappingHandlerMapping : Mapped "{[/error],produces=[text/html]}" onto public org.springframework.web.servlet.ModelAndView org.springframework.boot.autoconfigure.web.BasicErrorController.errorHtml(javax.servlet.http.HttpServletRequest,javax.servlet.http.HttpServletResponse)
2017-10-22 19:26:41.579  INFO 9913 --- [           main] o.s.w.s.handler.SimpleUrlHandlerMapping  : Mapped URL path [/webjars/**] onto handler of type [class org.springframework.web.servlet.resource.ResourceHttpRequestHandler]
2017-10-22 19:26:41.579  INFO 9913 --- [           main] o.s.w.s.handler.SimpleUrlHandlerMapping  : Mapped URL path [/**] onto handler of type [class org.springframework.web.servlet.resource.ResourceHttpRequestHandler]
2017-10-22 19:26:41.622  INFO 9913 --- [           main] o.s.w.s.handler.SimpleUrlHandlerMapping  : Mapped URL path [/**/favicon.ico] onto handler of type [class org.springframework.web.servlet.resource.ResourceHttpRequestHandler]
2017-10-22 19:26:41.908  INFO 9913 --- [           main] o.s.j.e.a.AnnotationMBeanExporter        : Registering beans for JMX exposure on startup
2017-10-22 19:26:42.005  INFO 9913 --- [           main] s.b.c.e.t.TomcatEmbeddedServletContainer : Tomcat started on port(s): 8080 (http)
2017-10-22 19:26:42.012  INFO 9913 --- [           main] c.e.F.FirstspringbootApplication         : Started FirstspringbootApplication in 4.842 seconds (JVM running for 5.979)

```

* 在 resource 目录下，新建一个配置application.yml

```bash
server:
  port: 10000
  context-path: /springboot-cuixin
```

* 继续运行程序，可以看到输出log，系统监听的端口号已经修改为10000， 这表示配置文件已经生效了。
```bash
...
2017-10-22 19:35:57.633  INFO 10152 --- [           main] s.b.c.e.t.TomcatEmbeddedServletContainer : Tomcat initialized with port(s): 10000 (http)
2017-10-22 19:35:57.650  INFO 10152 --- [           main] o.apache.catalina.core.StandardService   : Starting service [Tomcat]
2017-10-22 19:35:57.651  INFO 10152 --- [           main] org.apache.catalina.core.StandardEngine  : Starting Servlet Engine: Apache Tomcat/8.5.23
2017-10-22 19:35:57.777  INFO 10152 --- [ost-startStop-1] o.a.c.c.C.[.[.[/springboot-cuixin]       : Initializing Spring embedded WebApplicationContext
...
```

* 写一个controler， 实现最简单的restful协议
* 注意，一定要在application同包路径下创建controler 类，如下所示
```bash
package com.example.FirstspringbootApplication;

import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HelloControler {
    @RequestMapping(value = {"/hi"})
    public String say() {
        return "hi\n";
    }

}

```

* 然后运行application，启动服务
* 在客户端启动脚本，浏览器也可， curl也可，得到如下结果

```bash
www:~ eharry$ curl 127.0.0.1:10000/springboot-cuixin/hi
hi
```


