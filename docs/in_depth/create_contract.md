# 创建合约模块

为开发Liquid合约，您首先需要在代码中使用`use`关键字引入`liquid_lang`模块，`liquid_lang`模块中包含了用于定义合约各个组成部分的属性的实现：

```rust
use liquid_lang as liquid;
```

在引入的过程中，我们使用了`as`关键字将`liquid_lang`模块重命名为`liquid`，此后您便可以使用这个较短的名字引用`liquid_lang`模块中提供的所有功能。

Liquid使用Rust语言中的模块语法来创建合约，以`mod`关键字表示。您可以自行决定该模块的名字（在`mod`关键字之后），但是建议按照Rust语言代码风格为该模块取名，以防编译器向您发出抱怨。您需要在为该模块添加`#[liquid::contract(...)]`属性，以向Liquid表明此模块包含了合约的完整定义，从而引导Liquid解析您的合约，其中`...`用于描述合约属性：

```rust
#[liquid::contract(version = "0.1.0", hash_type = "keccak256")]
mod hello_world {
    // ...
}
```

Liquid合约有两种属性：

- `version`：`version`用于指定所使用的Liquid版本。在未来，随着Liquid不断迭代，可能会引入不兼容的功能特性，在这种情况下，您所指定的Liquid版本将会影响Liquid解析合约的方式。`version`必须以[语义化版本](https://semver.org/lang/zh-CN/)的格式提供，即版本是以英语句号`.`分割的主版本号、次版本号及修订号。

- `hash_type`：Liquid在某些场合需要使用到哈希函数（如计算合约方法选择器、参数编码等）。`hash_type`提供了两个选项：`keccak256`及`sm3`，用于在不同的场景下，指定Liquid使用的哈希函数类型。当您的合约需要部署至非国密FISCO BCOS区块链平台时，您需要指定`hash_type`为`keccak256`以启用Keccak-256哈希算法；反之，若您的合约需要部署至国密FISCO BCOS区块链平台，则您需要指定`hash_type`为`sm3`以启用国密SM3哈希算法。`hash_type`属性是可选的，当您没有提供时，Liquid默认将`hash_type`设置为`keccak256`。

```eval_rst
.. admonition:: 注意

   为保证合约能够正常被部署、调用，请务必确认您在``hash_type``中所指定的哈希函数类型符合合约运行环境的要求。
```

Rust语言中存在声明模块可见性的语法，主要用于控制当前模块能否被其他模块使用，但对于Liquid合约，这种语法并无意义。为避免Liquid合约的表现与您所预期的模块可见性存在差异，Liquid不允许您为合约模块添加任何可见性声明。例如，下列试图将合约模块声明为公开的代码是非法的：

```rust
// Forbidden!
#[liquid::contract(version = "0.1.0", hash_type = "keccak256")]
pub mod hello_world {
    // ...
}
```

除此之外，定义合约的`mod`必须是内联的，即只能使用`mod m { ... }`的形式定义，而其他方式是非法的：

```rust
// Forbidden!
#[liquid::contract(version = "0.1.0", hash_type = "keccak256")]
mod hello_world;
```

这种形式要求您必须在同一份源代码文件中提供合约的完整定义，从而保证Liquid能够立即解析您的合约。

合约模块创建完成后，你便可以开始在模块中继续定义合约其他的组成部分，包括[状态变量](./state.html)、[合约方法](./method.html)及[事件](./event.html)。
