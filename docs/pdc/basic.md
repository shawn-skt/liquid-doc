# 基本结构

## 协作

可在终端中执行以下命令调用`cargo-liquid`创建协作项目，其中最后一个参数可以替换为实际的项目名称：

```eval_rst
.. code-block:: shell
   :linenos:

   cargo liquid new collaboration voting
```

与普通合约的开发类似，所有代码可以组织在项目根目录下的`lib.rs`文件中。用于构建协作的各组成部分（如合约、权利等）的定义均需要放置于一个由`#[liquid(collaboration)]`属性标注的`mod`代码块内部，如下列代码所示：

```eval_rst
.. code-block:: rust
   :linenos:
   :emphasize-lines: 1

   #[liquid::collaboration]
   mod voting {
       ...
   }
```

```eval_rst
.. admonition:: 注意

   由于协作与普通合约的内部实现方式与运行机制存在差异，因此协作与普通合约不能够在同一项目中共存，即 ``#[liquid::collaboration]`` 与 ``#[liquid::contract]`` 属性标注的 ``mod`` 代码块不能出现在同一个项目的代码文件中。
```

## 合同模板

合同模板同于定义合同中能够包含的数据内容，以及哪些实体能够创建对应的合同。合同模板中的内容需要放置于有`#[liquid(contract)]`属性标注的`struct`代码块中。在合同模板中能够使用复杂的复合类型，如结构体、枚举等，但是这些类型必须派生自`liquid_lang`库中的`InOut`属性，如下列代码所示：

```eval_rst
.. code-block:: rust
   :linenos:
   :emphasize-lines: 3,9


   use liquid_lang::InOut;

   #[derive(InOut)]
   pub struct Proposal {
       proposer: Address,
       content: String,
   }

   #[liquid(contract)]
   pub struct Decision {
       #[liquid(signers)]
       government: Address,
       proposal: Proposal,
       #[liquid(signers)]
       voters: Vec<Address>,
       accept: bool,
   }
```

合同模板的定义中**不允许为各个成员指定可见性**。在当前的实现中，合同中所有的数据内容均为公开可见。在未来，Liquid 会引入隐私保护技术，能够根据各个参与方的角色分配自动处理合同数据访问过程中可见性及权限管理。

在一个协作中，**能够包含多个合同模板的定义**。此外，如下列代码所示，合同模板也可以像普通类型一般用作变量、结构体成员、函数参数或返回值的类型。但需要注意的是，在运行过程中创建与合同模板同类型的临时变量并不意味着进行了合同签署，此时的合同模板类型仅具有“聚合其他数据类型”的意义：

```eval_rst
.. code-block:: rust
   :linenos:

   ...
   let decision: Decision = Decision {
      government,
      proposal,
      voters,
      accept
   };
```

协作中，被`#[liquid(contract)]`属性标注的`struct`代码块中的类型名称会用作合同模板的名称。合同模板名称要求在链的维度全局唯一，若试图部署与已有合同模板重名的合同模板，则会导致部署失败。

## 签署方

与现实中类似，签署方经过协商达成一致后，能够基于合同模板签署生成有效的合同。代表签署方的具体账户地址需要包含于合同的数据内容中，因此需要在合同模板的定义中指定签署方位于哪些成员变量中。可以通过在合同模板的成员定义前标注`#[liquid(signers)]`属性，表示该成员中包含了签署方的账户地址，如下列代码所示：

```eval_rst
.. code-block:: rust
   :linenos:
   :emphasize-lines: 3,6

   #[liquid(contract)]
   pub struct Decision {
       #[liquid(signers)]
       government: Address,
       proposal: Proposal,
       #[liquid(signers)]
       voters: Vec<Address>,
       accept: bool,
   }
```

被`#[liquid(signers)]`属性标注的成员的数据类型`T`需要满足下列要求之一：

-   `T`为`Address`类型；
-   `T`是一个集合类型（如`Vec`、`HashMap`等），但是`&'a T`类型必须实现了`IntoIterator<Item = &'a Address>`特性，其中`a`为对应成员变量的生命周期。

在上述代码示例中，`government`成员的数据类型是`Address`类型，因此可以用于定义签署方；同理，`voters`的类型是元素类型为`Address`的动态数组，但是标准库中为`&'a Vec<Address>`实现了`IntoIterator<Item = &'a Address>`特性，因此可以同样被用于定义签署方。

```eval_rst
.. note::

   在 `选择器 <./selector.html>`_ 一节中，我们会介绍如何使用选择器从合同模板的成员中“选出”签署方的账户地址。在使用选择器时，成员的数据类型并不一定需要满足上述要求，但是被选数据的类型依然需要满足上述要求。
```

