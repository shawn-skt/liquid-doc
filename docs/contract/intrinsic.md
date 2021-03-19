# 环境与内置方法

## 环境

环境能够用于在合约代码中访问某些区块链执行上下文中的信息。以获取合约调用者的账户地址为例，可以通过如下形式在合约方法中借助环境取得该信息：

```eval_rst
.. code-block:: rust
   :linenos:

   self.env().get_caller();
```

其中`self`是执行合约方法时当前合约对象的引用。在构建合约时，Liquid 会自动在合约实现一个名为`env`的私有方法。`env`方法不接受任何参数，但会返回一个环境访问器。获得环境访问器后，便可以通过环境访问器调用所需方法，能且仅能通过环境访问器获取区块链执行上下文信息。目前环境访问器提供了以下方法：

<ul class="method-introduction">
<li>

```rust
pub fn get_caller(self) -> address
```

</li>
<p>

获取合约调用者的账户地址。

</p>
<li>

```rust
pub fn get_tx_origin(self) -> address
```

</li>
<p>

获取整个合约调用链中，最开始发起调用的调用方的账户地址，此时获得的账户地址一定是一个外部账户地址。

</p>
<li>

```rust
pub fn now(self) -> timestamp
```

</li>
<p>

获取当前区块的时间戳，以 13 位时间戳的形式表示。其中`timestamp`为`u64`类型的别名。

</p>
<li>

```rust
pub fn get_address(self) -> address
```

</li>
<p>
获取合约自身的账户地址。
</p>
<li>

```rust
pub fn is_contract(self, account: &address) -> bool
```

</li>

<p>
传入某个账户地址，判断该账户是否为合约账户。
</p>
<li>

```rust
 pub fn emit<E>(self, event: E)
```

</li>
<p>

触发事件，要求模板参数`E`必须为被`#[liquid(event)]`属性标注的结构体类型。

</p>
</ul>

每次调用环境相关的的接口时，都需要消耗一个环境访问器，因此不能通过如下方式复用环境访问器：

<div class="wrong-example">

```eval_rst
.. code-block:: rust
   :linenos:
   :emphasize-lines: 4

   let env_access = &self.env();
   let caller = env_access.get_caller();
   // Compile error, due to that `env_access` had been consumed already.
   env_access.emit(some_event);
```

</div>

正确的方式是每次调用环境相关的接口时都调用`self.env()`创建一个环境访问器对象。环境访问器极为轻量，因此无需担心创建时的性能开销：

```eval_rst
.. code-block:: rust
   :linenos:

   let caller = self.env().get_caller();
   self.env().emit(some_event);
```

## 内置函数

Liquid 提供了一些基本的内置函数。在构建合约时，Liquid 会自动导入这些函数，因此在合约代码中可以直接使用这些函数。内置函数包括：

<ul class="method-introduction">
<li>

```rust
pub fn require<Q>(expr: bool, msg: Q)
where
    Q: AsRef<str>,
```

</li>

<p>

断言函数，用于判断布尔类型的断言表达式`expr`是否成立。若断言成立，则合约代码继续向下执行；若不成立，则直接终止合约代码的运行并引发交易回滚，然后将异常信息`msg`放入交易回执中一并返回至合约的调用方。

</p>
</ul>
