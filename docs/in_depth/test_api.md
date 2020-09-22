# 测试专用API

Liquid的特色功能之一是能够在合约中编写单元测试。但是在单元测试中，有时除了需要对合约方法的输出、状态变量的值等进行测试，还需要测试区块链的状态，甚至需要改变区块链的状态来观察对合约方法执行逻辑的影响。Liquid提供了一组测试专用的API，使得在本地运行合约的单元测试时，您能够基于这些API获取或改变模拟区块链环境中的状态，从而对合约进行更深入一步的测试。

```eval_rst
.. admonition:: 注意

   本节所述的API仅能够在单元测试中使用，请不要在合约逻辑中使用这些API，否则会引发编译报错。
```

## 使用方式

使用测试专用API前，需要导入位于`liquid_core::env`模块中的`test`模块，所有的测试专用API均位于`test`模块中：

```rust
// 导入`test`模块
use liquid_core::env::test;

#[test]
fn foo() {
    // 在单元测试中使用测试专用API
    let events = test::get_events();
    // ...
}
```

## push_execution_context

- 签名：`push_execution_context(caller: Address)`

- 功能：在合约的调用栈的栈顶压入一个新的合约执行环境，目前执行环境中仅包括当前合约的调用者地址。通过该API可以影响环境模块中`get_caller`接口的返回值。

## pop_execution_context

- 签名：`pop_execution_context()`

- 功能：从合约的调用栈的栈顶弹出一个合约执行环境，需要和`push_execution_context`配合使用

## default_accounts

- 签名：`default_accounts() -> DefaultAccounts`

- 功能：合约的测试过程中需要经常使用一些虚拟的账户地址，本API可以返回一组固定的虚拟地址，从而免去每次手工创建合约地址的麻烦，使得单元测试具有更好的可读性。返回值中`DefaultAccounts`的定义如下：

  ```rust
  pub struct DefaultAccounts {
    pub alice: Address,
    pub bob: Address,
    pub charlie: Address,
    pub david: Address,
    pub eva: Address,
    pub frank: Address,
  }
  ```

  您和可以通过如下方式使用这些虚拟地址：

  ```rust
  let accounts = test::default_accounts();
  let alice = accounts.alice;
  // ...
  ```

## get_events

- 签名：`get_events() -> Vec<Event>`

- 功能：当单元测试开始运行后，本地模拟区块链环境中会维护一个事件记录器，每当合约方法触发事件时，事件记录器中会增加一条事件记录，您可以获取这些事件记录以测试您的合约方法是否触发了正确的事件。返回值中表示事件的`Event`的定义是：

  ```rust
  pub struct Event {
    pub data: Vec<u8>,
    pub topics: Vec<Hash>,
  }
  ```

  其中，`data`为事件中经过编码后的数据，您可以调用`Event`的`decode_data`接口对数据进行解码，其签名为：

  ```rust
  decode_data<R>(&self) -> R
  ```

  其中泛型参数`R`是事件定义中各个非索引的字段的类型所组成的元组类型，您可以使用如下的方式调用该接口：

  ```rust
  #[liquid(event)]
  struct foo {
      x: u128,
      y: bool,
  }

  // ...

  let event = test::get_events()[0];
  let (x, y) = event.decode_data<(u128, bool)>();
  // ...
  ```

  除`data`外，`Event`中还包括一个由事件索引组成的数组`topics`。每个索引的类型为`Hash`，其内部是一个长度为32的字节数组。`Hash`类型能够方便与字节数组、字符串互相转换，其接口与[`Address`类型](./types.html#Address)类似。