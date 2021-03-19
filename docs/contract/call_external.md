# 外部合约调用

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
    .. code-block:: rust
       :linenos:

       #[liquid::interface(name = auto)]
       mod kv_table {
           use super::entry::*;
           // ...
       }
    ```

- 自定义数据结构：使用`struct`结构体语法，用于声明外部合约中所使用到自定义数据结构，如：

    ```eval_rst
    .. code-block:: rust
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
    .. code-block:: rust
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

    由于在执行外部合约调用时需要计算目标方法的选择器，因此需要所声明的接口签名（包括接口名称及参数类型）与实际的被调用方法的签名完全一致，即使接口名称并不满足Rust编程规范中“函数名必须为snake_case式命名”的要求。为避免Rust编译器给出警告，Liquid会自动为所声明的方法添加`#[allow(non_snake_case)]`属性。

    在外部合约声明中，必须有且只能有一个`extern`代码块，且该代码块中需要有至少一个接口的声明。接口的声明中，只能包含相应外部方法的签名，而不能包含其实现。每个外部合约方法的第一个参数均需要是接收器，可以为`&self`或`&mut self`，用于表示相应接口是否为只读接口。所声明的接口的只读性需要和实际被调用方法的只读性一致，否则可能会导致调用失败。接口的声明中无需包含构造函数的声明。接口声明中所使用的参数及返回值类型均需要是ABI编解码器能够编解码的类型。

    由于Solidity语言支持重载语法，因此Solidity合约中可能会出现名称相同但参数不同的合约方法。为支持调用这些方法，Liquid允许您在接口声明中声明名称相同但参数类型不同的接口，Liquid将会使用特殊的方法对这些重载方法进行支持。但是需要注意的是，您只能在外部合约声明中使用这种语法。由于Rust本身并不支持重载语法，因此在合约的定义中您仍然无法使用方法重载。

    `extern`关键字后无需指定任何ABI类型，但是为防止某些代码补全工具自动将`extern`补全为`extern "C"`，您也可以写作`extern "liquid"`，此处的“"liquid"”仅仅是一个占位符，没有任何实际意义。

外部合约声明的描述对象与合约相同，两者均是对智能合约行为的表述，只是外部合约声明中并不包含其行为的具体实现，因此两者在语义上属于同等地位。当合约项目中包含外部合约声明时，较好的代码组织方式是将两者放置于同级的命名空间中，而不是在合约内部放置外部合约声明：

```eval_rst
.. code-block:: rust
   :linenos:
   :emphasize-lines: 1-10

   // Good programming practice
   #[liquid::interface(name = auto)]
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
       #[liquid::interface(name = auto)]
       mod entry {
           // ...
       }
       // ...
   }
```

## 使用外部合约

合约编译时，Liquid会在声明外部合约的模块中自动生成一个用于表示外部合约的类型，该类型可以用于调用外部合约或可将其用作合约方法或状态变量的类型，在后文中，我们称这个类型为外部合约类型。

您可能已经在前面的示例中注意到：在声明外部合约时，所使用的`#[liquid::interface(...)]`属性中包含了一个名为`name`的参数。`name`参数用于指定所生成的外部类型的名字，其参数可以为`auto`或一个字符串常量。当指定`name`参数为`auto`时，Liquid会自动选择外部合约声明所使用的模块名的“CamelCase”式命名作为外部合约类型的名字，例如在上述名为kv_table的外部合约声明中，由于`name`被指定为`auto`，因此所声明的外部合约类型名为KvTable；当指定`name`参数为一个字符串常量时，则外部合约类型的名字便是参数所指定的名称，例如上述外部合约声明也可以改写为：

```eval_rst
.. code-block:: rust
   :linenos:

   #[liquid::interface(name = "Foo")]
   mod kv_table {
       // ...
   }
```

此时用于表示kv_table的外部合约类型的名字便是“Foo”。

```eval_rst
.. admonition:: 注意

   请注意name = auto与name = "auto"的区别：前者的“auto”没有双引号，用于指示Liquid按照驼峰规则自动生成外部合约类型的名字；后者的“auto”有双引号，用于指示Liquid生成一个名为“auto”的的外部合约类型。
```

外部合约类型可以用在合约或外部合约声明中的任何位置：它们能够用作合约方法的参数或返回值类型，也可以用作状态变量或合约方法中临时变量的类型。使用外部合约类型时，需要在使用之前将其符号导入，如下列代码所示：

```eval_rst
.. code-block:: rust
   :linenos:

   #[liquid::interface(name = auto)]
   mod kv_table_factory {
       use super::kv_table::*;

       extern "liquid" {
           fn openTable(&self, name: String) -> KvTable;
           // ...
       }
   }

   #[liquid::contract(version = "0.2.0")]
   mod kv_table_test {
       use super::{kv_table_factory::*};
       use liquid_core::storage;

       #[liquid(storage)]
       struct KvTableTest {
          table_factory: storage::Value<KvTableFactory>,
       }
       //...
   }
```

