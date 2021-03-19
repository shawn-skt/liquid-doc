# 测试外部合约

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
