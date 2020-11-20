# 基本开发流程

本节主要介绍Liquid项目的开发生命周期，涵盖项目的创建、测试、构建、部署及调用。

## 新建项目

在命令行中执行以下命令创建Liquid项目：

```bash
cargo liquid new hello_world
```

`cargo liquid`是调用命令行工具`cargo-liquid`的另一种写法，这种记法使得`liquid`看上去像是`cargo`子命令。上述命令将会在当前目录下新建一个名为hello_world的项目，您此时应该能够看到当面目录下新生成了一个名为hello_world的目录：

```bash
cd ./hello_world
```

hello_world项目内的目录结构如下所示：

```bash
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

1. `.gitignore`：隐藏文件，用于在告诉Git哪些文件或目录不需要被添加到版本管理中。Liquid会默认将某些项目（如临时文件等）排除在版本管理之外，如果您不使用Git管理您的项目版本，可以忽略该文件；
2. `.liquid\`：隐藏目录，用于实现Liquid的某些内部功能，其中`abi_gen`目录下包含了ABI生成器的实现，该目录下的编译配置及代码逻辑是固定的，您不需要也不应该修改该目录下的任何文件，否则可能会造成ABI生成出错；
3. `Cargo.toml`：项目配置清单，主要包括项目信息、外部库依赖、编译配置等，一般而言您无需修改该文件，除非您有特殊的需求（引用额外的第三方库、调整优化等级等）；
4. `lib.rs`：Liquid项目根文件。

当执行`cargo liquid new`命令时，Liquid会以上一节中介绍的Hello World合约为模板创建新的项目，因此创建出的`lib.rs`文件中包含了Hello World合约的代码实现，这是一个能立即编译运行的最简Liquid项目。尽管简单，但Hello World合约仍然是我们学习Liquid的起点，接下来我们将主要使用它来对Liquid项目的开发过程进行讲解。

## 测试

在Hello World合约代码的底部，我们为Hello World合约编写了两个分别用于检查`get`方法与`set`方法功能正确性的单元测试用例。Liquid内置了对区块链链上环境的模拟，因此即使不将项目部署上链，我们也能够在本地方便地执行单元测试。在hello_world目录下执行以下命令可快速执行单元测试：

```bash
cargo +nightly test
```

```eval_rst
.. admonition:: 注意

   上述命令与创建合约项目时的命令有两点不同：1、命令中并不包含liquid子命令，因为Liquid使用标准cargo单元测试框架来执行单元测试，因此不需要调用cargo-liquid；2、执行时需要加上“+nightly”选项以启用nightly版本的Rust编译工具。这些差别在构建合约的命令中也存在，因此请务必注意。
```

执行结束后，命令行中显示如下内容：

```bash
running 2 tests
test hello_world::tests::set_works ... ok
test hello_world::tests::get_works ... ok

test result: ok. 2 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out

   Doc-tests hello_world

running 0 tests

test result: ok. 0 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out
```

从结果中可以看出，我们通过了所有的单元测试，因此我们可以有信心地认为合约的实现逻辑是符合预期的。我们接下来可以开始着手构建Hello World合约项目，并把它部署到真正的区块链上。

## 构建

构建的目的是将Liquid项目编译为能在区块链系统上运行的Wasm格式字节码。在命令行中执行以下命令构建Liquid项目：

```bash
cargo +nightly liquid build
```

该命令会引导编译器以`wasm32`为目标编译项目并生成ABI。命令执行完成后，命令行中会显示以下内容：

```bash
:-) Done in 35 seconds, your contract is ready now:
Binary: <path>\hello_world\target\hello_world.wasm
ABI: <path>\hello_world\target\hello_world.abi
```

hello_world项目下的target目录中回包含一个同名的`.wasm`文件及`.abi`文件，分别存放了Hello World合约的字节码及ABI，其中ABI文件的内容如下：

```json
[
    {
        "inputs":[

        ],
        "payable":false,
        "stateMutability":"nonpayable",
        "type":"constructor"
    },
    {
        "constant":true,
        "inputs":[

        ],
        "name":"get",
        "outputs":[
            {
                "name":"",
                "type":"string"
            }
        ],
        "payable":false,
        "stateMutability":"view",
        "type":"function"
    },
    {
        "constant":false,
        "inputs":[
            {
                "name":"name",
                "type":"string"
            }
        ],
        "name":"set",
        "outputs":[

        ],
        "payable":false,
        "stateMutability":"nonpayable",
        "type":"function"
    }
]
```

```eval_rst
.. admonition:: 注意

   如果您希望构建出的Wasm格式字节码能够在国密版FISCO BCOS区块链节点上运行，请在使用构建命令时添加-g选项。
```

## 部署

使用Node.js SDK CLI工具提供的`deployWasm`命令，我们可以将编译出的Hello World合约字节码部署至实际的区块链系统中，`deployWasm`命令的使用方式如下：

```bash
cli.js deployWasm <bin> <abi> [parameters...]

Deploy a contract written in Wasm

Positionals:
  bin         The path of then Wasm contract                    [string] [required]
  abi         The path of the corresponding ABI file            [string] [required]
  parameters  The parameters(splitted by space) of constructor  [array] [default: []]
```

执行该命令时需要依次传入字节码文件的路径、ABI文件的路径及构造函数的参数。当配置好CLI工具后（见[配置手册](https://github.com/FISCO-BCOS/nodejs-sdk#22-%E9%85%8D%E7%BD%AE)，我们可以使用以下命令部署HelloWorld合约（其构造函数参数为空，因此我们在命令中没有提供任何构造函数参数）：

```bash
node .\cli.js deployWasm <path of hello_word.wasm> <path of hello_world.abi>
```

部署成功后，返回格式如下结果，其中包含状态码、合约地址及交易哈希：

```json
{
  "status": "0x0",
  "contractAddress": "0x039ced1cd5bea5ace04de8e74c66e312ba4a48af",
  "transactionHash": "0xf84811a5c7a5d3a4452a65e6929a49e69d9a55a0f03b5a03a3e8956f80e9ff41"
}
```

## 调用

使用Node.js SDK CLI工具提供的`call`命令，我们可以调用已被部署到区块链上的智能合约，`call`命令的使用方式如下：

```bash
cli.js call <contractName> <contractAddress> <function> [parameters...]

Call a contract by a function and parameters

Positionals:
  contractName     The name of a contract                           [string] [required]
  contractAddress  20 Bytes - The address of a contract             [string] [required]
  function         The function of a contract                       [string] [required]
  parameters       The parameters(splitted by space) of a function  [array] [default: []]
```

执行该命令时需要依次传入合约名（对于Liquid合约，是合约项目名）、合约地址、要调用的合约方法名及传递给合约方法的参数。以调用Hello World合约的`get`方法为例，我们可以使用以下命令调用该方法（其方法参数为空，因此我们在命令中不提供任何方法参数）：

```bash
node .\cli.js call hello_world 0x039ced1cd5bea5ace04de8e74c66e312ba4a48af get
```

命令返回的结果如下：

```json
{
  "status": "0x0",
  "output": {
    "function": "get()",
    "result": [
      "Alice"
    ]
  }
}
```

其中`output.result`字段中包含了`get`方法的返回值。可以看到，正如我们所预期的那样，`get`方法返回了字符串“Alice”。
