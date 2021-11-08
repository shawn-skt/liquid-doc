# 权限模型

PDC 最重要的使命是在分布式环境中，确保所有参与协作的参与方遵循合同中所确定的权利与义务的分配，任何实体均不能游走于规则之外。隐藏在 PDC 背后的权限模型是实现这一目标的重要保障，本节将通过实例逐步讲解 PDC 中权限模型的设计，以及如何基于权限模型设计多方协作工作流。

## 问题起源

在之前的章节中，我们简要介绍了 IOU 的概念，在此我们先给出 IOU 合同模板的简单实现：

```eval_rst
.. code-block:: rust
   :linenos:

   #[liquid::collaboration]
   mod iou {
       #[liquid(contract)]
       pub struct SimpleIou {
           #[liquid(signers)]
           issuer: Address,
           owner: Address,
           cash: u32,
       }
   }
```

在`SimpleIou`中，借据的发行方`issuer`是唯一的签署方，即只需要`issuer`的授权即可签署。可以使用如下形式的测试代码展示如何在 Alice（发行方） 与 Bob（所属方） 之间创建价值为 100 元的简单借据：

```eval_rst
.. code-block:: rust
   :linenos:

   // 在之后的示例中将省略Alice与Bob的账户地址分配
   let alice = default_accounts.alice;
   let bob = default_accounts.bob;

   test::set_caller(alice);
   let iou = sign! { SimpleIou =>
       issuer: alice,
       owner: bob,
       cash: 100
   };
   test::pop_execution_context();
```

上述过程最大的问题是，整个流程并没有 Bob 的参与。当借据合同正式在链上生成记录后，Bob 完全可以对借据的内容进行否认，譬如 Bob 可以坚称对于签署借据合同一事并不知情，Alice 实际上欠自己更多。在这种情况下，借据合同将完全失去其应有的效力。在现实商业逻辑中，只有参与方对合同内容取得一致性共识后，合同才能够对各方的行为进行有效的规约。因此，为修复上述问题，我们需要借据的所属方也加入至签署方集合中，即只有当发行方及签署方同时知晓合同内容并授权后，才能签署借据合同：

```eval_rst
.. code-block:: rust
   :linenos:

   #[liquid::collaboration]
   mod iou {
       #[liquid(contract)]
       pub struct Iou {
           #[liquid(signers)]
           issuer: Address,
           #[liquid(signers)]
           owner: Address,
           cash: u32,
       }

       #[liquid(rights_belong_to = "owner")]
       impl Iou {
           pub fn transfer(self, new_owner: Address) -> ContractId<Iou> {
               assert!(self.owner != new_owner);
               sign! { Iou =>
                   owner: new_owner,
                   ..self
               }
           }
       }
   }
```

然而这种方案所面临的问题是，由于每笔交易只能由一个账户地址主动发起，即每笔交易只能反映出仅有一个账户地址对交易中的行为进行了授权，因而 Alice 与 Bob 无法同时授权签署借据合同：

<div class="wrong-example">

```eval_rst
.. code-block:: rust
   :linenos:
   :emphasize-lines: 2-7,18-19

   test::set_caller(alice);
   // Fail to sign due to the lack of Bob's authorization.
   let iou = sign! { Iou =>
       issuer: alice,
       owner: bob,
       cash: 100,
   };
   test::pop_execution_context();

   // Alice issues an Iou to herself.
   test::set_caller(alice);
   let iou = sign! { Iou =>
       issuer: alice,
       owner: alice,
       cash: 100,
   };

   // But she still can't transfer it to Bob.
   let iou = iou.transfer(bob);
   test::pop_execution_context();
```

</div>

针对这些问题，我们将使用巧妙的工作流机制予以解决。

## 提议模式

如果 Alice 与 Bob 之间没有长期合作关系，Alice 可以向 Bob 发起一个提议合同，提议合同内容为：Alice 向 Bob 发行价值为 100 元的借据，并在合同中给予 Bob 接受的权利。提议合同的模板定义如下列代码所示：

```eval_rst
.. code-block:: rust
   :linenos:

   #[liquid::collaboration]
   mod iou {
       #[liquid(contract)]
       pub struct IouProposal {
           #[liquid(signers = "$.issuer")]
           iou: Iou,
       }

       #[liquid(rights_belong_to = "iou {$.owner}")]
       impl IouProposal {
           pub fn accept(self) -> ContractId<Iou> {
               sign! { Iou =>
                   ..self.iou
               }
           }
       }
   }
```

在上述代码中，由于合同模板`Iou`自身也是一个普通的结构体类型，因此可以用于`IouProposal`合约模板中成员类型定义。`IouProposal`合约模板中只有一个`iou`成员，即 Alice 向 Bob 提议的借据合同中的内容，根据选择器语法，签署`IouProposal`合同只需要提议中的`issuer`授权即可，因此 Alice 能够首先发起提议：

```eval_rst
.. code-block:: rust
   :linenos:

   test::set_caller(alice);
   let proposal  = sign! { IouProposal =>
       iou: Iou {
           issuer: alice,
           owner: bob,
           cash: 100,
       }
   };
   test::pop_execution_context();
```

