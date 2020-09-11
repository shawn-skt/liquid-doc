# 基本开发流程

本节主要介绍Liquid合约的开发生命周期，涵盖合约的创建、测试、构建、部署及调用。

## 创建合约

当您进入到您的工作目录后，您就可以开始着手创建您的合约了。在命令行中执行以下命令：

```bash
cargo liquid new hello_world
```

`cargo liquid`是调用命令行工具`cargo-liquid`的另一种记法，这种记法有使得`liquid`看上去像是`cargo`子命令的效果。上述命令将会在当前目录下新建一个名为“hello_world”的项目，您此时应该能够看到当面目录下多出来一个名为“hello_world”的目录：

```bash
cd ./hello_world
```

此时hello_world项目内的目录结构如下所示：

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

从上往下依次介绍各个文件的作用：

1. `.gitignore`：隐藏文件，用于在告诉Git哪些文件或目录不需要被添加到版本管理中。Liquid会默认将某些项目排除在版本管理之外，如果您不需要使用到Git，可以忽略该文件。
2. `.liquid\`：隐藏目录，用于实现Liquid的某些内部功能，其中`abi_gen`目录下包含了ABI生成器的实现，该目录下的编译配置及代码逻辑是固定的，您不应当修改该目录下的任何文件，否则可能会造成ABI生成出错。
3. `Cargo.toml`：项目元信息，主要包括项目信息、外部包依赖、编译配置等，一般而言您无需修改该文件，除非您有特殊得需求等（引用新的第三方库、调整优化等级）。
4. `lib.rs`：Liquid合约源代码，您可以在此文件中进行Liquid合约的开发。

当执行`cargo liquid new`命令时，Liquid会以我们之前介绍过的`HelloWorld`合约为模板创建新的项目，因此创建出的`lib.rs`文件中包含了`HelloWorld`合约的代码实现，以及大量的解释每个程序语句的目的及功能的注释，这是一个能直接编译运行的“最简单”的合约。`HelloWorld`合约我们学习Liquid的起点，随着学习的深入，我们可以基于它开发出功能更为强大的合约！

本节更加关注Liquid合约的开发步骤，因此接下来都我们将围绕这个自动生成的`HelloWorld`合约进行讲解:)

## 测试合约

在`HelloWorld`合约代码的底部，我们为`HelloWorld`合约撰写了了两个分别检验`get`方法与`set`方法功能正确性的基本单元测试。Liquid内置了对区块链链上环境的模拟，因此即使不将合约部署上链，我们也能够在本地方便地执行合约并观察合约的运行状态，仿佛合约真的已经部署在链上一般。在`hello_world`目录下执行以下命令便可快速执行单元测试：

```bash
cargo +nightly test
```

```eval_rst
.. admonition:: 注意

   上述命令与创建合约项目时的命令有两点不同：1、命令中**并不**包含``liquid``字样，因为我们使用的是标准cargo单元测试框架来执行单元测试，因此不需要执行``cargo-liquid``；2、执行时需要加上``+nightly``选项以启动nightly版本的rust工具链。这些差别在构建合约的命令中也存在，因此请务必注意。
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

从结果上看，我们通过了所有的单元测试，因此我们可以很有信心地认为我们的合约逻辑是正确无误的！我们接下来可以开始着手构建`HelloWorld`合约，并把它部署到真正的区块链上。

## 构建合约

构建合约的目的是将合约编译为能在区块链上运行的Wasm格式字节码。在命令行中执行以下命令构建合约：

```bash
cargo +nightly liquid build
```

该命令会引导编译器以`wasm32`为目标编译合约并生成合约的ABI。执行完成后，命令行中会显示以下内容：

```bash
Your contract is ready:
  binary: <your working root directory>\hello_world\target\hello_world.wasm
  ABI : <your working root directory>\hello_world\target\hello_world.abi
```

`hello_world`项目下的`target`目录中回包含一个同名的`.wasm`文件及`.abi`文件，分别存放了合约字节码及ABI。其中合约ABI文件的内容如下：

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

## 部署合约

使用Node.js SDK CLI工具提供的`deployWasm`命令，我们可以将编译出的合约字节码部署至真实的区块链上，`deployWasm`命令的使用方式如下：

```bash
cli.js deployWasm <bin> <abi> [parameters...]

Deploy a contract written in Wasm

Positionals:
  bin         The path of then Wasm contract                    [string] [required]
  abi         The path of the corresponding ABI file            [string] [required]
  parameters  The parameters(splitted by space) of constructor  [array] [default: []]
```

执行该命令时需要依次传入字节码文件的路径、ABI文件的路径及构造函数的参数。当配置好CLI工具后（见[配置手册](https://github.com/FISCO-BCOS/nodejs-sdk#22-%E9%85%8D%E7%BD%AE)，我们可以使用以下命令部署`HelloWorld`合约（其构造函数参数为空，因此我们在命令中没有提供任何构造函数参数）：

```bash
node .\cli.js deployWasm <your working root directory>\hello_world\target\hello_world.wasm <your working root directory>\hello_world\target\hello_world.abi
```

部署成功后，命令返回如下结果：

```json
{
  "status": "0x0",
  "contractAddress": "0x039ced1cd5bea5ace04de8e74c66e312ba4a48af",
  "transactionHash": "0xf84811a5c7a5d3a4452a65e6929a49e69d9a55a0f03b5a03a3e8956f80e9ff41"
}
```

其中包含状态码、合约地址及交易哈希。

## 调用合约

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

执行该命令时需要依次传入合约名（对于Liquid合约，是合约项目名）、合约地址、要调用的合约方法名及传递给合约方法的参数。以调用`HelloWorld`合约的`get`方法为例，我们可以使用以下命令调用该方法（其方法参数为空，因此我们在命令中没有提供任何方法参数）：

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
      "Hello, Alice!"
    ]
  }
}
```

其中`output.result`字段中包含了`get`方法的返回值。可以看到，正如我们所预期的那样，`get`方法返回了字符串`"Hello, Alice!"`。
