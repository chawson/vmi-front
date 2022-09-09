# Actix概念
 本文档中加 * 的概念，表示没有实体
## HttpServer
    httpsever 用户创建一个服务实例

```rs
HttpServer::new(|| {})
.bind(("host", "port"))?
.run()
.await
```

## App
    app 用于创建 actix-web程序，作为httpserver的处理程序
    app 是actix-web的核心

## Scope
    scope可以创建一个url前缀的作用域,service可以添加到scope
    scope用于关联一组service
```rs
HttpServer::new(|| {
    App::new()
    .service(hello)
})
.bind(("host", "port"))?
.run
.await
```

## Resource
    resource用于针对一个资源进行处理，一个url就是一个资源
    resource需要通过route关联service (default_service除外)
    Resource实现了ServiceFactory

## Route
    可以根据请求参数指定对资源的处理方法

## Service
    处理资源的方法，方法可以通过注解关联资源(直接的service)
    也可用通过 route.to 指定普通方法。
    service等价于resource[+guard][+route]

## *Handler
    方法

## Guard
    guard trait是策略拦截器, 可用于resource和service

## AppData
    Data是一种包装器用于 service方法间共享全局(或scope范围内的状态)
    提取Data遵循就近原则(scope比全局优先)。
    如果不使用Data包装app_data,则需要在HttpRequest中获取AppData

## ServiceConfig
    ServiceConfig用于轻松实现actix-web的多模块开发
    app全局和scope均可使用configuration注册
    ServiceConfig拥有配置app_data, routes和services的能力

### *Workers多线程
    HttpServer默认是多线程的，默认线程数=逻辑CPU数，
    但是可以通过workers指定线程数。线程间不共享应用程序状态
    并且处理程序可以自由操作它们的状态副本,而无需考虑并发问题
```rs
HttpServer::new(||{}).workers(4)
```
