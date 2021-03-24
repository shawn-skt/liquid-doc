# 权利

## 语法概述

在 PDC 中，合同权利的具象体现是⼀段基于合同内容的可执行代码，可用于修改合同状态、创建新的合同等。当某个参与⽅能够行使某项权利时，即意味着该参与方拥有执行这段代码的权限。所有权利的定义均需要放在与合同模板相关联的`impl`代码块中，同时使用`#[liquid(rights)]`属性对该代码块进行标注，例如在下列代码中，定义了一项名为`add`的权利：

```eval_rst
.. code-block:: rust
   :linenos:
   :emphasize-lines: 1, 3

   #[liquid(contract)]
   pub struct Ballot {
       #[liquid(signers)]
       government: address,
       #[liquid(signers = "$[..](?@.voted).addr")]
       voters: Vec<Voter>,
       proposal: Proposal,
   }

   #[liquid(rights)]
   impl Ballot {
       #[liquid(belongs_to = "government")]
       pub fn add(mut self, voter_addr: address) -> ContractId<Ballot> {
           ...
       }
   }
```

被`#[liquid(rights)]`属性标注的代码块中，每一项代表权利的函数的可见性必须为`pub`，即所有权利都需对外可见。若需要编写无需公开的辅助函数，则可以将辅助函数的定义放置于另一个普通的`impl`代码块中，或直接放置于`impl`代码块之外，例如：

```eval_rst
.. code-block:: rust
   :linenos:

   #[liquid(rights)]
   impl Ballot {
       ...
   }

   impl Ballot {
       fn helper_1(&self) {
           ...
       }
   }

   fn helper_2() {
       ...
   }
```

每项权利必须要使用`#[liquid(belongs_to)]`属性标注此项权利属于哪些参与方。权利的所属所属方的账户地址必须包含在合同内容中，例如在上述示例中，名为`add`的权利属于合同中的`government`成员。所属方后可跟随一个由花体括号`{}`括起的选择器，其语法与上节中的[对象选择器](./selector.md)及[函数选择器](./selector.md)相同。例如，若需要将`add`权利分配给所有的投票者，即`voters`中所有投票者的账户地址，则上述示例可以改写为：

```eval_rst
.. code-block:: rust
   :linenos:
   :emphasize-lines: 1

   #[liquid(belongs_to = "voters{ $[..].addr }")]
   pub fn add(mut self, voter_addr: address) -> ContractId<Ballot> {
       ...
   }
```

由于所有的权利都需要基于具体的合同执行，因此权利的第一项参数必须是接收器（Receiver），用于和具体的合同进行绑定。接收器可以为下列四种之一：

-   `self`，以只读的方式访问当前合同，不能修改合同中的内容，并且在权利行使完毕后，作废当前合同；

-   `mut self`，以可写的方式访问当前合同，可以修改合同中的内容，并且在权利行使完毕后，作废当前合同；

-   `&self`，以只读的方式访问当前合同，不能修改合同中的内容。权利行使完毕后，不会作废当前合同；

-   `&mut self`，以可写的方式访问当前合同，可以修改合同中的内容。权利行使完毕后，不会作废当前合同。

