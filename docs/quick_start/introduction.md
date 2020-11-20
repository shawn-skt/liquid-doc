# Liquid简介

## 概述

Liquid是一种[嵌入式领域特定语言](http://wiki.haskell.org/Embedded_domain_specific_language)（**e**mbedded **D**omain **S**pecific **L**anguage，eDSL），其特性可以从下列两个方面理解：

- **领域特定**：领域特定语言是指专用于某个应用程序领域的计算机语言。与能够被应用在各个领域的通用编程语言（如C++、Java等）不同，Liquid是专为区块链底层平台FISCO BCOS设计的、用于编写能够被编译为[Wasm](https://webassembly.org/)字节码格式的智能合约语言。使用Liquid编写的智能合约能够在内置有Wasm虚拟机的FISCO BCOS区块链节点上运行。

- **嵌入式**：Liquid没有设计新的语法，而是将自身“嵌入”在通用编程语言[Rust](https://www.rust-lang.org/)中，即Rust是Liquid的宿主语言。Liquid对Rust语言的部分语法进行了重新诠释，从而能够借助Rust语言来方便地表达智能合约中特有的语义。使用Liquid编写的智能合约，本身也是合法的Rust程序，能够使用现有Rust标准工具链进行编译、优化。

```eval_rst
.. important::

   为了能够更好的使用Liquid进行智能合约开发，我们强烈建议您提前掌握Rust语言的基础知识，尤其是借用、生命周期、属性等关键概念。若您此前无Rust语言相关的知识背景，推荐您参考 Rust语言官方教程_。同时，Liquid的合约编程模型与现有的主流智能合约编程语言（如 Solidity_ 或 Vyper_ 等）较为接近，如果您有过使用这些语言进行智能合约开发的经验，将有助于学习和使用Liquid。

.. _Rust语言官方教程: https://doc.rust-lang.org/book/
.. _Solidity: https://solidity.readthedocs.io/en/latest/
.. _Vyper: https://vyper.readthedocs.io/en/stable/
```

## 关键特性

- **丰富的语法、安全的语义**：您能够在Liquid合约中使用Rust提供的大部分语言特性，包括强大的类型系统、移动语义、标准库及闭包等。此外，Rust编译器内置的可代码达性检查、借用检查、生命周期检查及代码风格检查也同样能够应用于Liquid合约，这些检查策略可以帮助您写出更加健壮及安全的合约代码。

- **高效**：Wasm是一种可移植、体积小、加载快的字节码格式，Liquid支持将合约代码编译为Wasm格式字节码，从而使得您的智能合约能够以更高的效率在在区块链系统中运行。

- **支持单元测试**：Liquid支持在项目内部方便地为合约编写单元测试用例，并支持在本地执行这些用例，从而帮助您在正式部署合约之前发现可能存在的漏洞。

- **完全兼容Solidity ABI**：Liquid合约的应用程序二进制接口与Solidity完全兼容，因此Liquid合约可以与Solidity合约互相调用，同时，为Solidity合约开发的应用程序也能够无缝迁移至Liquid生态中。

## 从简单合约出发

本小节将会以一个简单的Hello World合约为例，展示Liquid语言的基本特性，以帮助您快速建立对Liquid的初步认知。如果您对Liquid的高级特性及实现细节感兴趣，请参考**深入学习**一章。

### 合约代码

Hello World合约的完整Liquid代码如下所示：

```eval_rst
.. code-block:: rust
   :linenos:

   #![cfg_attr(not(feature = "std"), no_std)]
   use liquid_lang as liquid;

   #[liquid::contract(version = "0.1.0")]
   mod hello_world {
       use liquid_core::storage;

       #[liquid(storage)]
       struct HelloWorld {
           name: storage::Value<String>,
       }

       #[liquid(methods)]
       impl HelloWorld {
           pub fn new(&mut self) {
               self.name.initialize(String::from("Alice"));
           }

           pub fn get(&self) -> String {
               self.name.clone()
           }

           pub fn set(&mut self, name: String) {
               *self.name = name;
           }
       }

       #[cfg(test)]
       mod tests {
           use super::*;
           #[test]
           fn get_works() {
               let contract = HelloWorld::new();
               assert_eq!(contract.get(), String::from("Alice"));
           }

           #[test]
           fn set_works() {
               let mut contract = HelloWorld::new();
               let new_name = String::from("Bob");
               contract.set(new_name.clone());
               assert_eq!(contract.get(), new_name));
           }
       }
   }
```

### 代码解析

代码中第1行：

```eval_rst
.. code-block:: rust
   :lineno-start: 1

   #![cfg_attr(not(feature = "std"), no_std)]
```

用于向编译器表明，当以非std模式（即编译为Wasm字节码）编译时，启用`no_std`属性。出于安全性的考虑，Wasm对Rust标准包的支持较为有限，因此需要启用该属性以保证您的合约能够运行在Wasm虚拟机上。

第3行用于导入`liquid_lang`包，Liquid诸多特性的实现均位于该包中。

第5~6行用于声明`alloc`包，由于我们在拼接字符串时使用了`format!`宏，而`format!`宏需要从Rust语言的基础包`alloc`中导入。

第8~51行是合约主体。本质上，合约就是一系列函数（合约方法）与数据（状态变量）的集合。在Liquid中，合约方法及状态变量封装于一个由`contract`属性标注的模块中：

- 第8行用于向Liquid表明其后跟随的`mod`中的内容是合约主体，同时，通过`contract`属性的参数将合约属性传递给Liquid，合约属性主要包括要使用的Liquid版本等；

- 第12~15行定义了合约的状态变量。在`Hello World`合约中，声明了一个名为`name`、类型为`String`的状态变量。但是我们可以注意到，`name`的类型并没有直接写为`String`，而是写为`storage::Value<String>`。此处的`Value`一种状态变量容器，用于帮助我们访问区块链存储。

- 第17~30行定义了合约方法。在HelloWorld合约中，我们定义了三个合约方法：
  - `new`：构造函数。在Liquid合约中，名称为`new`的合约方法会被认为是合约构造函数。构造函数会在合约部署时自动执行。此处的构造函数用于将合约状态变量`name`初始化为"Alice"；

  - `get`：方法会将状态变量`name`的值拼接至字符串"Hello, "尾部，并将拼接后的新字符串返回给调用者；
  
  - `set`：方法允许调用者向其传递一个字符串参数，并使用该参数修改状态变量`name`的值。

第32~50行定义了一个专用于单元测试的模块。单元测试并不是合约的的一部分，而是用于在本机运行，以检查合约方法实现逻辑的正确性。第32行是一个编译开关，意为只有当`test`编译标志启用时，其后跟随的模块才会参与编译，否则直接从代码中剔除。当将Liquid编译为Wasm字节码时， `test`编译标志不会启用，因此最后的合约字节码中不会包含任何测试。由于模块会进行命名空间隔离，因此我们需要在第34行从外部导入我们刚刚定义的合约符号，以方便在单元测试中使用。在`tests`模块中，我们编写了2个单元测试，分别用于测试`get`函数和`set`函数的正确性。

## Let's Liquid!

在接下来的篇幅中，我们将介绍Liquid合约开发环境的搭建及基本的开发流程，以帮助您把对于区块链应用的绝妙创意快速变为现实。
