# 类型

由于Liquid以Rust语言为宿主语言，因此理论上Liquid合约中能够使用Rust语言所能表示的[所有类型](https://doc.rust-lang.org/book/ch03-02-data-types.html)。然而，这一点并不是总是成立的，出于各种设计考虑（如兼容Solidity、简化类型复杂度等），在某些场合，您能使用的类型的范围是有限的，这些场合包括：状态变量的类型、合约方法的参数及返回值类型、定义事件参数。了解类型的使用限制对您开发Liquid合约极为重要。

## 状态变量中的类型限制

为节省链上存储空间及提高编解码效率，Liquid使用了紧凑的二进制编码格式[SCALE](https://substrate.dev/docs/en/knowledgebase/advanced/codec)来存储状态变量的值，因此，凡是能够被SCALE编解码器编解码的类型都能够用作状态变量的实际类型，这些类型包括：

- bool
- u{8,16,32,64,128}
- i{8,16,32,64,128}
- String
- Address
- 元组
- 数组
- 动态数组（`Vec<T>`）
- 结构体

当使用元组、数组、动态数组及结构体这类复合类型定义状态变量时，Liquid要求它们的各个字段或元素类型也同样能够被SCALE编解码器编解码。特别的，对于结构体，在您在定义了结构体后，还需要为结构体添加derive属性`State`，才能够将结构体用于定义状态变量中，其中`State`属性的定义位于`liquid_lang`模块中：

```rust
use liquid_lang::State;

#[derive(State)]
pub struct Foo {
    b: bool,
    i: i32,
}

#[liquid(storage)]
struct Bar {
    foo: storage::Value<Foo>,
}
```

`State`属性会在编译期自动展开，为您定义的结构体生成SCALE编解码方法，从而能够用于定义状态变量。

需要注意的是，尽管此处的动态数组（`Vec<T>`）与容器中的[序列容器](./state.html#序列容器)（`storage::Vec<T>`）名称上类似，但两者是完全不一样的概念。序列容器能以类似动态数组的方式访问区块链存储，而动态数组由Rust语言的标准库提供，只是内存中一段连续的存储空间，两者的区别主要体现在：

- 动态数组中相邻元素在内存中的位置也是相邻的，但序列容器中相邻元素在区块链存储中的位置并不一定是相邻的；
- 动态数组支持在任意位置插入及删除元素，但序列容器只能在尾部插入及删除元素；
- 动态数组能够直接使用`for ... in ...`语法进行迭代，但序列容器在使用`for ... in ...`语法进行迭代前必须要先调用`iter()`接口生成迭代器；
- 动态数组能够整体作为一个状态变量的值存入区块链存储中，但是序列容器无法做到这一点。例如，您可以在容器中存放动态数组：

    ```rust
    #[liquid(storage)]
    struct Foo {
        foo: storage::Value<Vec<u8>>,
        // ...
    }
    ```

    但是您不能将状态变量定义为：

    ```rust
    #[liquid(storage)]
    struct Foo {
        foo: storage::Value<storage::Vec<u8>>,
        // ...
    }
    ```

    需要注意的是，上述举例中形如`storage::Value<Vec<u8>>`的容器使用方式并不为我们所推荐。因为这种情况下，合约初次访问该状态变量时，需要一次性从区块链存储读入所有元素的编码并从中解码出完整的动态数组；当该状态变量更新后需要写回至区块链存储时，同样需要对动态数组的所有元素进行编码并将所有编码一次性写回至区块链存储中。当动态数组中元素个数较多时，编解码过程中将会带来极大的计算和资源开销。此处正确的方式应该是使用`storage::Vec<u8>`。

## 合约方法中的类型限制

为兼容Solidity，Liquid采用了Solidity中的[ABI编解码](https://solidity.readthedocs.io/en/v0.7.1/abi-spec.html#formal-specification-of-the-encoding)方案来对合约方法的参数及返回值分别进行解码、编码。因此，凡是能够被ABI编解码器编解码的类型都能够用作合约方法的参数类型或返回值类型，这些类型包括：

- bool
- u{8,16,32,64,128}
- i{8,16,32,64,128}
- String
- Address
- 动态数组
- 结构体

当使用动态数组及结构体这类复合类型声明合约方法的参数类型或返回值类型时，Liquid要求它们的各个字段或元素类型也同样能够被ABI编解码器编解码。特别的，对于结构体，在您在定义了结构体后，还需要为结构体添加derive属性`InOut`，才能够将结构体用于声明合约方法的参数类型或返回值类型，其中`InOut`属性的定义位于`liquid_lang`模块中：

```rust
use liquid_lang::InOut;

#[derive(InOut)]
pub struct Foo {
    b: bool,
    i: i32,
}

#[liquid(methods)]
impl Bar {
    pub fn bar(&self, foo: Foo) -> Foo {
        // ...
    }
}
```

`InOut`属性会在编译期自动展开，为您定义的结构体生成ABI编解码方法，从而能够用于声明合约方法的参数类型或返回值类型。

如果您需要一个结构体既能够用于定义状态变量，又能够用于声明合约方法的参数类型或返回值类型，只需要同时从`State`、`InOut`两个属性derive即可：

```rust
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
        // ...
    }
}
```

## 事件参数中的类型限制

Liquid的事件模型被设计为与Solidity中的事件模型基本保持一致，从而使得依赖事件机制的外部应用基本无需改动即可迁移至Liquid体系内。因此，Liquid事件定义中的参数类型同样需要能够被ABI编解码器编解码，能够使用的类型包括：

- bool
- u{8,16,32,64,128}
- i{8,16,32,64,128}
- String
- Address
- 动态数组
- 结构体

对于结构体，您也只需要为其添加derive属性`InOut`即可用于声明事件参数的类型。当您将某个参数设置为`indexed`时，其能够使用的类型进一步限制为：

- bool
- u{8,16,32,64,128}
- i{8,16,32,64,128}
- String
- Address

## `Address`

在前面的描述中，已经多次出现`Address`类型。`Address`类型用于表示一个链上地址，是Liquid专门定义的类型，而不是由Rust语言提供，只是在构建Liquid合约时，Liquid会自动导入`Address`类型的定义，从而让您能够像使用一个Rust语言基本类型一样使用`Address`类型。`Address`类型的内部是一个长度为20的字节数组。为方便使用，`Address`类型提供了下列接口：

- `new`

  签名：`new(address: [u8; 20]) -> Self`

  功能：您可以通过传入一个长度为20的字节数组，直接构造出一个对应的`Address`对象。

- `default`

  签名：`default() -> Self`

  功能：返回一个地址为0x0000000000000000000000000000000000000000的`Address`对象。

- `empty`

  签名：`empty() -> Self`

  功能：同`default`

- `to_string`

  签名：`to_string(&self) -> String`

  功能：将`Address`转换为以16进制表示的字符串，以`0x`开头。注意，`Address`类型是通过实现`string::ToString` trait来提供`to_string`接口，在合约编译过程中编译器可能会提示您需要在代码中加入一行"`use crate::alloc::string::ToString;`"。

- `from`

  签名：`from(addr: &str) -> Self`

  功能：将一个16进制表示的字符串转换为`Address`对象，字符串可以`0x`或`0X`开头，也可不带任何前缀。

此外，`Address`类型还实现了比较功能，您可以直接使用`==`、`>`等运算符判断地址间是否相等或地址间的大小关系。
