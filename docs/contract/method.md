# 合约方法

合约方法可以用于访问合约的状态变量，并向调用者返回调用结果。在定义了合约状态变量后，我们可以通过为被`#[liquid(storage)]`属性标注的结构体实现成员方法来定义合约方法，其语法如下所示：

```eval_rst
.. code-block:: rust
   :linenos:

   #[liquid(storage)]
   struct Foo {
       ...
   }

   #[liquid(methods)]
   impl Foo {
       ...
   }
```

在上述代码中，状态变量定义位于`Foo`结构体类型中，因此需要通过为`Foo`结构体类型实现成员方法来定义合约方法时，所有合约方法的定义放置于`impl`代码块，请注意`struct`代码块与`impl`代码块中的类型名称必须要一致，同时需要使用`#[liquid(methods)]`属性标注`impl`代码块，以告知 Liquid 该代码块中包含合约方法的定义。

虽然在 Liquid 合约中只能将状态变量的定义集中至一处中，但是合约方法的定义并不存在这个限制，您可以将合约方法的定义分散在多个`impl`代码块中。Liquid 在解析合约时，会自动组合这些分散的`impl`代码块。但是对于简单的合约，我们一般不推荐这样做，这样会使得合约代码看起来较为凌乱。例如，[HelloWorld 合约](../quickstart/example.html#hello-world)也可以写成如下形式：

```eval_rst
.. code-block:: rust
   :linenos:

   #[liquid(storage)]
   struct HelloWorld {
       ...
   }

   #[liquid(methods)]
   impl HelloWorld {
       pub fn new(&mut self) {
           ...
       }
   }

   #[liquid(methods)]
   impl HelloWorld {
       pub fn get(&self) -> String {
           ...
       }
   }

   #[liquid(methods)]
   impl HelloWorld {
       pub fn set(&mut self, name: String) {
           ...
       }
   }
```

```eval_rst
.. admonition:: 注意

   定义合约方法时，请不要在 ``impl`` 关键字前添加 ``default`` 关键字或任何可见性声明。
```

## 方法签名

Liquid 中合约方法的签名由可见性声明、合约方法名、接收器（Receiver）、参数及返回值组成。除此之外，不允许为合约方法添加`const`、`async`、`unsafe`或`extern "C"`等修饰符，也不能使用模板参数或者可变参数。

### 可见性声明

可见性声明只能为`pub`或者为空，当可见性为`pub`时，表示该合约方法是公开方法，可供外部用户或其他合约调用；反之，若可见性声明为空，则表示该合约方法是私有方法，只能在合约内部调用：

```eval_rst
.. code-block:: rust
   :linenos:

   // Public method.
   pub fn plus(&self, x: u8, y: u8) -> u8 {
       self.plus_impl(x, y)
   }

   // Private method.
   fn plus_impl(&self, x: u8, y: u8) -> u8 {
       x + y
   }
```

### 接收器

合约方法的接收器只能为`&self`或`&mut self`。Liquid 在执行合约方法时会自动生成一个合约对象，`&self`即表示该合约对象的只读引用，而`&mut self`则表示该合约对象的可变引用。只有通过接收器才能够访问合约中的状态变量及方法，即只能通过`self.foo`或`self.bar()`之类形式访问合约状态变量或合约方法。

当接收器为`&self`时，表明该合约方法是一个只读方法（类似于 Solidity 语言中的`view`或`pure`修饰符的功能），此时无法在方法中改变任何状态变量的值，也无法调用任何能够改变合约状态的其他方法。调用只读方法时，不会生成交易，即相关操作记录无需区块链节点共识，也不会以交易的形式记录于区块链上；当接收器为`&mut self`时，表明该合约方法是一个可写方法，即能够修改状态变量的值，也能够调用合约中其他任何可写或只读方法。调用可写方法时，区块链节点间会就对应交易进行共识并将相关交易记录于区块链上：

<div class="wrong-example">

```eval_rst
.. code-block:: rust
   :linenos:
   :emphasize-lines: 10

   #[liquid(storage)]
   struct Foo {
       value: storage::Value<u8>,
   }

   #[liquid(methods)]
   impl Foo {
       pub fn read_only(&self) -> u8 {
           // Compile error, can't modify state in an read-only method.
           self.x += 1;
           self.x
       }

       pub fn writable(&mut self) -> u8 {
          // Pass
          self.x += 1;
          self.x
       }
   }
```

</div>

### 参数

Liquid 强制要求合约方法的第一个参数必须为接收器，合约方法要使用到的其他参数需要跟在接收器之后。为在编译期确定合约参数的解码方式，Liquid 限制合约方法的参数（不包括接收器在内）个数不能超过 16 个。与 Solidity，当前 Liquid 只限制合约方法的参数个数不能超过 16 个，但是对局部变量的个数没有限制，未来可能会放宽这一限制。

当前，为兼容 Solidity，只有在 Solidity 中有对应类型的数据类型才能用作公开方法的参数类型（如`u8`、`String`等），未来可能会放宽这一限制，关于类型的更多信息请参考[类型](./types.md)一节。私有方法的参数类型则没有该限制，可以使用包括引用、`Option<T>`及`Result<T, E>`在内的任意数据类型作为私有方法的参数类型。

<div class="wrong-example">

```eval_rst
.. code-block:: rust
   :linenos:
   :emphasize-lines: 2

   // Compile error, for now `Option<u8>` is not supported in public method
   pub fn foo(&self, x: Option<u8>) {
       ...
   }

   // Pass.
   fn bar(&self, y: Option<u8>) {
       ...
   }
```

</div>

### 返回值

当合约方法没有返回值时，可以不写返回值类型或令返回值类型为 unit 类型（即`()`）:

```eval_rst
.. code-block:: rust
   :linenos:

   pub fn foo(&self) {
       ...
   }

   pub fn bar(&self) -> () {
       ...
   }
```

当合约方法有一个返回值时，直接将返回值的类型置于`->`后即可：

```eval_rst
.. code-block:: rust
   :linenos:

   pub fn foo(&self) -> String {
       ...
   }
```

当合约方法有多个返回值时，需要将返回值类型写为元组的形式，元组中每个元素即是一个返回值类型：

```eval_rst
.. code-block:: rust
   :linenos:

   pub fn foo(&self) -> (String, bool, u8) {
       (String::from("hello"), false, 0u8)
   }
```

与参数类型的限制类似，为在编译期确定合约返回值的编码方法，Liquid 限制合约方法的返回值个数不能超过 16 个，未来可能会放宽这一限制。同时，只有在 Solidity 中有对应类型的数据类型才能用作公开方法的返回值类型，私有方法的返回值类型则没有这个限制。

## 构造函数

构造函数是一种特殊的合约方法，用于在部署合约时自动执行，且不能被用户或外部合约调用。Liquid 合约中，构造函数名字必须为`new`，合约中必须有且只有一个构造函数，因此在 Liquid 合约中无法定义同名的其他合约方法。此外，构造函数的可见性必须为`pub`、接收器必须为`&mut self`且不能有返回值，合法的构造函数形式如下列代码所示：

```eval_rst
.. code-block:: rust
   :linenos:

   pub fn new(&mut self, ...) {
       ...
   }
```

**构造函数对于 Liquid 合约极其重要**，因为 Liquid 并不会主动为状态变量分配默认值，因此要求在使用状态变量之前务必先初始化状态变量，否则会引发运行时异常，而构造函数则是最适合用于执行状态变量初始化。尽管也可以在其他合约方法中初始化状态变量，但是并不推荐这样做，因为外部用户或其他合约可能跳过该合约方法的调用，但是构造函数在部署时一定会被执行。因此，请尽量将所有状态变量初始化的工作放置于构造函数中，例如：

```eval_rst
.. code-block:: rust
   :linenos:

   #[liquid(storage)]
   struct Foo {
       b: storage::Vec<bool>,
       i: storage::Value<i32>,
   }

   #[liquid(methods)]
   impl Foo {
       pub fn new(&mut self) {
           self.b.initialize();
           self.i.initialize(0);
       }
   }
```

**不要忘记初始化状态变量。**

请将上面这句话默读三遍，然后喝杯咖啡，接着再读一遍。😛

## 访问器

在[状态变量与容器](./state.md)一节中，我们提到可以将状态变量的可见性声明为`pub`，Liquid 将会自动为该状态变量生成一个访问器以用于外界直接读取该状态变量的值。访问器是一个与状态变量同名的公开方法，假设有状态变量的定义如下：

```eval_rst
.. code-block:: rust
   :linenos:

   #[liquid(storage)]
   struct Foo {
       pub b: storage::Value<bool>,
   }
```

当将状态变量`b`的可见性声明为`pub`时，可以理解为 Liquid 会在合约中自动插入以下代码：

```eval_rst
.. code-block:: rust
   :linenos:

   #[liquid(methods)]
   impl Foo {
       pub fn b(&self) -> bool {
           self.b.get()
       }
   }
```

因此，当指定要为某个状态变量生成访问器时，合约中将不能再定义一个同名的合约方法，否则编译器会报重复定义错误，例如：

<div class="wrong-example">

```eval_rst
.. code-block:: rust
   :linenos:
   :emphasize-lines: 9

   #[liquid(storage)]
   struct Foo {
       pub b: storage::Value<bool>,
   }

   #[liquid(methods)]
   impl Foo {
       // Compile error, attempt to redefine `b`.
       pub fn b(&self) {
           ...
       }
   }
```

不同容器类型所生成访问器并不相同，其区别见下表（表中我们假定状态变量的名字为`foo`）：

| 容器类型                              | 访问器                               |
| :------------------------------------ | :----------------------------------- |
| 单值容器`Value<T>`                    | `pub fn foo(&self) -> T`             |
| 向量容器`Vec<T>`                      | `pub fn foo(&self, index: u32) -> T` |
| 映射容器`Mapping<K, V>`               | `pub fn foo(&self, key: K) -> V`     |
| 可迭代映射容器`IterableMapping<K, V>` | `pub fn foo(&self, key: K) -> V`     |

## 杂注

Liquid 规定合约模块中所有的`impl`代码块都需要被`#[liquid(methods)]`属性标注，即合约模块中的`impl`代码块只能用于定义合约方法。当在合约模块中试图为另外某个类型实现成员或静态方法时将导致编译报错，例如：

```rust
#[liquid::contract(version = "0.1.0")]
mod foo {
    #[liquid(storage)]
    struct Foo {
        bar: String,
    }

    // 合约方法
    impl Foo {
        // ...
    }

    // 另外一个普通结构体的定义
    struct Ace {
        // ...
    }

    // 编译错误，存在多个impl代码块
    impl Ace {
        // ...
    }
}
```

<div class="wrong-example">

```eval_rst
.. code-block:: rust
   :linenos:
   :emphasize-lines: 17-19

   #[liquid::contract]
   mod foo {
       #[liquid(storage)]
       struct Foo {
           ...
       }

       // Pass, definition of contract methods is allowed.
       impl Foo {
           ...
       }

       // The definition of another type.
       struct Ace;

       // Compile error, `impl` blocks in contract should be tagged with `#[liquid(methods)]`.
       impl Ace {
           ...
       }
   }
```

但如果的确有类似的需求，可以将该类型成员或静态方法的实现挪出合约模块的，然后再在合约模块内引用相关符号，例如：

```eval_rst
.. code-block:: rust
   :linenos:

   // The definition of another type.
   struct Ace;

   // Implementations...
   impl Ace {
       ...
   }

   #[liquid::contract]
   mod foo {
       // Reference outer symbols
       use super::Ace;
   }
```