您可以通过外部合约对象调用外部合约中的方法，可使用以下两种方式构造外部合约对象：

- 外部合约类型所提供的`at`函数。`at`是一个静态函数，其接受一个`address`类型的参数，其使用方式如下：

    ```eval_rst
    .. code-block:: rust
       :linenos:

       let entry = Entry::at("0x1001".parse().unwrap());
    ```

- 外部合约类型实现了`From<address>`特性，因此您可以通过显式的类型转换将一个`address`类型的对象转换为外部合约对象（同时外部合约类型也实现了`Into<address>`特性，因此外部合约类型可以和地址类型相互转换），其使用方式如下：

    ```eval_rst
    .. code-block:: rust
       :linenos:

       let addr: address = "0x1001".parse().unwrap();
       let entry: Entry = addr.into();
    ```

构造出外部合约对象后，您便能够通过成员函数的形式调用外部合约的方法，例如：

```eval_rst
.. code-block:: rust
   :linenos:

   let entry = Entry::at("0x1001".parse().unwrap());
   let i = entry.getInt().unwrap();
```

需要注意的是，当您声明某个外部合约方法的返回值为某个类型`T`时，Liquid会自动将该外部合约方法的返回值变换为`Option<T>`。当外部合约方法因为某些原因（如权限等）调用失败时，此时会向调用者返回`None`，您可以对返回值进行检查，以判断外部合约调用是否成功，从而当调用失败时，可以执行您所指定的错误处理逻辑。

外部合约中重载方法的调用方式较为特殊，Liquid会为重载方法生成一个特殊的、与重载函数同名的成员(而不是成员方法)，并自动为该成员的类型实现`Fn`、`FnOnce`、`FnMut`特性。相应地，调用重载方法的方式也需要是以下形式：

```eval_rst
.. code-block:: rust
   :linenos:

   (entry.set)(String::from("id"), id.clone());
   (entry.set)(String::from("item_price"), item_price);
   (entry.set)(String::from("item_name"), item_name);
```

若您不使用该语法调用重载方法，则会得到形式如下的编译器报错：

```text
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

特别地，在上述示例中，由于`set`是`Entry`类型的一个成员，您甚至可以在代码中使用如下方式调用`set`：

```eval_rst
.. code-block:: rust
   :linenos:

   let set = &entry.set;
   set(String::from("id"), id.clone());
   set(String::from("item_price"), item_price);
   set(String::from("item_name"), item_name);
```

## 单元测试

当在本地运行对合约的单元测试时，由于Liquid无法获知链上外部合约的具体实现逻辑，Liquid会使用[模拟对象](https://zh.wikipedia.org/wiki/%E6%A8%A1%E6%8B%9F%E5%AF%B9%E8%B1%A1)机制对外部合约进行模拟，从而使得即使不将合约部署至链上，也可以对包含了外部合约调用的合约方法进行测试。具体而言，您可以为外部合约方法设置“期望”，并在“期望”中指定外部合约方法的工作方式。

为某一外部合约方法设置“期望”，您首先要获取该合约方法的模拟上下文。Liquid会在外部合约类型中，为每一个外部合约方法生成一个以该方法名为前缀、且后缀为`_context`的静态函数，您可以通过调用该函数获取该方法的模拟上下文，例如：

```eval_rst
.. code-block:: rust
   :linenos:

   #[test]
   fn get_works() {
       let create_table_ctx = KvTableFactory::createTable_context();
   }
```

随后，你可以调用模拟上下文的`expect`方法，表示您希望创建一个对于该外部合约方法的“期望”：

```eval_rst
.. code-block:: rust
   :linenos:

   #[test]
   fn get_works() {
       let get_ctx = KvTable::get_context();
       get_ctx
           .expect()
           .when(predicate::eq(String::from("cat")))
           .returns_const((true, Entry::at(Default::default())));
   }
```

其中，`when`方法表示的语义是“若参数满足...条件时...”，其参数个数与外部合约方法参数数量相同，且每个参数都是一个关于对应外部合约方法参数的谓词，用于判断调用时传入的参数是否满足谓词的要求。`returns_const`方式表示的语义是“返回一个常量”，且要求返回的常量的类型会外部合约方法的类型一致。在上述示例中，我们所创建的“期望”是：调用`get`方法时，若第一个参数等于`"cat"`，则返回的常量(true, Entry::at(Default::default()))。

除了`when`方法，还可以调用`when_fn`方法，其作用与`when`方法类似，只是其参数为一个闭包，且闭包的参数数量及类型与外部合约方法一致。类似的，除`returns_const`方法外，您还可以使用`returns`方法，其参数同样为一个闭包，且且闭包的参数数量及类型、返回值类型与外部合约方法一致。例如，上述示例也可以改写为：

```eval_rst
.. code-block:: rust
   :linenos:

   #[test]
   fn get_works() {
       let get_ctx = KvTable::get_context();
       get_ctx
           .expect()
           .when_fn(|key| key == String::from("cat"))
           .returns(|_| (true, Entry::at(Default::default())));
   }
