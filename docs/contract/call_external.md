# 外部合约调用

## 外部合约声明

当需要调用外部合约时，需要首先在代码中声明外部合约所包含的公开方法。同合约模块类似，外部合约声明也需要使用模块（`mod`）模块语法，并需要在模块定义前使用`#[liquid::interface]`属性进行标注，例如：

```eval_rst
.. code-block:: rust
   :linenos:
   :emphasize-lines: 1

   #[liquid::interface(name = auto)]
   mod entry {
       ...
   }
```

在用于声明外部合约的模块中，可以使用以下语法元素：

-   符号引入：使用`use ... as ...`语法，以将在模块外部定义的符号引入至当前模块中，例如：

    ```eval_rst
    .. code-block:: rust
       :linenos:
       :emphasize-lines: 3

       #[liquid::interface(name = auto)]
       mod kv_table {
           use super::entry::*;
           ...
       }
    ```

-   结构体类型定义：使用`struct`结构体语法定义新的结构体类型，该结构体类型之后可用于定义外部合约公开方法的参数或返回值的类型，例如：

    ```eval_rst
    .. code-block:: rust
       :linenos:
       :emphasize-lines: 3-6

        #[liquid::interface(name = auto)]
        mod kv_table {
            struct Result {
                success: bool,
                value: Entry,
            }
            ...
        }
    ```

    所定义的结构体类型中，不允许为成员指定可见性。同时，由于外部合约声明中的结构体类型定义一般会用于定义外部合约方法的参数或返回值的类型，因此 Liquid 会自动为这些结构体类型添加`#[derive(liquid_lang::InOut)]`属性，请勿重复标注该属性。

