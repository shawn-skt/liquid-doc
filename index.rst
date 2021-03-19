==============
Liquid
==============

Liquid由微众银行区块链团队开发并完全开源，是一种基于 `Rust语言 <https://www.rust-lang.org/>`_ 的 `嵌入式领域特定语言 <http://wiki.haskell.org/Embedded_domain_specific_language>`_ （ embedded Domain Specific Language，eDSL），能够用于编写在 `FISCO BCOS <https://github.com/FISCO-BCOS/FISCO-BCOS>`_ 区块链底层平台上运行的智能合约。

智能合约开发者可以通过Liquid提供的特殊属性标注来表达智能合约中特有的语义，例如在下列的代码片段中，分别通过 ``#[liquid(storage)]`` 及 ``#[liquid(methods)]`` 属性标注对智能合约的状态变量及外部方法进行了定义：

.. code-block:: rust
   :linenos:
   :emphasize-lines: 3,8

   ...

       #[liquid(storage)]
       struct HelloWorld {
          name: storage::Value<String>,
       }

       #[liquid(methods)]
       impl HelloWorld {
           pub fn new(&mut self) {
               self.name.initialize(String::from("Alice"));
           }

   ...


在编译阶段，Liquid会通过Rust语言中的宏系统对智能合约代码进行展开，并将其变换为区块链底层平台对应的具体实现，开发者则完全无需关这些细节，因而能够更高效地进行智能合约开发。同时，Liquid还提供专有开发工具，能够将Liquid智能合约编译为 `Wasm <https://webassembly.org/>`_ 格式字节码，从而使得Liquid智能合约能够在搭载有Wasm虚拟机的区块链底层平台中运行。使用Liquid编写的智能合约，其自身也是合法的Rust语言代码，在整个软件开发周期中均能够结合现有的Rust语言标准工具链进行开发。

.. hint::

   为了能够更好地使用Liquid进行智能合约开发，我们强烈建议提前参考 `Rust语言官方教程 <https://doc.rust-lang.org/book/>`_ 掌握Rust语言的基础知识，尤其借用、生命周期、属性等关键概念。

微众银行区块链团队秉承多方参与、资源共享、友好协作和价值整合的理念，将Liquid项目完全向公众开源，并专设有智能合约编译技术专项兴趣小组（CTSC-SIG），欢迎广大企业及技术爱好者踊跃参与Liquid项目共建。

* `GitHub主页 <https://github.com/FISCO-BCOS/liquid>`_
* `公众号 <_static/images/public_account.png>`_

--------
关键特性
--------

.. raw:: html

   <div class="features">
      <div class="feature">
         <img class="feature-icon" src="_static/images/safety.svg" alt="safety">
         <div class="feature-title">
            <span class ="zh-title">安全</span>
            <p class="title-initial">S</p><p class="title-rest">afety</p>
         </div>
            <ul>
               <li>
                  内置<a href="./docs/contract/asset.html">线性资产模型</a>，对安全可控、不可复制的资产类型进行了高级抽象，确保链上资产类应用具备金融级安全性
               </li>
               <li>
                  支持在智能合约内部便捷地编写单元测试用例，可通过内嵌的区块链模拟环境直接在本地运行
               </li>
               <li>
                  内置算数溢出及内存越界安全检查
               </li>
               <li>
                  能够结合模糊测试等工具进行深度测试
               </li>
               <li>
                  未来将进一步集成形式化验证技术
               </li>
            </ul>
      </div>
      <hr/>
      <div class="feature">
         <img class="feature-icon" src="_static/images/performance.svg" alt="performance">
         <div class="feature-title">
            <span class ="zh-title">高效</span>
            <p class="title-initial">P</p><p class="title-rest">erformance</p>
         </div>
         <ul>
            <li>
               配合Rust语言后端LLVM优化器，支持将智能合约代码编译为可移植、体积小、加载快Wasm格式字节码
            </li>
            <li>
               结合Tree-Shaking技术及wasm-opt等工具，能够进一步压缩智能合约体积
            </li>
            <li>
               对Wasm执行引擎进行了深度优化，辅以并行化等技术，最终实现对于同类型智能合约，Liquid版实现对比Solidity版实现约有30%的性能提升<sup>*</sup>
            </li>
         </ul>
      </div>
      <hr/>
      <div class="feature">
         <img class="feature-icon" src="_static/images/experience.svg" alt="experience">
         <div class="feature-title">
            <span class ="zh-title">体验友好</span>
            <p class="title-initial">E</p><p class="title-rest">xperience</p>
         </div>
         <ul>
            <li>
               支持使用Rust语言提供的大部分现代语言特性（如移动语义及自动类型推导等）
            </li>
            <li>
               提供专有开发工具及编辑器插件辅助开发，配合Rust语言标准工具链，使智能合约开发过程如丝般顺滑
            </li>
            <li>
               丰富的标准库及第三方组件，能够充分复用已有功能，避免重复开发
            </li>
         </ul>
      </div>
      <hr/>
      <div class="feature">
         <img class="feature-icon" src="_static/images/customization.svg" alt="customization">
         <div class="feature-title">
            <span class ="zh-title">可定制化</span>
            <p class="title-initial">C</p><p class="title-rest">ustomization</p>
         </div>
         <ul>
            <li>
               能够根据业务需求对编程模型、语言文法的进行深度定制，例如目前已的集成<a href="./docs/pdc/index.html">可编程分布式协作编程模型</a>
            </li>
            <li>
               可定制的特性使Liquid拥有无限的可能性，未来还将进一步探索如何与隐私保护、跨链协同等功能相结合
            </li>
         </ul>
      </div>
   </div>

.. toctree::
   :caption: 快速开始

   docs/quickstart/prerequisite.md
   docs/quickstart/example.md

.. toctree::
   :caption: 基本合约

   docs/contract/contract_mod.md
   docs/contract/state.md
   docs/contract/method.md
   docs/contract/event.md
   docs/contract/types.md
   docs/contract/intrinsic.md
   docs/contract/call_external.md
   docs/contract/asset.md


.. toctree::
   :caption: 可编程分布式协作

   docs/pdc/introduction.md
   docs/pdc/basic.md
   docs/pdc/selector.md
   docs/pdc/right.md
   docs/pdc/utilities.md
   docs/pdc/authority.md


.. toctree::
   :caption: 测试专区

   docs/testing/test_api.md

.. toctree::
   :caption: 进阶主题

   docs/advance/design.md
   docs/advance/compile_options.md
   docs/advance/bei.md
   docs/advance/bwci.md

