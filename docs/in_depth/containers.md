# 状态变量及容器

## 状态变量

Liquid中使用结构体的语法封装状态变量定义，以`struct`关键字表示。为向Liquid表明该此结构体中包含了状态变量的定义，您需要在此`struct`上添加`liquid(storage)`属性：

```rust
#[liquid(storage)]
struct HelloWorld {
    name: storage::Value<String>,   // 状态变量
    ...
}
```

在状态变量的定义中，状态变量的名称位于左侧，其后紧跟一个英语冒号及状态变量类型。注意，虽然在设计上状态变量`name`是`String`类型，但是我们没有直接写为`name: String`，而是写为了`name: storage::Value<String>`，其中`storage::Value`是Liquid提供的一种容器模板类型，它用于将我们对状态变量的操作转换为对区块链存储操作。使用容器对定义状态变量至关重要，事实上，若您忘记在状态变量定义中使用容器封装，Liquid将会拒绝编译合约！为了使用容器，您可以在定义状态变量之前先使用下列程序语句引入`liquid_core::storage`模块：

```rust
use liquid_core::storage;
```

```eval_rst
.. admonition:: 注意

   用于定义状态变量的结构体在Liquid合约中能且仅能出现一次，同时，Liquid不允许合约中不存在状态变量的定义。
```

在[HelloWorld合约](../quick_start/introduction.html#hello-world)中，我们能够容器是Liquid合约访问区块链存储的关键桥接者。

## 容器