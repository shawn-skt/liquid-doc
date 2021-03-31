==============
Liquid
==============

不断多样化、复杂化的应用场景为智能合约编程语言带来了全新挑战：分布式、不可篡改的执行环境要求智能合约具备更强的隐私安全性与鲁棒性；日渐扩大的服务规模要求智能合约能够更加高效运行；智能合约开发过程需要对开发者更加友好；对于跨链协同等不断涌现的新型计算范式，也需要能够提供原生抽象。在上述背景下，微众银行区块链团队提出了 **SPEC** 设计规范，即智能合约编程语言应当涵盖安全（Security）、性能（Performance）、体验（Experience）及可定制（Customization） 四大要旨。

微众银行区块链团队结合对智能合约技术的理解与掌握，选择以 Rust 语言为载体对 **SPEC** 设计规范进行工程化实现，即 Liquid 项目。Liquid 对 **SPEC** 设计规范中的技术要旨提供了全方位支持，能够用来编写运行于区块链底层平台 `FISCO BCOS <https://github.com/FISCO-BCOS/FISCO-BCOS>`_ 的智能合约。

--------
关键特性
--------

.. raw:: html

   <div class="features">
      <div class="feature">
         <img class="feature-icon" src="_static/images/safety.svg" alt="safety">
         <div class="feature-title">
            <span class ="zh-title">安全</span>
            <p class="title-initial">S</p><p class="title-rest">ecurity</p>
         </div>
            <ul>
               <li>
                  提供<a href="./docs/asset/asset.html">线性资产模型</a>确保链上资产类应用具备金融级安全性
               </li>
               <li>
                  支持在智能合约内部便捷地编写单元测试用例，可通过内嵌的区块链模拟环境直接在本地执行
               </li>
               <li>
                  内置算数溢出及内存越界安全检查
               </li>
               <li>
                  能够结合模糊测试等工具进行深度测试
               </li>
               <li>
                  未来将进一步集成形式化验证及数据隐私保护技术
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
               配合LLVM优化器，支持将智能合约代码编译为可移植、体积小、加载快Wasm格式字节码
            </li>
            <li>
               结合Tree-Shaking等技术，能够进一步压缩智能合约体积
            </li>
            <li>
               对Wasm执行引擎进行了深度优化，支持交易并行化等技术
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
               支持使用大部分现代语言特性（如移动语义及自动类型推导等）
            </li>
            <li>
               提供专有开发工具及编辑器插件辅助开发，使智能合约开发过程如丝般顺滑
            </li>
            <li>
               丰富的标准库及第三方组件，充分复用已有功能，避免重复开发
            </li>
         </ul>
      </div>
      <hr/>
      <div class="feature">
         <img class="feature-icon" src="_static/images/customization.svg" alt="customization">
         <div class="feature-title">
            <span class ="zh-title">定制能力</span>
            <p class="title-initial">C</p><p class="title-rest">ustomization</p>
         </div>
         <ul>
            <li>
               能够根据业务需求对编程模型、语言文法的进行深度定制。目前已集成<a href="./docs/pdc/introduction.html">可编程分布式协作编程模型</a>
            </li>
            <li>
               未来将进一步探索如何与跨链协同等编程范式相结合
            </li>
         </ul>
      </div>
   </div>

--------
合作共建
--------

微众银行区块链团队秉承多方参与、资源共享、友好协作和价值整合的理念，将Liquid项目完全向公众开源，并专设有智能合约编译技术专项兴趣小组（CTSC-SIG），欢迎广大企业及技术爱好者踊跃参与Liquid项目共建。

* `GitHub主页 <https://github.com/WeBankBlockchain/liquid>`_
* `Gitee主页 <https://gitee.com/WebankBlockchain/liquid>`_
* `公众号 <../../_static/images/public_account.png>`_
* `CTSC-SIG <https://mp.weixin.qq.com/s/NfBZtPWxXdnP0XLLGrQKow>`_



.. toctree::
   :hidden:
   :caption: 快速开始

   docs/quickstart/prerequisite.md
   docs/quickstart/example.md

.. toctree::
   :hidden:
   :caption: 基础语法

   docs/contract/contract_mod.md
   docs/contract/state.md
   docs/contract/method.md
   docs/contract/event.md
   docs/contract/types.md
   docs/contract/intrinsic.md
   docs/contract/call_external.md

.. toctree::
   :hidden:
   :caption: 开发与测试

   docs/dev_testing/development.md
   docs/dev_testing/compile_options.md
   docs/dev_testing/test_api.md
   docs/dev_testing/test_external.md

.. toctree::
   :hidden:
   :caption: 线性资产模型

   docs/asset/asset.md

.. toctree::
   :hidden:
   :caption: 可编程分布式协作

   docs/pdc/introduction.md
   docs/pdc/basic.md
   docs/pdc/selector.md
   docs/pdc/right.md
   docs/pdc/utilities.md
   docs/pdc/authority.md
   docs/pdc/design_pattern.md

.. toctree::
   :hidden:
   :caption: 参考

   docs/advance/metaprogramming.md
   docs/advance/architecture.md
   docs/advance/fbei.md
   docs/advance/fbwci.md