```

您可以在创建“期望”后不调用`when`或`when_fn`方法，此时表示“对于任意参数...”。下面的示例中，表示的语义为“对于任意的参数，均返回`(true, Entry::at(Default::default()))`”：

```eval_rst
.. code-block:: rust
   :linenos:

   #[test]
   fn get_works() {
       let get_ctx = KvTable::get_context();
       get_ctx
           .expect()
           .returns(|_| (true, Entry::at(Default::default())));
   }
```

您也可以在创建“期望”后不调用`returns`或`returns_const`方法，此时表示“返回一个默认值”，使用这种写法时，需要外部合约方法的返回值实现了`std::Default`特性。下面的示例中，表示的语义为“当参数等于`"cat"`时，返回`(bool, Entry)`类型的默认值”：

```eval_rst
.. code-block:: rust
   :linenos:

   #[test]
   fn get_works() {
       let get_ctx = KvTable::get_context();
       get_ctx
           .expect()
           .when_fn(|key| key == String::from("cat"))
   }
```

甚至，您可以既不调用`when`或`when_fn`方法，也不调用`returns`或`returns_const`方法，此时表示的语义为“对任意参数，均返回默认值”：

```eval_rst
.. code-block:: rust
   :linenos:

   #[test]
   fn get_works() {
       let get_ctx = KvTable::get_context();
       get_ctx.expect();
   }
```

除`returns`或`returns_const`方法外，您还可以调用`throws`方法，用于模拟外部合约调用失败时的场景，例如在下面的例子中，表示的语义为“当参数等于`"dog"`时，令外部合约调用失败”：

```eval_rst
.. code-block:: rust
   :linenos:

   #[test]
   fn get_works() {
       let get_ctx = KvTable::get_context();
       get_ctx
           .expect()
           .when_fn(|primary_key| primary_key == "dog")
           .throws();
   }
```

当外部合约中存在重载函数时，您需要在调用`expect`方法时通过传入类型参数以指定为哪一个重载方法创建期望，其中类型参数为一个元组，元组中包含了对应重载方法的全部参数类型。除此之外，其使用方式与普通合约方法一致，如下列代码所示：

```eval_rst
.. code-block:: rust
   :linenos:

   let entry_set_ctx = Entry::set_context();
   entry_set_ctx
       .expect::<(String, String)>();
```

每执行完一个单元测试用例，所有外部合约方法的期望均会被清空，且不同单元测试用例之间的期望互不影响。您可以为同一个外部合约方法创建多个“期望”，当运行单元测试时，会按照先入先出的顺序对参数进行匹配，并执行第一个匹配成功的“期望”所包含的行为。若没有任何“期望”与参数成功匹配，则会引发panic，其提示信息如下所示：

```text
thread 'kv_table_test::tests::set_works' panicked at 'no matched expectation is found for `getString(&self, key: String)` in `Entry`'
```

少数时候，外部合约的方法中可能恰好包含与模拟上下文获取函数（`xxx_context`）同名的方法，如下列代码所示：

```eval_rst
.. code-block:: rust
   :linenos:

   #[liquid::interface(name = auto)]
   mod foo {
       extern {
           fn foo();
           // Ops, what a coincidence...
           fn foo_context();
       }
   }
```

此时若Liquid再生成一个同名的`foo_context`函数的话，会导致编译时报重复定义错误。为避免发生这种情况，Liquid允许您为外部合约方法标注一个名为`liquid(mock_context_getter = "...")`的属性，其参数为一个字符串常量，此时Liquid会按照您所提供的名字生成模拟上下文获取函数，因此上述示例可以改写为如下形式：

```eval_rst
.. code-block:: rust
   :linenos:

   #[liquid::interface(name = auto)]
   mod foo {
       extern {
           fn foo();
           // The compiler will be happy.
           #[liquid(mock_context_getter = "my_foo_context")]
           fn foo_context();
       }
   }
```

此时，若需要在单元测试中获取`foo_context`函数的模拟上下文，则可以通过调用`my_foo_context`函数：

```eval_rst
.. code-block:: rust
   :linenos:

   let foo_context_ctx = Foo::my_foo_context();
```
