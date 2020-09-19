# 合约方法

合约方法可以操作合约的状态变量，并向调用者返回调用结果。在我们定义了合约状态变量后，我们就可以为定义状态变量的结构体添加结构体方法，这些结构体方法便是合约方法。在Liquid中，定义合约的方式是使用`impl`关键字：

```rust
#[liquid(storage)]
struct Foo {
    // ...
}

#[liquid(methods)]
impl Foo {
    // ...
}
```

在上述代码中，您将状态变量定义在了`Foo`结构体中，因此在定义合约方法时，您需要写为`impl Foo { .. }`，请注意两者的名称必须要一致。别忘了为`impl`代码块添加`#[liquid(methods)]`属性，只有这样，Liquid才能知道在这个代码块中有合约方法的定义，进而开始解析。

虽然在Liquid的合约中您只能将状态变量的定义集中至一处结构体中，但是合约方法的定义并不存在这个限制，您可以将合约方法的定义分散在多个`impl`代码块中。Liquid在解析合约时，会自动组合这些分散的`impl`代码块。但是对于简单的合约，我们一般不推荐这样做，这样会使得合约代码看起来较为凌乱。例如，对于[HelloWorld合约](../quick_start/introduction.html#hello-world)，您完全可以写成如下形式：

```rust
#[liquid(storage)]
struct HelloWorld {
    // ...
}

#[liquid(methods)]
impl HelloWorld {
    pub fn new(&mut self) {
        // ...
    }
}

#[liquid(methods)]
impl HelloWorld {
    pub fn get(&self) -> String {
        // ...
    }
}

#[liquid(methods)]
impl HelloWorld {
    pub fn set(&mut self, name: String) {
        // ...
    }
}
```

```eval_rst
.. admonition:: 注意

   定义合约方法时，请不要在``impl``关键字前添加``default``关键字或任何可见性声明。
```

## 方法签名

Liquid中合约方法的签名由可见性声明、合约方法名、Receiver、参数及返回值组成。除此之外，您不能为合约方法添加`const`、`async`、`unsafe`、`extern "C"`等修饰符，也不能使用模板参数或者可变参数。

```eval_rst
.. admonition:: 注意

   在为公开的合约方法计算函数选择器时，Liquid不会将可见性声明、Receiver、返回值计入合约方法的签名中
```

### 可见性声明

可见性声明只能为`pub`或者为空，当可见性为`pub`时，表示该合约方法是公开方法，在构建合约期间，Liquid会为公开方法生成ABI，从而在合约部署至链上后，用户或外部合约可以根据ABI调用公开方法；反之，若没有声明可见性，则表示该合约方式是私有方法，只能在合约内部调用：

```rust
// 公开方法，可被外部调用
pub fn plus(&self, x: u8, y: u8) -> u8 {
    self.plus_impl(x, y)
}

// 私有方法，仅能在内部调用
fn plus_impl(&self, x: u8, y: u8) -> u8 {
    x + y
}
```

### Receiver

Liquid中，Receiver只能为`&self`或`&mut self`。Liquid合约在执行时，会自动生成一个合约对象，`&self`即表示该合约对象的只读引用，而`&mut self`则表示该合约对象的可变引用。通过Receiver，您才能够访问合约中的状态变量及方法，即您需要通过`self.foo`或`self.bar()`的形式访问状态变量或合约方法。

当Receiver为`&self`时，表明该合约方法是一个只读方法（类似于Solidity语言中的`view`或`pure`关键字），您无法在方法中改变任何状态变量，也无法调用任何能够改变合约状态的其他方法。调用只读方法时，不会生成记录于区块链上的交易；当Receiver为`&mut self`时，表明该合约方法是一个可变方法，能够修改状态变量，也能够调用合约中其他任何可变或只读方法。调用可变方法时，区块链底层平台会生成一笔相关的交易信息并记录于区块链上：

```rust
#[liquid(storage)]
struct {
    value: storage::Value<u8>,
}

// 只读方法
pub fn read_only(&self) -> u8 {
    // 编译错误，在只读方法内修改合约状态。
    self.x += 1;
    self.x
}

// 可变方法
pub fn writable(&mut self) -> u8 {
    // 编译通过
    self.x += 1;
    self.x
}
```

### 参数

Liquid强制要求合约方法的第一个参数必须为Receiver，合约方法要使用到的其他外部参数需要跟在Receiver之后。为在编译期确定合约参数的解码方法，Liquid限制了合约方法的参数（不包括Receiver在内）个数不能超过16个（注意，是参数的个数不能超过16个，而不是局部变量个数不能超过16个），未来可能会放宽这一限制。

为兼容Solidity，只有能够映射至Solidity中的数据类型的数据类型才能用作公开方法的参数类型（如`u8`、`String`等），关于哪些类型能够用作公开方法的参数类型，请参考[类型](./types.html)一节。私有方法的参数类型则没有这个限制，您可以使用包括引用、`Option`、`Result`在内的任意数据类型作为私有方法的参数类型。

```rust
// 不是所有数据类型都能够作为公开方法的参数类型
pub fn foo(&self, x: u8) {
    // ...
}

// 私有方法可以使用任意数据类型作为参数类型
fn bar(&self, y: Option<&u8>) {
    // ...
}
```

### 返回值

当合约方法没有返回值时，可以不写返回值类型或令返回值类型为unit（即`()`）:

```rust
pub fn foo(&self) {
    // ...
}

pub fn bar(&self) -> () {
    // ...
}
```

当合约方法有一个返回值时，直接将返回值的类型放置于`->`后即可：

```rust
pub fn foo(&self) -> String {
    // ...
}
```

当合约方法有多个返回值时，需要将返回值类型写为元组的形式，元组中每个元素即是一个返回值：

```rust
pub fn foo(&self) -> (String, bool, u8) {
    // ...
    (String::from("hello"), false, 0u8)
}
```

为在编译期确定合约返回值的编码方法，Liquid限制了合约方法的返回值个数不能超过16个，未来可能会放宽这一限制。同时，只有能够映射至Solidity中的数据类型的数据类型才能用作公开方法的返回值类型，关于哪些类型能够用作公开方法的返回值类型，请参考[类型](./types.html)一节。私有方法的参数类型则没有这个限制。

## 构造函数

构造函数是一种特殊的合约方法，用于在部署合约时自动执行，而不能被用户或外部合约调用。Liquid中，构造函数名字必须为`new`，合约中必须有且只有一个构造函数，因此您无法在Liquid合约中定义同名的其他合约方法。此外，构造函数的可见性必须为`pub`、Receiver必须为`&mut self`且不能有返回值，合法的构造函数形式如下列代码所示：

```rust
pub fn new(&mut self, ...) {
    // ...
}
```

构造函数对于Liquid合约极其重要，因为Liquid并不支持为状态变量分配默认值，因此要求您在使用状态变量之前一定要初始化状态变量，否则会引发panic。而构造函数是最适合执行状态变量初始化的地方，尽管您也可以在其他合约方法中初始化状态变量，但是并不推荐这样做，因为用户可能调用不到您的合约方法，但是构造函数在部署时一定会被执行。因此，请将所有状态变量初始化的工作全部放于构造函数中：

```rust
#[liquid(storage)]
struct Foo {
    b: storage::Vec<bool>,
    i: storage::Value<i32>,
}

impl Foo {
    pub fn new(&mut self) {
        self.b.initialize();
        self.i.initialize(0);
    }
}
```

不要忘记初始化状态变量。请将这句话默读三遍，然后喝杯咖啡，再读一遍。:)

