# 外部合约 Mock

当合约中包含外部合约声明时，由于合约的所有单元测试均在本地执行，因此执行单元测试时，Liquid 无法获知实际外部合约的具体实现逻辑。为能够对包含有外部合约调用的合约进行单元测试，Liquid 使用[模拟对象](https://zh.wikipedia.org/wiki/%E6%A8%A1%E6%8B%9F%E5%AF%B9%E8%B1%A1)机制对外部合约进行模拟，从而使得即使不将合约部署至链上，也可以对包含有外部合约调用的合约进行测试。具体而言，可以为外部合约方法设置**期望**，并通过期望指定在测试时，外部合约方法应当以何种方式进行工作。

为了能够给某一外部合约方法设置期望，首先需要获取该合约方法的模拟上下文。在测试合约时，Liquid 会通过外部合约类型为每一个外部合约方法生成一个静态的模拟上下文获取方法。模拟上下文获取方法的名称形如`<method_name>_context`，其中`<method_name>`为对应外部合约方法的名称。模拟上下文获取方法不接受任何参数。通过调用模拟上下文获取方法便可以获得对应外部合约方法的模拟上下文，例如：

```eval_rst
.. code-block:: rust
   :linenos:
   :emphasize-lines: 13

   #[liquid::interface(name = auto)]
   mod kv_table {
       use super::entry::*;

       extern "liquid" {
           fn get(&self, primary_key: String) -> (bool, Entry);
           fn set(&mut self, primary_key: String, entry: Entry) -> u8;
           ...
       }
   }

   #[test]
   fn get_works() {
       let get_ctx = KvTable::get_context();
   }
```

随后，通过调用模拟上下文的`expect`方法，便能够创建一个对该外部合约方法的期望，随后能够通过期望指定该合约方法的工作方式，例如：

```eval_rst
.. code-block:: rust
   :linenos:
   :emphasize-lines: 5-7

   #[test]
   fn get_works() {
       let get_ctx = KvTable::get_context();
       get_ctx
           .expect()
           .when(predicate::eq(String::from("cat")))
           .returns((true, Entry::at(Default::default())));
   }
```

上述代码示例中，`when`方法的语义是“若参数满足...条件时...”，其参数个数与外部合约方法参数数量相同，且每个参数都是一个关于对应外部合约方法参数的谓词，用于判断调用外部合约方法时传入的参数是否满足谓词的要求。`returns`方法的语义是“返回一个固定值”，其参数为期望外部合约方法返回的固定值，且要求该固定值的类型与该外部合约方法的返回值类型一致。综上所述，我们对`get`方法创建的期望是：调用该方法时，若第一个参数为`"cat"`，则返回的固定值`(true, Entry::at(Default::default()))`。

除了`when`方法，还可以使用`when_fn`方法，其作用与`when`方法类似，只是其参数为一个闭包，闭包的参数数量及类型与外部合约方法一致，且在闭包中能够实现更加复杂的谓词逻辑。类似地，除`returns`方法外，还可以使用`returns_fn`方法，其参数同样为一个闭包，且闭包的参数数量及类型、返回值数量及类型与外部合约方法一致。上述示例也可以改写为如下等价的形式：

```eval_rst
.. code-block:: rust
   :linenos:
   :emphasize-lines: 6-7

   #[test]
   fn get_works() {
       let get_ctx = KvTable::get_context();
       get_ctx
           .expect()
           .when_fn(|key| key == String::from("cat"))
           .returns_fn(|_| (true, Entry::at(Default::default())));
   }
```

在创建期望后可以不调用`when`或`when_fn`方法，此时表示的语义时“对于任意参数...”。例如在下面的示例中，创建的期望为：对于任意的参数，`get`方法均返回`(true, Entry::at(Default::default()))`：

```eval_rst
.. code-block:: rust
   :linenos:

   #[test]
   fn get_works() {
       let get_ctx = KvTable::get_context();
       get_ctx
           .expect()
           .returns_fn(|_| (true, Entry::at(Default::default())));
   }
```

类似地，在创建期望后也可以不调用`returns`或`returns_fn`方法，此时表示的语义是“返回一个默认值”。这种使用方式需要外部合约方法返回值的类型实现了[`Default`](https://doc.rust-lang.org/beta/core/default/trait.Default.html) trait。例如在下面的示例中，创建的期望为：当第一个参数等于`"cat"`时，`set`方法返回`u8`类型的默认值，即 0：

```eval_rst
.. code-block:: rust
   :linenos:

   #[test]
   fn set_works() {
       let set_ctx = KvTable::set_context();
       set_ctx
           .expect()
           .when_fn(|key| key == String::from("cat"))
   }
```

甚至，可以既不调用`when`或`when_fn`方法，也不调用`returns`或`returns_fn`方法，此时表示的语义为“对任意参数，均返回默认值”。例如在下面的示例中，创建的期望为：对于任意的参数，`set`方法均回`u8`类型的默认值，即 0：

```eval_rst
.. code-block:: rust
   :linenos:

   #[test]
   fn set_works() {
       let set_ctx = KvTable::set_context();
       set_ctx.expect();
   }
```

除了`returns`或`returns_fn`方法外，还可以调用`throws`方法，用于模拟外部合约方法调用失败时的场景。例如在下面的例子中，创建的期望为：当参数等于`"dog"`时，`get`方法调用失败：

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

当外部合约中存在重载函数时，需要在调用`expect`方法时传入类型参数以指定为哪一个重载方法创建期望。类型参数为一个元组，元组中依次排列对应重载方法的全部参数类型。除此之外，使用方式与普通合约方法一致，如下列代码所示：

```eval_rst
.. code-block:: rust
   :linenos:

   let entry_set_ctx = Entry::set_context();
   entry_set_ctx
       .expect::<(String, String)>();
```

每当执行完一个单元测试用例，所有外部合约方法的期望均会被清空，因此不同单元测试用例之间的期望互不影响。

可以为同一个外部合约方法创建多个期望。当执行单元测试用例时，会按照先入先出的顺序使用期望中的参数谓词对参数进行匹配，并执行第一个匹配成功的期望所指定的行为。若没有任何期望与参数成功匹配，则会引发`panic`，其提示信息如下所示：

```text
thread 'kv_table_test::tests::set_works' panicked at 'no matched expectation is found for `getString(&self, key: String)` in `Entry`'
```

在少部分情况下，外部合约声明中可能恰好包含一个与模拟上下文获取方法同名的外部合约方法，如下列代码所示：

```eval_rst
.. code-block:: rust
   :linenos:
   :emphasize-lines: 6

   #[liquid::interface(name = auto)]
   mod foo {
       extern {
           fn foo();
           // Oops, what a coincidence...
           fn foo_context();
       }
   }
```

此时若 Liquid 再生成一个同名的`foo_context`方法，则会导致编译器报告重复定义的错误。为避免这种情况发生，Liquid 允许为外部合约方法标注名为`#[liquid(mock_context_getter)]`的属性，其参数为一个字符串常量，用于告知 Liquid 在为该合约方法生成模拟上下文获取方法时，使用属性中指定的方法名。基于这一机制，上述示例可以改写为如下形式：

```eval_rst
.. code-block:: rust
   :linenos:
   :emphasize-lines: 6

   #[liquid::interface(name = auto)]
   mod foo {
       extern {
           fn foo();
           // The compiler will be happy.
           #[liquid(mock_context_getter = "liquid_is_fun")]
           fn foo_context();
       }
   }
```

此时，若需要在单元测试用例中获取`foo_context`方法的模拟上下文，则可以通过调用`liquid_is_fun`函数：

```eval_rst
.. code-block:: rust
   :linenos:

   let foo_ctx = Foo::liquid_is_fun();
```
