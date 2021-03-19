# 开发示例

本节将以简单的 HelloWorld 合约为例介绍 Liquid 智能合约的开发步骤，将会涵盖智能合约的创建、开发、测试、构建、部署及调用等步骤。

## 创建

在终端中执行以下命令创建 Liquid 智能合约项目：

```shell
cargo liquid new contract hello_world
```

```eval_rst
.. note::

   ``cargo liquid`` 是调用命令行工具 ``cargo-liquid`` 的另一种写法，这种写法使得 ``liquid`` 看上去似乎是 ``cargo`` 的子命令。
```

上述命令将会在当前目录下创建一个名为 hello_world 的智能合约项目，此时会观察到当前目录下新建了一个名为“hello_world”的目录：

```shell
cd ./hello_world
```

hello_world 目录内的文件结构如下所示：

```shell
hello_world/
├── .gitignore
├── .liquid
│   └── abi_gen
│       ├── Cargo.toml
│       └── main.rs
├── Cargo.toml
└── lib.rs
```

其中各文件的功能如下：

-   `.gitignore`：隐藏文件，用于告诉版本管理软件[Git](https://git-scm.com/)哪些文件或目录不需要被添加到版本管理中。Liquid 会默认将某些不重要的问题件（如编译过程中生成的临时文件）排除在版本管理之外，如果不需要使用 Git 管理对项目版本进行管理，可以忽略该文件；

-   `.liquid\`：隐藏目录，用于实现 Liquid 智能合的内部功能，其中`abi_gen`子目录下包含了 ABI 生成器的实现，该目录下的编译配置及代码逻辑是固定的，如果被修改可能会造成无法正常生成 ABI；

-   `Cargo.toml`：项目配置清单，主要包括项目信息、外部库依赖、编译配置等，一般而言无需修改该文件，除非有特殊的需求（如引用额外的第三方库、调整优化等级等）；

-   `lib.rs`：Liquid 智能合约项目根文件，合约代码存放于此文件中。

## 开发

智能合约项目创建完毕后，`lib.rs`文件中会自动填充部分样板代码，我们可以基于这些样板代码做进一步的开发。在本节示例中，我们将`lib.rs`文件中的内容替换为以下内容：

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

上述智能合约代码中所使用的各种语法的详细说明可参阅“**基本合约**”一章，在本节中我们先只进行简单的解释：

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

## 测试

在正式部署之前，在本地对智能合约进行详尽的单元测试是一种良好的开发习惯。Liquid 内置了对区块链链上环境的模拟，因此即使不将智能合约部署上链，也能够在本地方便地执行单元测试。在 hello_world 项目根目录下执行以下命令即可执行我们预先编写好的单元测试用例：

```bash
cargo +nightly test
```

```eval_rst
.. admonition:: 注意

   上述命令与创建合约项目时的命令有两点不同：

   #. 命令中并不包含 ``liquid`` 子命令，因为Liquid可以使用标准cargo单元测试框架来执行单元测试，因此并不需要调用 ``cargo-liquid`` ；
   #. 和创建项目时不同，此处的命令中需要加上 ``+nightly`` 选项，以启用nightly版本Rust语言编译工具。该差别在构建智能合约项目时也存在，请务必注意。
```

命令执行结束后，显示如下内容：

```bash
running 2 tests
test hello_world::tests::set_works ... ok
test hello_world::tests::get_works ... ok

test result: ok. 2 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out

   Doc-tests hello_world

running 0 tests

test result: ok. 0 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out
```

从结果中可以看出，所有用例均通过了测试，因此可以有信心认为智能合约中的逻辑实现是正确无误的 😄。我们接下来将开始着手构建 HelloWorld 智能合约，并把它部署至真正的区块链上。

## 构建

在 hello_world 项目根目录下执行以下命令即可开始进行构建：

```bash
cargo +nightly liquid build
```

该命令会引导 Rust 语言编译器以`wasm32-unknown-unknown`为目标对智能合约代码进行编译，最终生成 Wasm 格式字节码及 ABI。命令执行完成后，会显示如下形式的内容：

```
:-) Done in 9 seconds, your project is ready now:
Binary: C:/Users/liche/hello_world/target/hello_world.wasm
ABI: C:/Users/liche/hello_world/target/hello_world.abi
```

其中，“Binary:”后为生成的字节码文件的绝对路径，“ABI:”后为生成的 ABI 文件的绝对路径。为尽量简化 FISCO BCOS 各语言 SDK 的适配工作，Liquid 采用了与 Solidity ABI 规范兼容的 ABI 格式，HelloWorld 智能合约的 ABI 文件内容如下所示：

```json
[
    {
        "inputs": [],
        "payable": false,
        "stateMutability": "nonpayable",
        "type": "constructor"
    },
    {
        "constant": true,
        "inputs": [],
        "name": "get",
        "outputs": [
            {
                "name": "",
                "type": "string"
            }
        ],
        "payable": false,
        "stateMutability": "view",
        "type": "function"
    },
    {
        "constant": false,
        "inputs": [
            {
                "name": "name",
                "type": "string"
            }
        ],
        "name": "set",
        "outputs": [],
        "payable": false,
        "stateMutability": "nonpayable",
        "type": "function"
    }
]
```

```eval_rst
.. hint::

   如果希望构建出能够在国密版FISCO BCOS区块链底层平台上运行的智能合约，请在执行构建命令时添加-g选项，例如： ``cargo +nightly liquid build -g``。