## 访问器

在[状态变量及容器](./state.html)一节中，我们提到，您可以将状态变量的可见性声明为`pub`，Liquid将会自动为该状态变量生成一个访问器用于外界直接读取该状态变量。访问器是一个与状态变量同名的公开方法，您可以理解为，假设有如下状态变量的定义如下：

```rust
#[liquid(storage)]
struct Foo {
    pub b: storage::Value<bool>,
}
```

当将`b`的可见性声明为`pub`时，Liquid会在您的合约中自动插入以下代码：

```rust
#[liquid(methods)]
impl Foo {
    pub fn b(&self) -> bool {
        self.b.get()
    }
}
```

因此，当您指定要为某个状态使用访问器时，您将不能再为合约定义一个同名的合约方法，否则编译器会报重复定义错误：

```rust
#[liquid(storage)]
struct Foo {
    pub b: storage::Value<bool>,
}

// 编译出错
#[liquid(methods)]
impl Foo {
    fn b(&self) ...
}
```

不同容器类型所生成访问器不一样，其区别请参考下表（我们假定状态变量的名字为foo）：

|容器类型|访问器|
|:--|:--|
|基础容器`Value<T>`| `pub fn foo(&self) -> T` |
|序列容器`Vec<T>`| `pub fn foo(&self, index: u32) -> T` |
|映射容器`Mapping<K, V>`| `pub fn foo(&self, key: K) -> V` |
|可迭代映射容器`IterableMapping<K, V>`| `pub fn foo(&self, key: K) -> V` |

## 杂注

在合约模块中，Liquid只允许存在一个`impl`代码块，且只能用于为定义状态变量的结构体添加成员函数（即合约方法）。当您在合约模块内定义了某个另外的结构体并试图为其实现成员函数时，Liquid将会发出编译错误：

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

若您的确有这种需求，可以采用将该结构体的定义及成员函数的实现挪出合约模块，然后在合约模块内引用该结构的定义：

```rust
// 另外一个普通结构体的定义
struct Ace {
    // ...
}

// 编译通过
impl Ace {
    // ...
}

#[liquid::contract(version = "0.1.0")]
mod foo {
    // 引用外部定义
    use super::Ace;

    #[liquid(storage)]
    struct Foo {
        bar: String,
    }

    // 合约方法
    impl Foo {
        // ...
    }
}
```
