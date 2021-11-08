# 单元测试专用 API

Liquid 的特色功能之一是能够直接在合约中编写单元测试用例并在本地执行测试。但是在单元测试的过程中中，除了需要对合约方法的输出、状态变量的内容等进行测试外，有时还需要对区块链的状态进行测试，甚至需要改变区块链状态来观察对合约方法执行流程的影响。为此，Liquid 提供了一组测试专用的 API，使得在本地执行合约单元测试时，能够基于这些 API 获取或改变本地模拟区块链环境中的状态，从而使单元测试的过程更为灵活。

```eval_rst
.. admonition:: 注意

   本节所述的API仅能够在单元测试用例中使用，请不要在合约方法中使用这些API，否则会引发编译错误。
```

## 使用方式

使用单元测试专用 API 之前，首先需要导入位于`liquid_lang:env`模块中的`test`子模块，所有的测试专用 API 的实现均位于`test`子模块中：

```eval_rst
.. code-block:: rust
   :linenos:
   :emphasize-lines: 4


   #[cfg(test)]
   mod tests {
       use super::*;
       use liquid::env::test;

       #[test]
       fn foo() {
           let events = test::get_events();
           ...
       }
       ...
```

## API 列表

<ul class="method-introduction">
<li>

```rust
pub fn set_caller(caller: Address)
```

</li>
<p>

将参数中的账户地址压入合约调用栈的栈顶，通过该 API 可以设置合约的调用者，即能够影响环境访问器的`get_caller`方法的返回值。使用完毕后需要配合`push_execution_context`方法将合约调用者还原。

</p>

<li>

```rust
pub fn pop_execution_context()
```

</li>
<p>

将合约调用栈栈顶的环境信息弹出。

</p>

<li>

```rust
pub fn default_accounts() -> DefaultAccounts
```

</li>
<p>

合约的测试过程中需要经常使用一些虚拟的账户地址，该 API 可以返回一组固定的账户地址常量，从而免去每次手工创建账户地址的麻烦，并使得单元测试用例拥有更好的可读性。返回值中`DefaultAccounts`类型的定义如下：

</p>

<div class="code-example">

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

</div>
<p>

可以通过如下方式使用这些虚拟地址：

</p>
<div class="code-example">

```rust
let accounts = test::default_accounts();
let alice = accounts.alice;
```

</div>

<li>

```rust
pub fn get_events() -> Vec<Event>
```

</li>

<p>

单元测试开始执行后，本地模拟区块链环境中会维护一个事件记录器。每当合约方法触发事件时，事件记录器中便会增加一条事件记录，可以通过该 API 获取这些事件记录以测试合约方法是否触发了正确的事件。返回值中表示事件的`Event`类型的定义是：

</p>

<div class ="code-example">

```rust
pub struct Event {
    pub data: Vec<u8>,
    pub topics: Vec<Hash>,
}
```

</div>
<p>

其中，`data`为经过编码后的事件数据，可以通过调用`Event`类型的`decode_data`方法对数据进行解码，`decode_data`方法的签名为：

</p>
<div class ="code-example">

```rust
pub fn decode_data<R>(&self) -> R
```

</div>
<p>

其中泛型参数`R`是事件定义中各个非索引字段的类型所组成的元组类型，可以使用如下方式调用该方法：

</p>
<div class ="code-example">

```rust
#[liquid(event)]
struct foo {
    x: u128,
    y: bool,
}
...
let event = test::get_events()[0];
let (x, y) = event.decode_data<(u128, bool)>();
```

</div>

<p>

除`data`外，`Event`类型中还包括一个由事件索引组成的数组成员`topics`，每个索引的类型为`Hash`。`Hash`类型内部是一个长度为 32 的字节数组，能够方便与字节数组、字符串互相转换，其提供的方法与[地址类型](../contract/types.html#id2)类似。

</p>
</ul>
