# 合约模块

为开发 Liquid 合约，首先需要在代码中通过`use`关键字引入`liquid_lang`库，`liquid_lang`库包含智能合约解析功能的实现：

```eval_rst
.. code-block:: rust
   :linenos:

   use liquid_lang as liquid;
```

上述代码使用`as`关键字将`liquid_lang`库重命名为`liquid`，此后便可以通过这个较短的名字使用`liquid_lang`库提供的所有功能。

Liquid 使用 Rust 语言中的模块（`mod`）语法创建合约，在`mod`关键字之后是合约模块名。合约模块名能够自定义，但是建议按照 Rust 语言代码风格为其命名（即小写加下划线形式），以防编译器发出风格警告。合约模块需要使用`#[liquid::contract]`属性进行标注，以向 Liquid 告知该该模块中包含有智能合约各个组成部分的定义，从而引导 Liquid 解析该合约：

```eval_rst
.. code-block:: rust
   :linenos:
   :emphasize-lines: 1

   #[liquid::contract]
   mod hello_world {
       ...
   }
```

Rust 语言中支持为模块声明可见性（如`pub`、`pub(crate)`等），可用于控制当前模块能否被其他模块使用。然而对于 Liquid 而言，由于所有合约都会对外部可见，因此模块的可见性声明并无实际意义。为避免引发歧义，Liquid 禁止为合约模块添加任何可见性声明。例如，下列试图将合约模块的可见性声明为`pub`的代码会引发编译时报错：

<div class="wrong-example">

```eval_rst
.. code-block:: rust
   :linenos:
   :emphasize-lines: 2

   #[liquid::contract]
   pub mod hello_world {
       ...
   }
```

</div>

除此之外，合约模块必须是内联的，即智能合约各个组成部分的定义都必须放置于合约模块名后、由花体括号`{}`括起的代码块中，从而保证 Liquid 能够完整解析智能合约。非内联形式的模块声明是非法的，例如：

<div class="wrong-example">

```eval_rst
.. code-block:: rust
   :linenos:
   :emphasize-lines: 2

   #[liquid::contract]
   mod hello_world;
```

</div>

合约模块创建完成后，便能够继续在其中定义[状态变量](./state.md)、[合约方法](./method.md)及[事件](./event.md)。