随后，根据`IouProposal`合同模板的定义，Bob 有资格行使其`accept`权利，若 Bob 选择行使`accept`权利，则能够成功创建出同时包含 Alice 与 Bob 授权的借据合同：

```eval_rst
.. code-block:: rust
   :linenos:

   test::set_caller(bob);
   let iou = proposal.accept();
   test::pop_execution_context();
```

之所以能够成功创建，是由于 Alice 作为提议的发起方，她必然熟悉并认可借据合同中的内容。而 Bob 作为提议的接受方，也必定是在查看过提议内容并确认无误后才会选择主动接受，因此 Bob 选择行使`accept`权利就代表了他对提议内容同样认可。因此在收集到双方的认可后，借据合同被成功创建。同时也藉由此机制，确保了双方对合同内容均事先知情，因此具有无可辩驳的现实效力。若 Bob 对提议内容抱有怀疑，他直接选择不行使`accept`权利即可，此时链上只是多了一份提议合同的记录，但是对双方而言均没有任何损失。

在解决完借据发行的问题后，我们可以使用类似的方法解决所有权转移的问题。同发行问题一样，所有权的转移也同时需要新旧双方一致同意方可进行，我们可以设计如下列代码所示的提议合同模板：

```eval_rst
.. code-block:: rust
   :linenos:

   #[liquid::collaboration]
   mod iou {
       #[liquid(contract)]
       pub struct TransferProposal {
           #[liquid(signers = inherited)]
           iou: Iou
           new_owner: Address,
       }

       #[liquid(rights)]
       impl IouProposal {
           #[liquid(belongs_to = "iou {$.owner}")]
           pub fn cancel(self) {
               sign! { Iou =>
                   ..self.iou
               }
           }

           #[liquid(belongs_to = "new_owner")]
           pub fn accept(self) -> ContractId<Iou> {
               sign! { Iou =>
                   ..self.iou
               }
           }

           #[liquid(belongs_to = "new_owner")]
           pub fn reject(self) -> ContractId<Iou> {
               sign! { Iou =>
                   owner: self.new_owner,
                   ..self.iou
               }
           }
       }
   }
```

在上述合同模板中，定义了更为丰富的权利，使得双方能够对所有权的转移过程进行更多控制。例如在`new_owner`做出选择前，当前的`owner`能够有机会取消这笔交易。一般而言，提议类合同都需要定义`accept`、`reject`及`cancel`三项权利。为了能够使当前`owner`能够创建所有权转移的提议合同，`Iou`合同模板中需要增加如下权利定义：

```eval_rst
.. code-block:: rust
   :linenos:

   #[liquid(belongs_to = "owner")]
   pub fn propose_transfer(self, new_owner: Address) -> ContractId<TransferProposal> {
       assert!(self.owner != new_owner);
       sign! { TransferProposal =>
           iou: self,
           new_owner,
       }
   }
```

现在 Bob 便可以将他的借据合同的所有权转移至 Charlie ，甚至签署借据合同也可以通过`TransferProposal`实现，如下列代码所示：

```eval_rst
.. code-block:: rust
   :linenos:

   let charlie = default_accounts.charlie;

   // Alice issues an Iou using a transfer proposal.
   test::set_caller(alice);
   let proposal  = sign! { TransferProposal =>
       iou: Iou {
           issuer: alice,
           owner: alice,
           cash: 100,
       },
       new_owner: bob,
   };
   test::pop_execution_context();

   // Bob accepts the transfer from Alice.
   test::set_caller(bob);
   let iou = proposal.accept();
   test::pop_execution_context();

   // Bob offers Charlie a transfer.
   test::set_caller(bob);
   let proposal = iou.propose_transfer(charlie);
   test::pop_execution_context();

   // Charlie accepts the transfer from Bob.
   test::set_caller(charlie);
   let iou = proposal.accept();
   test::pop_execution_context();
```

## 角色合同模式

提议模式一般用于临时协作的场景中，如参与方之间需要长期合作，例如 Alice 需要持续向 Bob 转移借据所有权，则每次转移时都需要经历提议-接受的工作步骤，流程较为繁琐且需要双方随时在线。可以使用角色合同模式解决这一问题，将长期合作中双方的角色通过合同的形式固定下来。

提议模式的问题根源在于无论是提议或是接受的过程中，均只有单边参与。若双方能够同时参与到`transfer`权利的行使过程中，则能够直接同时获得双方的授权，进而创建出`Iou`合约，因此我们可以为`Iou`合同模板定义如下权利，要求行权时需要同时取得双方的授权：

```eval_rst
.. code-block:: rust
   :linenos:

   #[liquid(belongs_to = "owner, ^new_owner")]
   pub fn mutual_transfer(self, new_owner: Address) -> ContractId<Iou> {
       sign! { Iou =>
           owner: new_owner,
           ..self
       }
   }
```

