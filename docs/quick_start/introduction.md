# Liquid简介

## 概述

Liquid是一种[嵌入式领域特定语言](http://wiki.haskell.org/Embedded_domain_specific_language)（embedded Domain-Specific Language，eDSL），其特性可以从下列两个方面理解：

- **领域特定语言**：领域特定语言是指专用于某个应用程序领域的计算机语言。与能够被应用在各个领域的通用编程语言（如C++、Java等）不同，Liquid被设计为专注为区块链底层平台[FISCO BCOS](https://github.com/FISCO-BCOS/FISCO-BCOS)编写能够被编译为[WebAssembly](https://webassembly.org/)（Wasm）字节码格式的智能合约。使用Liquid编写的智能合约能够在内置有Wasm虚拟机的FISCO BCOS区块链节点上运行。

- **嵌入式**：Liquid没有设计新的语法，而是将自身“嵌入”在通用编程语言[Rust](https://www.rust-lang.org/)中，即Rust语言是Liquid的宿主语言。Liquid对Rust语言的部分语法进行了重新诠释，从而能够借助Rust语言来方便地表达智能合约特有的语义。使用Liquid编写的应用程序，本身也是合法的Rust程序，能够使用现有Rust标准工具链进行编译、优化。

```eval_rst
.. important::

   Liquid选择Rust语言作为宿主语言也意味着，为了能够更好的使用Liquid进行智能合约开发，我们强烈建议您提前掌握Rust语言的基础知识，尤其是借用、生命周期、属性等关键概念。若您此前无Rust语言相关的知识背景，推荐您参考`Rust语言官方教程 <https://doc.rust-lang.org/book/>`_ 。同时，Liquid的基础编程模型与现有的主流智能合约编程语言（如`Solidity <https://solidity.readthedocs.io/en/latest/>`_、`Vyper  <https://vyper.readthedocs.io/en/stable/>`_等）较为接近，如果您有使用这些语言进行智能合约开发的经验，将有助于学习使用Liquid。
```

## 关键特性

- **丰富的语法、安全的语义**：您能够在Liquid合约中大部分地方中使用Rust提供的语言特性，包括强大的类型系统、移动语义、标准容器及λ表达式等。此外，Rust语言内置的可达性检查、借用检查、生命周期检查及代码风格检查等对于Liquid合约仍然是有效的，这些检查策略可以帮助您写出更加健壮及安全的合约代码

- **高效**：Wasm是一种可移植、体积小、加载快的字节码格式，Liquid支持将合约代码编译为Wasm格式字节码，从而使得您的智能合约能够以更高的效率在在区块链上运行

- **支持单元测试**：Liquid支持在合约内部方便地编写单元测试。当以`std`模式编译合约时，Liquid会引导编译器将合约编译为本机机器码并运行单元测试，从而帮助您在部署合约之前发现可能存在的漏洞

- **完全兼容Solidity ABI**：Liquid合约的应用程序二进制接口与Solidity完全兼容，因此Liquid合约可以与Solidity合约互相调用。同时，为Solidity合约开发的应用程序也能够无缝迁移至Liquid

## 从简单合约出发

本小节将会以一个简单`Hello World`合约为例，展示Liquid的基本特性，以帮助您快速建立Liquid的初步认知。此处我们不会对Liquid语言的高级特性及实现细节展开讨论，如果您对此感兴趣，请参考**深入学习**一章。

### Hello World合约

`Hello World`合约的完整Liquid代码如下：

```rust
 1 #![cfg_attr(not(feature = "std"), no_std)]
 2
 3 use liquid_lang as liquid;
 4
 5 #[macro_use]
 6 extern crate alloc;
 7
 8 #[liquid::contract(version = "0.1.0")]
 9 mod hello_world {
10     use liquid_core::storage;
11
12     #[liquid(storage)]
13     struct HelloWorld {
14         name: storage::Value<String>,
15     }
16
17     #[liquid(methods)]
18     impl HelloWorld {
19         pub fn new(&mut self) {
20             self.name.initialize(String::from("Alice"));
21         }
22
23         pub fn get(&self) -> String {
24             format!("Hello, {}!", self.name.clone())
25         }
26
27         pub fn set(&mut self, name: String) {
28             *self.name = name;
29         }
30     }
31
32     #[cfg(test)]
33     mod tests {
34         use super::*;
35
36         #[test]
37         fn get_works() {
38             let contract = HelloWorld::new();
39             assert_eq!(contract.get(), String::from("Hello, Alice!"));
40         }
41
42         #[test]
43         fn set_works() {
44             let mut contract = HelloWorld::new();
45
46             let new_name = String::from("Bob");
47             contract.set(new_name.clone());
48             assert_eq!(contract.get(), format!("Hello, {}!", new_name));
49         }
50     }
51 }
```

### 合约代码剖析

第1行用于向编译器表明，当以非std模式（即编译为Wasm字节码）编译时，启用`no_std`属性。出于安全性的考虑，Wasm对Rust标准库的支持较为有限，因此需要启用该属性以保证您的合约能够运行在Wasm虚拟机上。

第3行用于导入`liquid_lang`库，Liquid诸多特性的实现均位于该库中。

第5~6行用于声明`alloc`库，由于我们在拼接字符串时使用了`format!`宏，而`format!`宏需要从`alloc`库中导入。

第8~51行是合约主体。本质上，合约就是一系列函数（合约方法）与数据（状态变量）的集合，在Liquid中，合约方法及状态变量封装于一个由`contract`属性标注的`mod`中，其中`contract`属性的定义位于`liquid_lang`中：

- 第8行声明合约了的元数据，元数据通过`contract`属性的参数传递给Liquid，主要包括要使用的Liquid版本等；

- 第12~15行定义了合约的状态变量，合约的所有状态变量需要被封装于一个由`liquid(storage)`属性标注的`struct`中。在`Hello World`合约中，声明了一个名为`name`的状态变量，其类型为`Value<String>`。此处`String`是状态变量的实际类型，即字符串；而`Value`则是一种状态变量容器。读写状态变量时需要对链上持久化的状态进行访问，而`Value`容器对这些操作进行了封装，因此可以使得您像使用普通变量那样使用状态变量。在**深入学习**一章中，我们还将学习到更多容器的使用；

- 第17~30行定义了合约方法，合约的所有方法需要被封装于一个由`liquid(methods)`属性标注的`impl`块中，且`impl`块的标识符需要与封装合约状态变量的`struct`的标识符相同（此合约中标识符都为"HelloWorld"）。在`HelloWorld`合约中，我们为合约定义了三个合约方法：
  - `new`：构造函数。在Liquid中，每个合约有且仅能有一个构造函数，且构造函数的名称必须为`new`。构造函数会在合约部署时自动执行，但不能被用户或外部合约调用。此处的构造函数用于将合约状态变量`name`初始化为"Alice"；

  - `get`:法会将状态变量`name`的值拼接至字符串`"Hello, "`尾部，并将拼接后的新字符串返回给调用者；
  
  - `set`方法允许调用者向其传递一个字符串参数，并使用该参数修改状态变量`name`的值。

第32~50行定义了一个专用于单元测试的mod。单元测试并不是合约的的一部分，而是用于在本机运行以检查合约方法实现逻辑的正确性。第32行是一个编译开关，意为只有当`test`编译标志启用时，其后跟随的`mod`才会参与编译，否则直接从代码中剔除。当将Liquid编译为Wasm字节码时， `test`编译标志不会启用，因此最后的合约字节码中不会包含任何测试。由于`mod`会进行命名空间隔离，因此我们需要在第34行从外部导入我们刚刚定义的合约符号，以方便在单元测试中使用。在`tests`模块中，我们编写了2个单元测试，分别用于测试`get`函数和`set`函数的正确性。

## Let's Liquid!

在接下来的篇幅中，我们将介绍Liquid合约开发环境的搭建及基本的开发流程，以帮助您将您对区块链应用的创意快速变为现实。