```

## 部署

使用 Node.js SDK CLI 工具提供的`deploy`子命令，我们可以将 Hello World 合约构建生成的 Wasm 格式字节码部署至真实的区块链上，`deploy`子命令的使用说明如下：

```shell
cli.js exec deploy <contract> [parameters..]

Deploy a contract written in Solidity or Liquid

Positionals:
  contract    The path of the contract                       [string] [required]
  parameters  The parameters(split by space) of constructor
                                                           [array] [default: []]

Options:
  --version   Show version number                                      [boolean]
  --abi, -a   The path of the corresponding ABI file                    [string]
  --who, -w   Who will do this operation                                [string]
  -h, --help  Show help                                                [boolean]
```

执行该命令时需要传入字节码文件的路径及构造函数的参数，并通过`--abi`选项传入 ABI 文件的路径。当根据[配置手册](https://github.com/FISCO-BCOS/nodejs-sdk#22-%E9%85%8D%E7%BD%AE)配置好 CLI 工具后，可以使用以下命令部署 HelloWorld 智能合约。由于合约中的构造函数不接受任何参数，因此无需在部署时提供参数：

```shell
node ./cli.js exec deploy C:/Users/liche/hello_world/target/hello_world.wasm --abi C:/Users/liche/hello_world/target/hello_world.abi
```

部署成功后，返回如下形式的结果，其中包含状态码、合约地址及交易哈希：

```json
{
    "status": "0x0",
    "contractAddress": "0x039ced1cd5bea5ace04de8e74c66e312ba4a48af",
    "transactionHash": "0xf84811a5c7a5d3a4452a65e6929a49e69d9a55a0f03b5a03a3e8956f80e9ff41"
}
```

## 调用

使用 Node.js SDK CLI 工具提供的`call`子命令，我们可以调用已被部署到链上的智能合约，`call`子命令的使用方式如下：

```shell
cli.js exec call <contractName> <contractAddress> <function> [parameters..]

Call a contract by a function and parameters

Positionals:
  contractName     The name of a contract                    [string] [required]
  contractAddress  20 Bytes - The address of a contract      [string] [required]
  function         The function of a contract                [string] [required]
  parameters       The parameters(split by space) of a function
                                                           [array] [default: []]

Options:
  --version   Show version number                                      [boolean]
  --who, -w   Who will do this operation                                [string]
  -h, --help  Show help                                                [boolean]
```

执行该命令时需要传入合约名、合约地址、要调用的合约方法名及传递给该合约方法的参数。以调用 HelloWorld 智能合约中的`get`方法为例，可以使用以下命令调用该方法。由于`get`方法不接受任何参数，因此无需在调用时提供参数：

```bash
node .\cli.js exec call hello_world 0x039ced1cd5bea5ace04de8e74c66e312ba4a48af get
```

调用成功后，返回如下形式结果：

```json
{
    "status": "0x0",
    "output": {
        "function": "get()",
        "result": ["Alice"]
    }
}
```

其中`output.result`字段中包含了`get`方法的返回值。可以看到，`get`方法返回了字符串“Alice”。
