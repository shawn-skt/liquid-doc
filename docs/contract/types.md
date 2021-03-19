# 类型

由于 Liquid 以 Rust 语言为宿主语言，因此合约中能够使用 Rust 语言支持的[所有数据类型](https://doc.rust-lang.org/book/ch03-02-data-types.html)。为方便合约编写，Liquid 也提供了一系列内置数据类型。此外，出于各种设计考虑（如兼容 Solidity、简化类型检查流程等），在[状态变量](./state.md)、[合约方法](./method.md)及[事件](./event.md)的定义中能够使用的数据类型会受到一定限制。本节将会对这些知识要点进行逐一介绍。

## 地址类型

地址类型（`address`）专用于表示账户地址，其内部实现是一个长度为 20 的字节数组。构建合约时，Liquid 会自动导入`address`类型的定义，从而能够像使用一个 Rust 语言基本类型一样使用`address`类型。`address`类型提供以下方法：

<ul class="method-introduction">
<li>

```rust
pub const fn new(addr: [u8; 20]) -> Self
```

</li>
<p>

基于一个长度为 20 的字节数组构造`address`类型对象，注意该方法为常量方法（`const fn`）。

</p>
<li>

```rust
pub const fn empty() -> Self
```

</li>
<p>
构造一个内容为空的`address`类型的对象，注意该方法同样也为常量方法。
</p>
</ul>

同时，`address`类型还实现了以下 trait：

<ul class="method-introduction">
<li>

```rust
impl Default for Address {
    fn default() -> Self;
}
```

</li>
<p>

构造一个内容为空的`address`类型的对象，与`address::empty()`的功能相同。

</p>
<li>

```rust
impl fmt::Display for Address {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result;
}
```

</li>
<p>

将`address`类型对象转换为可读的格式化 16 进制字符串。同时根据[`ToString`](https://doc.rust-lang.org/stable/alloc/string/trait.ToString.html)trait 的[定义]，所有实现了`Display` trait 的类型将会自动实现`ToString` trait，因此可以在代码中使用如下方式`address`类型对象转换为字符串：

</p>
<div class="code-example">

```rust
let addr = ...;
let addr_str = addr.to_string();
```

</div>

<li>

```rust
impl FromStr for Address {
    fn from_str(mut s: &str) -> Result<Self, Self::Err>;
}
```

</li>
<p>

将一个 16 进制表示的字符串转换为`address`类型对象，字符串可以`0x`或`0X`开头，也可不带任何前缀。当字符串带前缀时，要求字符串长度为 42；不带前缀时则要求长度为 40，若长度不足则会自动在左端补零。若字符串不能表示一个合法的账户地址（如长度超长或包含非法字符），则执行转换时会引发运行时异常。由于[`str`](https://doc.rust-lang.org/stable/std/primitive.str.html)类型为实现了`FromStr` trait 的类型自动实现了`parse`方法，因此可以在代码中使用如下方式将符合要求的字符串转换为`address`类型对象：

</p>
<div class="code-example">

```rust
let addr_str = "0x3e9afaa4a062a49d64b8ab057b3cb51892e17ecb";
let addr = addr_str.parse<address>();
```

</div>
<li>

```rust
impl From<[u8; 20]> for Address {
    fn from(bytes: [u8; 20]) -> Self;
}
```

</li>
<p>
将长度为 20 的字节数组转换为`address`类型对象，其使用方式如下：
</p>
<div class="code-example">

```rust
let addr_bytes: [u8; 20] = [0x3e, 0x9a, ...];
let addr: address = addr_bytes.into();
```

</div>
</ul>

此外，`address`类型还实现了`Copy`、`Clone`、`PartialEq`、`Eq`，`PartialOrd`及`Ord` trait，因此可以直接对`address`类型对象使用值拷贝，或在`address`类型对象间进行大小的比较。

```eval_rst
.. note::

   ``address`` 是 ``Address`` 的类型别名。
```

## 动态字节数组类型

容纳字节数据的数组，其类型名称为`bytes`，是`Vec<u8>`类型的封装，数组长度运行时动态可变。`bytes`类型提供以下方法：

<ul class="method-introduction">
<li>

```rust
pub fn new() -> Self
```

</li>
<p>

构造一个空字节数组

</p>
</ul>

同时，`bytes`类型还实现了以下 trait：

<ul class="method-introduction">
<li>

```rust
impl core::ops::Deref for Bytes {
    type Target = Vec<u8>;

    fn deref(&self) -> &Self::Target;
}
```

```rust
impl core::ops::DerefMut for Bytes {
    fn deref_mut(&mut self) -> &mut Self::Target;
}
```

</li>
<p>

通过内部`Vec<u8>`数组的只读引用或可变引用，通过 Rust 语言的[解引用强制多态](https://doc.rust-lang.org/reference/type-coercions.html)，可以直接在`bytes`类型对象上使用`Vec<u8>`提供的成员方法，例如：

</p>

<div class="code-example">

```rust
let mut b1 = Bytes::new();
b1.push(1);
assert_eq!(b1.len(), 1);
assert_eq!(b1[0], 1);
```

</div>
<li>

```rust
impl From<&[u8]> for Bytes {
    fn from(origin: &[u8]) -> Self;
}

impl<const N: usize> From<[u8; N]> for Bytes {
    fn from(origin: [u8; N]) -> Self;
}

impl<const N: usize> From<&[u8; N]> for Bytes {
    fn from(origin: &[u8; N]) -> Self;
}

impl From<Vec<u8>> for Bytes {
    fn from(origin: Vec<u8>) -> Self;
}
```

</li>
<p>

用于将`u8`类型的切片、数组及动态数组转换为`bytes`类型对象。

</p>
</ul>

```eval_rst
.. note::

   ``bytes`` 是 ``Bytes`` 的类型别名。
```

## 定长数组类型

容纳字节数据的数组，但其数组长度在编译期长度就已经确定，是对应长度`u8`数组类型的封装。Liquid 提供`bytes1`、`bytes2`、...、`bytes32`共 32 种类型，分别代表长度为 1、2、...、32 的定长字节数组类型。`bytes#N`类型实现了以下 trait：

<ul class="method-introduction">
<li>

```rust
// Same for Bytes2, Bytes3...
impl core::ops::Shl<usize> for Bytes1 {
    type Output = Self;

    fn shl(mut self, mid: usize) -> Self::Output;
}

// Same for Bytes2, Bytes3...
impl core::ops::Shr<usize> for Bytes1 {
    type Output = Self;

    fn shr(mut self, mid: usize) -> Self::Output;
}
```

</li>
<p>

左移及右移运算。注意`bytes#N`类型的移位是按位进行，而不是按字节，因此例如有类型为`bytes1`的变量`b`，其内容为`0b01010101`，则执行 `b << 1`后所得结果为`0b10101010u8`。另外`bytes#N`类型的移位运算**不是**循环移位，移出的左（右）端的位将会被直接丢弃，同时在右（左）端补零。

</p>

<li>

```rust
// Same for Bytes2, Bytes3...
impl core::ops::BitAnd for Bytes1 {
    type Output = Self;

    fn bitand(self, rhs: Self) -> Self::Output;
}

// Same for Bytes2, Bytes3...
impl core::ops::BitOr for Bytes1 {
    type Output = Self;

    fn bitor(self, rhs: Self) -> Self::Output;
}

// Same for Bytes2, Bytes3...
impl core::ops::BitXor for Bytes1 {
    type Output = Self;

    fn bitxor(self, rhs: Self) -> Self::Output;
}
```

</li>
<p>

按位与、或及异或运算。

</p>

<li>

```rust
// Same for Bytes2, Bytes3...
impl FromStr for Bytes1 {
    fn from_str(s: &str) -> Result<Self, Self::Err>;
}
```

</li>
<p>

将一个字符串转换为`bytes#N`类型对象，转换时会直接将字符串的原始字节数组填入`bytes#N`类型对象中。要求字符串的原始字节数组长度必须要小于或等于定长字节数组的长度，若长度将会在左端补零。由于[`str`](https://doc.rust-lang.org/stable/std/primitive.str.html)类型为实现了`FromStr` trait 的类型自动实现了`parse`方法，因此可以在代码中使用如下方式将符合要求的字符串转换为`bytes#N`类型对象：

</p>
<div class="code-example">

```rust
// Due to that string in Rust using UTF-8 encoding,
// `b` equals to [0xe4, 0xbd, 0xa0, 0xe5, 0xa5, 0xbd]
let b: bytes6 = "你好".parse().unwrap();
```

</div>
<li>

```rust
// Same for Bytes2, Bytes3...
impl core::ops::Index<usize> for Bytes1 {
    type Output = u8;

    fn index(&self, index: usize) -> &Self::Output;
}

impl core::ops::IndexMut<usize> for Bytes1 {
    fn index_mut(&mut self, index: usize) -> &mut Self::Output;
}
```

</li>
<p>

支持通过下标对字节数组中的值进行随机访问，返回对应字节的只读或可变引用。下标的类型为`usize`。

</p>
</ul>

`bytes#N`类型实现了整数类型到`bytes#N`类型、`bytes#N`类型到`bytes#N`类型的转换，所有转换都是通过实现相应的[`From`](https://doc.rust-lang.org/nightly/core/convert/trait.From.html) trait 实现。整数类型转换到`bytes#N`类型时，要求整数类型的存储大小不得超过目标定长字节数组的长度；`bytes#N`类型到`bytes#N`类型时，要求原始字节数组的长度不得超过目标定长字节数组的长度，例如：

```rust
let b1: bytes1 = 0b10101010u8.into();
let b2: bytes32 = b1.into();
```

此外，`bytes#N`类型还实现了`Copy`、`Clone`、`PartialEq`、`Eq`、`PartialOrd`、`Ord` trait，因此可以直接对长度相同的`bytes#N`类型对象使用值拷贝，或在长度相同的`bytes#N`类型对象间进行大小比较。

```eval_rst
.. note::

   ``bytes1`` 、 ``bytes2`` 、...、 ``bytes32`` 分别是 ``Bytes1`` 、 ``Bytes2`` 、...、 ``Bytes32`` 的类型别名。
```

## 大整数类型

Liquid 中的大整数类型包括`u256`及`i256`，分别对应无符号 256 位整数及有符号 256 位整数。`u256`、`i256`的使用方式与 Rust 语言中的原生整数类型类似，支持**同类型之间**的加、减、乘、除、大小比较等运算，其中`i256`还支持取负运算。

`u256`类型及`i256`类型提供的方法及构造方式类似，只是由于`i256`能够表示负数，因此其数值表示范围与`u256`不相同。与在此仅对`u256`类型进行详细介绍，`i256`同理类推即可。`u256`类型实现了以下 trait：

<ul class="method-introduction">
<li>

```rust
impl FromStr for u256 {
    fn from_str(s: &str) -> Result<Self, Self::Err>;
}
```

</li>
<p>

基于 10 进制或 16 进制字符串构造`u256`类型对象，其中 16 进制字符串必须以`0x`或`0X`开头。当字符串中包含非法字符时会引发运行时异常。

</p>

<li>

```rust
#[cfg(feature = "std")]
impl fmt::Display for u256 {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result;
}

#[cfg(feature = "std")]
impl fmt::Debug for u256 {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result;
}
```

</li>

<p>

用于将`u256`类型对象转换为格式化字符串。需要注意的是，上述实现仅在进行合约单元测试时提供，在正式的合约代码中不允许使用上述实现。

</p>
</ul>

此外，`u256`类型还实现了各种整数类型（包括有符号整数类型）到`u256`类型的转换。支持有符号整数类型转换到`u256`类型的原因是为了方便开发者书写如下代码：

```rust
let u: u256 = 1024.into();
```

由于 Rust 语言编译器在做类型推断时会将表示范围内的整数自动推导为有符号整数类型，例如上述代码中 1024 会被推导为`i32`类型，若没有实现有符号整数类型转换到`u256`类型的转换，开发者将不得不将上述代码改写为：

```rust
let u: u256 = 1024u32.into();
```

但是若尝试将一个负数转换为`u256`类型对象，会导致引发运行时异常。`i256`类型则没有这个问题。

## 类型限制

### 状态变量

为节省链上存储空间及提高编解码效率，Liquid 使用了紧凑的二进制编码格式[SCALE](https://substrate.dev/docs/en/knowledgebase/advanced/codec)来对状态变量进行编解码。因此只要能够被 SCALE 编解码器编解码的类型都能够用于定义状态变量的实际类型，这些类型包括：

-   基本类型

    -   `bool`
    -   `u8`，`u16`，`u32`，`u64`，`u128`，`u256`
    -   `i8`，`i16`，`i32`，`i64`，`i128`，`i256`
    -   `String`
    -   `address`
    -   `bytes`
    -   `bytes1`，`bytes2`，...，`bytes32`
    -   `Option`
    -   `Result`

-   复合类型
    -   元组类型
    -   数组类型
    -   动态数组类型（`Vec<T>`）
    -   结构体类型
    -   枚举类型，但最多能够有 256 个枚举变体（variants）

当使用复合类型时，Liquid 要求它们的各个成员或元素类型也同样能够被 SCALE 编解码器编解码，特别的，复合类型能够嵌套复合类型，如`Vec<[(u8, address); 5]>`。对于结构体类型，若需要用于定义状态变量的类型，则必须要在结构体定义前 derive `InOut`属性，否则会引发编译报错，其中`State`属性的定义位于`liquid_lang`库中，需要在合约代码中提前导入：

```eval_rst
.. code-block:: rust
   :linenos:
   :emphasize-lines: 1, 3, 11

   use liquid_lang::State;

   #[derive(State)]
   pub struct Foo {
       b: bool,
       i: i32,
   }
   ...
   #[liquid(storage)]
   struct Bar {
       foo: storage::Value<Foo>,
   }

```

需要注意的是，尽管此处的动态数组（`Vec<T>`）与容器中的[向量容器](./state.html#id5)（`storage::Vec<T>`）名称上类似，但两者是完全不一样的概念。向量容器能以类似动态数组的方式访问区块链底层存储，而动态数组的实现则是由 Rust 语言的标准库提供，表示内存中一段连续的存储空间。两者的区别主要体现在：

-   动态数组中相邻元素在内存中的位置也是相邻的，但向量容器中相邻元素在区块链底层存储中的位置并不一定是相邻的；
-   动态数组支持在任意位置插入或删除元素，但向量容器只能在尾部插入及删除元素；
-   动态数组能够直接使用`for ... in ...`语法进行迭代，但向量容器在使用`for ... in ...`语法进行迭代前必须要先调用`iter()`方法生成迭代器；
-   动态数组能够整体作为一个状态变量的值存入区块链存储中，但是向量容器无法做到这一点。例如，下列代码展示了在单值容器中存放动态数组：

    ```rust
    #[liquid(storage)]
    struct Foo {
        foo: storage::Value<Vec<u8>>,
    }
    ```

    但是不能将状态变量定义为：

    ```rust
    #[liquid(storage)]
    struct Foo {
        foo: storage::Value<storage::Vec<u8>>,
    }
    ```

```eval_rst
.. admonition:: 注意

   上述示例中形如 ``storage::Value<Vec<u8>>`` 的容器使用方式并不为我们所推荐。因为这种情况下，每次初次读取该状态变量时，都需要从区块链底层存储读入所有元素的编码并从中解码出完整的动态数组；当更新该状态变量后、需要写回至区块链底层存储时，同样需要对动态数组的所有元素进行编码然后再写回至区块链存储中。当动态数组中的元素个数较多时，编解码过程中将会带来极大的计算开销。正确的方式应该是使用向量容器 ``storage::Vec<u8>`` 。
```

### 合约方法参数及返回值

为兼容 Solidity 合约，Liquid 当前采用了 Solidity 所使用的[ABI 编解码](https://solidity.readthedocs.io/en/v0.7.1/abi-spec.html#formal-specification-of-the-encoding)方案来对合约方法的参数及返回值进行编解码。因此只要能够被 ABI 编解码器编解码的类型都能够用作合约方法的参数类型或返回值类型，这些类型包括：

-   基本类型

    -   `bool`
    -   `u8`，`u16`，`u32`，`u64`，`u128`，`u256`
    -   `i8`，`i16`，`i32`，`i64`，`i128`，`i256`
    -   `String`
    -   `address`
    -   `bytes`
    -   `bytes1`，`bytes2`，...，`bytes32`

-   复合类型
    -   元组类型
    -   数组类型
    -   动态数组类型（`Vec<T>`）
    -   结构体类型

当使用复合类型时，Liquid 要求它们的各个成员或元素类型也同样能够被 ABI 编解码器编解码。对于结构体类型，若需要用于定义合约方法参数或返回值的类型，则必须要在结构体定义前 derive `InOut`属性，否则会引发编译报错，其中`InOut`属性的定义位于`liquid_lang`库中，需要在合约代码中提前导入：

```eval_rst
.. code-block:: rust
   :linenos:
   :emphasize-lines: 1, 3, 11

   use liquid_lang::InOut;

   #[derive(InOut)]
   pub struct Foo {
       b: bool,
       i: i32,
   }
   ...
   #[liquid(methods)]
   impl Bar {
       pub fn bar(&self, foo: Foo) -> Foo {
           ...
       }
   }

```

如果需要某个结构体类型既能够用于定义状态变量的类型，又能够用于定义合约方法参数或返回值的类型，只需要同时 derive `State`、`InOut`两个属性即可：

```eval_rst
.. code-block:: rust
   :linenos:
   :emphasize-lines: 1, 3, 11, 16

   use liquid_lang::{InOut, State};

   #[derive(InOut, State)]
   pub struct Foo {
       b: bool,
       i: i32,
   }

   #[liquid(storage)]
   struct Bar {
       foo: storage::Value<Foo>,
   }

   #[liquid(methods)]
   impl Bar {
       pub fn bar(&self, foo: Foo) -> Foo {
           ...
       }
   }
```

### 事件参数

为方便依赖事件机制的外部应用能够无缝迁移至 Liquid 生态体系内，Liquid 的事件机制对 Solidity 中的事件机制基本保持兼容。因此，Liquid 事件定义中的参数类型同样需要能够被 ABI 编解码器编解码，事件参数定义中能够使用的数据类型包括：

-   基本类型

    -   `bool`
    -   `u8`，`u16`，`u32`，`u64`，`u128`，`u256`
    -   `i8`，`i16`，`i32`，`i64`，`i128`，`i256`
    -   `String`
    -   `address`
    -   `bytes`
    -   `bytes1`，`bytes2`，...，`bytes32`

-   复合类型
    -   元组类型
    -   数组类型
    -   动态数组类型（`Vec<T>`）
    -   结构体类型

对于结构体类型的定义，只需要在其定义前 derive `InOut`属性即可用于定义事件参数的类型。当某个参数被设置为可索引时，其定义中能够使用的类型进一步收窄为：

-   `bool`
-   `u8`，`u16`，`u32`，`u64`，`u128`，`u256`
-   `i8`，`i16`，`i32`，`i64`，`i128`，`i256`
-   `String`
-   `address`