-   合约方法声明：所有外部合约公开方法的声明都需要封装于`extern`关键字后、由花体括号`{}`括起的代码块中，例如：

    ```eval_rst
    .. code-block:: rust
       :linenos:
       :emphasize-lines: 3-6

        #[liquid::interface(name = auto)]
        mod entry {
            extern "liquid" {
                fn getInt(&self, key: String) -> i256;
                ...
            }
        }
    ```

    不允许为外部合约方法的声明添加任何可见性声明，因为这些方法必定都是公开的。由于在执行外部合约调用时需要计算目标方法的选择器，因此需要所声明的方法签名（包括方法名称及参数类型）与目标方法的实际签名完全一致，即使方法名称可能并不满足 Rust 语言编程规范中关于“方法名必须使用 snake_case 式命名”的要求。为避免 Rust 编译器报出代码风格警告，Liquid 会自动为所有外部合约方法的声明添加`#[allow(non_snake_case)]`属性。

    在用于外部合约声明的模块中，必须有且只能有一个`extern`代码块，且该代码块中需要有至少一个合约方法的声明。`extern`代码块中，只能包含外部合约公开方法的签名，而不能包含其实现。每个外部合约公开方法的签名中，第一个参数必须为接收器，可以为`&self`或`&mut self`，用于表示该方法是否为只读方法。所声明的的只读性必须要和目标方法的只读性一致，否则可能会导致调用失败。外部合约公开方法的声明中无需包含构造函数的声明。

    <!-- 由于 Solidity 语言支持重载语法，即 Solidity 合约中可能会出现名称相同但参数不同的合约方法。为支持调用这些方法，Liquid 允许在`extern`代码块中声明名称相同但参数类型不同的外部合约公开方法。由于 Rust 语言本身不支持重载语法，因此 Liquid 将会使用特殊手段对这些重载方法提供支持，例如： -->

    <!-- ```eval_rst
    .. code-block:: rust
       :linenos:
       :emphasize-lines: 4-7


       #[liquid::interface(name = auto)]
       mod entry {
           extern "solidity" {
               fn set(&mut self, key: String, value: i256);
               fn set(&mut self, key: String, value: u256);
               fn set(&mut self, key: String, value: Address);
               fn set(&mut self, key: String, value: String);
               ...
           }
       }
    ``` -->

    <!-- ```eval_rst
    .. admonition:: 注意

       只能在用于外部合约声明的模块中使用这种语法，合约代码中仍然无法使用重载语法。
    ``` -->

    <!-- `extern`关键字后的字符串`"solidity"`用于表示所声明的外部合约使用[ABI 编解码](https://solidity.readthedocs.io/en/v0.7.1/abi-spec.html#formal-specification-of-the-encoding)方案对参数即返回值进行编解码，当前 Liquid 中仅支持调用这类外部合约。 -->

外部合约声明的描述对象与合约模块相同，两者均是对智能合约行为的描述，只是外部合约声明中并不包含其行为的具体实现，因此两者在语义上属于同等地位。当需要声明外部合约时，较好的代码组织方式是将外部合约声明与合约模块放置于同级的命名空间中，而不是在合约模块内部放置外部合约声明：

<div class="wrong-example">

```eval_rst
.. code-block:: rust
   :linenos:
   :emphasize-lines: 13-20

   // Good programming practice (•‿•).
   #[liquid::interface(name = auto)]
   mod entry {
       ...
   }

   #[liquid::contract]
   mod kv_table_test {
       ...
   }

   // Bad programming practice (×﹏×).
   #[liquid::contract]
   mod kv_table_test {
       #[liquid::interface(name = auto)]
       mod entry {
           ...
       }
       ...
   }
```

</div>

## 调用外部合约

构建合约时，Liquid 会在声明外部合约的模块中自动生成一个代表外部合约的类型，在后文中，我们称这个类型为外部合约类型。外部合约类型可以用于构造外部合约对象，通过外部合约对象便可调用外部合约公开方法。

尽管我们始终没有解释，但从前面的示例可以观察到，在声明外部合约时，所使用的`#[liquid::interface]`属性中包含了一个名为`name`的参数。`name`参数用于指定所生成的外部合约类型的名字，其参数可以为`auto`或一个字符串常量。当指定`name`参数为`auto`时，Liquid 会将声明外部合约所使用的模块名的“CamelCase”式命名作为外部合约类型的名字。例如在上述名为 `kv_table` 的外部合约声明中，由于`name`参数被指定为`auto`，因此所声明的外部合约类型名为 `KvTable`；当`name`参数为一个字符串常量时，则外部合约类型的名字是参数所指定的名称。例如，若将上述外部合约声明改写为：

```eval_rst
.. code-block:: rust
   :linenos:
   :emphasize-lines: 1

   #[liquid::interface(name = "Foo")]
   mod kv_table {
       ...
   }
```

此时外部合约类型的名称便是`Foo`。

```eval_rst
.. admonition:: 注意

   请注意 ``name = auto`` 与 ``name = "auto"`` 的区别：前者的 ``auto`` 没有双引号，用于指示Liquid按照驼峰规则自动生成外部合约类型名称；后者的 ``auto`` 带有有双引号，用于指示Liquid生成一个名为 ``auto`` 的外部合约类型。
```

外部合约类型可以用在合约模块或外部合约声明中的任何位置。外部合约类型既能够用于定义合约方法参数或返回值的类型，也可以用于定义状态变量或临时变量的类型。使用外部合约类型时，需要先将其符号导入，导入方式如下列代码所示：

```eval_rst
.. code-block:: rust
   :linenos:
   :emphasize-lines: 11, 15

   #[liquid::interface(name = auto)]
   mod kv_table_factory {
       extern "liquid" {
           fn openTable(&self, name: String) -> KvTable;
           ...
       }
   }

   #[liquid::contract]
   mod kv_table_test {
       use super::{kv_table_factory::*};

       #[liquid(storage)]
       struct KvTableTest {
          table_factory: storage::Value<KvTableFactory>,
       }
       ...
   }
```

需要先通过外部合约类型构造出外部合约对象后，才能通过外部合约对象调用外部合约公开方法。可使用下列两种方式构造外部合约对象：

-   外部合约类型所提供的`at`方法。`at`是一个静态方法，其接受一个`Address`类型的参数，其使用方式如下：

    ```eval_rst
    .. code-block:: rust
       :linenos:

       let entry = Entry::at("0x1001".parse().unwrap());
    ```

-   外部合约类型实现了`From<Address>` trait，因此可以通过显式的类型转换将一个`Address`类型对象转换为外部合约对象。同时，外部合约类型也实现了`Into<Address>` trait，因此外部合约类型可以和地址类型相互转换。类型转换的使用方式如下：

    ```eval_rst
    .. code-block:: rust
       :linenos:

       let addr_1: Address = "0x1001".parse().unwrap();
       let entry: Entry = addr_1.into();
       let addr_2: Address = entry.into();
       assert_eq!(addr_1, addr_2);
    ```

构造出外部合约对象后，便能够通过成员方法的形式调用外部合约公开方法，如下列代码所示：

```eval_rst
.. code-block:: rust
   :linenos:
   :emphasize-lines: 2

   let entry = Entry::at("0x1001".parse().unwrap());
   let i = entry.getInt().unwrap();
```

注意在上述代码中，当声明某个外部合约方法的返回值类型为`T`时，Liquid 会在构建合约时自动将该外部合约方法的返回值变换为`Option<T>`。当外部合约方法因为某些原因（如权限等）调用失败时，此时则会返回`None`，否则返回包含实际返回值的`Some`。基于这一机制，可以根据返回值的内容判断外部合约调用是否成功，从而当外部合约方法调用失败时，继续执行指定的错误处理逻辑。

外部合约中重载方法的调用方式较为特殊，Liquid 会为重载方法生成一个特殊的、与重载方法同名的**成员**（注意不是成员方法）。该成员的类型也经过特殊处理，自动实现了`Fn`、`FnOnce`、`FnMut`等 trait。相应地，也需要使用如下的特殊方式调用重载方法：

```eval_rst
.. code-block:: rust
   :linenos:
   :emphasize-lines: 1-3

   (entry.set)(String::from("id"), id.clone());
   (entry.set)(String::from("item_price"), item_price);
   (entry.set)(String::from("item_name"), item_name);
```

注意到上述代码中，`entry.set`的两边都是用括号`()`括起。若不使用该方式调用外部合约的重载方法，例如去掉`entry.set`两边的括号，则会导致编译时报错如下：

```
┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈
error[E0599]: no method named `set` found for struct `entry::__liquid_private::Entry` in the current scope
  --> $DIR/13-interface.rs:94:19
   |
6  | mod entry {
   | --------- method `set` not found for this
...
94 |             entry.set(String::from("id"), id.clone());
   |                   ^^^ field, not a method
   |
help: to call the function stored in `set`, surround the field access with parentheses
   |
94 |             (entry.set)(String::from("id"), id.clone());
   |             ^         ^
┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈┈
```

特别地，在上述示例中，由于`set`是`Entry`类型的一个成员，因而在代码中可以先获取`set`成员的引用，然后再进行调用：

```eval_rst
.. code-block:: rust
   :linenos:
   :emphasize-lines: 1

   let set = &entry.set;
   set(String::from("id"), id.clone());
   set(String::from("item_price"), item_price);
   set(String::from("item_name"), item_name);
```
