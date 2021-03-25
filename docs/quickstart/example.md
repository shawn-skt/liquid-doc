# Hello World!

```eval_rst
.. hint::

   为了能够更好地使用Liquid进行智能合约开发，我们强烈建议提前参考 `Rust语言官方教程 <https://doc.rust-lang.org/book/>`_ ，掌握Rust语言的基础知识，尤其借用、生命周期、属性等关键概念。
```

本节将以简单的 HelloWorld 合约为示例，帮助读者快速建立对 Liquid 合约的直观认识。

```eval_rst
.. code-block:: rust
   :linenos:

   #![cfg_attr(not(feature = "std"), no_std)]

   use liquid::storage;
   use liquid_lang as liquid;

   #[liquid::contract]
   mod hello_world {
       use super::*;

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
               self.name.set(name)
           }
       }

       #[cfg(test)]
       mod tests {
           use super::*;

           #[test]
           fn get_works() {
               let contract = HelloWorld::new();
               assert_eq!(contract.get(), "Alice");
           }

           #[test]
           fn set_works() {
               let mut contract = HelloWorld::new();

               let new_name = String::from("Bob");
               contract.set(new_name.clone());
               assert_eq!(contract.get(), "Bob");
           }
       }
   }
```

上述智能合约代码中所使用的各种语法的详细说明可参阅“**普通合约**”一章，在本节中我们先进行初步的认识：

-   第 1 行：

    ```eval_rst
    .. code-block:: rust
       :lineno-start: 1

       #![cfg_attr(not(feature = "std"), no_std)]
    ```

    `cfg_attr`是 Rust 语言中的内置属性之一。此行代码用于向编译器告知，若编译时没有启用`std`特性，则在全局范围内启用`no_std`属性，所有 Liquid 智能合约项目都需要以此行代码为首行。当在本地运行单元测试用例时，Liquid 会自动启用`std`特性；反之，当构建为可在区块链底层平台部署及运行的 Wasm 格式字节码时，`std`特性将被关闭，此时`no_std`特性将被自动启用。

    由于 Wasm 虚拟机的运行时环境较为特殊，对 Rust 语言标准库的支持并不完整，因此需要启用`no_std`特性以保证智能合约代码能够被 Wasm 虚拟机执行。相反的，当在本地运行单元测试用例时，Liquid 并不生成 Wasm 格式字节码，而是生成可在本地直接运行的可执行二进制文件，因此并不受前述限制。

-   第 2~3 行：

    ```eval_rst
    .. code-block:: rust
       :lineno-start: 2

       use liquid::storage;
       use liquid_lang as liquid;
    ```

    上述代码用于导入`liquid_lang`库并将其重命名为`liquid`，同时一并导入`liquid_lang`库中的`storage`模块。`liquid_lang`库是 Liquid 的核心组成部分，Liquid 中的诸多特性均由该库实现，而`storage`模块对区块链状态读写接口进行了封装，是定义智能合约状态变量所必须依赖的模块。

-   第 10~13 行：

    ```eval_rst
    .. code-block:: rust
       :lineno-start: 10

       #[liquid(storage)]
       struct HelloWorld {
           name: storage::Value<String>,
       }
    ```

    上述代码用于定义 HelloWorld 合约中的状态变量，状态变量中的内容会在区块链底层存储中永久保存。可以看出，HelloWorld 合约中只包含一个名为“name”的状态变量，且其类型为字符串类型`String`。但是注意到在声明状态变量类型时并没有直接写为`String`，而是将其置于单值容器`storage::Value`中，更多关于容器的说明可参阅[状态变量与容器](../contract/state.md)一节。

-   第 15~28 行：

    ```eval_rst
    .. code-block:: rust
       :lineno-start: 15

       #[liquid(methods)]
       impl HelloWorld {
           pub fn new(&mut self) {
               self.name.initialize(String::from("Alice"));
           }

           pub fn get(&self) -> String {
               self.name.clone()
           }

           pub fn set(&mut self, name: String) {
               self.name.set(name)
           }
       }
    ```

    上述代码用于定义 HelloWorld 合约的合约方法。示例中的合约方法均为外部方法，即可被外界直接调用，其中：

    -   `new`方法为 HelloWorld 合约的构造函数，构造函数会在合约部署时自动执行。示例中`new`方法会在初始时将状态变量`name`的内容初始化为字符串“Alice”；

    -   `get`方法用于将状态变量`name`中的内容返回至调用者

    -   `set`方法要求调用者向其传递一个字符串参数，并将状态变量`name`的内容修改为该参数。

-   第 30~48 行：

    ```eval_rst
    .. code-block:: rust
       :lineno-start: 30

       #[cfg(test)]
       mod tests {
           use super::*;

           #[test]
           fn get_works() {
               let contract = HelloWorld::new();
               assert_eq!(contract.get(), "Alice");
           }

           #[test]
           fn set_works() {
               let mut contract = HelloWorld::new();

               let new_name = String::from("Bob");
               contract.set(new_name.clone());
               assert_eq!(contract.get(), "Bob");
           }
       }
    ```

    上述代码用于编写 HelloWorld 合约的单元测试用例。首行`#[cfg(test)]`用于告知编译器，只有启用`test`编译标志时，才编译其后跟随的模块，否则直接从代码中剔除。当将 Liquid 智能合约编译为 Wasm 格式字节码时，不会启用`test`编译标志，因此最终的字节码中不会包含任何与测试相关的代码。代码中的剩余部分则是包含了单元测试用例的具体实现，示例中的用例分别用于测试`get`方法及`set`方法的逻辑正确性，其中每一个测试用例均由`#[test]`属性进行标注。