注意在上述代码中，`#[liquid(belongs_to)]`属性中包含了两个权利所属方，而在之前的示例中权利所属方往往只有一个。实际上，通过逗号`,`将不同的参与方连接起来，权利的所属方能够扩展至任意多个。当有多个权利所属方时，需要这些所属方同时授权此能够行使该权利。此外，权利所属方中的`new_owner`并非来自于合同自身，而是直接来自于权利的参数，为了表示这种来源上的差异，`new_owner`之前有一个`^`。但是与之前的问题类似，如果直接行使该权利，则有且仅有一个所属方能够授权。因此这种权利无法直接行使，我们可以先定义一个名为`IouSender`角色合同模板，用于指定某个参与方负责转移借据所有权；

```eval_rst
.. code-block:: rust
   :linenos:

   #[liquid(contract)]
   pub struct IouSender {
       sender: Address,
       #[liquid(signers)]
       receiver: Address,
   }

   #[liquid(rights)]
   impl IouSender {
       #[liquid(belongs_to = "sender")]
       pub fn send_iou(&mut self, iou_id: ContractId<Iou>) -> ContractId<Iou> {
           let iou = iou_id.fetch();
           assert!(iou.cash > 0);
           assert!(self.sender == iou.owner);
           iou_id.mutual_transfer(self.receiver)
       }
   }
```

在上述定义中，`receiver`可以签署一份`IouSender`合同，合同中包含发行方的账户地址（`sender`）。`sender`拥有一项名为`send_iou`的权利，能够向`receiver`转移价值大于 0 的借据。由于`send_iou`的接收器为`&mut self`，因此行使完该项权利后，对应的`IouSender`合同不会作废，因此`sender`能够持续向`receiver`转移借据。由于`IouSender`合同由`receiver`签署，因此它了解对许可了合同中的所有内容，而行使`send_iou`权利时也经过了的`sender`的授权，因此在执行至第 15 行行使`mutual_transfer`权利时，同时获得了`receiver`与`sender`的授权，因此能够执行成功。上述过程的工作流可以表述如下：

```eval_rst
.. code-block:: rust
   :linenos:

   // Bob allows Alice to send him Ious.
   test::set_caller(bob);
   let sender_alice = sign! { IouSender =>
       sender: alice,
       receiver: bob,
   };
   test::pop_execution_context();

   // Charlie allows Bob to send him Ious.
   test::set_caller(charlie);
   let sender_bob = sign! { IouSender =>
       sender: bob,
       receiver: charlie,
   };
   test::pop_execution_context();

   // Alice can now send the Iou she issued herself earlier.
   test::set_caller(alice);
   let iou = sender_alice.send_iou(iou);
   test::pop_execution_context();

   // Bob sends it on to Charlie.
   test::set_caller(bob);
   let iou = sender_bob.send_iou(iou);
   test::pop_execution_context();
```

## PDC 中的权限模型

上述示例有助于帮助我们建立关于 PDC 如何管理授权的直觉认识，接下来我们将学习关于 PDC 中权限模型的正式表述，以便能够合理地推测协作的运行模式或编写正确的协作，从而保障权利不会被恶意使用。

PDC 将签署合同、行权及查询合同内容同意称为**动作**，每个动作都可能包含其他动作，例如在前述示例中，行使`send_iou`权利是就会`mutual_transfer`权利。这种存在直接因果关系的动作在 PDC 中分别称之为**父动作**与**子动作**，整个关系链中第一个动作被称之为**根动作**。每次执行动作时，都有一个必要授权方（Required Authorizers）集合`RA`（即根据定义执行该动作必须要经过哪些参与方的授权），以及一个已授权方（Authorizers）集合`A`（即实际行使该动作时，哪些参与方已经授过权）。PDC 中的权限模型要求执行每个动作时，`RA`必须是`A`的子集。

`RA`的构造方式：

-   如果是行使权利，则`RA`就是由`#[liquid(rights_belong_to)]`或`#[liquid(belongs_to)]`属性注明的权利所属方组成的集合；

-   如果是签署合同，则`RA`就是由`#[liquid(signers)]`属性注明的合同签署方组成的集合；

-   如果是查询合同内同，则`RA`是空集。

`A`的构造方式：

-   如果是根动作，则`A`仅包含发起交易的账户地址；

-   如果是子动作，则`A`是父动作的`A`与执行父动作的合同的签署方集合的并集。

以前述 Bob 通过行使`send_iou`权利向 Charlie 转移借据为例，解释 PDC 权限模型的工作机制：

1. Bob 发起交易行使`send_iou`权利，此时为根动作，因此`A` = `[Bob]`；

2. 由于`send_iou`只允许合同中的`sender`执行，因此`RA` = `[Bob]`；

3. 满足`RA` ⊆ `A`，开始执行`send_iou`；

4. 执行过程需要行使`mutual_transfer`权利，此时`A` = `[Bob, Charlie]`，`RA` = `[Bob, Charlie]`；

5. 满足`RA` ⊆ `A`，开始执行`mutual_transfer`；

6. 执行过程中需要签署`Iou`合同，此时`A` = `[Alice, Bob, Charlie]`，`RA` = `[Alice，Charlie]`；

7. 满足`RA` ⊆ `A`，成功创建`Iou`合同。