```eval_rst
.. note::

   ``#[liquid(signers)]`` 属性中 ``signers`` 可以理解为一个包含所有签署方账户地址的集合，使用该属性对成员进行标注时，意即“将该成员中所包含的账户地址加入至 ``signers`` 集合中。”
```

**签署合同时，要求至少有一个有效的签署⽅**。此项要求会在编译期进⾏检查，因此合同模板的定义至中少需要有一个成员被`#[liquid(signers)]`属性标注。同时，由于存在被标注成员中不包含任何有效签署方的情况，例如成员是一个集合类型但是签署时集合为空，因此此项要求也会在实际签署合同时再次进行检查。

当合同模板中包含另一个合同模板时，可以通过指定`signers`为`inherited`来继承被包含合同模板的签署方定义，例如：

```eval_rst
.. code-block:: rust
   :linenos:
   :emphasize-lines: 9

   #[liquid(contract)]
   pub struct Foo {
       #[liquid(signers)]
       addr: Address,
   }

   #[liquid(contract)]
   pub struct Bar {
       #[liquid(signers = inherited)]
       foo: Foo,
   }
```

此时`Bar`合同签署方的账户地址位于成员“foo”的“addr”字段中。

## 部署

协作的构建方式与普通合约的构建方式相同，在项目根目录执行`cargo liquid build`命令后（可以根据需求添加`-g`选项），便会在项目根目录下的`target`目录中生成协作的 Wasm 格式字节码及 ABI 文件。协作需要通过 Node.js CLI 工具的`initialize`命令部署至链上：

```
node ./cli.js exec initialize C:/Users/liche/voting/target/voting.wasm C:/Users/liche/voting/target/voting.abi
```

由于部署过程中需要访问[CNS 服务](https://fisco-bcos-doc.readthedocs.io/zh_CN/latest/docs/articles/3_features/35_contract/contract_name_service.html?highlight=%E5%90%88%E7%BA%A6%E5%91%BD%E5%90%8D%E6%9C%8D%E5%8A%A1)，因此需要使用拥有 CNS 服务访问权限的账户执行部署过程。可以通过`--who`或`-w`选项指定执行`initialize`命令的账户名，若不提供则默认使用配置文件中`accounts`配置项下的首个账户。

随后，可以通过`sign`命令签署合同，`sign`命令的使用方式如下所示：

```
cli.js exec sign <contractName> [parameters..]

Sign a contract

Positionals:
  contractName  The name of the contract                     [string] [required]
  parameters    The parameters(split by space) of the contract
                                                           [array] [default: []]

Options:
  --version   Show version number                                      [boolean]
  --who, -w   Who will do this operation                                [string]
  -h, --help  Show help                                                [boolean]
```

签署时，需要提供合同模板的名称及合同的数据内容，同样也可以通过`--who`或`-w`选项指定执行`sign`命令的账户名，若不提供则默认使用配置文件中`accounts`配置项下的首个账户。其中，合同内容需要以空格分割的形式，逐项提供合同模板中各个成员的值。例如，以签署一份`voters`成员为空数组的 Decision 合同为例：

```node
node ./cli.js exec sign Decision 0x144d5ca47de35194b019b6f11a56028b964585c9 '{\"proposer\":\"0x144d5ca47de35194b019b6f11a56028b96458\",\"content\":\"Playing\"}' [] true
```

正常情况下，执行结果如下所示：

```json
{
    "status": "0x0",
    "contractId": 0,
    "transactionHash": "0x31fa4a1fb42258c12eb5328903914bd215adb3e36212662e93fe7ee1a5e8c120"
}
```

可以看到结果中除了表示交易状态及哈希值的`status`及`transactionHash`字段外，还多了一个名为`contractId`（合同 ID）的字段，这是由于基于同一份合同模板可以执行多次签署，每次签署都将会实例化出一份新的合同，并使用唯一的合同 ID 进行标识。实现上，对于同类型的合同，合同 ID 是一个从 0 开始单调递增的整数。通过合同模板的名称及合同 ID，便能定位到具体的合同以执行行权、查询等功能，例如，若想查询刚刚签署的 `Decision` 合同中的内容，我们可以执行如下命令：

```
node ./cli.js exec fetch Decision#0
```

命令中的“Decision#0”即表示合同 ID 为 0 的 Decision 合同。正常情况下，执行结果如下所示：

```json
{
    "status": "0x0",
    "Decision": {
        "government": "0x144d5ca47de35194b019b6f11a56028b964585c9",
        "proposal": {
            "proposer": "0x000144d5ca47de35194b019b6f11a56028b96458",
            "content": "Playing"
        },
        "voters": [],
        "accept": true
    },
    "transactionHash": "0x4cf410d14004cc713c959c8639a263a86311f688f89c80589b7f33aff99b6632"
}
```