作废合同意味着之后不能再基于该合同继续行使权利，但是与该合同相关的数据并不会从链上删除，其`contractId`也不会被废弃，可以继续用于查询合同中的内容。在某些领域，作废机制也被称作“归档”，因为虽然不能再继续行权，但是合同内容仍会作为存证保留在区块链中，可供日后取证所用。作废机制在由旧合同生成新合同时比较有用，能够用于避免产生重复的新合同。例如，在[完整的投票协作](https://gitee.com/WebankBlockchain/liquid/blob/dev/examples/collaboration/voting/src/lib.rs)中，`government`被授予根据已投票的提案中产生出一项新决议的权利，如下列代码所示，用于执行此功能的`decide`权利的接收器是`self`，因此在行权完毕后，原始的提案将会被作废，从而避免产生重复的决议（代码中的`sign!`宏及`ContractId`类型将在下一节中进行详细解释。）：

```eval_rst
.. code-block:: rust
   :linenos:

   #[liquid(rights)]
   impl Ballot {
       ...

       #[liquid(belongs_to = "government")]
       pub fn decide(self) -> ContractId<Decision> {
           require(
               self.voters.iter().all(|voter| voter.voted),
               "all voters must vote",
           );

           let yays = self.voters.iter().filter(|v| v.choice).count();
           let nays = self.voters.iter().filter(|v| !v.choice).count();
           require(yays != nays, "cannot decide on tie");

           let accept = yays > nays;
           let voters = self.voters.iter().map(|voter| voter.addr).collect();
           sign! { Decision =>
               accept,
               government: self.government,
               proposal: self.proposal,
               voters,
           }
       }
   }
```

当多项权利的所属方相同时，若为每项权利标注同样的`#[liquid(belongs_to)]`属性会导致代码稍显冗余，因此 Liquid 提供了另一种简便的属性`#[liquid(rights_belong_to)]`。该属性用于标注`impl`代码块，但是与`#[liquid(belongs_to)]`属性类似，需要被赋予一个用于指定权利所属方的字符串参数，用于表示该`impl`代码块中定义的所有权利均归属于这些所属方。属性参数中同样也可以使用选择器语法。当使用`#[liquid(rights_belong_to)]`属性后，`impl`代码块内部的函数均不允许再被标注`#[liquid(belongs_to)]`属性。在下列示例代码中，`government`同时拥有`add`及`decide`权利：

```eval_rst
.. code-block:: rust
   :linenos:

   #[liquid(rights_belong_to = "government")]
   impl Ballot {
       pub fn add(mut self, voter_addr: address) -> ContractId<Ballot> {
           ...
       }

       pub fn decide(self) -> ContractId<Decision> {
           ...
       }
   }
```

表示权利所属方的字符串也可以是空字符串，此时表示任何实体均可以行使该权利，例如：

```eval_rst
.. code-block:: rust
   :linenos:

   #[liquid(belongs_to = "")]
   pub fn vote(&mut self, choice: bool) {
       ...
   }
```

## 行权

可以通过 Node.js CLI 工具的`exercise`命令行使合同中的权利，`exercise`命令的使用方式如下所示，在使用时需要传递合同模板名称、合同 ID、权利名称以及行使权利时所需要参数：

```
cli.js exec exercise <contract> <rightName> [parameters..]

Exercise an right of a contract

Positionals:
  contract    The name and ID(split by `#`) of the exercised contract
                                                             [string] [required]
  rightName   The name of the exercised right                [string] [required]
  parameters  The parameters(split by space) of the contract
                                                           [array] [default: []]

Options:
  --version   Show version number                                      [boolean]
  --who, -w   Who will do this operation                                [string]
  -h, --help  Show help                                                [boolean]
```

假设`government`的账户地址是 Alice（0x144d5ca47de35194b019b6f11a56028b964585c9），Alice 可以首选签署一份投票者列表为空的提案合同：

```shell
node ./cli.js exec sign Ballot 0x144d5ca47de35194b019b6f11a56028b964585c9 [] '{\"proposer\":\"0x144d5ca47de35194b019b6f11a56028b96458\",\"content\":\"Playing\"}' --who alice
```

返回结果如下所示：

```json
{
    "status": "0x0",
    "contractId": 0,
    "transactionHash": "0x13c11b0d2e4907962d2dde5e09d8c1632fcb414c5a71f3195a86125f258f137e"
}
```

随后，Alice 通过行使`add`权利将 Bob（0x3b1b0b74801e104543ef05ed88cc215eb4e51d72）及 Charlie（0x1653641673a6f5eaebfcea9137b91407e7c86c35）添加至投票列表中：

```shell
node ./cli.js exec exercise Ballot#0 add 0x3b1b0b74801e104543ef05ed88cc215eb4e51d72 --who alice
node ./cli.js exec exercise Ballot#1 add 0x1653641673a6f5eaebfcea9137b91407e7c86c35 --who alice
```

注意命令中`Ballot`的合约 ID 在不断自增，这是由于根据`add`权利的定义，其会作废当前提案合同并生成一份新的提案合同，然后返回新提案合同的合同 ID。如果在 ID 为 0 的提案合同作废后继续在其上行使权利，则会导致如下所示的报错：

```
{
  "status": "0x16",
  "message": "the contract `Ballot` with id `0` had been abolished already",
  "transactionHash": "0xf0b8dfbe2d0bba0f40280d3b502d572787a0580d861070c5ce1916e7b009f57c"
}
```

但是在 ID 为 0 的提案合同作废后仍然可以查询其合同内容：

```shell
node ./cli.js exec fetch Ballot#0
```

返回结果如下所示：

```json
{
    "status": "0x0",
    "Ballot": {
        "government": "0x144d5ca47de35194b019b6f11a56028b964585c9",
        "voters": [],
        "proposal": {
            "proposer": "0x000144d5ca47de35194b019b6f11a56028b96458",
            "content": "Playing"
        }
    },
    "transactionHash": "0xdf7418f3c5bb6a569d1c1cb9f1e522865ab179927a6eb14fe202ed6303786e5b"
}
```

可以看出截至作废时，投票者列表仍然为空，因此新的投票者已经被加入至 ID 为 1 的提案合同中。

在 Bob 及 Charlie 投赞成票之后，Alice 可以行使`decide`权利以产生新的决议合同：

```shell
node ./cli.js exec exercise Ballot#2 decide --who alice
```

根据`decide`权利的定义，行权完毕后应当返回`Decision`合同的 ID：

```json
{
    "status": "0x0",
    "outputs": [1],
    "transactionHash": "0xb0cb7c048afc09083841bc49eb918648a91742fd1f4dffe1876144b8d38e2ca9"
}
```

```shell
node ./cli.js exec fetch Decision#1
```

返回结果如下所示，包含了合同 ID 为 1 的决议合同中的内容：

```json
{
    "status": "0x0",
    "Decision": {
        "government": "0x144d5ca47de35194b019b6f11a56028b964585c9",
        "proposal": {
            "proposer": "0x000144d5ca47de35194b019b6f11a56028b96458",
            "content": "Playing"
        },
        "voters": [
            "0x3b1b0b74801e104543ef05ed88cc215eb4e51d72",
            "0x1653641673a6f5eaebfcea9137b91407e7c86c35"
        ],
        "accept": true
    },
    "transactionHash": "0xe10cdc052fa4121c2fc52f5a135a5fb7821303b67bee0a814f4f8a7f37731384"
}
```

Liquid 在行权时会自动校验行权的发起方是否拥有行权的资格，假如在上述最后一步中，Bob 试图代替 Alice 行使`decide`权利：

```shell
node ./cli.js exec exercise Ballot#2 decide --who bob
```

则会导致执行失败，并报出权限校验不通过错误：

```json
{
    "status": "0x16",
    "message": "exercising right `decide` of contract `Ballot` is not permitted",
    "transactionHash": "0x40c167383c748c3d2bbc86bbe4186a6051294815fa3d1a02d5e03e7df6d44a36"
}
```
