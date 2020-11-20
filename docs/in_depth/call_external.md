# 外部合约调用

智能合约之间可以互相调用彼此的公开方法

## 外部合约声明

当您需要调用外部合约时，您需要在代码中编写所调用外部合约的声明。同合约类似，声明外部合约需要使用`mod`模块语法，并模块前添加`#[liquid::interface(...)]`属性：

```eval_rst
.. code-block:: rust
   :linenos:

   #[liquid::interface(name = auto)]
   mod entry {
       // ...
   }
```

在外部合约声明中，可以声明以下内容：

- 符号引入：使用`use ... as ...`语法，用于在外部合约声明所使用的模块中引入定义在外部的符号，如：

    ```eval_rst
    .. code-block:: rst
       :linenos:

       #[liquid::interface(name = auto)]
       mod kv_table {
           use super::entry::*;
           // ...
       }
    ```

- 自定义数据结构：使用`struct`结构体语法，用于声明外部合约中所使用到自定义数据结构，如：

    ```eval_rst
    .. code-block:: rst
       :linenos:

        #[liquid::interface(name = auto)]
        mod kv_table {
            use super::entry::*;

            struct Result {
                success: bool,
                value: Entry,
            }
            // ...
        }
    ```

    所声明的自定义数据结构中，不允许为成员指定可见性。同时，由于外部合约声明中的自定义数据结构一般会用作外部合约方法的参数及返回值类型，因此Liquid会自动为这些数据结构添加`#[derive(liquid_lang::InOut)]`属性。

- 合约方法：使用`extern`语法声明要调用的外部合约接口，如：

    ```eval_rst
    .. code-block:: rst
       :linenos:

        #[liquid::interface(name = auto)]
        mod entry {
            extern {
                fn getInt(&self, key: String) -> i256;
                fn getUint(&self, key: String) -> u256;
                fn getAddress(&self, key: String) -> address;
                fn getString(&self, key: String) -> String;

                fn set(&mut self, key: String, value: i256);
                fn set(&mut self, key: String, value: u256);
                fn set(&mut self, key: String, value: address);
                fn set(&mut self, key: String, value: String);
            }
        }
    ```

    由于在执行外部合约调用时需要计算目标方法的选择器，因此需要所声明的接口签名（包括接口名称及参数类型）与实际的被调用方法的签名完全一致，即使接口名称并不满足Rust编程规范中“函数名必须为snake_case形式”的要求。为避免Rust编译器给出警告，Liquid会自动为所声明的方法添加`#[allow(non_snake_case)]`属性。

    在外部合约声明中，必须有且只能有一个`extern`代码块，且该代码块中需要有至少一个接口的声明。接口的声明中，只能包含相应外部方法的签名，而不能包含其实现。每个外部合约方法的第一个参数均需要是接收器，可以为`&self`或`&mut self`，用于表示相应接口是否为只读接口。所声明的接口的只读性需要和实际被调用方法的只读性一致，否则可能会导致调用失败。接口的声明中无需包含构造函数的声明。接口声明中所使用的参数及返回值类型均需要是ABI编解码器能够编解码的类型。

    由于Solidity语言支持重载语法，因此Solidity合约中可能会出现名称相同但参数不同的合约方法。为支持调用这些方法，Liquid允许您在接口声明中声明名称相同但参数类型不同的接口，Liquid将会使用特殊的方法对这些重载方法进行支持。但是需要注意的是，您只能在外部合约声明中使用这种语法。由于Rust本身并不支持重载语法，因此在合约的定义中您仍然无法使用方法重载。

    `extern`关键字后无需指定任何ABI类型，但是为防止某些代码补全工具自动将`extern`补全为`extern "C"`，您也可以写作`extern "liquid"`，此处的“"liquid"”仅仅是一个占位符，没有任何实际意义。

外部合约声明的描述对象与合约相同，两者均是对智能合约行为的表述，只是外部合约声明中并不包含其行为的具体实现，因此两者在语义上属于同等地位。当合约项目中包含外部合约声明时，较好的代码组织方式是将两者放置于同级的命名空间中，而不是在合约内部放置外部合约声明：

```eval_rst
.. code-block:: rust
   :linenos:
   :emphasize-lines: 1-10

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
