# 外部合约调用

智能合约之间可以互相调用彼此的公开方法

## 外部合约声明

当您需要在Liquid项目中调用外部合约时，您需要在项目中声明所调用外部合约的接口。外部合约接口声明与合约均是一个合约的代表（尽管接口中没有实现），因此在语义上外部合约接口与合约时同级的，与合约类似，您也需要通过模块语法声明外部合约接口，并在该模块前添加`#[liquid::interface(...)]`属性：

```rust
#[liquid::interface]
mod entry {
    // ...
}
```

一个项目中可以声明多个外部合约

外部合约声明（interface）的描述对象与合约（contract）相同，两者均用于对智能合约的行为进行表述，只是外部合约声明中并不包含其行为的具体实现，因此两者在语义上属于同等地位。当合约项目中包含外部合约声明时，较好的代码组织方式是将两者放置于同级的命名空间中，而不是在合约内部放置外部合约声明：

```eval_rst
.. code-block:: rust
   :linenos:

   // Good programming practice
   #[liquid::interface]
   mod entry {
       // ...
   }

   #[liquid::contract(version = "0.2.0")]
   mod kv_table_test {
       // ...
   }

   // Bad programming practice
   #[liquid::contract(version = "0.2.0")]
   mod kv_table_test {
       #[liquid::interface]
       mod entry {
           // ...
       }

       // ...
   }
```
