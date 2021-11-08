# 特殊数据类型及宏

## ContractId 类型

`ContractId`是 Liquid 提供的原生数据类型，在协作中用于存储合同 ID，无需导入即可直接使用。`ContractId`是一种泛型数据类型，其类型定义如下：

```eval_rst
.. code-block:: rust
   :linenos:

    pub struct ContractId<T> {
        ...
    }
```

其中类型参数`T`必须为合同模板类型，因此下列代码会导致编译时报错：

<div class="wrong-example">

```eval_rst
.. code-block:: rust
   :linenos:
   :emphasize-lines: 1

   let something: ContractId<u8> = ...;
```

</div>

`ContractId`类型实现了标准库中的`Copy`、`Clone`、`PartialEq` trait，因此可以方便地进行值拷贝及相等性比较：

```eval_rst
.. code-block:: rust
   :linenos:

   let a: ContractId<Ballot> = ...;
   let b = a;
   assert_eq!(a, b);
```

`ContractId`类型能够在协作中的任何地方使用，但是当应用于定义合同模板成员、权利入参或返回值的类型时，其对外表现与`u32`类型一致。例如，假设协作中存在如下合同模板的定义：

```eval_rst
.. code-block:: rust
   :linenos:

   #[liquid(contract)]
   pub struct Offer {
       #[liquid(signers)]
       owner: Address,
       item_id: ContractId<Item>,
   }
```

通过 Node.js CLI 工具的`sign`命令签署生成`Offer`合同时，可以按照如下方式执行：

```shell
node ./cli.js sign Offer 0x144d5ca47de35194b019b6f11a56028b964585c9 1
```

注意在上述命令中，对第二项参数（即`item_id`）直接赋予整数 1。待交易被执行时，整数 1 会被 Liquid 自动转换为对应的`ContractId`类型变量，权利入参的传参及转换过程类似。当权利的返回值类型包括`ContractId`类型时，Liquid 会将其自动转换为整数并返回。

`ContractId`类型不仅用于存储合同 ID，更是对应合同的全权代表，当需要在权利代码中行使其他合同的权利或查询其他合同的数据内容时，均需要通过`ContractId`才能实现。例如在下列示例代码中，`Offer`合同模板中的`settle`权利能够直接通过合同自身的`item_id`成员（`ContractId<Item>`类型）直接调用`Item`合同模板中定义的`transfer_item`权利：

```eval_rst
.. code-block:: rust
   :linenos:

   #[liquid(rights_belong_to = "owner")]
   impl Item {
       pub fn transfer_item(self, new_owner: Address) -> ContractId<Item> {
           ...
       }
   }

   #[liquid(rights_belong_to = "owner")]
   impl Offer {
       pub fn settle(self, buyer: Address) -> ContractId<Item> {
           self.item_id.transfer_item(buyer)
       }
   }
```

需要注意的是，在上述示例中，`transfer_item`权利的接收器会使被行权的`Item`合同在执行结束后作废，因此若试图继续通过同样的`item_id`行权时，会引发“合同已作废”的运行时错误。

除了能够执行所指向合同中的权利，`ContractId`类型还实现了名为`fetch`的特殊方法，用于在代码中获取所指向合同中的数据类容，例如：

```eval_rst
.. code-block:: rust
   :linenos:

   pub fn buy_item(&self, offer_id: ContractId<Offer>) {
       let offer = offer_id.fetch();
       let vendor = offer.vendor;
       ...
   }
```

需要注意的是，在上述示例中，只能从`offer`变量中读取`offer_id`所对应合同中的数据内容，但无法基于`offer`变量行使任何`Offer`合同模板中定义的权利。

## sign!宏

`sign!`宏是 Liquid 原生提供的过程宏，用于在权利的执行过程中签订新的合同，无需导入即可直接使用，其使用方式如下所示：

```eval_rst
.. code-block:: rust
   :linenos:

   pub fn add(mut self, voter_addr: Address) -> ContractId<Ballot> {
       ...

       sign! { Ballot =>
           voters: self.voters,
           ..self
       }
    }
```

`sign!`宏的语法由三部分组成：合同模板名称、向右箭头（`=>`）及成员赋值。其中，合同模板名称必须是有效的合同模板类型名称，且不能使用`Self`指代自身；成员赋值部分的语法与 Rust 语言中[结构体赋值语法](https://doc.rust-lang.org/reference/expressions/struct-expr.html#functional-update-syntax)相同，但需要注意的是，成员赋值中包含 StructBase 语法时（即上述示例中的`..self`，其中`self`也可以换为其他表达式），务必需要保证`..`后的表达式的数据类型与待签署的合同模板类型一致。若`sign!`宏执行成功，则返回一个`ContractId`类型变量，变量中存储着由`sign!`宏签署生成的合同的 ID。

```eval_rst
.. admonition:: 注意

   ``sign!`` 宏是权利执行过程中唯一合法的构造 ``ContractId`` 类型变量的方式。
```
